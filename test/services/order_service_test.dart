import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import 'package:medios/features/orders/services/order_service.dart';
import 'package:medios/models/customer_order_model.dart';

void main() {
  late Database db;
  late OrderService service;

  setUp(() async {
    db = await createAndSetTestDb();
    service = OrderService();
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  test('loadOrders returns empty initially', () async {
    await service.loadOrders();
    expect(service.orders, isEmpty);
  });

  test('createOrder inserts with items', () async {
    await service.createOrder(CustomerOrderModel(
      customerName: 'Ali',
      orderNumber: OrderService.generateOrderNumber(),
      orderDate: DateTime.now(),
      totalAmount: 500,
      items: [CustomerOrderItemModel(
        medicineId: 1, medicineName: 'Panadol',
        quantity: 5, unitPrice: 100, totalPrice: 500,
      )],
    ));
    await service.loadOrders();
    expect(service.orders.length, 1);
    expect(service.orders.first.customerName, 'Ali');
  });

  test('updateStatus changes order status', () async {
    final id = await service.createOrder(CustomerOrderModel(
      customerName: 'Sara',
      orderNumber: OrderService.generateOrderNumber(),
      orderDate: DateTime.now(),
    ));
    await service.updateStatus(id, 'fulfilled');
    await service.loadOrders();
    expect(service.orders.first.status, 'fulfilled');
  });

  test('loadOrders filters by status', () async {
    await service.createOrder(CustomerOrderModel(customerName: 'A', orderNumber: OrderService.generateOrderNumber(), orderDate: DateTime.now()));
    await service.loadOrders(status: 'pending');
    expect(service.orders, isNotEmpty);
    await service.loadOrders(status: 'fulfilled');
    expect(service.orders, isEmpty);
  });

  test('generateOrderNumber returns unique numbers', () {
    final n1 = OrderService.generateOrderNumber();
    final n2 = OrderService.generateOrderNumber();
    expect(n1, isNot(n2));
    expect(n1, startsWith('ORD-'));
  });
}
