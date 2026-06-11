import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import 'package:medios/domain/entities/supplier.dart';
import 'package:medios/domain/repositories/supplier_repository.dart';
import 'package:medios/core/errors/app_error.dart';
import 'package:medios/models/user_model.dart';
import 'package:medios/features/auth/services/permission_service.dart';

void main() {
  late Database db;
  late SupplierRepository repository;

  setUp(() async {
    db = await createAndSetTestDb();
    
    // Set up active user with permissions
    final permissionService = GetIt.I<PermissionService>();
    await permissionService.setCurrentUser(UserModel(
      id: 1,
      username: 'test_admin',
      fullName: 'Test Admin',
      role: 'admin',
      passwordHash: '',
    ));

    repository = GetIt.I<SupplierRepository>();
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  group('Supplier CRUD Tests', () {
    test('getAll returns empty list initially', () async {
      final suppliers = await repository.getAll();
      expect(suppliers, isEmpty);
    });

    test('add supplier successfully registers record and updates ID', () async {
      final supplier = Supplier(
        name: 'ABC Pharmaceuticals',
        contactPerson: 'Alice',
        phone: '03001112222',
        email: 'abc@example.com',
        address: 'Industrial Area',
      );

      final result = await repository.add(supplier);
      expect(result.id, isNotNull);
      expect(result.name, 'ABC Pharmaceuticals');

      final list = await repository.getAll();
      expect(list.length, 1);
      expect(list.first.id, result.id);
    });

    test('add supplier fails with validation error if name is empty', () async {
      final supplier = Supplier(
        name: '',
        phone: '1234',
      );

      expect(
        () => repository.add(supplier),
        throwsA(isA<AppError>().having((e) => e.type, 'type', ErrorType.validation)),
      );
    });

    test('update supplier modifies data successfully', () async {
      final supplier = Supplier(
        name: 'XYZ Pharma',
        phone: '03005555555',
      );
      final added = await repository.add(supplier);

      final updated = added.copyWith(name: 'XYZ Distribution', contactPerson: 'Bob');
      final result = await repository.update(updated);

      expect(result.name, 'XYZ Distribution');
      expect(result.contactPerson, 'Bob');

      final fetched = await repository.getById(added.id!);
      expect(fetched?.name, 'XYZ Distribution');
    });

    test('delete supplier fails if they have associated purchase orders', () async {
      final supplier = Supplier(
        name: 'PO Supplier',
        phone: '9999',
      );
      final added = await repository.add(supplier);

      // Insert dummy purchase order associated with this supplier
      await db.insert('purchase_orders', {
        'supplier_id': added.id,
        'supplier_name': added.name,
        'order_number': 'PO-9009',
        'order_date': DateTime.now().toIso8601String(),
        'total_amount': 1500.0,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      expect(
        () => repository.delete(added.id!),
        throwsA(isA<AppError>().having((e) => e.type, 'type', ErrorType.validation)),
      );
    });

    test('delete supplier deletes successfully if no purchase orders exist', () async {
      final supplier = Supplier(
        name: 'Isolated Supplier',
        phone: '1111',
      );
      final added = await repository.add(supplier);

      await repository.delete(added.id!);
      final list = await repository.getAll();
      expect(list, isEmpty);
    });
  });
}
