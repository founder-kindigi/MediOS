import '../../domain/entities/medicine.dart';

/// Data model for medicine database operations.
///
/// This model represents the database structure and provides
/// mapping methods to/from domain entities.
class MedicineDataModel {
  final int? id;
  final String name;
  final String genericName;
  final int? categoryId;
  final String? categoryName;
  final String manufacturer;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final double wholesalePrice;
  final int stockQuantity;
  final int reorderLevel;
  final DateTime? expiryDate;
  final String? barcode;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicineDataModel({
    this.id,
    required this.name,
    required this.genericName,
    this.categoryId,
    this.categoryName,
    required this.manufacturer,
    this.unit = 'strip',
    required this.purchasePrice,
    required this.sellingPrice,
    this.wholesalePrice = 0,
    required this.stockQuantity,
    this.reorderLevel = 10,
    this.expiryDate,
    this.barcode,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert from database map to data model.
  factory MedicineDataModel.fromMap(Map<String, dynamic> map) {
    return MedicineDataModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      genericName: map['generic_name'] as String,
      categoryId: map['category_id'] as int?,
      categoryName: map['category_name'] as String?,
      manufacturer: map['manufacturer'] as String,
      unit: map['unit'] as String? ?? 'strip',
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      wholesalePrice: (map['wholesale_price'] as num?)?.toDouble() ?? 0,
      stockQuantity: map['stock_quantity'] as int,
      reorderLevel: map['reorder_level'] as int,
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'] as String)
          : null,
      barcode: map['barcode'] as String?,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert data model to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'generic_name': genericName,
      if (categoryId != null) 'category_id': categoryId,
      'manufacturer': manufacturer,
      'unit': unit,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'wholesale_price': wholesalePrice,
      'stock_quantity': stockQuantity,
      'reorder_level': reorderLevel,
      if (expiryDate != null) 'expiry_date': expiryDate!.toIso8601String(),
      if (barcode != null) 'barcode': barcode,
      if (description != null) 'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert data model to domain entity.
  Medicine toEntity() {
    return Medicine(
      id: id,
      name: name,
      genericName: genericName,
      categoryId: categoryId,
      categoryName: categoryName,
      manufacturer: manufacturer,
      unit: unit,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      wholesalePrice: wholesalePrice,
      stockQuantity: stockQuantity,
      reorderLevel: reorderLevel,
      expiryDate: expiryDate,
      barcode: barcode,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convert domain entity to data model.
  static MedicineDataModel fromEntity(Medicine entity) {
    return MedicineDataModel(
      id: entity.id,
      name: entity.name,
      genericName: entity.genericName,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      manufacturer: entity.manufacturer,
      unit: entity.unit,
      purchasePrice: entity.purchasePrice,
      sellingPrice: entity.sellingPrice,
      wholesalePrice: entity.wholesalePrice,
      stockQuantity: entity.stockQuantity,
      reorderLevel: entity.reorderLevel,
      expiryDate: entity.expiryDate,
      barcode: entity.barcode,
      description: entity.description,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is MedicineDataModel &&
        other.id == id &&
        other.name == name &&
        other.genericName == genericName &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      genericName,
      categoryId,
    );
  }

  @override
  String toString() {
    return 'MedicineDataModel(id: $id, name: $name, stock: $stockQuantity)';
  }
}