import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';

class DashboardService extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  double _totalRevenue = 0;
  int _totalSales = 0;
  int _totalMedicines = 0;
  int _lowStockCount = 0;
  int _expiredCount = 0;
  int _totalSuppliers = 0;
  int _totalCustomers = 0;
  Map<String, double> _weeklyRevenue = {};
  bool _isLoading = false;

  double get totalRevenue => _totalRevenue;
  int get totalSales => _totalSales;
  int get totalMedicines => _totalMedicines;
  int get lowStockCount => _lowStockCount;
  int get expiredCount => _expiredCount;
  int get totalSuppliers => _totalSuppliers;
  int get totalCustomers => _totalCustomers;
  Map<String, double> get weeklyRevenue => _weeklyRevenue;
  bool get isLoading => _isLoading;

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    _totalRevenue = await _db.getSum('sales', 'net_amount');
    _totalSales = await _db.getCount('sales');
    _totalMedicines = await _db.getCount('medicines');
    _totalSuppliers = await _db.getCount('suppliers');
    _totalCustomers = await _db.getCount('customers');

    final now = DateTime.now();
    _lowStockCount = await _db.getCount('medicines',
        where: 'stock_quantity <= reorder_level');
    _expiredCount = await _db.getCount('medicines',
        where: 'expiry_date IS NOT NULL AND expiry_date < ?',
        whereArgs: [now.toIso8601String()]);

    _weeklyRevenue = await _calcWeeklyRevenue();

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, double>> _calcWeeklyRevenue() async {
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
}
