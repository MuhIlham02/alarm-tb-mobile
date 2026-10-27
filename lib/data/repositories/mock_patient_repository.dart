import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../models/dose_log.dart';
import '../models/medication_schedule.dart';
import '../models/patient_profile.dart';
import 'patient_repository.dart';

class MockPatientRepository implements PatientRepository {
  MockPatientRepository(this._preferences);

  final SharedPreferences _preferences;
  static const _activatedKey = 'patient_activated';
  static const _consentKey = 'patient_consent';
  static const _profileKey = 'patient_profile';
  static const _logsKey = 'patient_dose_logs';
  static const _uuid = Uuid();

  PatientProfile get _seedProfile => PatientProfile(
    name: 'Sutrisno',
    medicalRecordNumber: '000101',
    prescription: 'OAT KDT Fase Intensif',
    medicationTime: '07:00',
    familySupport: 'PMO keluarga',
    controlDate: _dateAt(DateTime.now().add(const Duration(days: 7))),
    medicationPickupDate: _dateAt(DateTime.now().add(const Duration(days: 14))),
  );

  @override
  Future<bool> activate(String code) async {
    if (code != AppConstants.activationCode) return false;
    await _preferences.setBool(_activatedKey, true);
    await _preferences.setString(
      _profileKey,
      jsonEncode(_seedProfile.toJson()),
    );
    return true;
  }

  @override
  Future<PatientProfile?> fetchProfile() async {
    if (!(_preferences.getBool(_activatedKey) ?? false)) return null;
    final value = _preferences.getString(_profileKey);
    if (value == null) return _seedProfile;
    return PatientProfile.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  @override
  Future<bool> hasConsent() async => _preferences.getBool(_consentKey) ?? false;

  @override
  Future<void> saveConsent(bool agreed, String version) async {
    await _preferences.setBool(_consentKey, agreed);
    await _preferences.setString('consent_version', version);
  }

  @override
  Future<List<MedicationSchedule>> getSchedule() async {
    final now = DateTime.now();
    final schedules = <MedicationSchedule>[];
    for (var daysAgo = 29; daysAgo >= 0; daysAgo--) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: daysAgo));
      final dateString = _dateAt(date);
      final existing = _logForDate(dateString);
      final status =
          existing?.status ??
          (daysAgo == 0 ? 'belum_terkonfirmasi' : 'terlewat');
      schedules.add(
        MedicationSchedule(
          id: 'minum-$dateString',
          date: dateString,
          time: _seedProfile.medicationTime,
          type: 'minum',
          description: _seedProfile.prescription,
          status: status,
        ),
      );
    }
    schedules.addAll([
      MedicationSchedule(
        id: 'kontrol-${_seedProfile.controlDate}',
        date: _seedProfile.controlDate,
        time: '--:--',
        type: 'kontrol',
        description: 'Jadwal kontrol',
        status: 'terjadwal',
      ),
      MedicationSchedule(
        id: 'ambil-${_seedProfile.medicationPickupDate}',
        date: _seedProfile.medicationPickupDate,
        time: '--:--',
        type: 'ambil_obat',
        description: 'Jadwal ambil obat',
        status: 'terjadwal',
      ),
    ]);
    return schedules;
  }

  @override
  Future<void> recordDose(MedicationSchedule schedule, String status) async {
    final logs = _readLogs();
    final existingIndex = logs.indexWhere(
      (log) => log.scheduleId == schedule.id,
    );
    final log = DoseLog(
      clientUuid: _uuid.v4(),
      scheduleId: schedule.id,
      date: schedule.date,
      time: schedule.time,
      status: status,
      createdAt: DateTime.now().toIso8601String(),
    );
    if (existingIndex >= 0) {
      logs[existingIndex] = log;
    } else {
      logs.add(log);
    }
    await _saveLogs(logs);
  }

  @override
  Future<List<DoseLog>> getHistory() async => _readLogs();

  @override
  Future<int> pendingSyncCount() async =>
      _readLogs().where((log) => !log.synced).length;

  @override
  Future<void> syncPendingLogs() async {
    final logs = _readLogs().map((log) => log.copyWith(synced: true)).toList();
    await _saveLogs(logs);
  }

  List<DoseLog> _readLogs() {
    final raw = _preferences.getString(_logsKey);
    if (raw == null) return [];
    final values = jsonDecode(raw) as List<dynamic>;
    return values
        .map((value) => DoseLog.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  DoseLog? _logForDate(String date) {
    for (final log in _readLogs()) {
      if (log.date == date) return log;
    }
    return null;
  }

  Future<void> _saveLogs(List<DoseLog> logs) => _preferences.setString(
    _logsKey,
    jsonEncode(logs.map((log) => log.toJson()).toList()),
  );

  static String _dateAt(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
