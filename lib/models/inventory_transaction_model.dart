class InventoryTransactionModel {
  final int? id;
  final int medicineId;
  final String? medicineName;
  final String type;
  final int quantity;
  final String? referenceType;
  final int? referenceId;
  final String? notes;
  final DateTime createdAt;

  InventoryTransactionModel({
    this.id,
    required this.medicineId,
    this.medicineName,
    required this.type,
    required this.quantity,
    this.referenceType,
    this.referenceId,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'type': type,
      'quantity': quantity,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory InventoryTransactionModel.fromMap(Map<String, dynamic> map) {
    return InventoryTransactionModel(
      id: map['id'] as int?,
      medicineId: map['medicine_id'] as int,
      medicineName: map['medicine_name'] as String?,
      type: map['type'] as String,
      quantity: map['quantity'] as int,
      referenceType: map['reference_type'] as String?,
      referenceId: map['reference_id'] as int?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
