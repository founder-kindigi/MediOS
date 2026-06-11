import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import 'package:medios/domain/entities/return.dart';
import 'package:medios/domain/repositories/return_repository.dart';
import 'package:medios/core/errors/app_error.dart';
import 'package:medios/models/user_model.dart';
import 'package:medios/features/auth/services/permission_service.dart';

void main() {
  late Database db;
  late ReturnRepository repository;
  late int medicineId;
  late int saleId;

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

    repository = GetIt.I<ReturnRepository>();

    // Seed a medicine
    medicineId = await db.insert('medicines', {
      'name': 'Panadol',
      'generic_name': 'Paracetamol',
      'category_id': 1,
      'unit': 'strip',
      'purchase_price': 10.0,
      'selling_price': 15.0,
      'stock_quantity': 30,
      'reorder_level': 5,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Seed a completed sale
    saleId = await db.insert('sales', {
      'customer_id': 1,
      'customer_name': 'Walk-in Customer',
      'bill_number': 'BILL-100',
      'sale_date': DateTime.now().toIso8601String(),
      'total_amount': 150.0,
      'discount': 0.0,
      'tax': 0.0,
      'net_amount': 150.0,
      'payment_method': 'cash',
      'store_id': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Seed sale items
    await db.insert('sale_items', {
      'sale_id': saleId,
      'medicine_id': medicineId,
      'medicine_name': 'Panadol',
      'quantity': 10,
      'unit_price': 15.0,
      'total_price': 150.0,
    });
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  group('Clean Returns Tests', () {
    test('process return restores stock and logs inventory transaction', () async {
      final returnItem = ReturnItem(
        medicineId: medicineId,
        medicineName: 'Panadol',
        quantity: 4,
        unitPrice: 15.0,
        totalRefund: 60.0,
      );

      final returnRecord = Return(
        saleId: saleId,
        billNumber: 'BILL-100',
        returnNumber: 'RET-001',
        returnDate: DateTime.now(),
        totalRefund: 60.0,
        reason: 'expired',
        notes: 'Returning 4 expired panadols',
        createdAt: DateTime.now(),
        items: [returnItem],
      );

      final id = await repository.process(returnRecord, [returnItem]);
      expect(id, isPositive);

      // Verify stock was restored: 30 + 4 = 34
      final med = await db.query('medicines', columns: ['stock_quantity'], where: 'id = ?', whereArgs: [medicineId]);
      expect(med.first['stock_quantity'], 34);

      // Verify inventory log is created
      final txs = await db.query('inventory_transactions', where: 'reference_id = ? AND reference_type = ?', whereArgs: [id, 'return']);
      expect(txs.length, 1);
      expect(txs.first['type'], 'in');
      expect(txs.first['quantity'], 4);

      // Verify return can be retrieved with items
      final retrieved = await repository.getWithItems(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.returnNumber, 'RET-001');
      expect(retrieved.items.length, 1);
      expect(retrieved.items.first.medicineName, 'Panadol');
      expect(retrieved.items.first.quantity, 4);
    });

    test('process return fails if returning more items than sold', () async {
      final returnItem = ReturnItem(
        medicineId: medicineId,
        medicineName: 'Panadol',
        quantity: 12, // 12 exceeds sold quantity of 10
        unitPrice: 15.0,
        totalRefund: 180.0,
      );

      final returnRecord = Return(
        saleId: saleId,
        billNumber: 'BILL-100',
        returnNumber: 'RET-002',
        returnDate: DateTime.now(),
        totalRefund: 180.0,
        reason: 'damaged',
        notes: 'Exceeding limit',
        createdAt: DateTime.now(),
        items: [returnItem],
      );

      expect(
        () => repository.process(returnRecord, [returnItem]),
        throwsA(isA<AppError>().having((e) => e.message, 'message', contains('already returned'))),
      );

      // Stock must remain unchanged at 30
      final med = await db.query('medicines', columns: ['stock_quantity'], where: 'id = ?', whereArgs: [medicineId]);
      expect(med.first['stock_quantity'], 30);
    });

    test('process return cumulative items limits check', () async {
      // Return 6 first
      final item1 = ReturnItem(
        medicineId: medicineId,
        medicineName: 'Panadol',
        quantity: 6,
        unitPrice: 15.0,
        totalRefund: 90.0,
      );
      final returnRecord1 = Return(
        saleId: saleId,
        billNumber: 'BILL-100',
        returnNumber: 'RET-003A',
        returnDate: DateTime.now(),
        totalRefund: 90.0,
        reason: 'damaged',
        createdAt: DateTime.now(),
        items: [item1],
      );
      await repository.process(returnRecord1, [item1]);

      // Return another 5 (exceeds limit 6 + 5 = 11 > 10)
      final item2 = ReturnItem(
        medicineId: medicineId,
        medicineName: 'Panadol',
        quantity: 5,
        unitPrice: 15.0,
        totalRefund: 75.0,
      );
      final returnRecord2 = Return(
        saleId: saleId,
        billNumber: 'BILL-100',
        returnNumber: 'RET-003B',
        returnDate: DateTime.now(),
        totalRefund: 75.0,
        reason: 'damaged',
        createdAt: DateTime.now(),
        items: [item2],
      );

      expect(
        () => repository.process(returnRecord2, [item2]),
        throwsA(isA<AppError>().having((e) => e.message, 'message', contains('already returned'))),
      );
    });

    test('getTotalReturns sums refunds correctly', () async {
      final item1 = ReturnItem(medicineId: medicineId, medicineName: 'Panadol', quantity: 2, unitPrice: 15.0, totalRefund: 30.0);
      final item2 = ReturnItem(medicineId: medicineId, medicineName: 'Panadol', quantity: 3, unitPrice: 15.0, totalRefund: 45.0);

      await repository.process(Return(
        saleId: saleId,
        billNumber: 'BILL-100',
        returnNumber: 'RET-004A',
        returnDate: DateTime.now(),
        totalRefund: 30.0,
        createdAt: DateTime.now(),
        items: [item1],
      ), [item1]);

      await repository.process(Return(
        saleId: saleId,
        billNumber: 'BILL-100',
        returnNumber: 'RET-004B',
        returnDate: DateTime.now(),
        totalRefund: 45.0,
        createdAt: DateTime.now(),
        items: [item2],
      ), [item2]);

      final total = await repository.getTotalReturns(1);
      expect(total, 75.0);
    });
  });
}
