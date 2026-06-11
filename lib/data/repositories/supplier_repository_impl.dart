import '../../../../core/errors/app_error.dart';
import '../../../../features/auth/services/permission_service.dart';
import '../../../../core/security/permissions.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../datasources/local/supplier_local_data_source.dart';
import '../models/supplier_model.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final SupplierLocalDataSource _localDataSource;
  final PermissionService _permissionService;

  SupplierRepositoryImpl({
    required SupplierLocalDataSource localDataSource,
    required PermissionService permissionService,
  })  : _localDataSource = localDataSource,
        _permissionService = permissionService;

  @override
  Future<List<Supplier>> getAll({String? searchQuery}) async {
    try {
      final models = await _localDataSource.getAllSuppliers(searchQuery: searchQuery);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw AppError(
        message: 'Failed to load suppliers: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<Supplier?> getById(int id) async {
    try {
      final model = await _localDataSource.getSupplierById(id);
      return model?.toEntity();
    } catch (e) {
      throw AppError(
        message: 'Failed to get supplier: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<Supplier> add(Supplier supplier) async {
    _permissionService.checkPermission(AppPermission.canManageSuppliers);
    try {
      final errors = supplier.validate();
      if (errors.isNotEmpty) {
        throw AppError(
          message: 'Supplier validation failed: ${errors.join(", ")}',
          type: ErrorType.validation,
        );
      }

      final dataModel = SupplierDataModel.fromEntity(supplier);
      final id = await _localDataSource.insertSupplier(dataModel);
      return supplier.copyWith(id: id);
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to add supplier: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<Supplier> update(Supplier supplier) async {
    _permissionService.checkPermission(AppPermission.canManageSuppliers);
    try {
      if (supplier.id == null) {
        throw const AppError(
          message: 'Cannot update supplier with null ID',
          type: ErrorType.validation,
        );
      }

      final errors = supplier.validate();
      if (errors.isNotEmpty) {
        throw AppError(
          message: 'Supplier validation failed: ${errors.join(", ")}',
          type: ErrorType.validation,
        );
      }

      final dataModel = SupplierDataModel.fromEntity(supplier);
      final result = await _localDataSource.updateSupplier(dataModel);
      if (result == 0) {
        throw const AppError(
          message: 'Supplier not found',
          type: ErrorType.database,
        );
      }
      return supplier;
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to update supplier: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<void> delete(int id) async {
    _permissionService.checkPermission(AppPermission.canManageSuppliers);
    try {
      final poCount = await _localDataSource.getSupplierPurchaseOrdersCount(id);
      if (poCount > 0) {
        throw const AppError(
          message: 'Cannot delete supplier: they have associated purchase orders.',
          type: ErrorType.validation,
        );
      }

      final result = await _localDataSource.deleteSupplier(id);
      if (result == 0) {
        throw const AppError(
          message: 'Supplier not found',
          type: ErrorType.database,
        );
      }
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to delete supplier: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }
}
