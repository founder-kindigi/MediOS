import 'package:flutter/foundation.dart';
import '../../domain/entities/sale.dart';
import '../../domain/usecases/sale_usecases.dart';
import '../../features/stores/services/store_service.dart';
import '../../core/utils/disposal_helper.dart';

class SalesProvider extends ChangeNotifier with DisposableMixin {
  final GetSalesUseCase _getSales;
  final GetSalesByCustomerUseCase _getSalesByCustomer;
  final CreateSaleUseCase _createSale;
  final GetSaleWithItemsUseCase _getSaleWithItems;
  final GetTodaySalesSummaryUseCase _getTodaySummary;
  final StoreService _storeService;

  List<Sale> _sales = [];
  bool _isLoading = false;
  String? _error;

  SalesProvider({
    required GetSalesUseCase getSales,
    required GetSalesByCustomerUseCase getSalesByCustomer,
    required CreateSaleUseCase createSale,
    required GetSaleWithItemsUseCase getSaleWithItems,
    required GetTodaySalesSummaryUseCase getTodaySummary,
    required StoreService storeService,
  })  : _getSales = getSales,
        _getSalesByCustomer = getSalesByCustomer,
        _createSale = createSale,
        _getSaleWithItems = getSaleWithItems,
        _getTodaySummary = getTodaySummary,
        _storeService = storeService;

  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSales() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final storeId = _storeService.selectedStoreId;
      _sales = await _getSales.call(storeId: storeId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load sales: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Sale>> getSalesByCustomer(int customerId) async {
    try {
      return await _getSalesByCustomer.call(customerId);
    } catch (e) {
      _error = 'Failed to load customer sales: $e';
      rethrow;
    }
  }

  Future<int> createSale(Sale sale, List<SaleItem> items) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final storeId = _storeService.selectedStoreId;
      final saleWithItems = sale.copyWith(
        storeId: storeId,
        items: items,
      );
      final saleId = await _createSale.call(saleWithItems);
      _isLoading = false;
      await loadSales(); // Refresh local sales list
      notifyListeners();
      return saleId;
    } catch (e) {
      _error = 'Failed to create sale: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Sale?> getSaleWithItems(int saleId) async {
    try {
      return await _getSaleWithItems.call(saleId);
    } catch (e) {
      _error = 'Failed to load sale details: $e';
      rethrow;
    }
  }

  Future<double> getTodaySales() async {
    try {
      final storeId = _storeService.selectedStoreId;
      final summary = await _getTodaySummary.call(storeId: storeId);
      return summary.todaySales;
    } catch (e) {
      _error = 'Failed to load today sales: $e';
      return 0.0;
    }
  }

  Future<int> getTodayTransactionCount() async {
    try {
      final storeId = _storeService.selectedStoreId;
      final summary = await _getTodaySummary.call(storeId: storeId);
      return summary.transactionCount;
    } catch (e) {
      _error = 'Failed to load transaction count: $e';
      return 0;
    }
  }

  @override
  void dispose() {
    _sales = [];
    super.dispose();
  }
}
