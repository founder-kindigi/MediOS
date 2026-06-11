import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import 'package:medios/domain/entities/purchase_order.dart';
import 'package:medios/domain/repositories/purchase_order_repository.dart';
import 'package:medios/core/errors/app_error.dart';
import 'package:medios/models/user_model.dart';
import 'package:medios/features/auth/services/permission_service.dart';

void main() {
  late Database db;
  late PurchaseOrderRepository repository;
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

    repository = GetIt.I<PurchaseOrderRepository>();

    // Seed a medicine for tests
    medicineId = await db.insert('medicines', {
      'name': 'Aspirin',
      'generic_name': 'Acetylsalicylic acid',
      'category_id': 1,
      'unit': 'strip',
      'purchase_price': 8.0,
      'selling_price': 12.0,
      'stock_quantity': 10,
      'reorder_level': 5,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  group('Clean Purchase Order Tests', () {
    test('create purchase order and retrieve with items', () async {
      final orderItem = PurchaseOrderItem(
        medicineId: medicineId,
        medicineName: 'Aspirin',
        quantity: 100,
        unitPrice: 8.0,
        totalPrice: 800.0,
      );

      final order = PurchaseOrder(
        supplierId: 1,
        supplierName: 'Test Supplier',
        orderNumber: 'PO-100',
        orderDate: DateTime.now(),
        totalAmount: 800.0,
        status: 'pending',
        storeId: 1,
        createdAt: DateTime.now(),
        items: [orderItem],
      );

      final id = await repository.create(order, [orderItem]);
      expect(id, isPositive);

      final retrieved = await repository.getWithItems(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.orderNumber, 'PO-100');
      expect(retrieved.items.length, 1);
      expect(retrieved.items.first.medicineName, 'Aspirin');
      expect(retrieved.status, 'pending');

      // Verify stock hasn't changed yet (since it is still pending)
      final med = await db.query('medicines', columns: ['stock_quantity'], where: 'id = ?', whereArgs: [medicineId]);
      expect(med.first['stock_quantity'], 10);
    });

    test('updateStatus to received increases stock and logs inventory transaction', () async {
      final orderItem = PurchaseOrderItem(
        medicineId: medicineId,
        medicineName: 'Aspirin',
        quantity: 100,
        unitPrice: 8.0,
        totalPrice: 800.0,
      );

      final order = PurchaseOrder(
        supplierId: 1,
        supplierName: 'Test Supplier',
        orderNumber: 'PO-200',
        orderDate: DateTime.now(),
        totalAmount: 800.0,
        status: 'pending',
        storeId: 1,
        createdAt: DateTime.now(),
        items: [orderItem],
      );

      final id = await repository.create(order, [orderItem]);
      await repository.updateStatus(id, 'received');

      // Verify stock incremented: 10 + 100 = 110
      final med = await db.query('medicines', columns: ['stock_quantity'], where: 'id = ?', whereArgs: [medicineId]);
      expect(med.first['stock_quantity'], 110);

      // Verify inventory log is created
      final txs = await db.query('inventory_transactions', where: 'reference_id = ? AND reference_type = ?', whereArgs: [id, 'purchase_order']);
      expect(txs.length, 1);
      expect(txs.first['type'], 'in');
      expect(txs.first['quantity'], 100);
    });

    test('cancel received purchase order reverts stock and logs out transaction', () async {
      final orderItem = PurchaseOrderItem(
        medicineId: medicineId,
        medicineName: 'Aspirin',
        quantity: 50,
        unitPrice: 8.0,
        totalPrice: 400.0,
      );

      final order = PurchaseOrder(
        supplierId: 1,
        supplierName: 'Test Supplier',
        orderNumber: 'PO-300',
        orderDate: DateTime.now(),
        totalAmount: 400.0,
        status: 'pending',
        storeId: 1,
        createdAt: DateTime.now(),
        items: [orderItem],
      );

      final id = await repository.create(order, [orderItem]);
      await repository.updateStatus(id, 'received'); // stock becomes 10 + 50 = 60
      await repository.updateStatus(id, 'cancelled'); // reverts stock: 60 - 50 = 10

      final med = await db.query('medicines', columns: ['stock_quantity'], where: 'id = ?', whereArgs: [medicineId]);
      expect(med.first['stock_quantity'], 10);

      final txs = await db.query('inventory_transactions', where: 'reference_id = ? AND reference_type = ?', whereArgs: [id, 'purchase_order']);
      // Should have one 'in' log and one 'out' log
      expect(txs.length, 2);
      expect(txs.any((t) => t['type'] == 'in' && t['quantity'] == 50), isTrue);
      expect(txs.any((t) => t['type'] == 'out' && t['quantity'] == 50), isTrue);
    });

    test('cancelling received purchase order fails if stock is insufficient to revert', () async {
      final orderItem = PurchaseOrderItem(
        medicineId: medicineId,
        medicineName: 'Aspirin',
        quantity: 50,
        unitPrice: 8.0,
        totalPrice: 400.0,
      );

      final order = PurchaseOrder(
        supplierId: 1,
        supplierName: 'Test Supplier',
        orderNumber: 'PO-400',
        orderDate: DateTime.now(),
        totalAmount: 400.0,
        status: 'pending',
        storeId: 1,
        createdAt: DateTime.now(),
        items: [orderItem],
      );

      final id = await repository.create(order, [orderItem]);
      await repository.updateStatus(id, 'received'); // stock becomes 10 + 50 = 60

      // Simulate selling some stock so current stock becomes 30 (less than 50 required to revert)
      await db.update('medicines', {'stock_quantity': 30}, where: 'id = ?', whereArgs: [medicineId]);

      expect(
        () => repository.updateStatus(id, 'cancelled'),
        throwsA(isA<AppError>().having((e) => e.message, 'message', contains('Insufficient stock'))),
      );
    });

    test('delete is permitted for pending but blocked for received purchase orders', () async {
      final orderItem = PurchaseOrderItem(
        medicineId: medicineId,
        medicineName: 'Aspirin',
        quantity: 10,
        unitPrice: 8.0,
        totalPrice: 80.0,
      );

      final order1 = PurchaseOrder(
        supplierId: 1,
        supplierName: 'Test Supplier',
        orderNumber: 'PO-501',
        orderDate: DateTime.now(),
        totalAmount: 80.0,
        status: 'pending',
        storeId: 1,
        createdAt: DateTime.now(),
        items: [orderItem],
      );

      final order2 = PurchaseOrder(
        supplierId: 1,
        supplierName: 'Test Supplier',
        orderNumber: 'PO-502',
        orderDate: DateTime.now(),
        totalAmount: 80.0,
        status: 'pending',
        storeId: 1,
        createdAt: DateTime.now(),
        items: [orderItem],
      );

      final id1 = await repository.create(order1, [orderItem]);
      final id2 = await repository.create(order2, [orderItem]);

      // Delete pending (should work)
      await repository.delete(id1);
      final retrieved1 = await repository.getWithItems(id1);
      expect(retrieved1, isNull);

      // Try deleting received
      await repository.updateStatus(id2, 'received');
      expect(
        () => repository.delete(id2),
        throwsA(isA<AppError>().having((e) => e.message, 'message', contains('Cannot delete a received'))),
      );
    });
  });
}
