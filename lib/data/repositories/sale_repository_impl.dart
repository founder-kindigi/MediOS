import '../../../../core/errors/app_error.dart';
import '../../../../features/auth/services/permission_service.dart';
import '../../../../core/security/permissions.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';
import '../datasources/local/sale_local_data_source.dart';
import '../models/sale_model.dart';

class SaleRepositoryImpl implements SaleRepository {
  final SaleLocalDataSource _localDataSource;
  final PermissionService _permissionService;

  SaleRepositoryImpl({
    required SaleLocalDataSource localDataSource,
    required PermissionService permissionService,
  })  : _localDataSource = localDataSource,
        _permissionService = permissionService;

  @override
  Future<List<Sale>> getSales({required int storeId}) async {
    _permissionService.checkPermission(AppPermission.canViewSales);
    try {
      final maps = await _localDataSource.getSales(storeId: storeId);
      final sales = <Sale>[];
      for (final map in maps) {
        final saleId = map['id'] as int;
        final itemMaps = await _localDataSource.getSaleItems(saleId);
        final items = itemMaps.map((im) => SaleItemDataModel.fromMap(im).toEntity()).toList();
        sales.add(SaleDataModel.fromMap(map, items: items).toEntity());
      }
      return sales;
    } catch (e) {
      throw AppError(
        message: 'Failed to load sales: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<List<Sale>> getSalesByCustomer(int customerId) async {
    _permissionService.checkPermission(AppPermission.canViewSales);
    try {
      final maps = await _localDataSource.getSalesByCustomer(customerId);
      final sales = <Sale>[];
      for (final map in maps) {
        final saleId = map['id'] as int;
        final itemMaps = await _localDataSource.getSaleItems(saleId);
        final items = itemMaps.map((im) => SaleItemDataModel.fromMap(im).toEntity()).toList();
        sales.add(SaleDataModel.fromMap(map, items: items).toEntity());
      }
      return sales;
    } catch (e) {
      throw AppError(
        message: 'Failed to load customer sales: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<int> createSale(Sale sale) async {
    _permissionService.checkPermission(AppPermission.canCreateSale);
    try {
      final errors = sale.validate();
      if (errors.isNotEmpty) {
        throw AppError(
          message: 'Sale validation failed: ${errors.join(", ")}',
          type: ErrorType.validation,
        );
      }

      final saleModel = SaleDataModel.fromEntity(sale);
      final itemModels = sale.items.map((i) => SaleItemDataModel.fromEntity(i)).toList();
      
      return await _localDataSource.executeCreateSaleTransaction(
        saleModel,
        itemModels,
        storeId: sale.storeId ?? 1,
      );
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to create sale: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<Sale?> getSaleWithItems(int saleId) async {
    _permissionService.checkPermission(AppPermission.canViewSales);
    try {
      final saleMap = await _localDataSource.getSaleById(saleId);
      if (saleMap == null) return null;

      final itemMaps = await _localDataSource.getSaleItems(saleId);
      final items = itemMaps.map((im) => SaleItemDataModel.fromMap(im).toEntity()).toList();
      
      return SaleDataModel.fromMap(saleMap, items: items).toEntity();
    } catch (e) {
      throw AppError(
        message: 'Failed to get sale details: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<double> getTodaySales({required int storeId}) async {
    _permissionService.checkPermission(AppPermission.canViewSales);
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      return await _localDataSource.getTodaySales(
        storeId: storeId,
        startStr: startOfDay.toIso8601String(),
        endStr: endOfDay.toIso8601String(),
      );
    } catch (e) {
      throw AppError(
        message: 'Failed to calculate today sales: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<int> getTodayTransactionCount({required int storeId}) async {
    _permissionService.checkPermission(AppPermission.canViewSales);
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      return await _localDataSource.getTodayTransactionCount(
        storeId: storeId,
        startStr: startOfDay.toIso8601String(),
        endStr: endOfDay.toIso8601String(),
      );
    } catch (e) {
      throw AppError(
        message: 'Failed to count today transactions: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }
}
