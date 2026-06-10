class PurchaseOrderModel {
  final int? id;
  final int? supplierId;
  final String? supplierName;
  final String orderNumber;
  final DateTime orderDate;
  final double totalAmount;
  final String status;
  final String? notes;
  final int? storeId;
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
    this.storeId = 1,
    DateTime? createdAt,
    this.items = const [],
  })  : orderDate = orderDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  PurchaseOrderModel copyWith({
    int? id,
    int? supplierId,
    String? supplierName,
    String? orderNumber,
    DateTime? orderDate,
    double? totalAmount,
    String? status,
    String? notes,
    int? storeId,
    DateTime? createdAt,
    List<PurchaseOrderItemModel>? items,
  }) {
    return PurchaseOrderModel(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      orderNumber: orderNumber ?? this.orderNumber,
      orderDate: orderDate ?? this.orderDate,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      storeId: storeId ?? this.storeId,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

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
      'store_id': storeId,
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
      storeId: map['store_id'] as int? ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class PurchaseOrderItemModel {
  final int? id;
  final int? purchaseOrderId;
  final int medicineId;
  final String? medicineName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  PurchaseOrderItemModel({
    this.id,
    this.purchaseOrderId,
    required this.medicineId,
    this.medicineName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (purchaseOrderId != null) 'purchase_order_id': purchaseOrderId,
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
      purchaseOrderId: map['purchase_order_id'] as int?,
      medicineId: map['medicine_id'] as int,
      medicineName: map['medicine_name'] as String?,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
    );
  }
}
