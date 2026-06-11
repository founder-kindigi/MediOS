import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import 'package:medios/domain/entities/sale.dart';
import 'package:medios/domain/entities/customer.dart';
import 'package:medios/domain/repositories/sale_repository.dart';
import 'package:medios/domain/repositories/customer_repository.dart';
import 'package:medios/core/errors/app_error.dart';
import 'package:medios/models/user_model.dart';
import 'package:medios/features/auth/services/permission_service.dart';

void main() {
  late Database db;
  late SaleRepository repository;
  late CustomerRepository customerRepository;
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

    repository = GetIt.I<SaleRepository>();
    customerRepository = GetIt.I<CustomerRepository>();

    // Seed a dummy medicine for sales tests
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

  group('Sale Checkout Transactions', () {
    test('createSale successfully inserts sale record and decrements stock', () async {
      final saleItem = SaleItem(
        medicineId: medicineId,
        medicineName: 'Panadol',
        quantity: 5,
        unitPrice: 15.0,
        totalPrice: 75.0,
      );

      final sale = Sale(
        billNumber: 'BILL-001',
        totalAmount: 75.0,
        netAmount: 75.0,
        paymentMethod: 'cash',
        storeId: 1,
        items: [saleItem],
      );

      final id = await repository.createSale(sale);
      expect(id, isPositive);

      // Verify stock decremented: 50 - 5 = 45
      final med = await db.query('medicines', columns: ['stock_quantity'], where: 'id = ?', whereArgs: [medicineId]);
      expect(med.first['stock_quantity'], 45);

      // Verify inventory log created
      final txs = await db.query('inventory_transactions', where: 'reference_id = ?', whereArgs: [id]);
      expect(txs.length, 1);
      expect(txs.first['type'], 'out');
      expect(txs.first['quantity'], 5);

      // Verify sale can be retrieved with items
      final retrieved = await repository.getSaleWithItems(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.billNumber, 'BILL-001');
      expect(retrieved.items.length, 1);
      expect(retrieved.items.first.medicineName, 'Panadol');
    });

    test('createSale fails and rolls back if stock is insufficient', () async {
      final saleItem = SaleItem(
        medicineId: medicineId,
        medicineName: 'Panadol',
        quantity: 60, // Exceeds available stock (50)
        unitPrice: 15.0,
        totalPrice: 900.0,
      );

      final sale = Sale(
        billNumber: 'BILL-002',
        totalAmount: 900.0,
        netAmount: 900.0,
        paymentMethod: 'cash',
        storeId: 1,
        items: [saleItem],
      );

      expect(
        () => repository.createSale(sale),
        throwsA(isA<AppError>().having((e) => e.message, 'message', contains('Insufficient stock'))),
      );

      // Verify stock remains unchanged at 50
      final med = await db.query('medicines', columns: ['stock_quantity'], where: 'id = ?', whereArgs: [medicineId]);
      expect(med.first['stock_quantity'], 50);

      // Verify no sales transaction registered
      final sales = await db.query('sales');
      expect(sales, isEmpty);
    });

    test('credit sale updates customer balance and logs transaction', () async {
      final customer = Customer(
        name: 'Credit Client',
        phone: '111',
        creditLimit: 500.0,
        createdAt: DateTime.now(),
      );
      final addedCustomer = await customerRepository.add(customer);

      final saleItem = SaleItem(
        medicineId: medicineId,
        medicineName: 'Panadol',
        quantity: 10,
        unitPrice: 15.0,
        totalPrice: 150.0,
      );

      final sale = Sale(
        customerId: addedCustomer.id,
        customerName: addedCustomer.name,
        billNumber: 'BILL-CR-01',
        totalAmount: 150.0,
        netAmount: 150.0,
        paymentMethod: 'credit',
        storeId: 1,
        items: [saleItem],
      );

      final saleId = await repository.createSale(sale);
      expect(saleId, isPositive);

      // Verify customer current balance is updated (0 + 150 = 150)
      final updatedCustomer = await customerRepository.getById(addedCustomer.id!);
      expect(updatedCustomer?.currentBalance, 150.0);

      // Verify credit transaction recorded
      final ledger = await customerRepository.getLedger(addedCustomer.id!);
      expect(ledger.length, 1);
      expect(ledger.first.type, CreditTransactionType.sale);
      expect(ledger.first.amount, 150.0);
      expect(ledger.first.runningBalance, 150.0);
    });

    test('credit sale fails if it exceeds customer credit limit', () async {
      final customer = Customer(
        name: 'Strict Limit Client',
        phone: '222',
        creditLimit: 100.0, // Low credit limit
        createdAt: DateTime.now(),
      );
      final addedCustomer = await customerRepository.add(customer);

      final saleItem = SaleItem(
        medicineId: medicineId,
        medicineName: 'Panadol',
        quantity: 10,
        unitPrice: 15.0,
        totalPrice: 150.0, // Sale total exceeds credit limit (150 > 100)
      );

      final sale = Sale(
        customerId: addedCustomer.id,
        customerName: addedCustomer.name,
        billNumber: 'BILL-CR-02',
        totalAmount: 150.0,
        netAmount: 150.0,
        paymentMethod: 'credit',
        storeId: 1,
        items: [saleItem],
      );

      expect(
        () => repository.createSale(sale),
        throwsA(isA<AppError>().having((e) => e.message, 'message', contains('exceed customer credit limit'))),
      );

      // Verify customer balance remains 0
      final fetchedCustomer = await customerRepository.getById(addedCustomer.id!);
      expect(fetchedCustomer?.currentBalance, 0.0);

      // Verify stock remains unchanged at 50
      final med = await db.query('medicines', columns: ['stock_quantity'], where: 'id = ?', whereArgs: [medicineId]);
      expect(med.first['stock_quantity'], 50);
    });
  });
}
