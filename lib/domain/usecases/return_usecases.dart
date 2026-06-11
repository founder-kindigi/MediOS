import '../entities/return.dart';
import '../repositories/return_repository.dart';

class LoadReturnsUseCase {
  final ReturnRepository _repository;

  LoadReturnsUseCase(this._repository);

  Future<List<Return>> call(int storeId) {
    return _repository.getAll(storeId);
  }
}

class ProcessReturnUseCase {
  final ReturnRepository _repository;

  ProcessReturnUseCase(this._repository);

  Future<int> call(Return ret, List<ReturnItem> items) {
    return _repository.process(ret, items);
  }
}

class GetReturnWithItemsUseCase {
  final ReturnRepository _repository;

  GetReturnWithItemsUseCase(this._repository);

  Future<Return?> call(int returnId) {
    return _repository.getWithItems(returnId);
  }
}

class GetTotalReturnsUseCase {
  final ReturnRepository _repository;

  GetTotalReturnsUseCase(this._repository);

  Future<double> call(int storeId) {
    return _repository.getTotalReturns(storeId);
  }
}
