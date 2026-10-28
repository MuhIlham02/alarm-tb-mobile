import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/dose_log.dart';
import '../models/medication_schedule.dart';
import '../models/patient_profile.dart';
import 'patient_repository.dart';

class ApiPatientRepository implements PatientRepository {
  ApiPatientRepository({
    required Dio dio,
    required SharedPreferences preferences,
  }) : _dio = dio,
       _preferences = preferences {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Accept'] = 'application/json';
          final token = _preferences.getString(_tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final SharedPreferences _preferences;

  static const _tokenKey = 'api_patient_sanctum_token';
  static const _consentKey = 'api_patient_consent';
  static const _logsKey = 'api_patient_dose_logs';
  static const _profileKey = 'api_patient_profile';
  static const _scheduleKey = 'api_patient_schedule';
  static const _uuid = Uuid();

  @override
  Future<bool> activate(String code) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/aktivasi',
        data: {
          'kode': code.trim(),
          'nama_perangkat': 'Aplikasi Pasien Flutter',
        },
      );

      final data = response.data;
      final token = data?['token'] as String?;
      if (token == null || token.isEmpty) return false;

      await _preferences.setString(_tokenKey, token);

      final profilRaw = data?['profil'];
      if (profilRaw is Map<String, dynamic>) {
        final consentServer = profilRaw['consent_disetujui'] == true;
        await _preferences.setBool(_consentKey, consentServer);
        await _preferences.setString(_profileKey, jsonEncode(profilRaw));
      }

      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<PatientProfile?> fetchProfile() async {
    final token = _preferences.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/profil');
      final data = response.data;
      if (data == null) return null;

      final profileJson = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;

      if (profileJson.containsKey('consent_disetujui')) {
        await _preferences.setBool(
          _consentKey,
          profileJson['consent_disetujui'] == true,
        );
      }

      await _preferences.setString(_profileKey, jsonEncode(profileJson));
      return _parseProfileSafely(profileJson);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await _clearAuthSession();
        return null;
      }

      final cachedProfile = _preferences.getString(_profileKey);
      if (cachedProfile == null) return null;
      return _parseProfileSafely(
        jsonDecode(cachedProfile) as Map<String, dynamic>,
      );
    }
  }

  @override
  Future<bool> hasConsent() async =>
      _preferences.getBool(_consentKey) ?? false;

  @override
  Future<void> saveConsent(bool agreed, String version) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/consent',
      data: {'setuju': agreed},
    );
    await _preferences.setBool(_consentKey, agreed);
  }

  @override
  Future<List<MedicationSchedule>> getSchedule() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/jadwal',
        queryParameters: {'hari': 30},
      );
      final data = response.data;
      if (data == null) return [];

      final entries = data['jadwal'] as List<dynamic>? ?? [];
      await _preferences.setString(_scheduleKey, jsonEncode(entries));
      return entries
          .map((e) => _parseScheduleSafely(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      final cachedSchedule = _preferences.getString(_scheduleKey);
      if (cachedSchedule == null) return [];
      final entries = jsonDecode(cachedSchedule) as List<dynamic>;
      return entries
          .map((e) => _parseScheduleSafely(e as Map<String, dynamic>))
          .toList();
    }
  }

  @override
  Future<void> recordDose(MedicationSchedule schedule, String status) async {
    final normalizedStatus = status == 'ditunda' ? 'ditunda' : 'diminum';
    final logs = _readLogs();
    logs.add(
      DoseLog(
        clientUuid: _uuid.v4(),
        scheduleId: schedule.id,
        date: schedule.date,
        time: schedule.time,
        status: normalizedStatus,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    await _saveLogs(logs);

    // Offline-first: jika gagal konek saat kirim, biarkan tersimpan di antrean lokal
    try {
      await syncPendingLogs();
    } on DioException {
      // Akan disinkronkan ulang saat koneksi tersedia
    }
  }

  @override
  Future<List<DoseLog>> getHistory() async => _readLogs();

  @override
  Future<int> pendingSyncCount() async =>
      _readLogs().where((log) => !log.synced).length;

  @override
  Future<void> syncPendingLogs() async {
    final logs = _readLogs();
    final pendingLogs = logs.where((log) => !log.synced).take(100).toList();
    if (pendingLogs.isEmpty) return;

    final payloadItems = pendingLogs.map((log) {
      final parsedJadwalId = int.tryParse(log.scheduleId.toString());
      final statusValid = log.status == 'ditunda' ? 'ditunda' : 'diminum';
      return {
        'client_uuid': log.clientUuid,
        'jadwal_id': parsedJadwalId ?? log.scheduleId,
        'status': statusValid,
        'waktu_konfirmasi': log.createdAt,
      };
    }).toList();

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/log-minum/sinkron',
      data: {'items': payloadItems},
    );

    final hasilList = response.data?['hasil'] as List<dynamic>? ?? [];
    final processedUuids = <String>{};

    for (final item in hasilList) {
      if (item is Map<String, dynamic>) {
        final uuid = item['client_uuid']?.toString();
        final statusHasil = item['hasil']?.toString();
        if (uuid != null &&
            (statusHasil == 'dicatat' ||
                statusHasil == 'sudah_ada' ||
                statusHasil == 'ditolak')) {
          processedUuids.add(uuid);
        }
      }
    }

    for (var i = 0; i < logs.length; i++) {
      if (!logs[i].synced && processedUuids.contains(logs[i].clientUuid)) {
        logs[i] = logs[i].copyWith(synced: true);
      }
    }

    await _saveLogs(logs);
  }

  PatientProfile _parseProfileSafely(Map<String, dynamic> raw) {
    final adapted = Map<String, dynamic>.from(raw);
    adapted.putIfAbsent('no_rm', () => 'Pasien Aktif');

    try {
      return PatientProfile.fromJson(adapted);
    } catch (_) {
      final pmoRaw = raw['pmo'];
      String pmoText = 'Belum ditentukan';
      if (pmoRaw is Map<String, dynamic>) {
        final namaPmo = pmoRaw['nama'] ?? '';
        final hubPmo = pmoRaw['hubungan'] ?? '';
        pmoText = hubPmo.toString().isNotEmpty
            ? '$namaPmo ($hubPmo)'
            : namaPmo.toString();
      } else if (pmoRaw is String && pmoRaw.isNotEmpty) {
        pmoText = pmoRaw;
      }

      final resepRaw = raw['resep'];
      String resepText = 'Sesuai petunjuk petugas';
      if (resepRaw is List && resepRaw.isNotEmpty) {
        resepText = resepRaw
            .map((r) {
              if (r is Map<String, dynamic>) {
                final obat = r['nama_obat'] ?? '';
                final dosis = r['dosis_teks'] ?? '';
                final fase = r['fase'] ?? '';
                return '$obat ($dosis) - Fase $fase';
              }
              return r.toString();
            })
            .join(', ');
      } else if (resepRaw is String && resepRaw.isNotEmpty) {
        resepText = resepRaw;
      }

      return PatientProfile.fromJson({
        ...adapted,
        'pmo': pmoText,
        'resep': resepText,
        'resep_aktif': resepText,
        'jam_minum': raw['jam_minum_default'] ?? '07:00',
      });
    }
  }

  MedicationSchedule _parseScheduleSafely(Map<String, dynamic> raw) {
    try {
      return MedicationSchedule.fromJson(raw);
    } catch (_) {
      return MedicationSchedule.fromJson({
        ...raw,
        'id': raw['id']?.toString() ?? '0',
        'keterangan': raw['keterangan']?.toString() ?? '',
      });
    }
  }

  Future<void> _clearAuthSession() async {
    await _preferences.remove(_tokenKey);
    await _preferences.remove(_profileKey);
    await _preferences.remove(_consentKey);
  }

  List<DoseLog> _readLogs() {
    final raw = _preferences.getString(_logsKey);
    if (raw == null) return [];
    final values = jsonDecode(raw) as List<dynamic>;
    return values
        .map((value) => DoseLog.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveLogs(List<DoseLog> logs) => _preferences.setString(
    _logsKey,
    jsonEncode(logs.map((log) => log.toJson()).toList()),
  );
}