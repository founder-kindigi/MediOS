import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import 'package:medios/domain/entities/customer.dart';
import 'package:medios/domain/repositories/customer_repository.dart';
import 'package:medios/core/errors/app_error.dart';
import 'package:medios/models/user_model.dart';
import 'package:medios/features/auth/services/permission_service.dart';

void main() {
  late Database db;
  late CustomerRepository repository;

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

    // Retrieve repository from Service Locator (GetIt) registered in setupServiceLocator()
    repository = GetIt.I<CustomerRepository>();
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  group('Customer Profile CRUD Tests', () {
    test('getAll returns empty list when no customers exist', () async {
      final customers = await repository.getAll();
      expect(customers, isEmpty);
    });

    test('add customer successfully registers record and updates ID', () async {
      final customer = Customer(
        name: 'John Doe',
        phone: '03001234567',
        email: 'john@example.com',
        address: 'Test Address',
        creditLimit: 1000.0,
        createdAt: DateTime.now(),
      );

      final result = await repository.add(customer);
      expect(result.id, isNotNull);
      expect(result.name, 'John Doe');

      final list = await repository.getAll();
      expect(list.length, 1);
      expect(list.first.id, result.id);
    });

    test('add customer fails with validation error if name is empty', () async {
      final customer = Customer(
        name: '   ',
        phone: '1234567890',
        createdAt: DateTime.now(),
      );

      expect(
        () => repository.add(customer),
        throwsA(isA<AppError>().having((e) => e.type, 'type', ErrorType.validation)),
      );
    });

    test('update customer modifies data successfully', () async {
      final customer = Customer(
        name: 'Jane Doe',
        phone: '03009999999',
        createdAt: DateTime.now(),
      );
      final added = await repository.add(customer);

      final updated = added.copyWith(name: 'Jane Smith', phone: '03008888888');
      final result = await repository.update(updated);

      expect(result.name, 'Jane Smith');
      expect(result.phone, '03008888888');

      final fetched = await repository.getById(added.id!);
      expect(fetched?.name, 'Jane Smith');
    });

    test('delete customer fails if they have associated sales', () async {
      final customer = Customer(
        name: 'Client',
        phone: '1234',
        createdAt: DateTime.now(),
      );
      final added = await repository.add(customer);

      // Insert dummy sale associated with this customer
      await db.insert('sales', {
        'customer_id': added.id,
        'customer_name': added.name,
        'bill_number': 'BILL-101',
        'sale_date': DateTime.now().toIso8601String(),
        'total_amount': 250.0,
        'net_amount': 250.0,
        'payment_method': 'cash',
        'created_at': DateTime.now().toIso8601String(),
      });

      expect(
        () => repository.delete(added.id!),
        throwsA(isA<AppError>().having((e) => e.type, 'type', ErrorType.validation)),
      );
    });
  });

  group('Customer Credit Ledger & Payment Tests', () {
    test('setting opening balance updates balance and inserts transaction', () async {
      final customer = Customer(
        name: 'Khata Client',
        phone: '555',
        createdAt: DateTime.now(),
      );
      final added = await repository.add(customer);

      await repository.setOpeningBalance(customerId: added.id!, amount: 500.0, notes: 'Initial Balance');

      final fetched = await repository.getById(added.id!);
      expect(fetched?.currentBalance, 500.0);
      expect(fetched?.openingBalance, 500.0);

      final ledger = await repository.getLedger(added.id!);
      expect(ledger.length, 1);
      expect(ledger.first.type, CreditTransactionType.opening);
      expect(ledger.first.amount, 500.0);
      expect(ledger.first.runningBalance, 500.0);
    });

    test('recordPayment successfully decrements balance and logs transaction', () async {
      final customer = Customer(
        name: 'Paying Client',
        phone: '123',
        createdAt: DateTime.now(),
      );
      final added = await repository.add(customer);

      // Set initial balance
      await repository.setOpeningBalance(customerId: added.id!, amount: 300.0);

      // Record payment
      final result = await repository.recordPayment(
        customerId: added.id!,
        amount: 200.0,
        paymentMethod: 'cash',
        notes: 'Partial payment',
      );

      expect(result.isSuccess, isTrue);
      expect(result.newBalance, 100.0);

      final fetched = await repository.getById(added.id!);
      expect(fetched?.currentBalance, 100.0);

      final ledger = await repository.getLedger(added.id!);
      // Should have 2 entries: 1. opening balance, 2. payment
      expect(ledger.length, 2);
      expect(ledger.first.type, CreditTransactionType.payment);
      expect(ledger.first.amount, 200.0);
      expect(ledger.first.runningBalance, 100.0);
    });

    test('recordPayment returns failure if amount exceeds balance or no balance exists', () async {
      final customer = Customer(
        name: 'Limit Client',
        phone: '777',
        createdAt: DateTime.now(),
      );
      final added = await repository.add(customer);

      // Try paying when balance is zero
      final result1 = await repository.recordPayment(customerId: added.id!, amount: 50.0, paymentMethod: 'cash');
      expect(result1.isFailure, isTrue);
      expect(result1.errorMessage, contains('no outstanding balance'));

      // Set balance to 100
      await repository.setOpeningBalance(customerId: added.id!, amount: 100.0);

      // Try paying 150
      final result2 = await repository.recordPayment(customerId: added.id!, amount: 150.0, paymentMethod: 'cash');
      expect(result2.isFailure, isTrue);
      expect(result2.errorMessage, contains('exceeds outstanding balance'));
    });
  });
}
