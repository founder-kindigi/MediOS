import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import 'package:medios/features/settings/services/settings_service.dart';
import 'package:medios/core/security/secure_storage_service.dart';
import 'package:medios/core/constants/app_constants.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  late SettingsService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = await createAndSetTestDb();
    service = SettingsService(secureStorage: FakeSecureStorageService());
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  test('getAppInfo returns correct structure', () async {
    final info = await service.getAppInfo();
    expect(info['appName'], 'MediOS');
    expect(info['dbVersion'], AppConstants.dbVersion);
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

class FakeSecureStorageService implements SecureStorageService {
  final Map<String, String> _storage = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<void> store(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<String?> retrieve(String key) async {
    return _storage[key];
  }

  @override
  Future<void> storeMap(String key, Map<String, dynamic> data) async {
    _storage[key] = jsonEncode(data);
  }

  @override
  Future<Map<String, dynamic>?> retrieveMap(String key) async {
    final val = _storage[key];
    if (val == null) return null;
    return jsonDecode(val) as Map<String, dynamic>;
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<bool> contains(String key) async {
    return _storage.containsKey(key);
  }

  @override
  Future<void> clearAll() async {
    _storage.clear();
  }

  @override
  Future<void> migrateFromUnencrypted(Map<String, String> unencryptedData) async {
    _storage.addAll(unencryptedData);
  }

  @override
  Future<Map<String, dynamic>> getKeyInfo() async {
    return {'algorithm': 'AES-256-CBC'};
  }
}
