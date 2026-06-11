import '../../../../core/errors/app_error.dart';
import '../../../../features/auth/services/permission_service.dart';
import '../../../../core/security/permissions.dart';
import '../../domain/entities/return.dart';
import '../../domain/repositories/return_repository.dart';
import '../datasources/local/return_local_data_source.dart';
import '../models/return_model.dart';

class ReturnRepositoryImpl implements ReturnRepository {
  final ReturnLocalDataSource _localDataSource;
  final PermissionService _permissionService;

  ReturnRepositoryImpl({
    required ReturnLocalDataSource localDataSource,
    required PermissionService permissionService,
  })  : _localDataSource = localDataSource,
        _permissionService = permissionService;

  @override
  Future<List<Return>> getAll(int storeId) async {
    _permissionService.checkPermission(AppPermission.canViewSales);
    try {
      final models = await _localDataSource.getReturns(storeId);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw AppError(
        message: 'Failed to load returns: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<int> process(Return ret, List<ReturnItem> items) async {
    _permissionService.checkPermission(AppPermission.canRefundSale);
    try {
      final errors = ret.validate();
      if (errors.isNotEmpty) {
        throw AppError(
          message: 'Return validation failed: ${errors.join(", ")}',
          type: ErrorType.validation,
        );
      }

      final dataModel = ReturnDataModel.fromEntity(ret);
      final itemModels = items.map((i) => ReturnItemDataModel.fromEntity(i)).toList();
      final activeStoreId = 1; // Default fallback
      return await _localDataSource.insertReturn(dataModel, itemModels, activeStoreId);
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to process return: ${e.toString().replaceAll('Exception: ', '')}',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<Return?> getWithItems(int returnId) async {
    _permissionService.checkPermission(AppPermission.canViewSales);
    try {
      final retMap = await _localDataSource.getReturnById(returnId);
      if (retMap == null) return null;

      final itemMaps = await _localDataSource.getReturnItems(returnId);
      final items = itemMaps.map((m) => ReturnItemDataModel.fromMap(m).toEntity()).toList();
      return ReturnDataModel.fromMap(retMap, items).toEntity();
    } catch (e) {
      throw AppError(
        message: 'Failed to get return details: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<double> getTotalReturns(int storeId) async {
    _permissionService.checkPermission(AppPermission.canViewSales);
    try {
      return await _localDataSource.getTotalReturns(storeId);
    } catch (e) {
      throw AppError(
        message: 'Failed to get total returns: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }
}
