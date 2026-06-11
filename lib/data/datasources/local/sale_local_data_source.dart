import '../../../../core/database/database_helper.dart';
import '../../models/sale_model.dart';

class SaleLocalDataSource {
  final DatabaseHelper _dbHelper;

  SaleLocalDataSource({required DatabaseHelper databaseHelper})
      : _dbHelper = databaseHelper;

  /// Retrieves all sales for a store ID.
  Future<List<Map<String, dynamic>>> getSales({required int storeId}) async {
    final db = await _dbHelper.database;
    return await db.query(
      'sales',
      where: 'store_id = ?',
      whereArgs: [storeId],
      orderBy: 'sale_date DESC',
    );
  }

  /// Retrieves sales for a customer ID.
  Future<List<Map<String, dynamic>>> getSalesByCustomer(int customerId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'sales',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'sale_date DESC',
    );
  }

  /// Gets a sale header by ID.
  Future<Map<String, dynamic>?> getSaleById(int saleId) async {
    return await _dbHelper.getById('sales', saleId);
  }

  /// Gets sale line items by sale ID.
  Future<List<Map<String, dynamic>>> getSaleItems(int saleId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
  }

  /// Gets total sum of sales for today in a store.
  Future<double> getTodaySales({required int storeId, required String startStr, required String endStr}) async {
    return await _dbHelper.getSum(
      'sales',
      'net_amount',
      where: 'store_id = ? AND sale_date >= ? AND sale_date < ?',
      whereArgs: [storeId, startStr, endStr],
    );
  }

  /// Gets count of sales for today in a store.
  Future<int> getTodayTransactionCount({required int storeId, required String startStr, required String endStr}) async {
    return await _dbHelper.getCount(
      'sales',
      where: 'store_id = ? AND sale_date >= ? AND sale_date < ?',
      whereArgs: [storeId, startStr, endStr],
    );
  }

  /// Performs the atomic checkout transaction.
  Future<int> executeCreateSaleTransaction(
    SaleDataModel sale,
    List<SaleItemDataModel> items, {
    required int storeId,
  }) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      // 1. Stock validation check
      for (final item in items) {
        final maps = await txn.query('medicines', 
          columns: ['stock_quantity', 'name'], 
          where: 'id = ?', 
          whereArgs: [item.medicineId]
        );
        
        if (maps.isEmpty) {
          throw Exception('Medicine "${item.medicineName}" not found in database.');
        }
        
        final currentStock = maps.first['stock_quantity'] as int? ?? 0;
        if (currentStock < item.quantity) {
          final medName = maps.first['name'] as String? ?? item.medicineName;
          throw Exception('Insufficient stock for "$medName" (available: $currentStock, requested: ${item.quantity}).');
        }
      }

      // 2. Insert Sale header record
      final saleMap = sale.toMap()..['store_id'] = storeId;
      final saleId = await txn.insert('sales', saleMap);

      // 3. For each item: insert sale item, decrement stock, and log transaction
      for (final item in items) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'medicine_id': item.medicineId,
          'medicine_name': item.medicineName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total_price': item.totalPrice,
        });

        // Atomic decrement
        await txn.rawUpdate(
          'UPDATE medicines SET stock_quantity = stock_quantity - ?, updated_at = ? WHERE id = ?',
          [item.quantity, DateTime.now().toIso8601String(), item.medicineId],
        );

        // Audit log transaction
        await txn.insert('inventory_transactions', {
          'medicine_id': item.medicineId,
          'medicine_name': item.medicineName,
          'type': 'out',
          'quantity': item.quantity,
          'reference_type': 'sale',
          'reference_id': saleId,
          'notes': 'Sale Checkout: ${sale.billNumber}',
          'store_id': storeId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      // 4. Handle credit sale if payment method is 'credit'
      if (sale.paymentMethod == 'credit' && sale.customerId != null) {
        // Check customer credit limit
        final customerResult = await txn.query(
          'customers',
          columns: ['credit_limit', 'current_balance'],
          where: 'id = ?',
          whereArgs: [sale.customerId],
        );
        
        if (customerResult.isNotEmpty) {
          final creditLimit = (customerResult.first['credit_limit'] as num?)?.toDouble() ?? 0.0;
          final currentBalance = (customerResult.first['current_balance'] as num?)?.toDouble() ?? 0.0;
          final newBalance = currentBalance + sale.netAmount;
          
          // Check if exceeds credit limit
          if (creditLimit > 0 && newBalance > creditLimit) {
            throw Exception(
              'Credit sale would exceed customer credit limit. '
              'Current balance: $currentBalance, Sale amount: ${sale.netAmount}, '
              'New balance: $newBalance, Credit limit: $creditLimit'
            );
          }
          
          // Create credit transaction
          await txn.insert('credit_transactions', {
            'customer_id': sale.customerId,
            'transaction_date': DateTime.now().toIso8601String(),
            'transaction_type': 'sale',
            'reference_id': saleId,
            'reference_type': 'sale',
            'amount': sale.netAmount,
            'balance_after': newBalance,
            'description': 'Credit Sale: ${sale.billNumber}',
            'notes': sale.notes,
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
            whereArgs: [sale.customerId],
          );
        }
      }
      
      return saleId;
    });
  }
}
