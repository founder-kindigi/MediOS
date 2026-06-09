import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import '../../lib/features/settings/services/settings_service.dart';

void main() {
  late Database db;
  late SettingsService service;

  setUp(() async {
    db = await createAndSetTestDb();
    SharedPreferences.setMockInitialValues({});
    service = SettingsService();
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  test('getAppInfo returns correct structure', () async {
    final info = await service.getAppInfo();
    expect(info['appName'], 'MediOS');
    expect(info['dbVersion'], 8);
    expect(info.containsKey('medicines'), true);
  });

  test('defaultTaxRate defaults to 0', () async {
    final rate = await service.getDefaultTaxRate();
    expect(rate, 0);
  });

  test('setDefaultTaxRate persists value', () async {
    await service.setDefaultTaxRate(15);
    final rate = await service.getDefaultTaxRate();
    expect(rate, 15);
  });

  test('coupon CRUD works', () async {
    await service.addCoupon({'code': 'SAVE10', 'type': 'percentage', 'value': 10, 'min_purchase': 0, 'is_active': true});
    var coupons = await service.getCoupons();
    expect(coupons.length, 1);
    expect(coupons.first['code'], 'SAVE10');

    final valid = await service.validateCoupon('SAVE10', 100);
    expect(valid, isNotNull);
    expect(valid!['value'], 10);

    final invalid = await service.validateCoupon('FAKE', 100);
    expect(invalid, isNull);

    await service.removeCoupon('SAVE10');
    coupons = await service.getCoupons();
    expect(coupons, isEmpty);
  });

  test('lastSyncTime management', () async {
    final t = await service.getLastSyncTime();
    expect(t, isNull);
    await service.setLastSyncTime();
    final t2 = await service.getLastSyncTime();
    expect(t2, isNotNull);
  });
}
