import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/security/permissions.dart';
import '../../../features/auth/services/permission_service.dart';
import '../../../models/sale_model.dart';
import '../../stores/services/store_service.dart';
import '../../customers/services/customer_credit_service.dart';

class SalesService extends ChangeNotifier {
  final DatabaseHelper _db;
  final StoreService _storeService;
  final PermissionService _permissionService;
  final CustomerCreditService _creditService;

  SalesService({
    DatabaseHelper? databaseHelper,
    StoreService? storeService,
    PermissionService? permissionService,
    CustomerCreditService? creditService,
  }) : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>(),
        _storeService = storeService ?? GetIt.instance<StoreService>(),
        _permissionService = permissionService ?? GetIt.instance<PermissionService>(),
        _creditService = creditService ?? GetIt.instance<CustomerCreditService>();
  List<SaleModel> _sales = [];
  bool _isLoading = false;

  List<SaleModel> get sales => _sales;
  bool get isLoading => _isLoading;

  Future<void> loadSales() async {
    _isLoading = true;
    notifyListeners();

    try {
      final storeId = _storeService.selectedStoreId;
      final maps = await _db.query('sales',
          where: 'store_id = ?', whereArgs: [storeId], orderBy: 'sale_date DESC');
      _sales = maps.map((m) => SaleModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Failed to load sales: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<SaleModel>> getSalesByCustomer(int customerId) async {
    final maps = await _db.query('sales',
        where: 'customer_id = ?', whereArgs: [customerId], orderBy: 'sale_date DESC');
    return maps.map((m) => SaleModel.fromMap(m)).toList();
  }

  /// Creates a new sale with support for credit sales.
  /// For credit sales, also creates credit transaction and updates customer balance.
  Future<int> createSale(SaleModel sale, List<SaleItemModel> items) async {
    // Check permission
    _permissionService.checkPermission(AppPermission.canCreateSale);
    
    final db = await _db.database;
    final storeId = _storeService.selectedStoreId;
    
    final saleId = await db.transaction((txn) async {
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
      final id = await txn.insert('sales', saleMap);

      // 3. For each item: insert sale item, decrement stock, and log transaction
      for (final item in items) {
        await txn.insert('sale_items', {
          'sale_id': id,
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
          'reference_id': id,
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
          final creditLimit = (customerResult.first['credit_limit'] as num?)?.toDouble() ?? 0;
          final currentBalance = (customerResult.first['current_balance'] as num?)?.toDouble() ?? 0;
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
            'reference_id': id,
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
      
      return id;
    });

    await loadSales();
    return saleId;
  }

  Future<SaleModel?> getSaleWithItems(int saleId) async {
    final saleMap = await _db.getById('sales', saleId);
    if (saleMap == null) return null;

    final itemMaps = await _db.query('sale_items',
        where: 'sale_id = ?', whereArgs: [saleId]);

    final sale = SaleModel.fromMap(saleMap);
    final items = itemMaps.map((m) => SaleItemModel.fromMap(m)).toList();
    return SaleModel(
      id: sale.id,
      customerId: sale.customerId,
      customerName: sale.customerName,
      billNumber: sale.billNumber,
      saleDate: sale.saleDate,
      totalAmount: sale.totalAmount,
      discount: sale.discount,
      tax: sale.tax,
      netAmount: sale.netAmount,
      paymentMethod: sale.paymentMethod,
      notes: sale.notes,
      storeId: sale.storeId,
      createdAt: sale.createdAt,
      items: items,
    );
  }

  Future<double> getTodaySales() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final storeId = _storeService.selectedStoreId;

    return await _db.getSum('sales', 'net_amount',
        where: 'store_id = ? AND sale_date >= ? AND sale_date < ?',
        whereArgs: [storeId, startOfDay.toIso8601String(), endOfDay.toIso8601String()]);
  }

  Future<int> getTodayTransactionCount() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final storeId = _storeService.selectedStoreId;

    return await _db.getCount('sales',
        where: 'store_id = ? AND sale_date >= ? AND sale_date < ?',
        whereArgs: [storeId, startOfDay.toIso8601String(), endOfDay.toIso8601String()]);
  }

  @override
  void dispose() {
    // Clear sales data to prevent memory leaks
    _sales = [];
    
    super.dispose();
  }
}
