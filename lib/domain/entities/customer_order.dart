/// Domain entity representing a customer order item.
class CustomerOrderItem {
  final int? id;
  final int? orderId;
  final int medicineId;
  final String medicineName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const CustomerOrderItem({
    this.id,
    this.orderId,
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  /// Validate customer order item.
  List<String> validate() {
    final errors = <String>[];
    if (medicineId <= 0) {
      errors.add('Invalid medicine ID');
    }
    if (medicineName.trim().isEmpty) {
      errors.add('Medicine name is required');
    }
    if (quantity <= 0) {
      errors.add('Quantity must be greater than zero');
    }
    if (unitPrice < 0) {
      errors.add('Unit price cannot be negative');
    }
    if (totalPrice < 0) {
      errors.add('Total price cannot be negative');
    }
    return errors;
  }

  CustomerOrderItem copyWith({
    int? id,
    int? orderId,
    int? medicineId,
    String? medicineName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return CustomerOrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}

/// Domain entity representing a customer order.
class CustomerOrder {
  final int? id;
  final int? customerId;
  final String? customerName;
  final String orderNumber;
  final DateTime orderDate;
  final double totalAmount;
  final String status; // 'pending', 'fulfilled', 'cancelled'
  final String? notes;
  final int? storeId;
  final DateTime createdAt;
  final List<CustomerOrderItem> items;

  const CustomerOrder({
    this.id,
    this.customerId,
    this.customerName,
    required this.orderNumber,
    required this.orderDate,
    this.totalAmount = 0.0,
    this.status = 'pending',
    this.notes,
    this.storeId = 1,
    required this.createdAt,
    this.items = const [],
  });

  /// Check if the order is fulfilled.
  bool get isFulfilled => status == 'fulfilled';

  /// Check if the order is cancelled.
  bool get isCancelled => status == 'cancelled';

  /// Validate customer order entity.
  List<String> validate() {
    final errors = <String>[];
    if (orderNumber.trim().isEmpty) {
      errors.add('Order number is required');
    }
    if (totalAmount < 0) {
      errors.add('Total amount cannot be negative');
    }
    for (final item in items) {
      errors.addAll(item.validate());
    }
    return errors;
  }

  CustomerOrder copyWith({
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
    List<CustomerOrderItem>? items,
  }) {
    return CustomerOrder(
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
}
