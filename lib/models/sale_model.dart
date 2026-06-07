class SaleModel {
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
  final DateTime createdAt;
  final List<SaleItemModel> items;

  SaleModel({
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
    DateTime? createdAt,
    this.items = const [],
  })  : saleDate = saleDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'bill_number': billNumber,
      'sale_date': saleDate.toIso8601String(),
      'total_amount': totalAmount,
      'discount': discount,
      'tax': tax,
      'net_amount': netAmount,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SaleModel.fromMap(Map<String, dynamic> map) {
    return SaleModel(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String?,
      billNumber: map['bill_number'] as String,
      saleDate: DateTime.parse(map['sale_date'] as String),
      totalAmount: (map['total_amount'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble(),
      tax: (map['tax'] as num?)?.toDouble(),
      netAmount: (map['net_amount'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class SaleItemModel {
  final int? id;
  final int saleId;
  final int medicineId;
  final String? medicineName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  SaleItemModel({
    this.id,
    this.saleId = 0,
    required this.medicineId,
    this.medicineName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sale_id': saleId,
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    return SaleItemModel(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int? ?? 0,
      medicineId: map['medicine_id'] as int,
      medicineName: map['medicine_name'] as String?,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
    );
  }
}
