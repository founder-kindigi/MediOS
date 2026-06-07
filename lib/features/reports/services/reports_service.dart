import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';

class ReportsService extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<Map<String, double>> getMonthlyRevenue() async {
    final currentYear = DateTime.now().year;
    final result = <String, double>{};

    for (int month = 1; month <= 12; month++) {
      final monthStr = month.toString().padLeft(2, '0');
      final startDate = DateTime(currentYear, month, 1);
      final endDate = month < 12
          ? DateTime(currentYear, month + 1, 1)
          : DateTime(currentYear + 1, 1, 1);

      final revenue = await _db.getSum('sales', 'net_amount',
          where: 'sale_date >= ? AND sale_date < ?',
          whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()]);

      result[monthStr] = revenue;
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getTopMedicines({int limit = 10}) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT si.medicine_name, SUM(si.quantity) as total_qty, SUM(si.total_price) as total_revenue
      FROM sale_items si
      GROUP BY si.medicine_name
      ORDER BY total_qty DESC
      LIMIT ?
    ''', [limit]);
    return result;
  }

  Future<Map<String, double>> getSalesByPaymentMethod() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT payment_method, COALESCE(SUM(net_amount), 0) as total
      FROM sales
      GROUP BY payment_method
    ''');
    final map = <String, double>{};
    for (final row in result) {
      map[row['payment_method'] as String] = (row['total'] as num).toDouble();
    }
    return map;
  }

  Future<Map<String, double>> getSalesSummary() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final today = await _db.getSum('sales', 'net_amount',
        where: 'sale_date >= ?', whereArgs: [todayStart.toIso8601String()]);
    final week = await _db.getSum('sales', 'net_amount',
        where: 'sale_date >= ?', whereArgs: [weekStart.toIso8601String()]);
    final month = await _db.getSum('sales', 'net_amount',
        where: 'sale_date >= ?', whereArgs: [monthStart.toIso8601String()]);
    final total = await _db.getSum('sales', 'net_amount');

    return {'today': today, 'week': week, 'month': month, 'total': total};
  }

  Future<Map<String, dynamic>> getInventoryStats() async {
    final db = await _db.database;
    final totalMedicines = await _db.getCount('medicines');

    final totalStock = await db.rawQuery(
        'SELECT COALESCE(SUM(stock_quantity), 0) as total FROM medicines');
    final totalStockQty = (totalStock.first['total'] as num?)?.toInt() ?? 0;

    final stockValue = await db.rawQuery(
        'SELECT COALESCE(SUM(stock_quantity * purchase_price), 0) as value FROM medicines');
    final totalValue = (stockValue.first['value'] as num?)?.toDouble() ?? 0;

    final lowStock = await _db.getCount('medicines',
        where: 'stock_quantity <= reorder_level AND stock_quantity > 0');
    final outOfStock = await _db.getCount('medicines',
        where: 'stock_quantity = 0');
    final expired = await _db.getCount('medicines',
        where: 'expiry_date IS NOT NULL AND expiry_date < ?',
        whereArgs: [DateTime.now().toIso8601String()]);

    return {
      'totalMedicines': totalMedicines,
      'totalStockQty': totalStockQty,
      'totalValue': totalValue,
      'lowStock': lowStock,
      'outOfStock': outOfStock,
      'expired': expired,
    };
  }

  Future<Map<String, int>> getDailySalesCount({int days = 7}) async {
    final result = <String, int>{};
    final now = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

      final count = await _db.getCount('sales',
          where: 'sale_date >= ? AND sale_date < ?',
          whereArgs: [start.toIso8601String(), end.toIso8601String()]);
      result[key] = count;
    }
    return result;
  }

  Future<Map<String, double>> getWeeklyRevenue() async {
    final result = <String, double>{};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      final key = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1];

      final revenue = await _db.getSum('sales', 'net_amount',
          where: 'sale_date >= ? AND sale_date < ?',
          whereArgs: [start.toIso8601String(), end.toIso8601String()]);
      result[key] = revenue;
    }
    return result;
  }
}
