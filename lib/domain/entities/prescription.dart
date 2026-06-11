/// Domain entity representing a prescription item.
class PrescriptionItem {
  final int? id;
  final int? prescriptionId;
  final int medicineId;
  final String medicineName;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final int quantity;

  const PrescriptionItem({
    this.id,
    this.prescriptionId,
    required this.medicineId,
    required this.medicineName,
    this.dosage,
    this.frequency,
    this.duration,
    required this.quantity,
  });

  /// Validate prescription item.
  List<String> validate() {
    final errors = <String>[];
    if (medicineId <= 0) {
      errors.add('Invalid medicine ID');
    }
    if (medicineName.trim().isEmpty) {
      errors.add('Medicine name is required');
    }
    if (quantity <= 0) {
      errors.add('Quantity must be greater than zero');
    }
    return errors;
  }

  PrescriptionItem copyWith({
    int? id,
    int? prescriptionId,
    int? medicineId,
    String? medicineName,
    String? dosage,
    String? frequency,
    String? duration,
    int? quantity,
  }) {
    return PrescriptionItem(
      id: id ?? this.id,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Domain entity representing a prescription.
class Prescription {
  final int? id;
  final int? storeId;
  final String patientName;
  final String? patientPhone;
  final String? doctorName;
  final DateTime prescriptionDate;
  final String? notes;
  final String status; // 'active', 'completed', 'cancelled'
  final DateTime createdAt;
  final List<PrescriptionItem> items;

  const Prescription({
    this.id,
    this.storeId = 1,
    required this.patientName,
    this.patientPhone,
    this.doctorName,
    required this.prescriptionDate,
    this.notes,
    this.status = 'active',
    required this.createdAt,
    this.items = const [],
  });

  /// Check if the prescription is expired (older than 30 days).
  bool get isExpired => DateTime.now().difference(prescriptionDate).inDays > 30;

  /// Check if active.
  bool get isActive => status == 'active';

  /// Validate prescription.
  List<String> validate() {
    final errors = <String>[];
    if (patientName.trim().isEmpty) {
      errors.add('Patient name is required');
    }
    for (final item in items) {
      errors.addAll(item.validate());
    }
    return errors;
  }

  Prescription copyWith({
    int? id,
    int? storeId,
    String? patientName,
    String? patientPhone,
    String? doctorName,
    DateTime? prescriptionDate,
    String? notes,
    String? status,
    DateTime? createdAt,
    List<PrescriptionItem>? items,
  }) {
    return Prescription(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      doctorName: doctorName ?? this.doctorName,
      prescriptionDate: prescriptionDate ?? this.prescriptionDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
