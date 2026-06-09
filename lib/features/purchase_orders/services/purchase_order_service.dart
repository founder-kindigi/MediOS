import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/purchase_order_model.dart';

class PurchaseOrderService extends ChangeNotifier {
  final DatabaseHelper _db;

  PurchaseOrderService({DatabaseHelper? databaseHelper})
      : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>();
  List<PurchaseOrderModel> _orders = [];
  bool _isLoading = false;

  List<PurchaseOrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    final maps = await _db.query('purchase_orders', orderBy: 'order_date DESC');
    _orders = maps.map((m) => PurchaseOrderModel.fromMap(m)).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<int> createOrder(PurchaseOrderModel order, List<PurchaseOrderItemModel> items) async {
    final db = await _db.database;
    final orderId = await db.transaction((txn) async {
      final id = await txn.insert('purchase_orders', order.toMap());
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
    return PurchaseOrderModel(
      id: order.id,
      supplierId: order.supplierId,
      supplierName: order.supplierName,
      orderNumber: order.orderNumber,
      orderDate: order.orderDate,
      totalAmount: order.totalAmount,
      status: order.status,
      notes: order.notes,
      createdAt: order.createdAt,
      items: items,
    );
  }

  Future<void> updateStatus(int id, String status) async {
    await _db.update('purchase_orders', {'status': status},
        where: 'id = ?', whereArgs: [id]);
    await loadOrders();
  }

  Future<void> deleteOrder(int id) async {
    await _db.delete('purchase_orders', where: 'id = ?', whereArgs: [id]);
    await loadOrders();
  }
}
