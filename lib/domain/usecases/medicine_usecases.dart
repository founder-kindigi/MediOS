import '../entities/medicine.dart';
import '../repositories/medicine_repository.dart';

/// Use case for getting all medicines.
class GetAllMedicinesUseCase {
  final MedicineRepository _repository;

  GetAllMedicinesUseCase({required MedicineRepository repository})
      : _repository = repository;

  Future<PaginatedResult<Medicine>> call({
    int page = 1,
    int limit = 20,
    int? categoryId,
    String? searchQuery,
  }) async {
    return await _repository.getAll(
      page: page,
      limit: limit,
      categoryId: categoryId,
      searchQuery: searchQuery,
    );
  }
}

/// Use case for getting a medicine by ID.
class GetMedicineByIdUseCase {
  final MedicineRepository _repository;

  GetMedicineByIdUseCase({required MedicineRepository repository})
      : _repository = repository;

  Future<Medicine?> call(int id) async {
    return await _repository.getById(id);
  }
}

/// Use case for adding a new medicine.
class AddMedicineUseCase {
  final MedicineRepository _repository;

  AddMedicineUseCase({required MedicineRepository repository})
      : _repository = repository;

  Future<Medicine> call(Medicine medicine) async {
    return await _repository.add(medicine);
  }
}

/// Use case for updating an existing medicine.
class UpdateMedicineUseCase {
  final MedicineRepository _repository;

  UpdateMedicineUseCase({required MedicineRepository repository})
      : _repository = repository;

  Future<Medicine> call(Medicine medicine) async {
    return await _repository.update(medicine);
  }
}

/// Use case for deleting a medicine.
class DeleteMedicineUseCase {
  final MedicineRepository _repository;

  DeleteMedicineUseCase({required MedicineRepository repository})
      : _repository = repository;

  Future<void> call(int id) async {
    await _repository.delete(id);
  }
}

/// Use case for updating medicine stock.
class UpdateMedicineStockUseCase {
  final MedicineRepository _repository;

  UpdateMedicineStockUseCase({required MedicineRepository repository})
      : _repository = repository;

  Future<Medicine> call({
    required int medicineId,
    required int newQuantity,
    required String reason,
  }) async {
    return await _repository.updateStock(medicineId, newQuantity, reason);
  }
}

/// Use case for searching medicines.
class SearchMedicinesUseCase {
  final MedicineRepository _repository;

  SearchMedicinesUseCase({required MedicineRepository repository})
      : _repository = repository;

  Future<List<Medicine>> call(String query) async {
    return await _repository.search(query);
  }
}

/// Use case for getting low stock medicines.
class GetLowStockMedicinesUseCase {
  final MedicineRepository _repository;

  GetLowStockMedicinesUseCase({required MedicineRepository repository})
      : _repository = repository;

  Future<List<Medicine>> call() async {
    return await _repository.getLowStockMedicines();
  }
}

/// Use case for getting near expiry medicines.
class GetNearExpiryMedicinesUseCase {
  final MedicineRepository _repository;

  GetNearExpiryMedicinesUseCase({required MedicineRepository repository})
      : _repository = repository;

  Future<List<Medicine>> call() async {
    return await _repository.getNearExpiryMedicines();
  }
}

/// Use case for getting expired medicines.
class GetExpiredMedicinesUseCase {
  final MedicineRepository _repository;

  GetExpiredMedicinesUseCase({required MedicineRepository repository})
      : _repository = repository;

  Future<List<Medicine>> call() async {
    return await _repository.getExpiredMedicines();
  }
}

/// Use case for getting medicine count by category.
class GetMedicineCountByCategoryUseCase {
  final MedicineRepository _repository;

  GetMedicineCountByCategoryUseCase({required MedicineRepository repository})
      : _repository = repository;

  Future<Map<int, int>> call() async {
    return await _repository.getCountByCategory();
  }
}

/// Use case for getting total inventory value.
class GetInventoryValueUseCase {
  final MedicineRepository _repository;

  GetInventoryValueUseCase({required MedicineRepository repository})
      : _repository = repository;

  Future<double> call() async {
    return await _repository.getInventoryValue();
  }
}