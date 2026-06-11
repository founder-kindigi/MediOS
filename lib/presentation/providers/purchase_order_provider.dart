import 'package:flutter/foundation.dart';
import '../../domain/entities/purchase_order.dart';
import '../../domain/usecases/purchase_order_usecases.dart';
import '../../features/stores/services/store_service.dart';
import '../../core/utils/disposal_helper.dart';

class PurchaseOrderProvider extends ChangeNotifier with DisposableMixin {
  final LoadPurchaseOrdersUseCase _loadOrdersUseCase;
  final GetOrdersBySupplierUseCase _getOrdersBySupplierUseCase;
  final CreatePurchaseOrderUseCase _createOrderUseCase;
  final GetPurchaseOrderWithItemsUseCase _getOrderWithItemsUseCase;
  final UpdatePurchaseOrderStatusUseCase _updateStatusUseCase;
  final DeletePurchaseOrderUseCase _deleteOrderUseCase;
  final StoreService _storeService;

  List<PurchaseOrder> _orders = [];
  bool _isLoading = false;
  String? _error;

  PurchaseOrderProvider({
    required LoadPurchaseOrdersUseCase loadOrdersUseCase,
    required GetOrdersBySupplierUseCase getOrdersBySupplierUseCase,
    required CreatePurchaseOrderUseCase createOrderUseCase,
    required GetPurchaseOrderWithItemsUseCase getOrderWithItemsUseCase,
    required UpdatePurchaseOrderStatusUseCase updateStatusUseCase,
    required DeletePurchaseOrderUseCase deleteOrderUseCase,
    required StoreService storeService,
  })  : _loadOrdersUseCase = loadOrdersUseCase,
        _getOrdersBySupplierUseCase = getOrdersBySupplierUseCase,
        _createOrderUseCase = createOrderUseCase,
        _getOrderWithItemsUseCase = getOrderWithItemsUseCase,
        _updateStatusUseCase = updateStatusUseCase,
        _deleteOrderUseCase = deleteOrderUseCase,
        _storeService = storeService;

  List<PurchaseOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final storeId = _storeService.selectedStoreId;
      _orders = await _loadOrdersUseCase.call(storeId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load purchase orders: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<PurchaseOrder>> getOrdersBySupplier(int supplierId) async {
    try {
      return await _getOrdersBySupplierUseCase.call(supplierId);
    } catch (e) {
      _error = 'Failed to load supplier purchase orders: $e';
      rethrow;
    }
  }

  Future<int> createOrder(PurchaseOrder order, List<PurchaseOrderItem> items) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final storeId = _storeService.selectedStoreId;
      final orderWithStore = order.copyWith(storeId: storeId);
      final id = await _createOrderUseCase.call(orderWithStore, items);
      _isLoading = false;
      await loadOrders();
      return id;
    } catch (e) {
      _error = 'Failed to create purchase order: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<PurchaseOrder?> getOrderWithItems(int orderId) async {
    try {
      return await _getOrderWithItemsUseCase.call(orderId);
    } catch (e) {
      _error = 'Failed to get purchase order details: $e';
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
      _error = 'Failed to update status: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteOrder(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _deleteOrderUseCase.call(id);
      _isLoading = false;
      await loadOrders();
    } catch (e) {
      _error = 'Failed to delete purchase order: $e';
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
