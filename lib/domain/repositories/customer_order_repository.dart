import '../entities/customer_order.dart';

abstract class CustomerOrderRepository {
  /// Fetch all customer orders for a specific store, optionally filtered by status.
  Future<List<CustomerOrder>> getAll(int storeId, {String? status});

  /// Get a single customer order including all its items.
  Future<CustomerOrder?> getWithItems(int orderId);

  /// Create a new customer order.
  Future<int> create(CustomerOrder order);

  /// Update the status of a customer order (updating stock atomically if marked fulfilled or cancelled).
  Future<void> updateStatus(int id, String status);
}
