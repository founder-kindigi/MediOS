import 'package:flutter/foundation.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/usecases/customer_order_usecases.dart';
import '../../features/stores/services/store_service.dart';
import '../../core/utils/disposal_helper.dart';

class CustomerOrderProvider extends ChangeNotifier with DisposableMixin {
  final LoadCustomerOrdersUseCase _loadOrdersUseCase;
  final GetCustomerOrderWithItemsUseCase _getOrderWithItemsUseCase;
  final CreateCustomerOrderUseCase _createOrderUseCase;
  final UpdateCustomerOrderStatusUseCase _updateStatusUseCase;
  final StoreService _storeService;

  List<CustomerOrder> _orders = [];
  bool _isLoading = false;
  String? _error;

  CustomerOrderProvider({
    required LoadCustomerOrdersUseCase loadOrdersUseCase,
    required GetCustomerOrderWithItemsUseCase getOrderWithItemsUseCase,
    required CreateCustomerOrderUseCase createOrderUseCase,
    required UpdateCustomerOrderStatusUseCase updateStatusUseCase,
    required StoreService storeService,
  })  : _loadOrdersUseCase = loadOrdersUseCase,
        _getOrderWithItemsUseCase = getOrderWithItemsUseCase,
        _createOrderUseCase = createOrderUseCase,
        _updateStatusUseCase = updateStatusUseCase,
        _storeService = storeService;

  List<CustomerOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadOrders({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final storeId = _storeService.selectedStoreId;
      _orders = await _loadOrdersUseCase.call(storeId, status: status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load customer orders: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CustomerOrder?> getOrderWithItems(int orderId) async {
    try {
      return await _getOrderWithItemsUseCase.call(orderId);
    } catch (e) {
      _error = 'Failed to get customer order details: $e';
      rethrow;
    }
  }

  Future<int> createOrder(CustomerOrder order) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final storeId = _storeService.selectedStoreId;
      final orderWithStore = order.copyWith(storeId: storeId);
      final id = await _createOrderUseCase.call(orderWithStore);
      _isLoading = false;
      await loadOrders();
      return id;
    } catch (e) {
      _error = 'Failed to create customer order: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateStatus(int id, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _updateStatusUseCase.call(id, status);
      _isLoading = false;
      await loadOrders();
    } catch (e) {
      _error = 'Failed to update order status: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _orders = [];
    super.dispose();
  }
}
