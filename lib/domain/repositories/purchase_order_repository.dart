import '../entities/purchase_order.dart';

abstract class PurchaseOrderRepository {
  /// Fetch all purchase orders for a specific store.
  Future<List<PurchaseOrder>> getAll(int storeId);

  /// Fetch all purchase orders associated with a supplier.
  Future<List<PurchaseOrder>> getBySupplier(int supplierId);

  /// Create a new purchase order with its items.
  Future<int> create(PurchaseOrder order, List<PurchaseOrderItem> items);

  /// Get a single purchase order including all its items.
  Future<PurchaseOrder?> getWithItems(int orderId);

  /// Update the status of a purchase order (updating stock atomically if marked received or cancelled).
  Future<void> updateStatus(int id, String status);

  /// Delete a purchase order.
  Future<void> delete(int id);
}
