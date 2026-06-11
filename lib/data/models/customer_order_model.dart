import '../../domain/entities/customer_order.dart';

class CustomerOrderItemDataModel extends CustomerOrderItem {
  const CustomerOrderItemDataModel({
    super.id,
    super.orderId,
    required super.medicineId,
    required super.medicineName,
    required super.quantity,
    required super.unitPrice,
    required super.totalPrice,
  });

  factory CustomerOrderItemDataModel.fromEntity(CustomerOrderItem item) {
    return CustomerOrderItemDataModel(
      id: item.id,
      orderId: item.orderId,
      medicineId: item.medicineId,
      medicineName: item.medicineName,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      totalPrice: item.totalPrice,
    );
  }

  factory CustomerOrderItemDataModel.fromMap(Map<String, dynamic> map) {
    return CustomerOrderItemDataModel(
      id: map['id'] as int?,
      orderId: map['order_id'] as int?,
      medicineId: map['medicine_id'] as int,
      medicineName: map['medicine_name'] as String? ?? '',
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  CustomerOrderItem toEntity() {
    return CustomerOrderItem(
      id: id,
      orderId: orderId,
      medicineId: medicineId,
      medicineName: medicineName,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    );
  }
}

class CustomerOrderDataModel extends CustomerOrder {
  const CustomerOrderDataModel({
    super.id,
    super.customerId,
    super.customerName,
    required super.orderNumber,
    required super.orderDate,
    super.totalAmount = 0.0,
    super.status = 'pending',
    super.notes,
    super.storeId = 1,
    required super.createdAt,
    super.items = const [],
  });

  factory CustomerOrderDataModel.fromEntity(CustomerOrder order) {
    return CustomerOrderDataModel(
      id: order.id,
      customerId: order.customerId,
      customerName: order.customerName,
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

  factory CustomerOrderDataModel.fromMap(Map<String, dynamic> map, [List<CustomerOrderItem> items = const []]) {
    return CustomerOrderDataModel(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String?,
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
      'customer_id': customerId,
      'customer_name': customerName,
      'order_number': orderNumber,
      'order_date': orderDate.toIso8601String(),
      'total_amount': totalAmount,
      'status': status,
      'notes': notes,
      'store_id': storeId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CustomerOrder toEntity() {
    return CustomerOrder(
      id: id,
      customerId: customerId,
      customerName: customerName,
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
