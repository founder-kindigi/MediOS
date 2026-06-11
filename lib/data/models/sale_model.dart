import '../../domain/entities/sale.dart';

class SaleItemDataModel extends SaleItem {
  const SaleItemDataModel({
    super.id,
    super.saleId,
    required super.medicineId,
    super.medicineName,
    required super.quantity,
    required super.unitPrice,
    required super.totalPrice,
  });

  factory SaleItemDataModel.fromEntity(SaleItem item) {
    return SaleItemDataModel(
      id: item.id,
      saleId: item.saleId,
      medicineId: item.medicineId,
      medicineName: item.medicineName,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      totalPrice: item.totalPrice,
    );
  }

  factory SaleItemDataModel.fromMap(Map<String, dynamic> map) {
    return SaleItemDataModel(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int?,
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
      if (saleId != null) 'sale_id': saleId,
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  SaleItem toEntity() {
    return SaleItem(
      id: id,
      saleId: saleId,
      medicineId: medicineId,
      medicineName: medicineName,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    );
  }
}

class SaleDataModel extends Sale {
  SaleDataModel({
    super.id,
    super.customerId,
    super.customerName,
    required super.billNumber,
    super.saleDate,
    required super.totalAmount,
    super.discount,
    super.tax,
    required super.netAmount,
    super.paymentMethod,
    super.notes,
    super.storeId,
    super.createdAt,
    super.items,
  });

  factory SaleDataModel.fromEntity(Sale sale) {
    return SaleDataModel(
      id: sale.id,
      customerId: sale.customerId,
      customerName: sale.customerName,
      billNumber: sale.billNumber,
      saleDate: sale.saleDate,
      totalAmount: sale.totalAmount,
      discount: sale.discount,
      tax: sale.tax,
      netAmount: sale.netAmount,
      paymentMethod: sale.paymentMethod,
      notes: sale.notes,
      storeId: sale.storeId,
      createdAt: sale.createdAt,
      items: sale.items,
    );
  }

  factory SaleDataModel.fromMap(Map<String, dynamic> map, {List<SaleItem> items = const []}) {
    return SaleDataModel(
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
      'bill_number': billNumber,
      'sale_date': saleDate.toIso8601String(),
      'total_amount': totalAmount,
      'discount': discount,
      'tax': tax,
      'net_amount': netAmount,
      'payment_method': paymentMethod,
      'notes': notes,
      'store_id': storeId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Sale toEntity() {
    return Sale(
      id: id,
      customerId: customerId,
      customerName: customerName,
      billNumber: billNumber,
      saleDate: saleDate,
      totalAmount: totalAmount,
      discount: discount,
      tax: tax,
      netAmount: netAmount,
      paymentMethod: paymentMethod,
      notes: notes,
      storeId: storeId,
      createdAt: createdAt,
      items: items,
    );
  }
}
