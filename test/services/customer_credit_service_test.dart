import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:get_it/get_it.dart';
import 'package:medios/core/database/database_helper.dart';
import 'package:medios/features/auth/services/permission_service.dart';
import 'package:medios/features/customers/services/customer_credit_service.dart';
import 'package:medios/models/user_model.dart';
import '../test_helper.dart';

void main() {
  late Database db;
  late CustomerCreditService service;
  late PermissionService permissionService;

  setUp(() async {
    db = await createAndSetTestDb();
    permissionService = GetIt.I<PermissionService>();
    
    // Set current user as admin so that permission checks pass
    final adminUser = UserModel(
      id: 1,
      username: 'test_admin',
      fullName: 'Test Admin',
      role: 'admin',
      passwordHash: 'dummy',
    );
    await permissionService.setCurrentUser(adminUser);
    
    service = CustomerCreditService(
      databaseHelper: DatabaseHelper(),
      permissionService: permissionService,
    );
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  group('CustomerCreditService Tests', () {
    test('getCustomerBalance retrieves balance', () async {
      // 1. Insert customer with current balance
      final customerId = await db.insert('customers', {
        'name': 'Credit Customer',
        'phone': '0300-1234567',
        'credit_limit': 5000.0,
        'opening_balance': 0.0,
        'current_balance': 1500.0,
        'created_at': DateTime.now().toIso8601String(),
      });

      final balance = await service.getCustomerBalance(customerId);
      expect(balance, equals(1500.0));
    });

    test('createCreditSaleTransaction increases customer balance and creates ledger entry', () async {
      final customerId = await db.insert('customers', {
        'name': 'Credit Customer',
        'phone': '0300-1234567',
        'credit_limit': 5000.0,
        'opening_balance': 0.0,
        'current_balance': 1000.0,
        'created_at': DateTime.now().toIso8601String(),
      });

      final transaction = await service.createCreditSaleTransaction(
        customerId: customerId,
        saleId: 10,
        amount: 500.0,
        notes: 'Test credit sale',
      );

      expect(transaction.amount, equals(500.0));
      expect(transaction.balanceAfter - transaction.amount, equals(1000.0));
      expect(transaction.balanceAfter, equals(1500.0));
      expect(transaction.transactionType, equals('sale'));

      // Verify db updates
      final balance = await service.getCustomerBalance(customerId);
      expect(balance, equals(1500.0));

      final ledger = await service.getCustomerLedger(customerId);
      expect(ledger.length, equals(1));
      expect(ledger.first.amount, equals(500.0));
      expect(ledger.first.referenceId, equals(10));
    });

    test('recordPayment records payment, decreases balance, and creates ledger entry', () async {
      final customerId = await db.insert('customers', {
        'name': 'Credit Customer',
        'phone': '0300-1234567',
        'credit_limit': 5000.0,
        'opening_balance': 0.0,
        'current_balance': 1000.0,
        'created_at': DateTime.now().toIso8601String(),
      });

      final result = await service.recordPayment(
        customerId: customerId,
        amount: 400.0,
        paymentMethod: 'cash',
        description: 'Partial payment',
      );

      expect(result.isSuccess, isTrue);
      expect(result.newBalance, equals(600.0));

      // Verify balance in database
      final balance = await service.getCustomerBalance(customerId);
      expect(balance, equals(600.0));

      // Verify ledger transaction
      final ledger = await service.getCustomerLedger(customerId);
      expect(ledger.length, equals(1));
      expect(ledger.first.amount, equals(400.0));
      expect(ledger.first.transactionType, equals('payment'));
    });

    test('recordPayment fails if payment exceeds balance or if balance is zero', () async {
      final customerId = await db.insert('customers', {
        'name': 'Credit Customer',
        'phone': '0300-1234567',
        'credit_limit': 5000.0,
        'opening_balance': 0.0,
        'current_balance': 100.0,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 1. Exceeds balance
      final result1 = await service.recordPayment(
        customerId: customerId,
        amount: 200.0,
        paymentMethod: 'cash',
      );
      expect(result1.isSuccess, isFalse);
      expect(result1.errorMessage, contains('exceeds outstanding balance'));

      // 2. Clear balance
      await service.recordPayment(
        customerId: customerId,
        amount: 100.0,
        paymentMethod: 'cash',
      );

      // 3. Pay when balance is zero
      final result2 = await service.recordPayment(
        customerId: customerId,
        amount: 10.0,
        paymentMethod: 'cash',
      );
      expect(result2.isSuccess, isFalse);
      expect(result2.errorMessage, contains('no outstanding balance'));
    });

    test('updateCreditLimit updates the credit limit successfully', () async {
      final customerId = await db.insert('customers', {
        'name': 'Credit Customer',
        'phone': '0300-1234567',
        'credit_limit': 5000.0,
        'opening_balance': 0.0,
        'current_balance': 0.0,
        'created_at': DateTime.now().toIso8601String(),
      });

      await service.updateCreditLimit(customerId, 10000.0);

      final summary = await service.getCustomerCreditSummary(customerId);
      expect(summary.creditLimit, equals(10000.0));
    });

    test('setOpeningBalance sets opening balance and ledger transaction', () async {
      final customerId = await db.insert('customers', {
        'name': 'Credit Customer',
        'phone': '0300-1234567',
        'credit_limit': 5000.0,
        'opening_balance': 0.0,
        'current_balance': 0.0,
        'created_at': DateTime.now().toIso8601String(),
      });

      await service.setOpeningBalance(
        customerId: customerId,
        amount: 1200.0,
        notes: 'Legacy customer balance',
      );

      final balance = await service.getCustomerBalance(customerId);
      expect(balance, equals(1200.0));

      final summary = await service.getCustomerCreditSummary(customerId);
      expect(summary.openingBalance, equals(1200.0));

      final ledger = await service.getCustomerLedger(customerId);
      expect(ledger.length, equals(1));
      expect(ledger.first.transactionType, equals('opening'));
    });
  });
}
