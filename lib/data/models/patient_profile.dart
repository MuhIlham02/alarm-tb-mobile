class PatientProfile {
  const PatientProfile({
    required this.name,
    required this.medicalRecordNumber,
    required this.prescription,
    required this.medicationTime,
    required this.familySupport,
    this.controlDate = '',
    this.medicationPickupDate = '',
  });

  final String name;
  final String medicalRecordNumber;
  final String prescription;
  final String medicationTime;
  final String familySupport;
  final String controlDate;
  final String medicationPickupDate;

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      name: json['nama'] as String? ?? '',
      medicalRecordNumber: json['no_rm'] as String? ?? '',
      prescription: json['resep'] as String? ?? '',
      medicationTime: json['jam_minum'] as String? ?? '',
      familySupport: json['pmo'] as String? ?? '',
      controlDate: json['jadwal_kontrol'] as String? ?? '',
      medicationPickupDate: json['jadwal_ambil_obat'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'nama': name,
    'no_rm': medicalRecordNumber,
    'resep': prescription,
    'jam_minum': medicationTime,
    'pmo': familySupport,
    'jadwal_kontrol': controlDate,
    'jadwal_ambil_obat': medicationPickupDate,
  };
}
