import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import '../../lib/features/purchase_orders/services/purchase_order_service.dart';
import '../../lib/models/purchase_order_model.dart';

void main() {
  late Database db;
  late PurchaseOrderService service;

  setUp(() async {
    db = await createAndSetTestDb();
    service = PurchaseOrderService();
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  test('createOrder inserts with items', () async {
    final id = await service.createOrder(PurchaseOrderModel(
      orderNumber: 'PO-001', totalAmount: 1000,
      items: [PurchaseOrderItemModel(
        medicineId: 1, medicineName: 'Panadol',
        quantity: 100, unitPrice: 10, totalPrice: 1000,
      )],
    ), [PurchaseOrderItemModel(
      medicineId: 1, medicineName: 'Panadol',
      quantity: 100, unitPrice: 10, totalPrice: 1000,
    )]);
    expect(id, greaterThan(0));
    await service.loadOrders();
    expect(service.orders.length, 1);
    expect(service.orders.first.orderNumber, 'PO-001');
  });

  test('updateStatus changes status', () async {
    final id = await service.createOrder(PurchaseOrderModel(
      orderNumber: 'PO-002', totalAmount: 500,
    ), []);
    await service.updateStatus(id, 'received');
    await service.loadOrders();
    expect(service.orders.first.status, 'received');
  });

  test('getOrderWithItems returns order', () async {
    final id = await service.createOrder(PurchaseOrderModel(
      orderNumber: 'PO-003', totalAmount: 200,
    ), []);
    final loaded = await service.getOrderWithItems(id);
    expect(loaded, isNotNull);
    expect(loaded!.orderNumber, 'PO-003');
  });
}
