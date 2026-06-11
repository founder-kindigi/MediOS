import '../entities/customer_order.dart';
import '../repositories/customer_order_repository.dart';

class LoadCustomerOrdersUseCase {
  final CustomerOrderRepository _repository;

  LoadCustomerOrdersUseCase(this._repository);

  Future<List<CustomerOrder>> call(int storeId, {String? status}) {
    return _repository.getAll(storeId, status: status);
  }
}

class GetCustomerOrderWithItemsUseCase {
  final CustomerOrderRepository _repository;

  GetCustomerOrderWithItemsUseCase(this._repository);

  Future<CustomerOrder?> call(int orderId) {
    return _repository.getWithItems(orderId);
  }
}

class CreateCustomerOrderUseCase {
  final CustomerOrderRepository _repository;

  CreateCustomerOrderUseCase(this._repository);

  Future<int> call(CustomerOrder order) {
    return _repository.create(order);
  }
}

class UpdateCustomerOrderStatusUseCase {
  final CustomerOrderRepository _repository;

  UpdateCustomerOrderStatusUseCase(this._repository);

  Future<void> call(int id, String status) {
    return _repository.updateStatus(id, status);
  }
}
