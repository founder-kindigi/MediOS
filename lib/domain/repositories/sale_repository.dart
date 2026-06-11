import '../entities/sale.dart';

/// Repository interface for Sales data operations.
abstract class SaleRepository {
  /// Get all sales for a specific store.
  Future<List<Sale>> getSales({required int storeId});

  /// Get sales history for a specific customer.
  Future<List<Sale>> getSalesByCustomer(int customerId);

  /// Create/record a new sale.
  Future<int> createSale(Sale sale);

  /// Get sale details along with all its line items.
  Future<Sale?> getSaleWithItems(int saleId);

  /// Get total sales amount for today.
  Future<double> getTodaySales({required int storeId});

  /// Get total transaction count for today.
  Future<int> getTodayTransactionCount({required int storeId});
}
