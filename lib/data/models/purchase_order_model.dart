import '../../domain/entities/purchase_order.dart';

class PurchaseOrderItemDataModel extends PurchaseOrderItem {
  const PurchaseOrderItemDataModel({
    super.id,
    super.purchaseOrderId,
    required super.medicineId,
    super.medicineName,
    required super.quantity,
    required super.unitPrice,
    required super.totalPrice,
  });

  factory PurchaseOrderItemDataModel.fromEntity(PurchaseOrderItem item) {
    return PurchaseOrderItemDataModel(
      id: item.id,
      purchaseOrderId: item.purchaseOrderId,
      medicineId: item.medicineId,
      medicineName: item.medicineName,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      totalPrice: item.totalPrice,
    );
  }

  factory PurchaseOrderItemDataModel.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItemDataModel(
      id: map['id'] as int?,
      purchaseOrderId: map['purchase_order_id'] as int?,
      medicineId: map['medicine_id'] as int,
      medicineName: map['medicine_name'] as String?,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
    );
  }

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

  PurchaseOrderItem toEntity() {
    return PurchaseOrderItem(
      id: id,
      purchaseOrderId: purchaseOrderId,
      medicineId: medicineId,
      medicineName: medicineName,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    );
  }
}

class PurchaseOrderDataModel extends PurchaseOrder {
  const PurchaseOrderDataModel({
    super.id,
    super.supplierId,
    super.supplierName,
    required super.orderNumber,
    required super.orderDate,
    super.totalAmount = 0.0,
    super.status = 'pending',
    super.notes,
    super.storeId = 1,
    required super.createdAt,
    super.items = const [],
  });

  factory PurchaseOrderDataModel.fromEntity(PurchaseOrder order) {
    return PurchaseOrderDataModel(
      id: order.id,
      supplierId: order.supplierId,
      supplierName: order.supplierName,
      orderNumber: order.orderNumber,
      orderDate: order.orderDate,
      totalAmount: order.totalAmount,
      status: order.status,
      notes: order.notes,
      storeId: order.storeId,
      createdAt: order.createdAt,
      items: order.items,
    );
  }

  factory PurchaseOrderDataModel.fromMap(Map<String, dynamic> map, [List<PurchaseOrderItem> items = const []]) {
    return PurchaseOrderDataModel(
      id: map['id'] as int?,
      supplierId: map['supplier_id'] as int?,
      supplierName: map['supplier_name'] as String?,
      orderNumber: map['order_number'] as String,
      orderDate: DateTime.parse(map['order_date'] as String),
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'pending',
      notes: map['notes'] as String?,
      storeId: map['store_id'] as int? ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      items: items,
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

  PurchaseOrder toEntity() {
    return PurchaseOrder(
      id: id,
      supplierId: supplierId,
      supplierName: supplierName,
      orderNumber: orderNumber,
      orderDate: orderDate,
      totalAmount: totalAmount,
      status: status,
      notes: notes,
      storeId: storeId,
      createdAt: createdAt,
      items: items,
    );
  }
}
