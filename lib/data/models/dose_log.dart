class DoseLog {
  const DoseLog({
    required this.clientUuid,
    required this.scheduleId,
    required this.date,
    required this.time,
    required this.status,
    required this.createdAt,
    this.synced = false,
  });

  final String clientUuid;
  final String scheduleId;
  final String date;
  final String time;
  final String status;
  final String createdAt;
  final bool synced;

  factory DoseLog.fromJson(Map<String, dynamic> json) {
    return DoseLog(
      clientUuid: json['client_uuid'] as String? ?? '',
      scheduleId: json['jadwal_id'] as String? ?? '',
      date: json['tanggal'] as String? ?? '',
      time: json['jam'] as String? ?? '',
      status: json['status'] as String? ?? 'belum_terkonfirmasi',
      createdAt: json['waktu_konfirmasi'] as String? ?? '',
      synced: json['tersinkron'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'client_uuid': clientUuid,
    'jadwal_id': scheduleId,
    'tanggal': date,
    'jam': time,
    'status': status,
    'waktu_konfirmasi': createdAt,
    'tersinkron': synced,
  };

  DoseLog copyWith({bool? synced}) => DoseLog(
    clientUuid: clientUuid,
    scheduleId: scheduleId,
    date: date,
    time: time,
    status: status,
    createdAt: createdAt,
    synced: synced ?? this.synced,
  );
}
