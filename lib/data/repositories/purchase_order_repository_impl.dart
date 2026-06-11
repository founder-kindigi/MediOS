import '../../../../core/errors/app_error.dart';
import '../../../../features/auth/services/permission_service.dart';
import '../../../../core/security/permissions.dart';
import '../../domain/entities/purchase_order.dart';
import '../../domain/repositories/purchase_order_repository.dart';
import '../datasources/local/purchase_order_local_data_source.dart';
import '../models/purchase_order_model.dart';

class PurchaseOrderRepositoryImpl implements PurchaseOrderRepository {
  final PurchaseOrderLocalDataSource _localDataSource;
  final PermissionService _permissionService;

  PurchaseOrderRepositoryImpl({
    required PurchaseOrderLocalDataSource localDataSource,
    required PermissionService permissionService,
  })  : _localDataSource = localDataSource,
        _permissionService = permissionService;

  @override
  Future<List<PurchaseOrder>> getAll(int storeId) async {
    _permissionService.checkPermission(AppPermission.canViewPurchases);
    try {
      final models = await _localDataSource.getOrders(storeId);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw AppError(
        message: 'Failed to load purchase orders: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<List<PurchaseOrder>> getBySupplier(int supplierId) async {
    _permissionService.checkPermission(AppPermission.canViewPurchases);
    try {
      final models = await _localDataSource.getOrdersBySupplier(supplierId);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw AppError(
        message: 'Failed to load purchase orders by supplier: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<int> create(PurchaseOrder order, List<PurchaseOrderItem> items) async {
    _permissionService.checkPermission(AppPermission.canCreatePurchase);
    try {
      final errors = order.validate();
      if (errors.isNotEmpty) {
        throw AppError(
          message: 'Purchase Order validation failed: ${errors.join(", ")}',
          type: ErrorType.validation,
        );
      }

      final dataModel = PurchaseOrderDataModel.fromEntity(order);
      final itemModels = items.map((i) => PurchaseOrderItemDataModel.fromEntity(i)).toList();
      return await _localDataSource.insertOrder(dataModel, itemModels);
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to create purchase order: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<PurchaseOrder?> getWithItems(int orderId) async {
    _permissionService.checkPermission(AppPermission.canViewPurchases);
    try {
      final orderMap = await _localDataSource.getOrderById(orderId);
      if (orderMap == null) return null;

      final itemMaps = await _localDataSource.getOrderItems(orderId);
      final items = itemMaps.map((m) => PurchaseOrderItemDataModel.fromMap(m).toEntity()).toList();
      return PurchaseOrderDataModel.fromMap(orderMap, items).toEntity();
    } catch (e) {
      throw AppError(
        message: 'Failed to get purchase order: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateStatus(int id, String status) async {
    _permissionService.checkPermission(AppPermission.canApprovePurchase);
    try {
      final orderMap = await _localDataSource.getOrderById(id);
      if (orderMap == null) {
        throw const AppError(
          message: 'Purchase Order not found.',
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

  @override
  Future<void> delete(int id) async {
    _permissionService.checkPermission(AppPermission.canEditPurchase);
    try {
      final orderMap = await _localDataSource.getOrderById(id);
      if (orderMap == null) {
        throw const AppError(
          message: 'Purchase Order not found.',
          type: ErrorType.notFound,
        );
      }

      final status = orderMap['status'] as String? ?? 'pending';
      if (status == 'received') {
        throw const AppError(
          message: 'Cannot delete a received Purchase Order.',
          type: ErrorType.validation,
        );
      }

      await _localDataSource.deleteOrder(id);
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to delete purchase order: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }
}
