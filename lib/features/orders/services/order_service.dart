import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/errors/app_error.dart';
import '../../../models/customer_order_model.dart';
import '../../stores/services/store_service.dart';

class OrderService extends ChangeNotifier {
  final DatabaseHelper _db;
  final StoreService _storeService;

  OrderService({DatabaseHelper? databaseHelper, StoreService? storeService})
      : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>(),
        _storeService = storeService ?? GetIt.instance<StoreService>();
  List<CustomerOrderModel> _orders = [];
  bool _isLoading = false;

  List<CustomerOrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> loadOrders({String? status}) async {
    _isLoading = true;
    notifyListeners();
    final storeId = _storeService.selectedStoreId;
    final conditions = <String>['store_id = ?'];
    final whereArgs = <dynamic>[storeId];
    if (status != null) {
      conditions.add('status = ?');
      whereArgs.add(status);
  @override
  void dispose() {
    // Clear data to prevent memory leaks
    _orders = [];
    super.dispose();
  }

    }
    final maps = await _db.query('customer_orders',
      where: conditions.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    if (maps.isEmpty) {
      _orders = [];
    } else {
      final orderIds = maps.map((m) => m['id'] as int).toList();
      final placeholders = List.filled(orderIds.length, '?').join(',');
      final db = await _db.database;
      final itemMaps = await db.rawQuery(
        'SELECT * FROM customer_order_items WHERE order_id IN ($placeholders)',
        orderIds,
      );

      final itemsByOrderId = <int, List<Map<String, dynamic>>>{};
      for (final itemMap in itemMaps) {
        final orderId = itemMap['order_id'] as int;
        itemsByOrderId.putIfAbsent(orderId, () => []).add(itemMap);
      }

      _orders = maps.map((map) {
        final orderId = map['id'] as int;
        final items = itemsByOrderId[orderId] ?? [];
        return CustomerOrderModel.fromMap({...map, 'items': items});
      }).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<CustomerOrderModel?> getOrderWithItems(int orderId) async {
    final orderMap = await _db.getById('customer_orders', orderId);
    if (orderMap == null) return null;

    final items = await _getItems(orderId);
    final order = CustomerOrderModel.fromMap(orderMap);
    return order.copyWith(items: items);
  }

  Future<List<CustomerOrderItemModel>> _getItems(int orderId) async {
    final maps = await _db.query('customer_order_items',
      where: 'order_id = ?', whereArgs: [orderId]);
    return maps.map((m) => CustomerOrderItemModel.fromMap(m)).toList();
  }

  Future<int> createOrder(CustomerOrderModel order) async {
    final db = await _db.database;
    final storeId = _storeService.selectedStoreId;
    final id = await db.transaction((txn) async {
      final orderMap = order.toMap()..['store_id'] = storeId;
      final id = await txn.insert('customer_orders', orderMap..remove('id'));
      for (final item in order.items ?? []) {
        await txn.insert('customer_order_items', {
          'order_id': id,
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
    return id;
  }

  Future<void> updateStatus(int id, String status) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final currentOrder = await txn.query('customer_orders', columns: ['status', 'store_id'], where: 'id = ?', whereArgs: [id]);
      final currentStatus = currentOrder.isNotEmpty ? currentOrder.first['status'] as String : '';
      final orderStoreId = currentOrder.isNotEmpty ? currentOrder.first['store_id'] as int? ?? 1 : 1;

      await txn.update('customer_orders', {'status': status}, where: 'id = ?', whereArgs: [id]);

      if (status == 'fulfilled' && currentStatus != 'fulfilled') {
        final items = await txn.query('customer_order_items', where: 'order_id = ?', whereArgs: [id]);
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
              message: 'Insufficient stock for $medName: cannot fulfill order',
              type: ErrorType.validation,
            );
          }

          await txn.insert('inventory_transactions', {
            'medicine_id': medId,
            'medicine_name': medName,
            'type': 'out',
            'quantity': qty,
            'reference_type': 'customer_order',
            'reference_id': id,
            'store_id': orderStoreId,
            'notes': 'Customer Order Fulfilled',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      } else if (status == 'cancelled' && currentStatus == 'fulfilled') {
        final items = await txn.query('customer_order_items', where: 'order_id = ?', whereArgs: [id]);
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
            'store_id': orderStoreId,
            'notes': 'Customer Order Cancelled (Reverted)',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
    });
    await loadOrders();
  }

  static int _orderCounter = 0;
  static String generateOrderNumber() {
    _orderCounter++;
    return 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}${_orderCounter % 100}';
  }
}
