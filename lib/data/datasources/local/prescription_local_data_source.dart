import '../../../../core/database/database_helper.dart';
import '../../models/prescription_model.dart';

class PrescriptionLocalDataSource {
  final DatabaseHelper _db;

  PrescriptionLocalDataSource(this._db);

  Future<List<Map<String, dynamic>>> getPrescriptions(int storeId, {String? status}) async {
    final conditions = <String>['store_id = ?'];
    final whereArgs = <dynamic>[storeId];
    if (status != null) {
      conditions.add('status = ?');
      whereArgs.add(status);
    }
    return await _db.query(
      'prescriptions',
      where: conditions.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPrescriptionItemsByPrescriptionIds(List<int> pIds) async {
    if (pIds.isEmpty) return [];
    final placeholders = List.filled(pIds.length, '?').join(',');
    final db = await _db.database;
    return await db.rawQuery(
      'SELECT * FROM prescription_items WHERE prescription_id IN ($placeholders)',
      pIds,
    );
  }

  Future<Map<String, dynamic>> getPrescriptionById(int id) async {
    final map = await _db.getById('prescriptions', id);
    if (map == null) throw Exception('Prescription not found');
    return map;
  }

  Future<List<Map<String, dynamic>>> getPrescriptionItems(int prescriptionId) async {
    return await _db.query('prescription_items',
        where: 'prescription_id = ?', whereArgs: [prescriptionId]);
  }

  Future<int> insertPrescription(PrescriptionDataModel prescription, List<PrescriptionItemDataModel> items) async {
    final db = await _db.database;
    return await db.transaction((txn) async {
      final pMap = prescription.toMap();
      final id = await txn.insert('prescriptions', pMap);
      for (final item in items) {
        final itemMap = item.toMap()..['prescription_id'] = id;
        await txn.insert('prescription_items', itemMap);
      }
      return id;
    });
  }

  Future<int> updatePrescriptionStatus(int id, String status) async {
    final db = await _db.database;
    return await db.update(
      'prescriptions',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
