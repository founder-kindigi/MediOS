import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/errors/app_error.dart';
import '../../../models/purchase_order_model.dart';
import '../../stores/services/store_service.dart';

class PurchaseOrderService extends ChangeNotifier {
  final DatabaseHelper _db;
  final StoreService _storeService;

  PurchaseOrderService({DatabaseHelper? databaseHelper, StoreService? storeService})
      : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>(),
        _storeService = storeService ?? GetIt.instance<StoreService>();
  List<PurchaseOrderModel> _orders = [];
  bool _isLoading = false;

  List<PurchaseOrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final storeId = _storeService.selectedStoreId;
      final maps = await _db.query('purchase_orders',
          where: 'store_id = ?', whereArgs: [storeId], orderBy: 'order_date DESC');
      _orders = maps.map((m) => PurchaseOrderModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Failed to load purchase orders: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<PurchaseOrderModel>> getOrdersBySupplier(int supplierId) async {
    final maps = await _db.query('purchase_orders',
        where: 'supplier_id = ?', whereArgs: [supplierId], orderBy: 'order_date DESC');
    return maps.map((m) => PurchaseOrderModel.fromMap(m)).toList();
  }

  Future<int> createOrder(PurchaseOrderModel order, List<PurchaseOrderItemModel> items) async {
    final db = await _db.database;
    final storeId = _storeService.selectedStoreId;
    final orderId = await db.transaction((txn) async {
      final orderMap = order.toMap()..['store_id'] = storeId;
      final id = await txn.insert('purchase_orders', orderMap);
      for (final item in items) {
        await txn.insert('purchase_order_items', {
          'purchase_order_id': id,
          'medicine_id': item.medicineId,
          'medicine_name': item.medicineName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total_price': item.totalPrice,
        });
      }
      return id;
    });

    await loadOrders();
    return orderId;
  }

  Future<PurchaseOrderModel?> getOrderWithItems(int orderId) async {
    final orderMap = await _db.getById('purchase_orders', orderId);
    if (orderMap == null) return null;

    final itemMaps = await _db.query('purchase_order_items',
        where: 'purchase_order_id = ?', whereArgs: [orderId]);

    final order = PurchaseOrderModel.fromMap(orderMap);
    final items = itemMaps.map((m) => PurchaseOrderItemModel.fromMap(m)).toList();
    return order.copyWith(items: items);
  }

  Future<void> updateStatus(int id, String status) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final currentOrder = await txn.query('purchase_orders', columns: ['status', 'store_id'], where: 'id = ?', whereArgs: [id]);
      if (currentOrder.isEmpty) {
        throw AppError(
          message: 'Purchase Order not found.',
          type: ErrorType.notFound,
        );
      }
      final currentStatus = currentOrder.first['status'] as String;
      final orderStoreId = currentOrder.first['store_id'] as int? ?? 1;

      await txn.update('purchase_orders', {'status': status}, where: 'id = ?', whereArgs: [id]);

      if (status == 'received' && currentStatus != 'received') {
        final items = await txn.query('purchase_order_items', where: 'purchase_order_id = ?', whereArgs: [id]);
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
            'store_id': orderStoreId,
            'notes': 'Purchase Order Received',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      } else if (status == 'cancelled' && currentStatus == 'received') {
        final items = await txn.query('purchase_order_items', where: 'purchase_order_id = ?', whereArgs: [id]);
        for (final item in items) {
          final medId = item['medicine_id'] as int;
          final medName = item['medicine_name'] as String?;
          final qty = item['quantity'] as int;

          final changes = await txn.rawUpdate(
            'UPDATE medicines SET stock_quantity = stock_quantity - ?, updated_at = ? WHERE id = ? AND stock_quantity >= ?',
            [qty, DateTime.now().toIso8601String(), medId, qty],
          );
          if (changes == 0) {
            throw AppError(
              message: 'Insufficient stock to cancel received PO for $medName',
              type: ErrorType.validation,
            );
          }

          await txn.insert('inventory_transactions', {
            'medicine_id': medId,
            'medicine_name': medName,
            'type': 'out',
            'quantity': qty,
            'reference_type': 'purchase_order',
            'reference_id': id,
            'store_id': orderStoreId,
            'notes': 'Purchase Order Cancelled (Reverted)',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
    });
    await loadOrders();
  }

  Future<void> deleteOrder(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final order = await txn.query('purchase_orders', columns: ['status'], where: 'id = ?', whereArgs: [id]);
      if (order.isEmpty) {
        throw AppError(
          message: 'Purchase Order not found.',
          type: ErrorType.notFound,
        );
      }
      final status = order.first['status'] as String? ?? 'pending';
      if (status == 'received') {
        throw AppError(
          message: 'Cannot delete a received Purchase Order.',
          type: ErrorType.validation,
        );
      }
      await txn.delete('purchase_order_items', where: 'purchase_order_id = ?', whereArgs: [id]);
      await txn.delete('purchase_orders', where: 'id = ?', whereArgs: [id]);
    });
    await loadOrders();
  }

  @override
  void dispose() {
    // Clear data to prevent memory leaks
    _orders = [];
    super.dispose();
  }
}
