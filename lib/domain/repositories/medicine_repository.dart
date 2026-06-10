import '../entities/medicine.dart';

/// Repository interface for medicine data operations.
///
/// This follows the Repository Pattern to abstract data access
/// from the business logic layer.
abstract class MedicineRepository {
  /// Get all medicines with pagination support.
  ///
  /// [page]: The page number (1-indexed).
  /// [limit]: Number of items per page.
  /// [categoryId]: Optional filter by category.
  /// [searchQuery]: Optional search term.
  Future<PaginatedResult<Medicine>> getAll({
    int page = 1,
    int limit = 20,
    int? categoryId,
    String? searchQuery,
  });

  /// Get a medicine by ID.
  Future<Medicine?> getById(int id);

  /// Get medicines by barcode.
  Future<List<Medicine>> getByBarcode(String barcode);

  /// Get low stock medicines.
  Future<List<Medicine>> getLowStockMedicines();

  /// Get near expiry medicines.
  Future<List<Medicine>> getNearExpiryMedicines();

  /// Get expired medicines.
  Future<List<Medicine>> getExpiredMedicines();

  /// Add a new medicine.
  Future<Medicine> add(Medicine medicine);

  /// Update an existing medicine.
  Future<Medicine> update(Medicine medicine);

  /// Delete a medicine.
  Future<void> delete(int id);

  /// Update medicine stock quantity.
  Future<Medicine> updateStock(int medicineId, int newQuantity, String reason);

  /// Search medicines by name or generic name.
  Future<List<Medicine>> search(String query);

  /// Get medicine count by category.
  Future<Map<int, int>> getCountByCategory();

  /// Get total value of inventory.
  Future<double> getInventoryValue();
}

/// Paginated result for list operations.
class PaginatedResult<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNext;
  final bool hasPrevious;

  const PaginatedResult({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNext,
    required this.hasPrevious,
  });

  /// Create an empty paginated result.
  factory PaginatedResult.empty() {
    return PaginatedResult<T>(
      items: const [],
      currentPage: 1,
      totalPages: 1,
      totalItems: 0,
      hasNext: false,
      hasPrevious: false,
    );
  }

  /// Map the items to a different type.
  PaginatedResult<R> map<R>(R Function(T) mapper) {
    return PaginatedResult<R>(
      items: items.map(mapper).toList(),
      currentPage: currentPage,
      totalPages: totalPages,
      totalItems: totalItems,
      hasNext: hasNext,
      hasPrevious: hasPrevious,
    );
  }
}

/// Repository operation result with error handling.
sealed class RepositoryResult<T> {
  const RepositoryResult();
  
  factory RepositoryResult.success(T data) = RepositorySuccess<T>;
  factory RepositoryResult.failure(RepositoryError error) = RepositoryFailure<T>;
  factory RepositoryResult.notFound() = RepositoryNotFound<T>;
  
  bool get isSuccess => this is RepositorySuccess<T>;
  bool get isFailure => this is RepositoryFailure<T>;
  bool get isNotFound => this is RepositoryNotFound<T>;
  
  T? get dataOrNull => switch (this) {
    RepositorySuccess<T>(:final data) => data,
    _ => null,
  };
  
  RepositoryError? get errorOrNull => switch (this) {
    RepositoryFailure<T>(:final error) => error,
    _ => null,
  };
}

class RepositorySuccess<T> extends RepositoryResult<T> {
  final T data;
  const RepositorySuccess(this.data);
}

class RepositoryFailure<T> extends RepositoryResult<T> {
  final RepositoryError error;
  const RepositoryFailure(this.error);
}

class RepositoryNotFound<T> extends RepositoryResult<T> {
  const RepositoryNotFound();
}

/// Repository error types.
class RepositoryError implements Exception {
  final RepositoryErrorType type;
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;
  
  const RepositoryError({
    required this.type,
    required this.message,
    this.originalError,
    this.stackTrace,
  });
  
  @override
  String toString() {
    return 'RepositoryError(type: $type, message: $message)';
  }
}

enum RepositoryErrorType {
  network,
  database,
  validation,
  notFound,
  unauthorized,
  conflict,
  unknown,
}