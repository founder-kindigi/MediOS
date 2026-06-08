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
  final DateTime? createdAt;
  final List<CustomerOrderItemModel>? items;

  CustomerOrderModel({
    this.id,
    this.customerId,
    this.customerName,
    required this.orderNumber,
    required this.orderDate,
    this.totalAmount = 0,
    this.status = 'pending',
    this.notes,
    this.createdAt,
    this.items,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'customer_id': customerId,
    'customer_name': customerName,
    'order_number': orderNumber,
    'order_date': orderDate.toIso8601String(),
    'total_amount': totalAmount,
    'status': status,
    'notes': notes,
    'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
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
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
    items: map['items'] != null ? (map['items'] as List).map((i) => CustomerOrderItemModel.fromMap(i as Map<String, dynamic>)).toList() : null,
  );
}
