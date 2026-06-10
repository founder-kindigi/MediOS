import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../../core/database/database_helper.dart';
import '../../stores/services/store_service.dart';

class ReportsService extends ChangeNotifier {
  final DatabaseHelper _db;
  final StoreService _storeService;

  ReportsService({DatabaseHelper? databaseHelper, StoreService? storeService})
      : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>(),
        _storeService = storeService ?? GetIt.instance<StoreService>();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<Map<String, double>> getMonthlyRevenue({int? year}) async {
    final currentYear = (year ?? DateTime.now().year).toString();
    final storeId = _storeService.selectedStoreId;
    final db = await _db.database;

    final rows = await db.rawQuery('''
      SELECT substr(sale_date, 6, 2) as month, SUM(net_amount) as total
      FROM sales
      WHERE store_id = ? AND substr(sale_date, 1, 4) = ?
      GROUP BY month
    ''', [storeId, currentYear]);

    final result = <String, double>{};
    for (int month = 1; month <= 12; month++) {
      result[month.toString().padLeft(2, '0')] = 0.0;
    }
    for (final row in rows) {
      final monthStr = row['month'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      result[monthStr] = total;
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getTopMedicines({int limit = 10}) async {
    final db = await _db.database;
    final storeId = _storeService.selectedStoreId;
    final result = await db.rawQuery('''
      SELECT si.medicine_name, SUM(si.quantity) as total_qty, SUM(si.total_price) as total_revenue
      FROM sale_items si
      INNER JOIN sales s ON si.sale_id = s.id
      WHERE s.store_id = ?
      GROUP BY si.medicine_name
      ORDER BY total_qty DESC
      LIMIT ?
    ''', [storeId, limit]);
    return result;
  }

  Future<Map<String, double>> getSalesByPaymentMethod() async {
    final db = await _db.database;
    final storeId = _storeService.selectedStoreId;
    final result = await db.rawQuery('''
      SELECT payment_method, COALESCE(SUM(net_amount), 0) as total
      FROM sales
      WHERE store_id = ?
      GROUP BY payment_method
    ''', [storeId]);
    final map = <String, double>{};
    for (final row in result) {
      map[row['payment_method'] as String] = (row['total'] as num).toDouble();
    }
    return map;
  }

  Future<Map<String, double>> getSalesSummary() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1)).toIso8601String();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    final storeId = _storeService.selectedStoreId;
    final db = await _db.database;

    final rows = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN sale_date >= ? THEN net_amount ELSE 0 END) as today,
        SUM(CASE WHEN sale_date >= ? THEN net_amount ELSE 0 END) as week,
        SUM(CASE WHEN sale_date >= ? THEN net_amount ELSE 0 END) as month,
        SUM(net_amount) as total
      FROM sales
      WHERE store_id = ?
    ''', [todayStart, weekStart, monthStart, storeId]);

    if (rows.isEmpty || rows.first['total'] == null) {
      return {'today': 0.0, 'week': 0.0, 'month': 0.0, 'total': 0.0};
    }

    final row = rows.first;
    return {
      'today': (row['today'] as num?)?.toDouble() ?? 0.0,
      'week': (row['week'] as num?)?.toDouble() ?? 0.0,
      'month': (row['month'] as num?)?.toDouble() ?? 0.0,
      'total': (row['total'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<Map<String, dynamic>> getInventoryStats() async {
    final db = await _db.database;
    final storeId = _storeService.selectedStoreId;
    final nowStr = DateTime.now().toIso8601String();

    final rows = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_medicines,
        SUM(stock_quantity) as total_stock_qty,
        SUM(stock_quantity * purchase_price) as total_value,
        SUM(CASE WHEN stock_quantity <= reorder_level AND stock_quantity > 0 THEN 1 ELSE 0 END) as low_stock,
        SUM(CASE WHEN stock_quantity = 0 THEN 1 ELSE 0 END) as out_of_stock,
        SUM(CASE WHEN expiry_date IS NOT NULL AND expiry_date < ? THEN 1 ELSE 0 END) as expired
      FROM medicines
      WHERE store_id = ?
    ''', [nowStr, storeId]);

    if (rows.isEmpty || rows.first['total_medicines'] == 0) {
      return {
        'totalMedicines': 0,
        'totalStockQty': 0,
        'totalValue': 0.0,
        'lowStock': 0,
        'outOfStock': 0,
        'expired': 0,
      };
    }

    final row = rows.first;
    return {
      'totalMedicines': row['total_medicines'] as int? ?? 0,
      'totalStockQty': (row['total_stock_qty'] as num?)?.toInt() ?? 0,
      'totalValue': (row['total_value'] as num?)?.toDouble() ?? 0.0,
      'lowStock': (row['low_stock'] as num?)?.toInt() ?? 0,
      'outOfStock': (row['out_of_stock'] as num?)?.toInt() ?? 0,
      'expired': (row['expired'] as num?)?.toInt() ?? 0,
    };
  }

  Future<Map<String, int>> getDailySalesCount({int days = 7}) async {
    final result = <String, int>{};
    final now = DateTime.now();
    final storeId = _storeService.selectedStoreId;
    final db = await _db.database;

    final daysList = <String>[];
    for (int i = days - 1; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      result[key] = 0;
      daysList.add(key);
    }

    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1)).toIso8601String();
    
    final rows = await db.rawQuery('''
      SELECT substr(sale_date, 1, 10) as date_key, COUNT(*) as count
      FROM sales
      WHERE store_id = ? AND sale_date >= ?
      GROUP BY date_key
    ''', [storeId, startDate]);

    for (final row in rows) {
      final dateKey = row['date_key'] as String;
      final count = row['count'] as int;
      if (result.containsKey(dateKey)) {
        result[dateKey] = count;
      }
    }
    return result;
  }

  Future<Map<String, double>> getWeeklyRevenue() async {
    final result = <String, double>{};
    final now = DateTime.now();
    final storeId = _storeService.selectedStoreId;
    final db = await _db.database;

    final dayKeys = <String, String>{};
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final name = weekdayNames[day.weekday - 1];
      result[name] = 0.0;
      dayKeys[dateKey] = name;
    }

    final startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)).toIso8601String();

    final rows = await db.rawQuery('''
      SELECT substr(sale_date, 1, 10) as date_key, SUM(net_amount) as total
      FROM sales
      WHERE store_id = ? AND sale_date >= ?
      GROUP BY date_key
    ''', [storeId, startDate]);

    for (final row in rows) {
      final dateKey = row['date_key'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      final name = dayKeys[dateKey];
      if (name != null) {
        result[name] = total;
      }
    }
    return result;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
