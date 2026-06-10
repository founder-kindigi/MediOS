import '../../domain/entities/medicine.dart';
import '../../domain/repositories/medicine_repository.dart';
import '../datasources/local/medicine_local_data_source.dart';
import '../models/medicine_model.dart';

/// Implementation of the medicine repository.
class MedicineRepositoryImpl implements MedicineRepository {
  final MedicineLocalDataSource _localDataSource;

  MedicineRepositoryImpl({required MedicineLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<PaginatedResult<Medicine>> getAll({
    int page = 1,
    int limit = 20,
    int? categoryId,
    String? searchQuery,
  }) async {
    try {
      final offset = (page - 1) * limit;
      
      final medicines = await _localDataSource.getAllMedicines(
        limit: limit,
        offset: offset,
        categoryId: categoryId,
        searchQuery: searchQuery,
      );
      
      final totalItems = await _localDataSource.getMedicineCount(
        categoryId: categoryId,
        searchQuery: searchQuery,
      );
      
      final totalPages = (totalItems / limit).ceil();
      
      return PaginatedResult<Medicine>(
        items: medicines.map((m) => m.toEntity()).toList(),
        currentPage: page,
        totalPages: totalPages,
        totalItems: totalItems,
        hasNext: page < totalPages,
        hasPrevious: page > 1,
      );
    } catch (e, stackTrace) {
      throw RepositoryError(
        type: RepositoryErrorType.database,
        message: 'Failed to get medicines: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Medicine?> getById(int id) async {
    try {
      final medicine = await _localDataSource.getMedicineById(id);
      return medicine?.toEntity();
    } catch (e, stackTrace) {
      throw RepositoryError(
        type: RepositoryErrorType.database,
        message: 'Failed to get medicine by ID: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Medicine>> getByBarcode(String barcode) async {
    try {
      final medicines = await _localDataSource.getMedicinesByBarcode(barcode);
      return medicines.map((m) => m.toEntity()).toList();
    } catch (e, stackTrace) {
      throw RepositoryError(
        type: RepositoryErrorType.database,
        message: 'Failed to get medicines by barcode: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Medicine>> getLowStockMedicines() async {
    try {
      final medicines = await _localDataSource.getLowStockMedicines();
      return medicines.map((m) => m.toEntity()).toList();
    } catch (e, stackTrace) {
      throw RepositoryError(
        type: RepositoryErrorType.database,
        message: 'Failed to get low stock medicines: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Medicine>> getNearExpiryMedicines() async {
    try {
      final medicines = await _localDataSource.getNearExpiryMedicines();
      return medicines.map((m) => m.toEntity()).toList();
    } catch (e, stackTrace) {
      throw RepositoryError(
        type: RepositoryErrorType.database,
        message: 'Failed to get near expiry medicines: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Medicine>> getExpiredMedicines() async {
    try {
      final medicines = await _localDataSource.getExpiredMedicines();
      return medicines.map((m) => m.toEntity()).toList();
    } catch (e, stackTrace) {
      throw RepositoryError(
        type: RepositoryErrorType.database,
        message: 'Failed to get expired medicines: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Medicine> add(Medicine medicine) async {
    try {
      // Validate the medicine before adding
      final errors = medicine.validate();
      if (errors.isNotEmpty) {
        throw RepositoryError(
          type: RepositoryErrorType.validation,
          message: 'Medicine validation failed: ${errors.join(", ")}',
        );
      }
      
      final medicineModel = MedicineDataModel.fromEntity(medicine);
      final id = await _localDataSource.insertMedicine(medicineModel);
      
      // Return the medicine with the generated ID
      return Medicine(
        id: id,
        name: medicine.name,
        genericName: medicine.genericName,
        categoryId: medicine.categoryId,
        categoryName: medicine.categoryName,
        manufacturer: medicine.manufacturer,
        unit: medicine.unit,
        purchasePrice: medicine.purchasePrice,
        sellingPrice: medicine.sellingPrice,
        wholesalePrice: medicine.wholesalePrice,
        stockQuantity: medicine.stockQuantity,
        reorderLevel: medicine.reorderLevel,
        expiryDate: medicine.expiryDate,
        barcode: medicine.barcode,
        description: medicine.description,
        createdAt: medicine.createdAt,
        updatedAt: medicine.updatedAt,
      );
    } catch (e) {
      if (e is RepositoryError) rethrow;
      
      throw RepositoryError(
        type: RepositoryErrorType.database,
        message: 'Failed to add medicine: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<Medicine> update(Medicine medicine) async {
    try {
      if (medicine.id == null) {
        throw RepositoryError(
          type: RepositoryErrorType.validation,
          message: 'Cannot update medicine without ID',
        );
      }
      
      // Validate the medicine before updating
      final errors = medicine.validate();
      if (errors.isNotEmpty) {
        throw RepositoryError(
          type: RepositoryErrorType.validation,
          message: 'Medicine validation failed: ${errors.join(", ")}',
        );
      }
      
      final medicineModel = MedicineDataModel.fromEntity(medicine);
      await _localDataSource.updateMedicine(medicineModel);
      
      return medicine;
    } catch (e) {
      if (e is RepositoryError) rethrow;
      
      throw RepositoryError(
        type: RepositoryErrorType.database,
        message: 'Failed to update medicine: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      await _localDataSource.deleteMedicine(id);
    } catch (e, stackTrace) {
      throw RepositoryError(
        type: RepositoryErrorType.database,
        message: 'Failed to delete medicine: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Medicine> updateStock(int medicineId, int newQuantity, String reason) async {
    try {
      if (newQuantity < 0) {
        throw RepositoryError(
          type: RepositoryErrorType.validation,
          message: 'Stock quantity cannot be negative',
        );
      }
      
      // Get the current medicine
      final current = await getById(medicineId);
      if (current == null) {
        throw RepositoryError(
          type: RepositoryErrorType.notFound,
          message: 'Medicine not found',
        );
      }
      
      // Update the stock
      await _localDataSource.updateStock(medicineId, newQuantity);
      
      // Return updated medicine
      return current.withStockUpdate(newQuantity);
    } catch (e) {
      if (e is RepositoryError) rethrow;
      
      throw RepositoryError(
        type: RepositoryErrorType.database,
        message: 'Failed to update stock: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Medicine>> search(String query) async {
    try {
      final medicines = await _localDataSource.searchMedicines(query);
      return medicines.map((m) => m.toEntity()).toList();
    } catch (e, stackTrace) {
      throw RepositoryError(
        type: RepositoryErrorType.database,
        message: 'Failed to search medicines: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Map<int, int>> getCountByCategory() async {
    try {
      return await _localDataSource.getMedicineCountByCategory();
    } catch (e, stackTrace) {
      throw RepositoryError(
        type: RepositoryErrorType.database,
        message: 'Failed to get medicine count by category: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<double> getInventoryValue() async {
    try {
      return await _localDataSource.getInventoryValue();
    } catch (e, stackTrace) {
      throw RepositoryError(
        type: RepositoryErrorType.database,
        message: 'Failed to get inventory value: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}