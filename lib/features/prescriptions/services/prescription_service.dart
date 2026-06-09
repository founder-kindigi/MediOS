import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/prescription_model.dart';

class PrescriptionService extends ChangeNotifier {
  final DatabaseHelper _db;

  PrescriptionService({DatabaseHelper? databaseHelper})
      : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>();
  List<PrescriptionModel> _prescriptions = [];
  bool _isLoading = false;

  List<PrescriptionModel> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;

  Future<void> loadPrescriptions({String? status}) async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.query('prescriptions',
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status] : null,
      orderBy: 'created_at DESC',
    );
    _prescriptions = [];
    for (final map in maps) {
      final items = (await _getItems(map['id'] as int)).map((i) => i.toMap()).toList();
      _prescriptions.add(PrescriptionModel.fromMap({...map, 'items': items}));
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<List<PrescriptionItem>> _getItems(int prescriptionId) async {
    final maps = await _db.query('prescription_items',
      where: 'prescription_id = ?', whereArgs: [prescriptionId]);
    return maps.map((m) => PrescriptionItem.fromMap(m)).toList();
  }

  Future<int> createPrescription(PrescriptionModel prescription) async {
    final db = await _db.database;
    return await db.transaction((txn) async {
      final id = await txn.insert('prescriptions', prescription.toMap()..remove('id'));
      for (final item in prescription.items ?? []) {
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
  }

  Future<void> updateStatus(int id, String status) async {
    await _db.update('prescriptions', {'status': status}, where: 'id = ?', whereArgs: [id]);
    await loadPrescriptions();
  }

  Future<PrescriptionModel?> getById(int id) async {
    final map = await _db.getById('prescriptions', id);
    if (map == null) return null;
    final items = (await _getItems(id)).map((i) => i.toMap()).toList();
    return PrescriptionModel.fromMap({...map, 'items': items});
  }
}
