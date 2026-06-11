import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import 'package:medios/domain/entities/customer_order.dart';
import 'package:medios/domain/repositories/customer_order_repository.dart';
import 'package:medios/core/errors/app_error.dart';
import 'package:medios/models/user_model.dart';
import 'package:medios/features/auth/services/permission_service.dart';

void main() {
  late Database db;
  late CustomerOrderRepository repository;
  late int medicineId;

  setUp(() async {
    db = await createAndSetTestDb();

    // Set up active user with permissions
    final permissionService = GetIt.I<PermissionService>();
    await permissionService.setCurrentUser(UserModel(
      id: 1,
      username: 'test_admin',
      fullName: 'Test Admin',
      role: 'admin',
      passwordHash: '',
    ));

    repository = GetIt.I<CustomerOrderRepository>();

    // Seed a medicine
    medicineId = await db.insert('medicines', {
      'name': 'Panadol',
      'generic_name': 'Paracetamol',
      'category_id': 1,
      'unit': 'strip',
      'purchase_price': 10.0,
      'selling_price': 15.0,
      'stock_quantity': 50,
      'reorder_level': 5,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  group('Clean Customer Orders Tests', () {
    test('create customer order and retrieve with items', () async {
      final orderItem = CustomerOrderItem(
        medicineId: medicineId,
        medicineName: 'Panadol',
        quantity: 5,
        unitPrice: 15.0,
        totalPrice: 75.0,
      );

      final order = CustomerOrder(
        customerId: 1,
        customerName: 'Test Customer',
        orderNumber: 'ORD-100',
        orderDate: DateTime.now(),
        totalAmount: 75.0,
        status: 'pending',
        notes: 'Delivery requested',
        storeId: 1,
        createdAt: DateTime.now(),
        items: [orderItem],
      );

      final id = await repository.create(order);
      expect(id, isPositive);

      final retrieved = await repository.getWithItems(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.orderNumber, 'ORD-100');
      expect(retrieved.items.length, 1);
      expect(retrieved.items.first.medicineName, 'Panadol');
      expect(retrieved.status, 'pending');

      // Stock should remain unchanged (still pending)
      final med = await db.query('medicines', columns: ['stock_quantity'], where: 'id = ?', whereArgs: [medicineId]);
      expect(med.first['stock_quantity'], 50);
    });

    test('updateStatus to fulfilled decrements stock and logs inventory transaction', () async {
      final orderItem = CustomerOrderItem(
        medicineId: medicineId,
        medicineName: 'Panadol',
        quantity: 5,
        unitPrice: 15.0,
        totalPrice: 75.0,
      );

      final order = CustomerOrder(
        customerId: 1,
        customerName: 'Test Customer',
        orderNumber: 'ORD-200',
        orderDate: DateTime.now(),
        totalAmount: 75.0,
        status: 'pending',
        storeId: 1,
        createdAt: DateTime.now(),
        items: [orderItem],
      );

      final id = await repository.create(order);
      await repository.updateStatus(id, 'fulfilled');

      // Verify stock decremented: 50 - 5 = 45
      final med = await db.query('medicines', columns: ['stock_quantity'], where: 'id = ?', whereArgs: [medicineId]);
      expect(med.first['stock_quantity'], 45);

      // Verify inventory log is created
      final txs = await db.query('inventory_transactions', where: 'reference_id = ? AND reference_type = ?', whereArgs: [id, 'customer_order']);
      expect(txs.length, 1);
      expect(txs.first['type'], 'out');
      expect(txs.first['quantity'], 5);
    });

    test('updateStatus to fulfilled fails if stock is insufficient', () async {
      final orderItem = CustomerOrderItem(
        medicineId: medicineId,
        medicineName: 'Panadol',
        quantity: 60, // Exceeds stock of 50
        unitPrice: 15.0,
        totalPrice: 900.0,
      );

      final order = CustomerOrder(
        customerId: 1,
        customerName: 'Test Customer',
        orderNumber: 'ORD-300',
        orderDate: DateTime.now(),
        totalAmount: 900.0,
        status: 'pending',
        storeId: 1,
        createdAt: DateTime.now(),
        items: [orderItem],
      );

      final id = await repository.create(order);

      expect(
        () => repository.updateStatus(id, 'fulfilled'),
        throwsA(isA<AppError>().having((e) => e.message, 'message', contains('Insufficient stock'))),
      );

      // Verify stock remains 50
      final med = await db.query('medicines', columns: ['stock_quantity'], where: 'id = ?', whereArgs: [medicineId]);
      expect(med.first['stock_quantity'], 50);
    });

    test('cancel fulfilled customer order restores stock and logs in transaction', () async {
      final orderItem = CustomerOrderItem(
        medicineId: medicineId,
        medicineName: 'Panadol',
        quantity: 5,
        unitPrice: 15.0,
        totalPrice: 75.0,
      );

      final order = CustomerOrder(
        customerId: 1,
        customerName: 'Test Customer',
        orderNumber: 'ORD-400',
        orderDate: DateTime.now(),
        totalAmount: 75.0,
        status: 'pending',
        storeId: 1,
        createdAt: DateTime.now(),
        items: [orderItem],
      );

      final id = await repository.create(order);
      await repository.updateStatus(id, 'fulfilled'); // stock becomes 45
      await repository.updateStatus(id, 'cancelled'); // stock restored to 50

      final med = await db.query('medicines', columns: ['stock_quantity'], where: 'id = ?', whereArgs: [medicineId]);
      expect(med.first['stock_quantity'], 50);

      final txs = await db.query('inventory_transactions', where: 'reference_id = ? AND reference_type = ?', whereArgs: [id, 'customer_order']);
      expect(txs.length, 2);
      expect(txs.any((t) => t['type'] == 'out' && t['quantity'] == 5), isTrue);
      expect(txs.any((t) => t['type'] == 'in' && t['quantity'] == 5), isTrue);
    });
  });
}
