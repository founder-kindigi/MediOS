import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import '../../lib/features/customers/services/customer_service.dart';
import '../../lib/models/customer_model.dart';

void main() {
  late Database db;
  late CustomerService service;

  setUp(() async {
    db = await createAndSetTestDb();
    service = CustomerService();
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  test('loadCustomers returns empty', () async {
    await service.loadCustomers();
    expect(service.customers, isEmpty);
  });

  test('addCustomer creates record', () async {
    await service.addCustomer(CustomerModel(name: 'Ali Raza', phone: '03001234567'));
    await service.loadCustomers();
    expect(service.customers.length, 1);
  });

  test('searchCustomers filters', () async {
    await service.addCustomer(CustomerModel(name: 'Ali Raza', phone: '111'));
    await service.addCustomer(CustomerModel(name: 'Sara Khan', phone: '222'));
    await service.loadCustomers();
    final results = service.searchCustomers('sara');
    expect(results.length, 1);
  });
}
