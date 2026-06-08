class PrescriptionItem {
  final int? id;
  final int? prescriptionId;
  final int medicineId;
  final String medicineName;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final int quantity;

  PrescriptionItem({
    this.id,
    this.prescriptionId,
    required this.medicineId,
    required this.medicineName,
    this.dosage,
    this.frequency,
    this.duration,
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'prescription_id': prescriptionId,
    'medicine_id': medicineId,
    'medicine_name': medicineName,
    'dosage': dosage,
    'frequency': frequency,
    'duration': duration,
    'quantity': quantity,
  };

  factory PrescriptionItem.fromMap(Map<String, dynamic> map) => PrescriptionItem(
    id: map['id'] as int?,
    prescriptionId: map['prescription_id'] as int?,
    medicineId: map['medicine_id'] as int,
    medicineName: map['medicine_name'] as String,
    dosage: map['dosage'] as String?,
    frequency: map['frequency'] as String?,
    duration: map['duration'] as String?,
    quantity: map['quantity'] as int,
  );
}

class PrescriptionModel {
  final int? id;
  final String patientName;
  final String? patientPhone;
  final String? doctorName;
  final DateTime prescriptionDate;
  final String? notes;
  final String status;
  final DateTime? createdAt;
  final List<PrescriptionItem>? items;

  PrescriptionModel({
    this.id,
    required this.patientName,
    this.patientPhone,
    this.doctorName,
    required this.prescriptionDate,
    this.notes,
    this.status = 'active',
    this.createdAt,
    this.items,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'patient_name': patientName,
    'patient_phone': patientPhone,
    'doctor_name': doctorName,
    'prescription_date': prescriptionDate.toIso8601String(),
    'notes': notes,
    'status': status,
    'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  factory PrescriptionModel.fromMap(Map<String, dynamic> map) => PrescriptionModel(
    id: map['id'] as int?,
    patientName: map['patient_name'] as String,
    patientPhone: map['patient_phone'] as String?,
    doctorName: map['doctor_name'] as String?,
    prescriptionDate: DateTime.parse(map['prescription_date'] as String),
    notes: map['notes'] as String?,
    status: map['status'] as String? ?? 'active',
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
    items: map['items'] != null ? (map['items'] as List).map((i) => PrescriptionItem.fromMap(i as Map<String, dynamic>)).toList() : null,
  );
}
