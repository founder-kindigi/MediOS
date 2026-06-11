import '../../domain/entities/return.dart';

class ReturnItemDataModel extends ReturnItem {
  const ReturnItemDataModel({
    super.id,
    super.returnId,
    required super.medicineId,
    super.medicineName,
    required super.quantity,
    required super.unitPrice,
    required super.totalRefund,
  });

  factory ReturnItemDataModel.fromEntity(ReturnItem item) {
    return ReturnItemDataModel(
      id: item.id,
      returnId: item.returnId,
      medicineId: item.medicineId,
      medicineName: item.medicineName,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      totalRefund: item.totalRefund,
    );
  }

  factory ReturnItemDataModel.fromMap(Map<String, dynamic> map) {
    return ReturnItemDataModel(
      id: map['id'] as int?,
      returnId: map['return_id'] as int?,
      medicineId: map['medicine_id'] as int,
      medicineName: map['medicine_name'] as String?,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalRefund: (map['total_refund'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (returnId != null) 'return_id': returnId,
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_refund': totalRefund,
    };
  }

  ReturnItem toEntity() {
    return ReturnItem(
      id: id,
      returnId: returnId,
      medicineId: medicineId,
      medicineName: medicineName,
      quantity: quantity,
      unitPrice: unitPrice,
      totalRefund: totalRefund,
    );
  }
}

class ReturnDataModel extends Return {
  const ReturnDataModel({
    super.id,
    super.saleId,
    super.billNumber,
    required super.returnNumber,
    required super.returnDate,
    super.totalRefund = 0.0,
    super.reason = 'damaged',
    super.notes,
    required super.createdAt,
    super.items = const [],
  });

  factory ReturnDataModel.fromEntity(Return ret) {
    return ReturnDataModel(
      id: ret.id,
      saleId: ret.saleId,
      billNumber: ret.billNumber,
      returnNumber: ret.returnNumber,
      returnDate: ret.returnDate,
      totalRefund: ret.totalRefund,
      reason: ret.reason,
      notes: ret.notes,
      createdAt: ret.createdAt,
      items: ret.items,
    );
  }

  factory ReturnDataModel.fromMap(Map<String, dynamic> map, [List<ReturnItem> items = const []]) {
    return ReturnDataModel(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int?,
      billNumber: map['bill_number'] as String?,
      returnNumber: map['return_number'] as String,
      returnDate: DateTime.parse(map['return_date'] as String),
      totalRefund: (map['total_refund'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason'] as String? ?? 'damaged',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      items: items,
    );
  }

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

  Return toEntity() {
    return Return(
      id: id,
      saleId: saleId,
      billNumber: billNumber,
      returnNumber: returnNumber,
      returnDate: returnDate,
      totalRefund: totalRefund,
      reason: reason,
      notes: notes,
      createdAt: createdAt,
      items: items,
    );
  }
}
