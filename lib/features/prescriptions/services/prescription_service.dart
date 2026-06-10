import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/errors/app_error.dart';
import '../../../models/prescription_model.dart';
import '../../stores/services/store_service.dart';

class PrescriptionService extends ChangeNotifier {
  final DatabaseHelper _db;
  final StoreService _storeService;

  PrescriptionService({DatabaseHelper? databaseHelper, StoreService? storeService})
      : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>(),
        _storeService = storeService ?? GetIt.instance<StoreService>();

  List<PrescriptionModel> _prescriptions = [];
  bool _isLoading = false;

  List<PrescriptionModel> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;

  Future<void> loadPrescriptions({String? status}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final storeId = _storeService.selectedStoreId;
      final conditions = <String>['store_id = ?'];
      final whereArgs = <dynamic>[storeId];
      if (status != null) {
        conditions.add('status = ?');
        whereArgs.add(status);
  @override
  void dispose() {
    // Clear data to prevent memory leaks
    _prescriptions = [];
    super.dispose();
  }

      }

      final maps = await _db.query(
        'prescriptions',
        where: conditions.join(' AND '),
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
      );

      if (maps.isEmpty) {
        _prescriptions = [];
      } else {
        final prescriptionIds = maps.map((m) => m['id'] as int).toList();
        final placeholders = List.filled(prescriptionIds.length, '?').join(',');
        final db = await _db.database;
        final itemMaps = await db.rawQuery(
          'SELECT * FROM prescription_items WHERE prescription_id IN ($placeholders)',
          prescriptionIds,
        );

        final itemsByPrescriptionId = <int, List<Map<String, dynamic>>>{};
        for (final itemMap in itemMaps) {
          final prescriptionId = itemMap['prescription_id'] as int;
          itemsByPrescriptionId.putIfAbsent(prescriptionId, () => []).add(itemMap);
        }

        _prescriptions = maps.map((map) {
          final pId = map['id'] as int;
          final items = itemsByPrescriptionId[pId] ?? [];
          return PrescriptionModel.fromMap({...map, 'items': items});
        }).toList();
      }
    } catch (e) {
      _prescriptions = [];
      // Re-throw or handle as AppError if necessary
      if (e is AppError) {
        rethrow;
      }
      throw AppError(
        message: 'Failed to load prescriptions: ${e.toString()}',
        type: ErrorType.database,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<PrescriptionItem>> _getItems(int prescriptionId) async {
    final maps = await _db.query('prescription_items',
        where: 'prescription_id = ?', whereArgs: [prescriptionId]);
    return maps.map((m) => PrescriptionItem.fromMap(m)).toList();
  }

  Future<int> createPrescription(PrescriptionModel prescription) async {
    final db = await _db.database;
    final storeId = _storeService.selectedStoreId;
    final id = await db.transaction((txn) async {
      final pMap = prescription.toMap()..['store_id'] = storeId;
      final id = await txn.insert('prescriptions', pMap..remove('id'));
      for (final item in prescription.items) {
        await txn.insert('prescription_items', {
          'prescription_id': id,
          'medicine_id': item.medicineId,
          'medicine_name': item.medicineName,
          'dosage': item.dosage,
          'frequency': item.frequency,
          'duration': item.duration,
          'quantity': item.quantity,
        });
      }
      return id;
    });
    await loadPrescriptions();
    return id;
  }

  Future<void> updateStatus(int id, String status) async {
    final db = await _db.database;
    final rowsAffected = await db.update(
      'prescriptions',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rowsAffected == 0) {
      throw AppError(
        message: 'Prescription not found',
        type: ErrorType.database,
      );
    }
    await loadPrescriptions();
  }

  Future<PrescriptionModel?> getById(int id) async {
    final map = await _db.getById('prescriptions', id);
    if (map == null) return null;
    final items = (await _getItems(id)).map((i) => i.toMap()).toList();
    return PrescriptionModel.fromMap({...map, 'items': items});
  }
}
