class PurchaseOrderModel {
  final int? id;
  final int? supplierId;
  final String? supplierName;
  final String orderNumber;
  final DateTime orderDate;
  final double totalAmount;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final List<PurchaseOrderItemModel> items;

  PurchaseOrderModel({
    this.id,
    this.supplierId,
    this.supplierName,
    required this.orderNumber,
    DateTime? orderDate,
    this.totalAmount = 0,
    this.status = 'pending',
    this.notes,
    DateTime? createdAt,
    this.items = const [],
  })  : orderDate = orderDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'order_number': orderNumber,
      'order_date': orderDate.toIso8601String(),
      'total_amount': totalAmount,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PurchaseOrderModel.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderModel(
      id: map['id'] as int?,
      supplierId: map['supplier_id'] as int?,
      supplierName: map['supplier_name'] as String?,
      orderNumber: map['order_number'] as String,
      orderDate: DateTime.parse(map['order_date'] as String),
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'pending',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class PurchaseOrderItemModel {
  final int? id;
  final int purchaseOrderId;
  final int medicineId;
  final String? medicineName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  PurchaseOrderItemModel({
    this.id,
    this.purchaseOrderId = 0,
    required this.medicineId,
    this.medicineName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'purchase_order_id': purchaseOrderId,
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  factory PurchaseOrderItemModel.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItemModel(
      id: map['id'] as int?,
      purchaseOrderId: map['purchase_order_id'] as int? ?? 0,
      medicineId: map['medicine_id'] as int,
      medicineName: map['medicine_name'] as String?,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
    );
  }
}
