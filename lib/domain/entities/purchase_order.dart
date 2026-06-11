/// Domain entity representing a purchase order item.
class PurchaseOrderItem {
  final int? id;
  final int? purchaseOrderId;
  final int medicineId;
  final String? medicineName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const PurchaseOrderItem({
    this.id,
    this.purchaseOrderId,
    required this.medicineId,
    this.medicineName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  /// Validate item fields.
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
    if (totalPrice < 0) {
      errors.add('Total price cannot be negative');
    }
    return errors;
  }

  PurchaseOrderItem copyWith({
    int? id,
    int? purchaseOrderId,
    int? medicineId,
    String? medicineName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return PurchaseOrderItem(
      id: id ?? this.id,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}

/// Domain entity representing a purchase order.
class PurchaseOrder {
  final int? id;
  final int? supplierId;
  final String? supplierName;
  final String orderNumber;
  final DateTime orderDate;
  final double totalAmount;
  final String status; // 'pending', 'received', 'cancelled'
  final String? notes;
  final int? storeId;
  final DateTime createdAt;
  final List<PurchaseOrderItem> items;

  const PurchaseOrder({
    this.id,
    this.supplierId,
    this.supplierName,
    required this.orderNumber,
    required this.orderDate,
    this.totalAmount = 0.0,
    this.status = 'pending',
    this.notes,
    this.storeId = 1,
    required this.createdAt,
    this.items = const [],
  });

  /// Check if the purchase order is received.
  bool get isReceived => status == 'received';

  /// Check if the purchase order is cancelled.
  bool get isCancelled => status == 'cancelled';

  /// Validate purchase order entity.
  List<String> validate() {
    final errors = <String>[];
    if (orderNumber.trim().isEmpty) {
      errors.add('Order number is required');
    }
    if (supplierId != null && supplierId! <= 0) {
      errors.add('Invalid supplier ID');
    }
    if (totalAmount < 0) {
      errors.add('Total amount cannot be negative');
    }
    for (final item in items) {
      errors.addAll(item.validate());
    }
    return errors;
  }

  PurchaseOrder copyWith({
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
    List<PurchaseOrderItem>? items,
  }) {
    return PurchaseOrder(
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
}
