import '../entities/supplier.dart';

/// Repository interface for Supplier data operations.
abstract class SupplierRepository {
  /// Get all suppliers, optionally filtered by search query.
  Future<List<Supplier>> getAll({String? searchQuery});

  /// Get supplier by ID.
  Future<Supplier?> getById(int id);

  /// Add a new supplier.
  Future<Supplier> add(Supplier supplier);

  /// Update an existing supplier.
  Future<Supplier> update(Supplier supplier);

  /// Delete a supplier.
  Future<void> delete(int id);
}
