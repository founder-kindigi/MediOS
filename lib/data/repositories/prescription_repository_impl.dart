import '../../../../core/errors/app_error.dart';
import '../../../../features/auth/services/permission_service.dart';
import '../../../../core/security/permissions.dart';
import '../../domain/entities/prescription.dart';
import '../../domain/repositories/prescription_repository.dart';
import '../datasources/local/prescription_local_data_source.dart';
import '../models/prescription_model.dart';

class PrescriptionRepositoryImpl implements PrescriptionRepository {
  final PrescriptionLocalDataSource _localDataSource;
  final PermissionService _permissionService;

  PrescriptionRepositoryImpl({
    required PrescriptionLocalDataSource localDataSource,
    required PermissionService permissionService,
  })  : _localDataSource = localDataSource,
        _permissionService = permissionService;

  @override
  Future<List<Prescription>> getAll(int storeId, {String? status}) async {
    _permissionService.checkPermission(AppPermission.canViewPrescriptions);
    try {
      final maps = await _localDataSource.getPrescriptions(storeId, status: status);
      if (maps.isEmpty) return [];

      final pIds = maps.map((m) => m['id'] as int).toList();
      final itemMaps = await _localDataSource.getPrescriptionItemsByPrescriptionIds(pIds);

      final itemsByPrescriptionId = <int, List<Map<String, dynamic>>>{};
      for (final itemMap in itemMaps) {
        final prescriptionId = itemMap['prescription_id'] as int;
        itemsByPrescriptionId.putIfAbsent(prescriptionId, () => []).add(itemMap);
      }

      return maps.map((map) {
        final pId = map['id'] as int;
        final itemsList = itemsByPrescriptionId[pId] ?? [];
        final items = itemsList.map((i) => PrescriptionItemDataModel.fromMap(i).toEntity()).toList();
        return PrescriptionDataModel.fromMap(map, items).toEntity();
      }).toList();
    } catch (e) {
      throw AppError(
        message: 'Failed to load prescriptions: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<int> create(Prescription prescription) async {
    _permissionService.checkPermission(AppPermission.canManagePrescriptions);
    try {
      final errors = prescription.validate();
      if (errors.isNotEmpty) {
        throw AppError(
          message: 'Prescription validation failed: ${errors.join(", ")}',
          type: ErrorType.validation,
        );
      }

      final dataModel = PrescriptionDataModel.fromEntity(prescription);
      final itemModels = prescription.items.map((i) => PrescriptionItemDataModel.fromEntity(i)).toList();
      return await _localDataSource.insertPrescription(dataModel, itemModels);
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to create prescription: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateStatus(int id, String status) async {
    _permissionService.checkPermission(AppPermission.canManagePrescriptions);
    try {
      final rowsAffected = await _localDataSource.updatePrescriptionStatus(id, status);
      if (rowsAffected == 0) {
        throw const AppError(
          message: 'Prescription not found',
          type: ErrorType.notFound,
        );
      }
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to update prescription status: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<Prescription?> getById(int id) async {
    _permissionService.checkPermission(AppPermission.canViewPrescriptions);
    try {
      final map = await _localDataSource.getPrescriptionById(id);
      final itemMaps = await _localDataSource.getPrescriptionItems(id);
      final items = itemMaps.map((i) => PrescriptionItemDataModel.fromMap(i).toEntity()).toList();
      return PrescriptionDataModel.fromMap(map, items).toEntity();
    } catch (e) {
      throw AppError(
        message: 'Failed to get prescription details: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }
}
