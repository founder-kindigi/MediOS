import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/customer_order_model.dart';

class OrderService extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<CustomerOrderModel> _orders = [];
  bool _isLoading = false;

  List<CustomerOrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> loadOrders({String? status}) async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.query('customer_orders',
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status] : null,
      orderBy: 'created_at DESC',
    );
    _orders = [];
    for (final map in maps) {
      final items = (await _getItems(map['id'] as int)).map((i) => i.toMap()).toList();
      _orders.add(CustomerOrderModel.fromMap({...map, 'items': items}));
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<List<CustomerOrderItemModel>> _getItems(int orderId) async {
    final maps = await _db.query('customer_order_items',
      where: 'order_id = ?', whereArgs: [orderId]);
    return maps.map((m) => CustomerOrderItemModel.fromMap(m)).toList();
  }

  Future<int> createOrder(CustomerOrderModel order) async {
    final db = await _db.database;
    return await db.transaction((txn) async {
      final id = await txn.insert('customer_orders', order.toMap()..remove('id'));
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
  }

  Future<void> updateStatus(int id, String status) async {
    await _db.update('customer_orders', {'status': status}, where: 'id = ?', whereArgs: [id]);
    await loadOrders();
  }

  static int _orderCounter = 0;
  static String generateOrderNumber() {
    _orderCounter++;
    return 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}${_orderCounter % 100}';
  }
}
