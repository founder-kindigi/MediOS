import '../entities/sale.dart';
import '../repositories/sale_repository.dart';

class GetSalesUseCase {
  final SaleRepository _repository;
  GetSalesUseCase({required SaleRepository repository}) : _repository = repository;

  Future<List<Sale>> call({required int storeId}) async {
    return await _repository.getSales(storeId: storeId);
  }
}

class GetSalesByCustomerUseCase {
  final SaleRepository _repository;
  GetSalesByCustomerUseCase({required SaleRepository repository}) : _repository = repository;

  Future<List<Sale>> call(int customerId) async {
    return await _repository.getSalesByCustomer(customerId);
  }
}

class CreateSaleUseCase {
  final SaleRepository _repository;
  CreateSaleUseCase({required SaleRepository repository}) : _repository = repository;

  Future<int> call(Sale sale) async {
    return await _repository.createSale(sale);
  }
}

class GetSaleWithItemsUseCase {
  final SaleRepository _repository;
  GetSaleWithItemsUseCase({required SaleRepository repository}) : _repository = repository;

  Future<Sale?> call(int saleId) async {
    return await _repository.getSaleWithItems(saleId);
  }
}

class TodaySalesSummary {
  final double todaySales;
  final int transactionCount;

  const TodaySalesSummary({
    required this.todaySales,
    required this.transactionCount,
  });
}

class GetTodaySalesSummaryUseCase {
  final SaleRepository _repository;
  GetTodaySalesSummaryUseCase({required SaleRepository repository}) : _repository = repository;

  Future<TodaySalesSummary> call({required int storeId}) async {
    final todaySales = await _repository.getTodaySales(storeId: storeId);
    final transactionCount = await _repository.getTodayTransactionCount(storeId: storeId);
    return TodaySalesSummary(
      todaySales: todaySales,
      transactionCount: transactionCount,
    );
  }
}
