/// Domain entity representing a return item.
class ReturnItem {
  final int? id;
  final int? returnId;
  final int medicineId;
  final String? medicineName;
  final int quantity;
  final double unitPrice;
  final double totalRefund;

  const ReturnItem({
    this.id,
    this.returnId,
    required this.medicineId,
    this.medicineName,
    required this.quantity,
    required this.unitPrice,
    required this.totalRefund,
  });

  /// Validate return item.
  List<String> validate() {
    final errors = <String>[];
    if (medicineId <= 0) {
      errors.add('Invalid medicine ID');
    }
    if (quantity <= 0) {
      errors.add('Quantity must be greater than zero');
    }
    if (unitPrice < 0) {
      errors.add('Unit price cannot be negative');
    }
    if (totalRefund < 0) {
      errors.add('Total refund cannot be negative');
    }
    return errors;
  }

  ReturnItem copyWith({
    int? id,
    int? returnId,
    int? medicineId,
    String? medicineName,
    int? quantity,
    double? unitPrice,
    double? totalRefund,
  }) {
    return ReturnItem(
      id: id ?? this.id,
      returnId: returnId ?? this.returnId,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalRefund: totalRefund ?? this.totalRefund,
    );
  }
}

/// Domain entity representing a return.
class Return {
  final int? id;
  final int? saleId;
  final String? billNumber;
  final String returnNumber;
  final DateTime returnDate;
  final double totalRefund;
  final String reason; // 'damaged', 'expired', 'customer_returned'
  final String? notes;
  final DateTime createdAt;
  final List<ReturnItem> items;

  const Return({
    this.id,
    this.saleId,
    this.billNumber,
    required this.returnNumber,
    required this.returnDate,
    this.totalRefund = 0.0,
    this.reason = 'damaged',
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  /// Validate return entity.
  List<String> validate() {
    final errors = <String>[];
    if (returnNumber.trim().isEmpty) {
      errors.add('Return number is required');
    }
    if (saleId == null) {
      errors.add('Return must be associated with a sale');
    }
    if (totalRefund < 0) {
      errors.add('Total refund cannot be negative');
    }
    for (final item in items) {
      errors.addAll(item.validate());
    }
    return errors;
  }

  Return copyWith({
    int? id,
    int? saleId,
    String? billNumber,
    String? returnNumber,
    DateTime? returnDate,
    double? totalRefund,
    String? reason,
    String? notes,
    DateTime? createdAt,
    List<ReturnItem>? items,
  }) {
    return Return(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      billNumber: billNumber ?? this.billNumber,
      returnNumber: returnNumber ?? this.returnNumber,
      returnDate: returnDate ?? this.returnDate,
      totalRefund: totalRefund ?? this.totalRefund,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
