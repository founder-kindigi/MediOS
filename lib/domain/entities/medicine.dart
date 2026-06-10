/// Domain entity representing a medicine in the pharmacy system.
///
/// This is the core business entity, separate from data models.
/// It contains business logic and validation rules.
class Medicine {
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

  // Cached computed properties for performance
  late final bool _isLowStock;
  late final bool _isExpired;
  late final bool _isNearExpiry;
  late final double _profitMargin;
  late final double _wholesaleProfitMargin;

  Medicine({
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
  }) {
    // Compute expensive properties once in constructor
    _isLowStock = stockQuantity <= reorderLevel;
    
    final now = DateTime.now(); // Compute once for all date comparisons
    _isExpired = expiryDate != null && expiryDate!.isBefore(now);
    
    if (expiryDate != null && !_isExpired) {
      final thirtyDaysFromNow = now.add(const Duration(days: 30));
      _isNearExpiry = expiryDate!.isBefore(thirtyDaysFromNow);
    } else {
      _isNearExpiry = false;
    }
    
    // Compute profit margins
    if (purchasePrice == 0) {
      _profitMargin = 0;
      _wholesaleProfitMargin = 0;
    } else {
      _profitMargin = ((sellingPrice - purchasePrice) / purchasePrice) * 100;
      _wholesaleProfitMargin = ((wholesalePrice - purchasePrice) / purchasePrice) * 100;
    }
  }

  /// Check if the medicine is low on stock.
  bool get isLowStock => _isLowStock;

  /// Check if the medicine is expired.
  bool get isExpired => _isExpired;

  /// Check if the medicine is near expiry (within 30 days).
  bool get isNearExpiry => _isNearExpiry;

  /// Calculate the profit margin for this medicine.
  double get profitMargin => _profitMargin;

  /// Calculate the wholesale profit margin.
  double get wholesaleProfitMargin => _wholesaleProfitMargin;

  /// Validate the medicine entity.
  ///
  /// Returns a list of validation errors, or empty list if valid.
  /// [currentTime] optional parameter to avoid repeated DateTime.now() calls
  List<String> validate({DateTime? currentTime}) {
    final errors = <String>[];

    if (name.isEmpty) {
      errors.add('Medicine name is required');
    } else if (name.length > 100) {
      errors.add('Medicine name cannot exceed 100 characters');
    }

    if (genericName.isEmpty) {
      errors.add('Generic name is required');
    }

    if (manufacturer.isEmpty) {
      errors.add('Manufacturer is required');
    }

    if (purchasePrice < 0) {
      errors.add('Purchase price cannot be negative');
    }

    if (sellingPrice < 0) {
      errors.add('Selling price cannot be negative');
    }

    if (wholesalePrice < 0) {
      errors.add('Wholesale price cannot be negative');
    }

    if (sellingPrice < purchasePrice) {
      errors.add('Selling price cannot be less than purchase price');
    }

    if (wholesalePrice > 0 && wholesalePrice < purchasePrice) {
      errors.add('Wholesale price cannot be less than purchase price');
    }

    if (stockQuantity < 0) {
      errors.add('Stock quantity cannot be negative');
    }

    if (reorderLevel < 0) {
      errors.add('Reorder level cannot be negative');
    }

    // Use provided current time or get it once
    final now = currentTime ?? DateTime.now();
    if (expiryDate != null && expiryDate!.isBefore(now)) {
      errors.add('Expiry date cannot be in the past');
    }

    return errors;
  }

  /// Create a new medicine with updated stock quantity.
  Medicine withStockUpdate(int newQuantity) {
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
      stockQuantity: newQuantity,
      reorderLevel: reorderLevel,
      expiryDate: expiryDate,
      barcode: barcode,
      description: description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Create a new medicine with price update.
  Medicine withPriceUpdate({
    double? newPurchasePrice,
    double? newSellingPrice,
    double? newWholesalePrice,
  }) {
    return Medicine(
      id: id,
      name: name,
      genericName: genericName,
      categoryId: categoryId,
      categoryName: categoryName,
      manufacturer: manufacturer,
      unit: unit,
      purchasePrice: newPurchasePrice ?? purchasePrice,
      sellingPrice: newSellingPrice ?? sellingPrice,
      wholesalePrice: newWholesalePrice ?? wholesalePrice,
      stockQuantity: stockQuantity,
      reorderLevel: reorderLevel,
      expiryDate: expiryDate,
      barcode: barcode,
      description: description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Medicine &&
        other.id == id &&
        other.name == name &&
        other.genericName == genericName &&
        other.categoryId == categoryId &&
        other.manufacturer == manufacturer;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      genericName,
      categoryId,
      manufacturer,
    );
  }

  @override
  String toString() {
    return 'Medicine(id: $id, name: $name, genericName: $genericName, stock: $stockQuantity)';
  }
}