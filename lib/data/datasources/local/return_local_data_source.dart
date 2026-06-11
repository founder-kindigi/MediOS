import '../../../../core/database/database_helper.dart';
import '../../models/return_model.dart';

class ReturnLocalDataSource {
  final DatabaseHelper _db;

  ReturnLocalDataSource(this._db);

  Future<List<ReturnDataModel>> getReturns(int storeId) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT r.* FROM returns r
      LEFT JOIN sales s ON r.sale_id = s.id
      WHERE s.store_id = ? OR r.sale_id IS NULL
      ORDER BY r.return_date DESC
    ''', [storeId]);
    return maps.map((m) => ReturnDataModel.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>?> getReturnById(int id) async {
    return await _db.getById('returns', id);
  }

  Future<List<Map<String, dynamic>>> getReturnItems(int returnId) async {
    return await _db.query('return_items',
        where: 'return_id = ?', whereArgs: [returnId]);
  }

  Future<int> insertReturn(ReturnDataModel ret, List<ReturnItemDataModel> items, int activeStoreId) async {
    final db = await _db.database;
    return await db.transaction((txn) async {
      // 1. Get store_id from the sale
      final saleRows = await txn.query('sales', columns: ['store_id'], where: 'id = ?', whereArgs: [ret.saleId]);
      if (saleRows.isEmpty) {
        throw Exception('Associated sale not found. Cannot process return.');
      }
      final saleStoreId = saleRows.first['store_id'] as int? ?? activeStoreId;

      final id = await txn.insert('returns', ret.toMap());

      for (final item in items) {
        // 2. Get original sale item quantity and name
        final saleItemRows = await txn.query(
          'sale_items',
          columns: ['quantity', 'medicine_name'],
          where: 'sale_id = ? AND medicine_id = ?',
          whereArgs: [ret.saleId, item.medicineId],
        );
        if (saleItemRows.isEmpty) {
          throw Exception('Item "${item.medicineName ?? 'Item'}" was not found in the original sale.');
        }
        final originalQty = saleItemRows.first['quantity'] as int;
        final medName = saleItemRows.first['medicine_name'] as String? ?? item.medicineName;

        // 3. Get cumulative previously returned quantity for this sale item
        final prevReturnedRows = await txn.rawQuery('''
          SELECT COALESCE(SUM(ri.quantity), 0) as returned_qty
          FROM return_items ri
          INNER JOIN returns r ON ri.return_id = r.id
          WHERE r.sale_id = ? AND ri.medicine_id = ?
        ''', [ret.saleId, item.medicineId]);
        final prevReturnedQty = (prevReturnedRows.first['returned_qty'] as num?)?.toInt() ?? 0;

        if (prevReturnedQty + item.quantity > originalQty) {
          throw Exception('Cannot return ${item.quantity} items of "$medName". '
              'Original sold: $originalQty, already returned: $prevReturnedQty.');
        }

        final itemMap = item.toMap()..['return_id'] = id;
        await txn.insert('return_items', itemMap);

        final changes = await txn.rawUpdate(
          'UPDATE medicines SET stock_quantity = stock_quantity + ?, updated_at = ? WHERE id = ?',
          [item.quantity, DateTime.now().toIso8601String(), item.medicineId],
        );
        if (changes == 0) {
          throw Exception('Medicine "$medName" was not found or deleted. Stock cannot be restored.');
        }

        await txn.insert('inventory_transactions', {
          'medicine_id': item.medicineId,
          'medicine_name': item.medicineName,
          'type': 'in',
          'quantity': item.quantity,
          'reference_type': 'return',
          'reference_id': id,
          'store_id': saleStoreId,
          'notes': 'Return: ${ret.reason}',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      return id;
    });
  }

  Future<double> getTotalReturns(int storeId) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(r.total_refund), 0) as total
      FROM returns r
      LEFT JOIN sales s ON r.sale_id = s.id
      WHERE s.store_id = ? OR r.sale_id IS NULL
    ''', [storeId]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
