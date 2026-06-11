import '../../../../core/database/database_helper.dart';
import '../../models/purchase_order_model.dart';

class PurchaseOrderLocalDataSource {
  final DatabaseHelper _db;

  PurchaseOrderLocalDataSource(this._db);

  Future<List<PurchaseOrderDataModel>> getOrders(int storeId) async {
    final maps = await _db.query('purchase_orders',
        where: 'store_id = ?', whereArgs: [storeId], orderBy: 'order_date DESC');
    return maps.map((m) => PurchaseOrderDataModel.fromMap(m)).toList();
  }

  Future<List<PurchaseOrderDataModel>> getOrdersBySupplier(int supplierId) async {
    final maps = await _db.query('purchase_orders',
        where: 'supplier_id = ?', whereArgs: [supplierId], orderBy: 'order_date DESC');
    return maps.map((m) => PurchaseOrderDataModel.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>?> getOrderById(int id) async {
    return await _db.getById('purchase_orders', id);
  }

  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    return await _db.query('purchase_order_items',
        where: 'purchase_order_id = ?', whereArgs: [orderId]);
  }

  Future<int> insertOrder(PurchaseOrderDataModel order, List<PurchaseOrderItemDataModel> items) async {
    final db = await _db.database;
    return await db.transaction((txn) async {
      final orderMap = order.toMap();
      final id = await txn.insert('purchase_orders', orderMap);
      for (final item in items) {
        final itemMap = item.toMap()..['purchase_order_id'] = id;
        await txn.insert('purchase_order_items', itemMap);
      }
      return id;
    });
  }

  Future<void> updateStatusAndAdjustStock(int id, String status, String currentStatus, int storeId, List<Map<String, dynamic>> items) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // Update purchase order status
      await txn.update('purchase_orders', {'status': status}, where: 'id = ?', whereArgs: [id]);

      if (status == 'received' && currentStatus != 'received') {
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
            'reference_type': 'purchase_order',
            'reference_id': id,
            'store_id': storeId,
            'notes': 'Purchase Order Received',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      } else if (status == 'cancelled' && currentStatus == 'received') {
        for (final item in items) {
          final medId = item['medicine_id'] as int;
          final medName = item['medicine_name'] as String?;
          final qty = item['quantity'] as int;

          final changes = await txn.rawUpdate(
            'UPDATE medicines SET stock_quantity = stock_quantity - ?, updated_at = ? WHERE id = ? AND stock_quantity >= ?',
            [qty, DateTime.now().toIso8601String(), medId, qty],
          );
          if (changes == 0) {
            throw Exception('Insufficient stock to cancel received PO for $medName');
          }

          await txn.insert('inventory_transactions', {
            'medicine_id': medId,
            'medicine_name': medName,
            'type': 'out',
            'quantity': qty,
            'reference_type': 'purchase_order',
            'reference_id': id,
            'store_id': storeId,
            'notes': 'Purchase Order Cancelled (Reverted)',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
    });
  }

  Future<void> deleteOrder(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('purchase_order_items', where: 'purchase_order_id = ?', whereArgs: [id]);
      await txn.delete('purchase_orders', where: 'id = ?', whereArgs: [id]);
    });
  }
}
