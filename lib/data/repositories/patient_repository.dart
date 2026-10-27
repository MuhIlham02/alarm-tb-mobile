import '../models/dose_log.dart';
import '../models/medication_schedule.dart';
import '../models/patient_profile.dart';

abstract interface class PatientRepository {
  Future<bool> activate(String code);
  Future<PatientProfile?> fetchProfile();
  Future<bool> hasConsent();
  Future<void> saveConsent(bool agreed, String version);
  Future<List<MedicationSchedule>> getSchedule();
  Future<void> recordDose(MedicationSchedule schedule, String status);
  Future<List<DoseLog>> getHistory();
  Future<int> pendingSyncCount();
  Future<void> syncPendingLogs();
}
