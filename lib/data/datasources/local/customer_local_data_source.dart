import '../../../../core/database/database_helper.dart';
import '../../models/customer_model.dart';

class CustomerLocalDataSource {
  final DatabaseHelper _dbHelper;

  CustomerLocalDataSource({required DatabaseHelper databaseHelper})
      : _dbHelper = databaseHelper;

  Future<List<CustomerDataModel>> getAllCustomers({String? searchQuery}) async {
    final db = await _dbHelper.database;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      final maps = await db.query(
        'customers',
        where: 'LOWER(name) LIKE ? OR phone LIKE ?',
        whereArgs: [q, q],
        orderBy: 'name ASC',
      );
      return maps.map((m) => CustomerDataModel.fromMap(m)).toList();
    } else {
      final maps = await _dbHelper.query('customers', orderBy: 'name ASC');
      return maps.map((m) => CustomerDataModel.fromMap(m)).toList();
    }
  }

  Future<CustomerDataModel?> getCustomerById(int id) async {
    final map = await _dbHelper.getById('customers', id);
    if (map == null) return null;
    return CustomerDataModel.fromMap(map);
  }

  Future<int> insertCustomer(CustomerDataModel customer) async {
    return await _dbHelper.insert('customers', customer.toMap());
  }

  Future<int> updateCustomer(CustomerDataModel customer) async {
    final db = await _dbHelper.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    return await _dbHelper.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getCustomerSalesCount(int id) async {
    return await _dbHelper.getCount('sales', where: 'customer_id = ?', whereArgs: [id]);
  }

  Future<int> getCustomerOrdersCount(int id) async {
    return await _dbHelper.getCount('customer_orders', where: 'customer_id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getLedger(
    int customerId, {
    String? startDate,
    String? endDate,
    required int limit,
    required int offset,
  }) async {
    final db = await _dbHelper.database;
    var query = '''
      SELECT ct.*, c.name as customer_name
      FROM credit_transactions ct
      INNER JOIN customers c ON ct.customer_id = c.id
      WHERE ct.customer_id = ?
    ''';
    final queryArgs = <Object>[customerId];

    if (startDate != null) {
      query += ' AND ct.transaction_date >= ?';
      queryArgs.add(startDate);
    }

    if (endDate != null) {
      query += ' AND ct.transaction_date <= ?';
      queryArgs.add(endDate);
    }

    query += ' ORDER BY ct.transaction_date DESC, ct.id DESC LIMIT ? OFFSET ?';
    queryArgs.add(limit);
    queryArgs.add(offset);

    return await db.rawQuery(query, queryArgs);
  }

  Future<List<Map<String, dynamic>>> getPayments(
    int customerId, {
    String? startDate,
    String? endDate,
    required int limit,
    required int offset,
  }) async {
    var where = 'customer_id = ?';
    final whereArgs = <Object>[customerId];

    if (startDate != null) {
      where += ' AND payment_date >= ?';
      whereArgs.add(startDate);
    }

    if (endDate != null) {
      where += ' AND payment_date <= ?';
      whereArgs.add(endDate);
    }

    return await _dbHelper.query(
      'customer_payments',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'payment_date DESC, id DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getOverdueCustomers() async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
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
  }

  Future<List<Map<String, dynamic>>> getRecentCreditTransactions(int limit) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT ct.*, c.name as customer_name
      FROM credit_transactions ct
      INNER JOIN customers c ON ct.customer_id = c.id
      ORDER BY ct.transaction_date DESC, ct.id DESC
      LIMIT ?
    ''', [limit]);
  }

  Future<Map<String, dynamic>?> getCreditSalesAndPaymentsTotals(int customerId) async {
    final db = await _dbHelper.database;
    final salesResult = await db.rawQuery('''
      SELECT COALESCE(SUM(net_amount), 0) as total_sales
      FROM sales
      WHERE customer_id = ? AND payment_method = 'credit'
    ''', [customerId]);

    final paymentsResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total_payments
      FROM customer_payments
      WHERE customer_id = ?
    ''', [customerId]);

    final lastTxResult = await db.rawQuery('''
      SELECT transaction_date
      FROM credit_transactions
      WHERE customer_id = ?
      ORDER BY transaction_date DESC
      LIMIT 1
    ''', [customerId]);

    final lastPayResult = await db.rawQuery('''
      SELECT payment_date
      FROM customer_payments
      WHERE customer_id = ?
      ORDER BY payment_date DESC
      LIMIT 1
    ''', [customerId]);

    return {
      'total_sales': salesResult.first['total_sales'],
      'total_payments': paymentsResult.first['total_payments'],
      'last_transaction_date': lastTxResult.isNotEmpty ? lastTxResult.first['transaction_date'] : null,
      'last_payment_date': lastPayResult.isNotEmpty ? lastPayResult.first['payment_date'] : null,
    };
  }

  Future<int> insertCreditTransaction(Map<String, dynamic> map) async {
    return await _dbHelper.insert('credit_transactions', map);
  }

  Future<int> insertCustomerPayment(Map<String, dynamic> map) async {
    return await _dbHelper.insert('customer_payments', map);
  }

  Future<void> executeOpeningBalanceTransaction(int customerId, double amount, String? notes) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final customerResult = await txn.query(
        'customers',
        columns: ['name', 'current_balance'],
        where: 'id = ?',
        whereArgs: [customerId],
      );
      if (customerResult.isEmpty) {
        throw Exception('Customer not found');
      }
      final currentBalance = (customerResult.first['current_balance'] as num?)?.toDouble() ?? 0.0;
      final newBalance = currentBalance + amount;

      // Log opening balance transaction
      await txn.insert('credit_transactions', {
        'customer_id': customerId,
        'transaction_date': DateTime.now().toIso8601String(),
        'transaction_type': 'opening',
        'amount': amount,
        'balance_after': newBalance,
        'description': 'Opening Balance',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update customer balance
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
    });
  }

  Future<Map<String, dynamic>> executePaymentTransaction(
    int customerId,
    double amount,
    String paymentMethod,
    String? referenceNumber,
    String? description,
    String? notes,
  ) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      final customerResult = await txn.query(
        'customers',
        columns: ['name', 'current_balance'],
        where: 'id = ?',
        whereArgs: [customerId],
      );
      if (customerResult.isEmpty) {
        throw Exception('Customer not found');
      }
      final currentBalance = (customerResult.first['current_balance'] as num?)?.toDouble() ?? 0.0;

      if (currentBalance <= 0 && amount > 0) {
        throw Exception('Customer has no outstanding balance');
      }

      if (amount > currentBalance) {
        throw Exception('Payment amount ($amount) exceeds outstanding balance ($currentBalance)');
      }

      final newBalance = currentBalance - amount;

      // Create payment record
      final paymentId = await txn.insert('customer_payments', {
        'customer_id': customerId,
        'payment_date': DateTime.now().toIso8601String(),
        'amount': amount,
        'payment_method': paymentMethod,
        'reference_number': referenceNumber,
        'description': description,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Create credit transaction
      await txn.insert('credit_transactions', {
        'customer_id': customerId,
        'transaction_date': DateTime.now().toIso8601String(),
        'transaction_type': 'payment',
        'amount': amount,
        'balance_after': newBalance,
        'description': description ?? 'Payment Received',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });

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

      return {
        'paymentId': paymentId,
        'newBalance': newBalance,
      };
    });
  }
}
