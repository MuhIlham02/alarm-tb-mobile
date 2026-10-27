import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../models/dose_log.dart';
import '../models/medication_schedule.dart';
import '../models/patient_profile.dart';
import 'patient_repository.dart';

class ApiPatientRepository implements PatientRepository {
  ApiPatientRepository({
    required Dio dio,
    required SharedPreferences preferences,
  }) : _dio = dio,
       _preferences = preferences;

  final Dio _dio;
  final SharedPreferences _preferences;
  static const _logsKey = 'api_patient_dose_logs';
  static const _profileKey = 'api_patient_profile';
  static const _scheduleKey = 'api_patient_schedule';
  static const _uuid = Uuid();

  @override
  Future<bool> activate(String code) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/aktivasi',
      data: {'kode_aktivasi': code},
    );
    return response.data?['berhasil'] as bool? ?? true;
  }

  @override
  Future<PatientProfile?> fetchProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/profil');
      final data = response.data;
      if (data == null) return null;
      final profileJson = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;
      await _preferences.setString(_profileKey, jsonEncode(profileJson));
      return PatientProfile.fromJson(profileJson);
    } on DioException {
      final cachedProfile = _preferences.getString(_profileKey);
      if (cachedProfile == null) rethrow;
      return PatientProfile.fromJson(
        jsonDecode(cachedProfile) as Map<String, dynamic>,
      );
    }
  }

  @override
  Future<bool> hasConsent() async =>
      _preferences.getBool('api_patient_consent') ?? false;

  @override
  Future<void> saveConsent(bool agreed, String version) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/consent',
      data: {'setuju': agreed, 'versi': version},
    );
    await _preferences.setBool('api_patient_consent', agreed);
  }

  @override
  Future<List<MedicationSchedule>> getSchedule() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/jadwal',
        queryParameters: {'zona_waktu': AppConstants.timeZone},
      );
      final data = response.data;
      if (data == null) return [];
      final entries = data['jadwal'] as List<dynamic>? ?? [];
      await _preferences.setString(_scheduleKey, jsonEncode(entries));
      return entries
          .map(
            (entry) =>
                MedicationSchedule.fromJson(entry as Map<String, dynamic>),
          )
          .toList();
    } on DioException {
      final cachedSchedule = _preferences.getString(_scheduleKey);
      if (cachedSchedule == null) rethrow;
      final entries = jsonDecode(cachedSchedule) as List<dynamic>;
      return entries
          .map(
            (entry) =>
                MedicationSchedule.fromJson(entry as Map<String, dynamic>),
          )
          .toList();
    }
  }

  @override
  Future<void> recordDose(MedicationSchedule schedule, String status) async {
    final logs = _readLogs();
    logs.add(
      DoseLog(
        clientUuid: _uuid.v4(),
        scheduleId: schedule.id,
        date: schedule.date,
        time: schedule.time,
        status: status,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    await _saveLogs(logs);
    await syncPendingLogs();
  }

  @override
  Future<List<DoseLog>> getHistory() async => _readLogs();

  @override
  Future<int> pendingSyncCount() async =>
      _readLogs().where((log) => !log.synced).length;

  @override
  Future<void> syncPendingLogs() async {
    final logs = _readLogs();
    for (var index = 0; index < logs.length; index++) {
      final log = logs[index];
      if (log.synced) continue;
      try {
        await _dio.post<Map<String, dynamic>>(
          '/api/v1/log-minum/sinkron',
          data: {
            'client_uuid': log.clientUuid,
            'jadwal_id': log.scheduleId,
            'tanggal': log.date,
            'jam': log.time,
            'status': log.status,
            'waktu_konfirmasi': log.createdAt,
          },
        );
        logs[index] = log.copyWith(synced: true);
      } on DioException {
        await _saveLogs(logs);
        rethrow;
      }
    }
    await _saveLogs(logs);
  }

  List<DoseLog> _readLogs() {
    final raw = _preferences.getString(_logsKey);
    if (raw == null) return [];
    final values = (jsonDecode(raw) as List<dynamic>);
    return values
        .map((value) => DoseLog.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveLogs(List<DoseLog> logs) => _preferences.setString(
    _logsKey,
    jsonEncode(logs.map((log) => log.toJson()).toList()),
  );
}
