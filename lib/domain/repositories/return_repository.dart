import '../entities/return.dart';

abstract class ReturnRepository {
  /// Fetch all returns for a specific store.
  Future<List<Return>> getAll(int storeId);

  /// Process a new return. Restores stock atomically, checks quantities, and logs transactions.
  Future<int> process(Return ret, List<ReturnItem> items);

  /// Get a single return details including all returned items.
  Future<Return?> getWithItems(int returnId);

  /// Get cumulative total refunds for a store.
  Future<double> getTotalReturns(int storeId);
}
