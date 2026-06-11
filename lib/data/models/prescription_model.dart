import '../../domain/entities/prescription.dart';

class PrescriptionItemDataModel extends PrescriptionItem {
  const PrescriptionItemDataModel({
    super.id,
    super.prescriptionId,
    required super.medicineId,
    required super.medicineName,
    super.dosage,
    super.frequency,
    super.duration,
    required super.quantity,
  });

  factory PrescriptionItemDataModel.fromEntity(PrescriptionItem item) {
    return PrescriptionItemDataModel(
      id: item.id,
      prescriptionId: item.prescriptionId,
      medicineId: item.medicineId,
      medicineName: item.medicineName,
      dosage: item.dosage,
      frequency: item.frequency,
      duration: item.duration,
      quantity: item.quantity,
    );
  }

  factory PrescriptionItemDataModel.fromMap(Map<String, dynamic> map) {
    return PrescriptionItemDataModel(
      id: map['id'] as int?,
      prescriptionId: map['prescription_id'] as int?,
      medicineId: map['medicine_id'] as int,
      medicineName: map['medicine_name'] as String? ?? '',
      dosage: map['dosage'] as String?,
      frequency: map['frequency'] as String?,
      duration: map['duration'] as String?,
      quantity: map['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (prescriptionId != null) 'prescription_id': prescriptionId,
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'quantity': quantity,
    };
  }

  PrescriptionItem toEntity() {
    return PrescriptionItem(
      id: id,
      prescriptionId: prescriptionId,
      medicineId: medicineId,
      medicineName: medicineName,
      dosage: dosage,
      frequency: frequency,
      duration: duration,
      quantity: quantity,
    );
  }
}

class PrescriptionDataModel extends Prescription {
  const PrescriptionDataModel({
    super.id,
    super.storeId = 1,
    required super.patientName,
    super.patientPhone,
    super.doctorName,
    required super.prescriptionDate,
    super.notes,
    super.status = 'active',
    required super.createdAt,
    super.items = const [],
  });

  factory PrescriptionDataModel.fromEntity(Prescription prescription) {
    return PrescriptionDataModel(
      id: prescription.id,
      storeId: prescription.storeId,
      patientName: prescription.patientName,
      patientPhone: prescription.patientPhone,
      doctorName: prescription.doctorName,
      prescriptionDate: prescription.prescriptionDate,
      notes: prescription.notes,
      status: prescription.status,
      createdAt: prescription.createdAt,
      items: prescription.items,
    );
  }

  factory PrescriptionDataModel.fromMap(Map<String, dynamic> map, [List<PrescriptionItem> items = const []]) {
    return PrescriptionDataModel(
      id: map['id'] as int?,
      storeId: map['store_id'] as int? ?? 1,
      patientName: map['patient_name'] as String,
      patientPhone: map['patient_phone'] as String?,
      doctorName: map['doctor_name'] as String?,
      prescriptionDate: DateTime.parse(map['prescription_date'] as String),
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'active',
      createdAt: DateTime.parse(map['created_at'] as String),
      items: items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'store_id': storeId,
      'patient_name': patientName,
      'patient_phone': patientPhone,
      'doctor_name': doctorName,
      'prescription_date': prescriptionDate.toIso8601String(),
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Prescription toEntity() {
    return Prescription(
      id: id,
      storeId: storeId,
      patientName: patientName,
      patientPhone: patientPhone,
      doctorName: doctorName,
      prescriptionDate: prescriptionDate,
      notes: notes,
      status: status,
      createdAt: createdAt,
      items: items,
    );
  }
}
