class MedicineModel {
  final int? id;
  final String name;
  final String genericName;
  final int? categoryId;
  final String? categoryName;
  final String manufacturer;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final int stockQuantity;
  final int reorderLevel;
  final DateTime? expiryDate;
  final String? barcode;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicineModel({
    this.id,
    required this.name,
    required this.genericName,
    this.categoryId,
    this.categoryName,
    required this.manufacturer,
    this.unit = 'strip',
    required this.purchasePrice,
    required this.sellingPrice,
    this.stockQuantity = 0,
    this.reorderLevel = 10,
    this.expiryDate,
    this.barcode,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'generic_name': genericName,
      'category_id': categoryId,
      'manufacturer': manufacturer,
      'unit': unit,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'stock_quantity': stockQuantity,
      'reorder_level': reorderLevel,
      'expiry_date': expiryDate?.toIso8601String(),
      'barcode': barcode,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      genericName: map['generic_name'] as String? ?? '',
      categoryId: map['category_id'] as int?,
      categoryName: map['category_name'] as String?,
      manufacturer: map['manufacturer'] as String? ?? '',
      unit: map['unit'] as String? ?? 'strip',
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0,
      sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0,
      stockQuantity: map['stock_quantity'] as int? ?? 0,
      reorderLevel: map['reorder_level'] as int? ?? 10,
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'] as String)
          : null,
      barcode: map['barcode'] as String?,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  bool get isLowStock => stockQuantity <= reorderLevel;
  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());
  bool get isNearExpiry =>
      expiryDate != null &&
      expiryDate!.difference(DateTime.now()).inDays <= 30 &&
      !isExpired;

  MedicineModel copyWith({int? stockQuantity, double? sellingPrice, int? reorderLevel, String? barcode}) {
    return MedicineModel(
      id: id,
      name: name,
      genericName: genericName,
      categoryId: categoryId,
      categoryName: categoryName,
      manufacturer: manufacturer,
      unit: unit,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      expiryDate: expiryDate,
      barcode: barcode ?? this.barcode,
      description: description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
