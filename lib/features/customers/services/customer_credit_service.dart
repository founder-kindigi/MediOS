import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common/sqlite_api.dart' show Database, DatabaseExecutor;
import '../../../core/database/database_helper.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/security/permissions.dart';
import '../../../features/auth/services/permission_service.dart';
import '../models/customer_credit.dart';
import '../../../models/sale_model.dart';

/// Service for managing customer credit (khata) system.
/// Handles credit sales, payments, balance tracking, and ledger management.
class CustomerCreditService extends ChangeNotifier {
  final DatabaseHelper _db;
  final PermissionService _permissionService;
  
  CustomerCreditService({
    DatabaseHelper? databaseHelper,
    PermissionService? permissionService,
  }) : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>(),
       _permissionService = permissionService ?? GetIt.instance<PermissionService>();

  /// Creates a credit sale transaction.
  /// This should be called within the sales transaction.
  Future<CreditTransaction> createCreditSaleTransaction({
    required int customerId,
    required int saleId,
    required double amount,
    required String? notes,
  }) async {
    // Check permission
    _permissionService.checkPermission(AppPermission.canManageCustomerCredit);
    
    try {
      // Get current balance and name
      final db = await _db.database;
      final customerResult = await db.query(
        'customers',
        columns: ['name', 'current_balance'],
        where: 'id = ?',
        whereArgs: [customerId],
      );
      if (customerResult.isEmpty) {
        throw AppError(
          message: 'Customer not found',
          type: ErrorType.notFound,
        );
      }
      final customerName = customerResult.first['name'] as String;
      final currentBalance = (customerResult.first['current_balance'] as num?)?.toDouble() ?? 0.0;
      final newBalance = currentBalance + amount;
      
      // Create transaction
      final transaction = CreditTransaction.sale(
        customerId: customerId,
        customerName: customerName,
        saleId: saleId,
        amount: amount,
        previousBalance: currentBalance,
        notes: notes,
      );
      
      // Insert transaction
      final transactionId = await _db.insert('credit_transactions', transaction.toMap());
      
      // Update customer balance
      await _updateCustomerBalance(customerId, newBalance);
      
      return transaction.copyWith(id: transactionId);
    } catch (e) {
      throw AppError(
        message: 'Failed to create credit sale transaction: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  /// Records a customer payment.
  Future<PaymentResult> recordPayment({
    required int customerId,
    required double amount,
    required String paymentMethod,
    String? referenceNumber,
    String? description,
    String? notes,
  }) async {
    // Check permission
    _permissionService.checkPermission(AppPermission.canManageCustomerCredit);
    
    return await _db.database.then((db) async {
      return await db.transaction((txn) async {
        try {
          // Get current balance and name
          final customerResult = await txn.query(
            'customers',
            columns: ['name', 'current_balance'],
            where: 'id = ?',
            whereArgs: [customerId],
          );
          if (customerResult.isEmpty) {
            return PaymentResult.failure(
              error: 'Customer not found',
            );
          }
          final customerName = customerResult.first['name'] as String;
          final currentBalance = (customerResult.first['current_balance'] as num?)?.toDouble() ?? 0.0;
          
          if (currentBalance <= 0 && amount > 0) {
            return PaymentResult.failure(
              error: 'Customer has no outstanding balance',
            );
          }
          
          if (amount > currentBalance) {
            return PaymentResult.failure(
              error: 'Payment amount ($amount) exceeds outstanding balance ($currentBalance)',
            );
          }
          
          final newBalance = currentBalance - amount;
          
          // Create payment record
          final payment = CustomerPayment(
            customerId: customerId,
            paymentDate: DateTime.now(),
            amount: amount,
            paymentMethod: paymentMethod,
            referenceNumber: referenceNumber,
            description: description,
            notes: notes,
            createdAt: DateTime.now(),
          );
          
          final paymentId = await txn.insert('customer_payments', payment.toMap());
          
          // Create credit transaction
          final transaction = CreditTransaction.payment(
            customerId: customerId,
            customerName: customerName,
            amount: amount,
            previousBalance: currentBalance,
            description: description,
            notes: notes,
          );
          
          await txn.insert('credit_transactions', transaction.toMap());
          
          // Update customer balance
          await txn.update(
            'customers',
            {
              'current_balance': newBalance,
              'last_credit_update': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [customerId],
          );
          
          return PaymentResult.success(
            paymentId: paymentId,
            newBalance: newBalance,
            message: 'Payment recorded successfully',
          );
        } catch (e) {
          return PaymentResult.failure(
            error: 'Failed to record payment: $e',
          );
        }
      });
    });
  }

  /// Gets a customer's current balance.
  Future<double> getCustomerBalance(int customerId) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'customers',
        columns: ['current_balance'],
        where: 'id = ?',
        whereArgs: [customerId],
      );
      
      if (result.isEmpty) {
        throw AppError(
          message: 'Customer not found',
          type: ErrorType.notFound,
        );
      }
      
      return (result.first['current_balance'] as num?)?.toDouble() ?? 0;
    } catch (e) {
      throw AppError(
        message: 'Failed to get customer balance: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  /// Gets customer credit summary.
  Future<CustomerCreditSummary> getCustomerCreditSummary(int customerId) async {
    try {
      final db = await _db.database;
      
      // Get customer info
      final customerResult = await db.query(
        'customers',
        where: 'id = ?',
        whereArgs: [customerId],
      );
      
      if (customerResult.isEmpty) {
        throw AppError(
          message: 'Customer not found',
          type: ErrorType.notFound,
        );
      }
      
      final customer = customerResult.first;
      final customerName = customer['name'] as String;
      final creditLimit = (customer['credit_limit'] as num?)?.toDouble() ?? 0;
      final openingBalance = (customer['opening_balance'] as num?)?.toDouble() ?? 0;
      final currentBalance = (customer['current_balance'] as num?)?.toDouble() ?? 0;
      
      // Get total sales
      final salesResult = await db.rawQuery('''
        SELECT COALESCE(SUM(net_amount), 0) as total_sales
        FROM sales
        WHERE customer_id = ? AND payment_method = 'credit'
      ''', [customerId]);
      
      final totalSales = (salesResult.first['total_sales'] as num?)?.toDouble() ?? 0;
      
      // Get total payments
      final paymentsResult = await db.rawQuery('''
        SELECT COALESCE(SUM(amount), 0) as total_payments
        FROM customer_payments
        WHERE customer_id = ?
      ''', [customerId]);
      
      final totalPayments = (paymentsResult.first['total_payments'] as num?)?.toDouble() ?? 0;
      
      // Get last transaction date
      final lastTransactionResult = await db.rawQuery('''
        SELECT transaction_date
        FROM credit_transactions
        WHERE customer_id = ?
        ORDER BY transaction_date DESC
        LIMIT 1
      ''', [customerId]);
      
      DateTime? lastTransactionDate;
      if (lastTransactionResult.isNotEmpty) {
        lastTransactionDate = DateTime.parse(lastTransactionResult.first['transaction_date'] as String);
      }
      
      // Get last payment date
      final lastPaymentResult = await db.rawQuery('''
        SELECT payment_date
        FROM customer_payments
        WHERE customer_id = ?
        ORDER BY payment_date DESC
        LIMIT 1
      ''', [customerId]);
      
      DateTime? lastPaymentDate;
      if (lastPaymentResult.isNotEmpty) {
        lastPaymentDate = DateTime.parse(lastPaymentResult.first['payment_date'] as String);
      }
      
      // Calculate days overdue (simplified - if balance > 0 and no payment in 30 days)
      int daysOverdue = 0;
      if (currentBalance > 0 && lastPaymentDate != null) {
        final daysSincePayment = DateTime.now().difference(lastPaymentDate).inDays;
        if (daysSincePayment > 30) {
          daysOverdue = daysSincePayment - 30;
        }
      }
      
      return CustomerCreditSummary(
        customerId: customerId,
        customerName: customerName,
        openingBalance: openingBalance,
        totalSales: totalSales,
        totalPayments: totalPayments,
        currentBalance: currentBalance,
        creditLimit: creditLimit,
        lastTransactionDate: lastTransactionDate,
        lastPaymentDate: lastPaymentDate,
        daysOverdue: daysOverdue,
      );
    } catch (e) {
      throw AppError(
        message: 'Failed to get credit summary: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  /// Gets customer credit transactions (ledger).
  Future<List<CreditTransaction>> getCustomerLedger(
    int customerId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final db = await _db.database;
      
      var query = '''
        SELECT ct.*, c.name as customer_name
        FROM credit_transactions ct
        INNER JOIN customers c ON ct.customer_id = c.id
        WHERE ct.customer_id = ?
      ''';
      final queryArgs = <Object>[customerId];
      
      if (startDate != null) {
        query += ' AND ct.transaction_date >= ?';
        queryArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        query += ' AND ct.transaction_date <= ?';
        queryArgs.add(endDate.toIso8601String());
      }
      
      query += ' ORDER BY ct.transaction_date DESC, ct.id DESC LIMIT ? OFFSET ?';
      queryArgs.add(limit);
      queryArgs.add(offset);
      
      final result = await db.rawQuery(query, queryArgs);
      
      return result.map((map) => CreditTransaction.fromMap(map)).toList();
    } catch (e) {
      throw AppError(
        message: 'Failed to get customer ledger: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  /// Updates customer credit limit.
  Future<void> updateCreditLimit(int customerId, double creditLimit) async {
    // Check permission
    _permissionService.checkPermission(AppPermission.canManageCustomerCredit);
    
    try {
      await _db.update(
        'customers',
        {
          'credit_limit': creditLimit,
          'last_credit_update': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [customerId],
      );
      
      notifyListeners();
    } catch (e) {
      throw AppError(
        message: 'Failed to update credit limit: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  /// Sets customer opening balance.
  Future<void> setOpeningBalance({
    required int customerId,
    required double amount,
    String? notes,
  }) async {
    // Check permission
    _permissionService.checkPermission(AppPermission.canManageCustomerCredit);
    
    return await _db.database.then((db) async {
      return await db.transaction((txn) async {
        try {
          // Get customer info (name and current balance)
          final customerResult = await txn.query(
            'customers',
            columns: ['name', 'current_balance'],
            where: 'id = ?',
            whereArgs: [customerId],
          );
          if (customerResult.isEmpty) {
            throw AppError(
              message: 'Customer not found',
              type: ErrorType.notFound,
            );
          }
          final customerName = customerResult.first['name'] as String;
          final currentBalance = (customerResult.first['current_balance'] as num?)?.toDouble() ?? 0.0;
          
          // Create opening balance transaction
          final transaction = CreditTransaction.openingBalance(
            customerId: customerId,
            customerName: customerName,
            amount: amount,
            notes: notes,
          );
          
          await txn.insert('credit_transactions', transaction.toMap());
          
          // Update customer balance
          final newBalance = currentBalance + amount;
          await txn.update(
            'customers',
            {
              'opening_balance': amount,
              'current_balance': newBalance,
              'last_credit_update': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [customerId],
          );
        } catch (e) {
          throw AppError(
            message: 'Failed to set opening balance: $e',
            type: ErrorType.database,
            originalError: e,
          );
        }
      });
    });
  }

  /// Gets overdue customers.
  Future<List<CustomerCreditSummary>> getOverdueCustomers() async {
    try {
      final db = await _db.database;
      
      // Simple query to find customers with balance > 0 and no payment in 30+ days
      final result = await db.rawQuery('''
        SELECT 
          c.id as customer_id,
          c.name as customer_name,
          c.current_balance,
          c.credit_limit,
          MAX(cp.payment_date) as last_payment_date
        FROM customers c
        LEFT JOIN customer_payments cp ON c.id = cp.customer_id
        WHERE c.current_balance > 0
        GROUP BY c.id, c.name, c.current_balance, c.credit_limit
        HAVING last_payment_date IS NULL 
          OR JULIANDAY('now') - JULIANDAY(last_payment_date) > 30
        ORDER BY c.current_balance DESC
      ''');
      
      final summaries = <CustomerCreditSummary>[];
      
      for (final row in result) {
        final customerId = row['customer_id'] as int;
        
        // Get full summary for each customer
        try {
          final summary = await getCustomerCreditSummary(customerId);
          summaries.add(summary);
        } catch (e) {
          // Skip customers with errors
          debugPrint('Error getting summary for customer $customerId: $e');
        }
      }
      
      return summaries;
    } catch (e) {
      throw AppError(
        message: 'Failed to get overdue customers: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  /// Gets all customer payments.
  Future<List<CustomerPayment>> getCustomerPayments(
    int customerId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final db = await _db.database;
      
      var where = 'customer_id = ?';
      final whereArgs = <Object>[customerId];
      
      if (startDate != null) {
        where += ' AND payment_date >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        where += ' AND payment_date <= ?';
        whereArgs.add(endDate.toIso8601String());
      }
      
      final result = await db.query(
        'customer_payments',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'payment_date DESC, id DESC',
        limit: limit,
        offset: offset,
      );
      
      return result.map((map) => CustomerPayment.fromMap(map)).toList();
    } catch (e) {
      throw AppError(
        message: 'Failed to get customer payments: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  /// Gets all customer credit records.
  Future<List<CustomerCredit>> getAllCustomerCredits() async {
    try {
      final db = await _db.database;
      final result = await db.rawQuery('''
        SELECT id as customer_id, name as customer_name, phone, email, credit_limit, 
               opening_balance, current_balance, last_credit_update, created_at 
        FROM customers 
        ORDER BY name ASC
      ''');
      return result.map((map) => CustomerCredit.fromMap(map)).toList();
    } catch (e) {
      throw AppError(
        message: 'Failed to get all customer credits: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  /// Gets customer credit info by ID.
  Future<CustomerCredit> getCustomerCredit(int customerId) async {
    try {
      final db = await _db.database;
      final result = await db.rawQuery('''
        SELECT id as customer_id, name as customer_name, phone, email, credit_limit, 
               opening_balance, current_balance, last_credit_update, created_at 
        FROM customers 
        WHERE id = ?
      ''', [customerId]);
      
      if (result.isEmpty) {
        throw AppError(
          message: 'Customer not found',
          type: ErrorType.notFound,
        );
      }
      
      return CustomerCredit.fromMap(result.first);
    } catch (e) {
      throw AppError(
        message: 'Failed to get customer credit info: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  /// Gets recent credit transactions across all customers.
  Future<List<CreditTransaction>> getRecentTransactions({int limit = 20}) async {
    try {
      final db = await _db.database;
      final result = await db.rawQuery('''
        SELECT ct.*, c.name as customer_name
        FROM credit_transactions ct
        INNER JOIN customers c ON ct.customer_id = c.id
        ORDER BY ct.transaction_date DESC, ct.id DESC
        LIMIT ?
      ''', [limit]);
      return result.map((map) => CreditTransaction.fromMap(map)).toList();
    } catch (e) {
      throw AppError(
        message: 'Failed to get recent credit transactions: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  /// Gets customer transactions (alias for getCustomerLedger).
  Future<List<CreditTransaction>> getCustomerTransactions(int customerId) async {
    return getCustomerLedger(customerId);
  }

  // Private helper methods

  Future<double> _getCustomerBalance(DatabaseExecutor txn, int customerId) async {
    final result = await txn.query(
      'customers',
      columns: ['current_balance'],
      where: 'id = ?',
      whereArgs: [customerId],
    );
    
    if (result.isEmpty) {
      throw AppError(
        message: 'Customer not found',
        type: ErrorType.notFound,
      );
    }
    
    return (result.first['current_balance'] as num?)?.toDouble() ?? 0;
  }

  Future<void> _updateCustomerBalance(int customerId, double newBalance) async {
    await _db.update(
      'customers',
      {
        'current_balance': newBalance,
        'last_credit_update': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [customerId],
    );
    
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}