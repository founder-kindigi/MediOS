import '../entities/purchase_order.dart';
import '../repositories/purchase_order_repository.dart';

class LoadPurchaseOrdersUseCase {
  final PurchaseOrderRepository _repository;

  LoadPurchaseOrdersUseCase(this._repository);

  Future<List<PurchaseOrder>> call(int storeId) {
    return _repository.getAll(storeId);
  }
}

class GetOrdersBySupplierUseCase {
  final PurchaseOrderRepository _repository;

  GetOrdersBySupplierUseCase(this._repository);

  Future<List<PurchaseOrder>> call(int supplierId) {
    return _repository.getBySupplier(supplierId);
  }
}

class CreatePurchaseOrderUseCase {
  final PurchaseOrderRepository _repository;

  CreatePurchaseOrderUseCase(this._repository);

  Future<int> call(PurchaseOrder order, List<PurchaseOrderItem> items) {
    return _repository.create(order, items);
  }
}

class GetPurchaseOrderWithItemsUseCase {
  final PurchaseOrderRepository _repository;

  GetPurchaseOrderWithItemsUseCase(this._repository);

  Future<PurchaseOrder?> call(int orderId) {
    return _repository.getWithItems(orderId);
  }
}

class UpdatePurchaseOrderStatusUseCase {
  final PurchaseOrderRepository _repository;

  UpdatePurchaseOrderStatusUseCase(this._repository);

  Future<void> call(int id, String status) {
    return _repository.updateStatus(id, status);
  }
}

class DeletePurchaseOrderUseCase {
  final PurchaseOrderRepository _repository;

  DeletePurchaseOrderUseCase(this._repository);

  Future<void> call(int id) {
    return _repository.delete(id);
  }
}
