import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../data/models/dose_log.dart';
import '../data/models/medication_schedule.dart';
import '../data/models/patient_profile.dart';
import '../data/repositories/patient_repository.dart';

class AppProvider extends ChangeNotifier {
  AppProvider(this._repository);

  final PatientRepository _repository;
  bool isLoading = true;
  bool isActivated = false;
  bool consentGranted = false;
  bool isBusy = false;
  int pendingCount = 0;
  String? errorMessage;
  PatientProfile? profile;
  List<MedicationSchedule> schedules = [];
  List<DoseLog> history = [];
  DateTime? deferredUntil;

  MedicationSchedule? get todayDose {
    final today = _dateAt(DateTime.now());
    for (final schedule in schedules) {
      if (schedule.date == today && schedule.type == 'minum') {
        for (final log in history.reversed) {
          if (log.scheduleId == schedule.id) {
            return schedule.copyWith(status: log.status);
          }
        }
        return schedule;
      }
    }
    return null;
  }

  Future<void> initialize() async {
    try {
      consentGranted = await _repository.hasConsent();
      profile = await _repository.fetchProfile();
      schedules = await _repository.getSchedule();
      history = await _repository.getHistory();
      pendingCount = await _repository.pendingSyncCount();
      isActivated = profile != null;
    } on DioException {
      errorMessage = 'Data belum dapat dimuat. Silakan coba kembali.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> activate(String code) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      isActivated = await _repository.activate(code);
      if (!isActivated) {
        errorMessage = 'Kode aktivasi tidak cocok. Periksa kembali kode Anda.';
        return false;
      }
      profile = await _repository.fetchProfile();
      schedules = await _repository.getSchedule();
      return true;
    } on DioException {
      errorMessage = 'Aktivasi belum berhasil. Periksa koneksi dan coba lagi.';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> acceptConsent() async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.saveConsent(true, AppConstants.consentVersion);
      consentGranted = true;
    } on DioException {
      errorMessage = 'Persetujuan belum tersimpan. Silakan coba kembali.';
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> recordDose(String status) async {
    final dose = todayDose;
    if (dose == null) return;
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.recordDose(dose, status);
      if (status == 'ditunda') {
        deferredUntil = DateTime.now().add(const Duration(minutes: 10));
      }
      await refreshRecords();
    } on DioException {
      errorMessage =
          'Konfirmasi disimpan di perangkat, tetapi belum tersinkron.';
      schedules = await _repository.getSchedule();
      history = await _repository.getHistory();
      pendingCount = await _repository.pendingSyncCount();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> refreshRecords() async {
    schedules = await _repository.getSchedule();
    history = await _repository.getHistory();
    pendingCount = await _repository.pendingSyncCount();
    notifyListeners();
  }

  Future<void> syncPending() async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.syncPendingLogs();
      await refreshRecords();
    } on DioException {
      errorMessage = 'Belum tersinkron. Data tetap tersimpan di perangkat.';
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  static String _dateAt(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
