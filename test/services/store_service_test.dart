import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import 'package:medios/features/stores/services/store_service.dart';
import 'package:medios/models/store_model.dart';

void main() {
  late Database db;
  late StoreService service;

  setUp(() async {
    db = await createAndSetTestDb();
    service = StoreService();
    await service.loadStores();
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  test('loadStores returns default Main Store', () {
    expect(service.stores.length, 1);
    expect(service.stores.first.name, 'Test Store');
  });

  test('addStore creates a new store', () async {
    await service.addStore(StoreModel(name: 'Branch 1', address: 'Lahore'));
    expect(service.stores.length, 2);
    expect(service.stores.first.name, 'Branch 1');
  });

  test('selectStore changes selected store', () {
    final store = service.stores.first;
    service.selectStore(store.id!);
    expect(service.selectedStoreId, store.id);
  });

  test('selectedStore returns correct store', () {
    final s = service.selectedStore;
    expect(s?.name, 'Test Store');
  });
}
