/// Domain entity representing a single item in a sale.
class SaleItem {
  final int? id;
  final int? saleId;
  final int medicineId;
  final String? medicineName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const SaleItem({
    this.id,
    this.saleId,
    required this.medicineId,
    this.medicineName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  /// Validates the sale item data.
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

  SaleItem copyWith({
    int? id,
    int? saleId,
    int? medicineId,
    String? medicineName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}

/// Domain entity representing a sale transaction.
class Sale {
  final int? id;
  final int? customerId;
  final String? customerName;
  final String billNumber;
  final DateTime saleDate;
  final double totalAmount;
  final double? discount;
  final double? tax;
  final double netAmount;
  final String paymentMethod;
  final String? notes;
  final int? storeId;
  final DateTime createdAt;
  final List<SaleItem> items;

  Sale({
    this.id,
    this.customerId,
    this.customerName,
    required this.billNumber,
    DateTime? saleDate,
    required this.totalAmount,
    this.discount,
    this.tax,
    required this.netAmount,
    this.paymentMethod = 'cash',
    this.notes,
    this.storeId = 1,
    DateTime? createdAt,
    this.items = const [],
  })  : saleDate = saleDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  /// Validates the sale data.
  List<String> validate() {
    final errors = <String>[];
    if (billNumber.trim().isEmpty) {
      errors.add('Bill number is required');
    }
    if (totalAmount < 0) {
      errors.add('Total amount cannot be negative');
    }
    if (discount != null && discount! < 0) {
      errors.add('Discount cannot be negative');
    }
    if (tax != null && tax! < 0) {
      errors.add('Tax cannot be negative');
    }
    if (netAmount < 0) {
      errors.add('Net amount cannot be negative');
    }
    if (items.isEmpty) {
      errors.add('Sale must contain at least one item');
    }

    for (final item in items) {
      errors.addAll(item.validate());
    }

    return errors;
  }

  Sale copyWith({
    int? id,
    int? customerId,
    String? customerName,
    String? billNumber,
    DateTime? saleDate,
    double? totalAmount,
    double? discount,
    double? tax,
    double? netAmount,
    String? paymentMethod,
    String? notes,
    int? storeId,
    DateTime? createdAt,
    List<SaleItem>? items,
  }) {
    return Sale(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      billNumber: billNumber ?? this.billNumber,
      saleDate: saleDate ?? this.saleDate,
      totalAmount: totalAmount ?? this.totalAmount,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      netAmount: netAmount ?? this.netAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      storeId: storeId ?? this.storeId,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
