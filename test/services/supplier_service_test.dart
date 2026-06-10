import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import 'package:medios/features/suppliers/services/supplier_service.dart';
import 'package:medios/models/supplier_model.dart';

void main() {
  late Database db;
  late SupplierService service;

  setUp(() async {
    db = await createAndSetTestDb();
    service = SupplierService();
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  test('loadSuppliers returns empty', () async {
    await service.loadSuppliers();
    expect(service.suppliers, isEmpty);
  });

  test('addSupplier creates record', () async {
    await service.addSupplier(SupplierModel(name: 'ABC Pharma', phone: '03001234567'));
    await service.loadSuppliers();
    expect(service.suppliers.length, 1);
    expect(service.suppliers.first.name, 'ABC Pharma');
  });

  test('searchSuppliers filters by name', () async {
    await service.addSupplier(SupplierModel(name: 'ABC Pharma', phone: '111'));
    await service.addSupplier(SupplierModel(name: 'XYZ Drugs', phone: '222'));
    await service.loadSuppliers();
    final results = service.searchSuppliers('xyz');
    expect(results.length, 1);
  });
}
