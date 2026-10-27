class MedicationSchedule {
  const MedicationSchedule({
    required this.id,
    required this.date,
    required this.time,
    required this.type,
    required this.description,
    required this.status,
  });

  final String id;
  final String date;
  final String time;
  final String type;
  final String description;
  final String status;

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) {
    return MedicationSchedule(
      id: json['id']?.toString() ?? '${json['tanggal']}-${json['jam']}',
      date: json['tanggal'] as String? ?? '',
      time: json['jam'] as String? ?? '',
      type: json['jenis'] as String? ?? '',
      description: json['keterangan'] as String? ?? '',
      status: json['status'] as String? ?? 'belum_terkonfirmasi',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tanggal': date,
    'jam': time,
    'jenis': type,
    'keterangan': description,
    'status': status,
  };

  MedicationSchedule copyWith({String? status}) => MedicationSchedule(
    id: id,
    date: date,
    time: time,
    type: type,
    description: description,
    status: status ?? this.status,
  );
}
