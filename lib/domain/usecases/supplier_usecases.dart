import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class GetAllSuppliersUseCase {
  final SupplierRepository _repository;
  GetAllSuppliersUseCase({required SupplierRepository repository}) : _repository = repository;

  Future<List<Supplier>> call({String? searchQuery}) async {
    return await _repository.getAll(searchQuery: searchQuery);
  }
}

class GetSupplierByIdUseCase {
  final SupplierRepository _repository;
  GetSupplierByIdUseCase({required SupplierRepository repository}) : _repository = repository;

  Future<Supplier?> call(int id) async {
    return await _repository.getById(id);
  }
}

class AddSupplierUseCase {
  final SupplierRepository _repository;
  AddSupplierUseCase({required SupplierRepository repository}) : _repository = repository;

  Future<Supplier> call(Supplier supplier) async {
    return await _repository.add(supplier);
  }
}

class UpdateSupplierUseCase {
  final SupplierRepository _repository;
  UpdateSupplierUseCase({required SupplierRepository repository}) : _repository = repository;

  Future<Supplier> call(Supplier supplier) async {
    return await _repository.update(supplier);
  }
}

class DeleteSupplierUseCase {
  final SupplierRepository _repository;
  DeleteSupplierUseCase({required SupplierRepository repository}) : _repository = repository;

  Future<void> call(int id) async {
    await _repository.delete(id);
  }
}
