import '../../../../core/database/database_helper.dart';
import '../../models/supplier_model.dart';

class SupplierLocalDataSource {
  final DatabaseHelper _dbHelper;

  SupplierLocalDataSource({required DatabaseHelper databaseHelper})
      : _dbHelper = databaseHelper;

  /// Retrieves all suppliers, with optional search filtering by name, phone, or contact person.
  Future<List<SupplierDataModel>> getAllSuppliers({String? searchQuery}) async {
    final db = await _dbHelper.database;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      final maps = await db.query(
        'suppliers',
        where: 'LOWER(name) LIKE ? OR phone LIKE ? OR LOWER(contact_person) LIKE ?',
        whereArgs: [q, q, q],
        orderBy: 'name ASC',
      );
      return maps.map((m) => SupplierDataModel.fromMap(m)).toList();
    } else {
      final maps = await _dbHelper.query('suppliers', orderBy: 'name ASC');
      return maps.map((m) => SupplierDataModel.fromMap(m)).toList();
    }
  }

  /// Retrieves a supplier by their database ID.
  Future<SupplierDataModel?> getSupplierById(int id) async {
    final map = await _dbHelper.getById('suppliers', id);
    if (map == null) return null;
    return SupplierDataModel.fromMap(map);
  }

  /// Inserts a new supplier record.
  Future<int> insertSupplier(SupplierDataModel supplier) async {
    return await _dbHelper.insert('suppliers', supplier.toMap());
  }

  /// Updates an existing supplier record.
  Future<int> updateSupplier(SupplierDataModel supplier) async {
    final db = await _dbHelper.database;
    return await db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  /// Deletes a supplier record.
  Future<int> deleteSupplier(int id) async {
    return await _dbHelper.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  /// Gets the count of purchase orders associated with a supplier.
  Future<int> getSupplierPurchaseOrdersCount(int id) async {
    return await _dbHelper.getCount('purchase_orders', where: 'supplier_id = ?', whereArgs: [id]);
  }
}
