class CustomerOrderItemModel {
  final int? id;
  final int? orderId;
  final int medicineId;
  final String medicineName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  CustomerOrderItemModel({
    this.id,
    this.orderId,
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'order_id': orderId,
    'medicine_id': medicineId,
    'medicine_name': medicineName,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total_price': totalPrice,
  };

  factory CustomerOrderItemModel.fromMap(Map<String, dynamic> map) => CustomerOrderItemModel(
    id: map['id'] as int?,
    orderId: map['order_id'] as int?,
    medicineId: map['medicine_id'] as int,
    medicineName: map['medicine_name'] as String,
    quantity: map['quantity'] as int,
    unitPrice: (map['unit_price'] as num).toDouble(),
    totalPrice: (map['total_price'] as num).toDouble(),
  );
}

class CustomerOrderModel {
  final int? id;
  final int? customerId;
  final String? customerName;
  final String orderNumber;
  final DateTime orderDate;
  final double totalAmount;
  final String status;
  final String? notes;
  final int? storeId;
  final DateTime createdAt;
  final List<CustomerOrderItemModel> items;

  CustomerOrderModel({
    this.id,
    this.customerId,
    this.customerName,
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

  CustomerOrderModel copyWith({
    int? id,
    int? customerId,
    String? customerName,
    String? orderNumber,
    DateTime? orderDate,
    double? totalAmount,
    String? status,
    String? notes,
    int? storeId,
    DateTime? createdAt,
    List<CustomerOrderItemModel>? items,
  }) {
    return CustomerOrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
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

  Map<String, dynamic> toMap() => {
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

  factory CustomerOrderModel.fromMap(Map<String, dynamic> map) => CustomerOrderModel(
    id: map['id'] as int?,
    customerId: map['customer_id'] as int?,
    customerName: map['customer_name'] as String?,
    orderNumber: map['order_number'] as String,
    orderDate: DateTime.parse(map['order_date'] as String),
    totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
    status: map['status'] as String? ?? 'pending',
    notes: map['notes'] as String?,
    storeId: map['store_id'] as int? ?? 1,
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
    items: map['items'] != null ? (map['items'] as List).map((i) => CustomerOrderItemModel.fromMap(i as Map<String, dynamic>)).toList() : const [],
  );
}
