import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../../core/database/database_helper.dart';
import '../../stores/services/store_service.dart';

class DashboardService extends ChangeNotifier {
  final DatabaseHelper _db;
  final StoreService _storeService;

  DashboardService({DatabaseHelper? databaseHelper, StoreService? storeService})
      : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>(),
        _storeService = storeService ?? GetIt.instance<StoreService>();

  double _totalRevenue = 0;
  int _totalSales = 0;
  int _totalMedicines = 0;
  int _lowStockCount = 0;
  int _expiredCount = 0;
  int _totalSuppliers = 0;
  int _totalCustomers = 0;
  double _todayRevenue = 0;
  int _todaySalesCount = 0;
  Map<String, double> _weeklyRevenue = {};
  List<Map<String, dynamic>> _recentSales = [];
  bool _isLoading = false;

  double get totalRevenue => _totalRevenue;
  int get totalSales => _totalSales;
  int get totalMedicines => _totalMedicines;
  int get lowStockCount => _lowStockCount;
  int get expiredCount => _expiredCount;
  int get totalSuppliers => _totalSuppliers;
  int get totalCustomers => _totalCustomers;
  double get todayRevenue => _todayRevenue;
  int get todaySalesCount => _todaySalesCount;
  Map<String, double> get weeklyRevenue => _weeklyRevenue;
  List<Map<String, dynamic>> get recentSales => _recentSales;
  bool get isLoading => _isLoading;

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final storeId = _storeService.selectedStoreId;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
      final db = await _db.database;

      final salesRows = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_sales,
          SUM(net_amount) as total_revenue,
          SUM(CASE WHEN sale_date >= ? THEN net_amount ELSE 0 END) as today_revenue,
          SUM(CASE WHEN sale_date >= ? THEN 1 ELSE 0 END) as today_sales_count
        FROM sales
        WHERE store_id = ?
      ''', [todayStart, todayStart, storeId]);

      if (salesRows.isNotEmpty && salesRows.first['total_sales'] != 0) {
        final r = salesRows.first;
        _totalSales = r['total_sales'] as int? ?? 0;
        _totalRevenue = (r['total_revenue'] as num?)?.toDouble() ?? 0.0;
        _todayRevenue = (r['today_revenue'] as num?)?.toDouble() ?? 0.0;
        _todaySalesCount = (r['today_sales_count'] as num?)?.toInt() ?? 0;
      } else {
        _totalSales = 0;
        _totalRevenue = 0.0;
        _todayRevenue = 0.0;
        _todaySalesCount = 0;
      }

      final medicinesRows = await db.rawQuery('''
        SELECT
          COUNT(*) as total_medicines,
          SUM(CASE WHEN stock_quantity <= reorder_level THEN 1 ELSE 0 END) as low_stock,
          SUM(CASE WHEN expiry_date IS NOT NULL AND expiry_date < ? THEN 1 ELSE 0 END) as expired
        FROM medicines
        WHERE store_id = ?
      ''', [now.toIso8601String(), storeId]);

      if (medicinesRows.isNotEmpty && medicinesRows.first['total_medicines'] != 0) {
        final r = medicinesRows.first;
        _totalMedicines = r['total_medicines'] as int? ?? 0;
        _lowStockCount = (r['low_stock'] as num?)?.toInt() ?? 0;
        _expiredCount = (r['expired'] as num?)?.toInt() ?? 0;
      } else {
        _totalMedicines = 0;
        _lowStockCount = 0;
        _expiredCount = 0;
      }

      _totalSuppliers = await _db.getCount('suppliers');
      _totalCustomers = await _db.getCount('customers');

      _weeklyRevenue = await _calcWeeklyRevenue();
      _recentSales = await _loadRecentSales();
    } catch (e, stackTrace) {
      debugPrint('Error loading dashboard data: $e\n$stackTrace');
      _totalRevenue = 0;
      _totalSales = 0;
      _totalMedicines = 0;
      _lowStockCount = 0;
      _expiredCount = 0;
      _totalSuppliers = 0;
      _totalCustomers = 0;
      _todayRevenue = 0;
      _todaySalesCount = 0;
      _weeklyRevenue = {};
      _recentSales = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, double>> _calcWeeklyRevenue() async {
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

  Future<List<Map<String, dynamic>>> _loadRecentSales() async {
    final db = await _db.database;
    final storeId = _storeService.selectedStoreId;
    return await db.rawQuery(
      'SELECT bill_number, customer_name, net_amount, sale_date FROM sales WHERE store_id = ? ORDER BY created_at DESC LIMIT 5',
      [storeId],
    );
  }

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

  @override
  void dispose() {
    // Clear dashboard data to prevent memory leaks
    _weeklyRevenue.clear();
    _recentSales.clear();
    
    super.dispose();
  }
}
