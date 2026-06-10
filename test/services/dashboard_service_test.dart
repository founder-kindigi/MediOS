import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import 'package:medios/features/dashboard/services/dashboard_service.dart';

void main() {
  late Database db;
  late DashboardService service;

  setUp(() async {
    db = await createAndSetTestDb();
    service = DashboardService();
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  test('loadDashboard populates all getters', () async {
    await service.loadDashboard();
    expect(service.totalRevenue, 0);
    expect(service.totalSales, 0);
    expect(service.totalMedicines, 0);
    expect(service.lowStockCount, 0);
    expect(service.expiredCount, 0);
  });

  test('getMonthlyRevenue returns map', () async {
    final rev = await service.getMonthlyRevenue();
    expect(rev, isA<Map<String, double>>());
  });

  test('weeklyRevenue getter returns map', () async {
    await service.loadDashboard();
    expect(service.weeklyRevenue, isA<Map<String, double>>());
  });
}
