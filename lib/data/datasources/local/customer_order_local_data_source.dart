import '../../../../core/database/database_helper.dart';
import '../../models/customer_order_model.dart';

class CustomerOrderLocalDataSource {
  final DatabaseHelper _db;

  CustomerOrderLocalDataSource(this._db);

  Future<List<Map<String, dynamic>>> getOrders(int storeId, {String? status}) async {
    final conditions = <String>['store_id = ?'];
    final whereArgs = <dynamic>[storeId];
    if (status != null) {
      conditions.add('status = ?');
      whereArgs.add(status);
    }
    return await _db.query('customer_orders',
      where: conditions.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getOrderItemsByOrderIds(List<int> orderIds) async {
    if (orderIds.isEmpty) return [];
    final placeholders = List.filled(orderIds.length, '?').join(',');
    final db = await _db.database;
    return await db.rawQuery(
      'SELECT * FROM customer_order_items WHERE order_id IN ($placeholders)',
      orderIds,
    );
  }

  Future<Map<String, dynamic>?> getOrderById(int id) async {
    return await _db.getById('customer_orders', id);
  }

  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    return await _db.query('customer_order_items',
      where: 'order_id = ?', whereArgs: [orderId]);
  }

  Future<int> insertOrder(CustomerOrderDataModel order, List<CustomerOrderItemDataModel> items) async {
    final db = await _db.database;
    return await db.transaction((txn) async {
      final orderMap = order.toMap();
      final id = await txn.insert('customer_orders', orderMap);
      for (final item in items) {
        final itemMap = item.toMap()..['order_id'] = id;
        await txn.insert('customer_order_items', itemMap);
      }
      return id;
    });
  }

  Future<void> updateStatusAndAdjustStock(int id, String status, String currentStatus, int storeId, List<Map<String, dynamic>> items) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update('customer_orders', {'status': status}, where: 'id = ?', whereArgs: [id]);

      if (status == 'fulfilled' && currentStatus != 'fulfilled') {
        for (final item in items) {
          final medId = item['medicine_id'] as int;
          final medName = item['medicine_name'] as String?;
          final qty = item['quantity'] as int;

          final changes = await txn.rawUpdate(
            'UPDATE medicines SET stock_quantity = stock_quantity - ?, updated_at = ? WHERE id = ? AND stock_quantity >= ?',
            [qty, DateTime.now().toIso8601String(), medId, qty],
          );
          if (changes == 0) {
            throw Exception('Insufficient stock for $medName: cannot fulfill order');
          }

          await txn.insert('inventory_transactions', {
            'medicine_id': medId,
            'medicine_name': medName,
            'type': 'out',
            'quantity': qty,
            'reference_type': 'customer_order',
            'reference_id': id,
            'store_id': storeId,
            'notes': 'Customer Order Fulfilled',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      } else if (status == 'cancelled' && currentStatus == 'fulfilled') {
        for (final item in items) {
          final medId = item['medicine_id'] as int;
          final medName = item['medicine_name'] as String?;
          final qty = item['quantity'] as int;

          await txn.rawUpdate(
            'UPDATE medicines SET stock_quantity = stock_quantity + ?, updated_at = ? WHERE id = ?',
            [qty, DateTime.now().toIso8601String(), medId],
          );

          await txn.insert('inventory_transactions', {
            'medicine_id': medId,
            'medicine_name': medName,
            'type': 'in',
            'quantity': qty,
            'reference_type': 'customer_order',
            'reference_id': id,
            'store_id': storeId,
            'notes': 'Customer Order Cancelled (Reverted)',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
    });
  }
}
