class ReturnModel {
  final int? id;
  final int? saleId;
  final String? billNumber;
  final String returnNumber;
  final DateTime returnDate;
  final double totalRefund;
  final String reason;
  final String? notes;
  final DateTime createdAt;
  final List<ReturnItemModel> items;

  ReturnModel({
    this.id,
    this.saleId,
    this.billNumber,
    required this.returnNumber,
    DateTime? returnDate,
    this.totalRefund = 0,
    this.reason = 'damaged',
    this.notes,
    DateTime? createdAt,
    this.items = const [],
  }) : returnDate = returnDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sale_id': saleId,
      'bill_number': billNumber,
      'return_number': returnNumber,
      'return_date': returnDate.toIso8601String(),
      'total_refund': totalRefund,
      'reason': reason,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReturnModel.fromMap(Map<String, dynamic> map) {
    return ReturnModel(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int?,
      billNumber: map['bill_number'] as String?,
      returnNumber: map['return_number'] as String,
      returnDate: DateTime.parse(map['return_date'] as String),
      totalRefund: (map['total_refund'] as num?)?.toDouble() ?? 0,
      reason: map['reason'] as String? ?? 'damaged',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class ReturnItemModel {
  final int? id;
  final int returnId;
  final int medicineId;
  final String? medicineName;
  final int quantity;
  final double unitPrice;
  final double totalRefund;

  ReturnItemModel({
    this.id,
    this.returnId = 0,
    required this.medicineId,
    this.medicineName,
    required this.quantity,
    required this.unitPrice,
    required this.totalRefund,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'return_id': returnId,
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_refund': totalRefund,
    };
  }

  factory ReturnItemModel.fromMap(Map<String, dynamic> map) {
    return ReturnItemModel(
      id: map['id'] as int?,
      returnId: map['return_id'] as int? ?? 0,
      medicineId: map['medicine_id'] as int,
      medicineName: map['medicine_name'] as String?,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalRefund: (map['total_refund'] as num).toDouble(),
    );
  }
}
