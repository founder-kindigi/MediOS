import '../../../../core/errors/app_error.dart';
import '../../../../features/auth/services/permission_service.dart';
import '../../../../core/security/permissions.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/repositories/customer_order_repository.dart';
import '../datasources/local/customer_order_local_data_source.dart';
import '../models/customer_order_model.dart';

class CustomerOrderRepositoryImpl implements CustomerOrderRepository {
  final CustomerOrderLocalDataSource _localDataSource;
  final PermissionService _permissionService;

  CustomerOrderRepositoryImpl({
    required CustomerOrderLocalDataSource localDataSource,
    required PermissionService permissionService,
  })  : _localDataSource = localDataSource,
        _permissionService = permissionService;

  @override
  Future<List<CustomerOrder>> getAll(int storeId, {String? status}) async {
    _permissionService.checkPermission(AppPermission.canViewOrders);
    try {
      final maps = await _localDataSource.getOrders(storeId, status: status);
      if (maps.isEmpty) return [];

      final orderIds = maps.map((m) => m['id'] as int).toList();
      final itemMaps = await _localDataSource.getOrderItemsByOrderIds(orderIds);

      final itemsByOrderId = <int, List<Map<String, dynamic>>>{};
      for (final itemMap in itemMaps) {
        final orderId = itemMap['order_id'] as int;
        itemsByOrderId.putIfAbsent(orderId, () => []).add(itemMap);
      }

      return maps.map((map) {
        final orderId = map['id'] as int;
        final itemsList = itemsByOrderId[orderId] ?? [];
        final items = itemsList.map((i) => CustomerOrderItemDataModel.fromMap(i).toEntity()).toList();
        return CustomerOrderDataModel.fromMap(map, items).toEntity();
      }).toList();
    } catch (e) {
      throw AppError(
        message: 'Failed to load customer orders: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<CustomerOrder?> getWithItems(int orderId) async {
    _permissionService.checkPermission(AppPermission.canViewOrders);
    try {
      final orderMap = await _localDataSource.getOrderById(orderId);
      if (orderMap == null) return null;

      final itemMaps = await _localDataSource.getOrderItems(orderId);
      final items = itemMaps.map((m) => CustomerOrderItemDataModel.fromMap(m).toEntity()).toList();
      return CustomerOrderDataModel.fromMap(orderMap, items).toEntity();
    } catch (e) {
      throw AppError(
        message: 'Failed to get customer order: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<int> create(CustomerOrder order) async {
    _permissionService.checkPermission(AppPermission.canManageOrders);
    try {
      final errors = order.validate();
      if (errors.isNotEmpty) {
        throw AppError(
          message: 'Customer Order validation failed: ${errors.join(", ")}',
          type: ErrorType.validation,
        );
      }

      final dataModel = CustomerOrderDataModel.fromEntity(order);
      final itemModels = order.items.map((i) => CustomerOrderItemDataModel.fromEntity(i)).toList();
      return await _localDataSource.insertOrder(dataModel, itemModels);
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to create customer order: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateStatus(int id, String status) async {
    _permissionService.checkPermission(AppPermission.canManageOrders);
    try {
      final orderMap = await _localDataSource.getOrderById(id);
      if (orderMap == null) {
        throw const AppError(
          message: 'Customer Order not found.',
          type: ErrorType.notFound,
        );
      }

      final currentStatus = orderMap['status'] as String? ?? 'pending';
      final storeId = orderMap['store_id'] as int? ?? 1;
      final items = await _localDataSource.getOrderItems(id);

      await _localDataSource.updateStatusAndAdjustStock(id, status, currentStatus, storeId, items);
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to update status: ${e.toString().replaceAll('Exception: ', '')}',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }
}
