import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import 'package:medios/features/reports/services/reports_service.dart';

void main() {
  late Database db;
  late ReportsService service;

  setUp(() async {
    db = await createAndSetTestDb();
    service = ReportsService();
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  test('getSalesSummary returns structure', () async {
    final summary = await service.getSalesSummary();
    expect(summary.containsKey('today'), true);
    expect(summary['total'], 0.0);
  });

  test('getMonthlyRevenue returns map', () async {
    final rev = await service.getMonthlyRevenue();
    expect(rev, isA<Map<String, double>>());
  });

  test('getTopMedicines returns list', () async {
    final top = await service.getTopMedicines();
    expect(top, isA<List>());
  });

  test('getSalesByPaymentMethod returns map', () async {
    final breakdown = await service.getSalesByPaymentMethod();
    expect(breakdown, isA<Map<String, double>>());
  });

  test('getInventoryStats returns structure', () async {
    final stats = await service.getInventoryStats();
    expect(stats.containsKey('totalValue'), true);
    expect(stats.containsKey('lowStock'), true);
  });

  test('getDailySalesCount returns map', () async {
    final daily = await service.getDailySalesCount();
    expect(daily, isA<Map<String, int>>());
  });

  test('getWeeklyRevenue returns map', () async {
    final weekly = await service.getWeeklyRevenue();
    expect(weekly, isA<Map<String, double>>());
  });
}
