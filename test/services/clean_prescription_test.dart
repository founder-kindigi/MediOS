import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import 'package:medios/domain/entities/prescription.dart';
import 'package:medios/domain/repositories/prescription_repository.dart';
import 'package:medios/models/user_model.dart';
import 'package:medios/features/auth/services/permission_service.dart';

void main() {
  late Database db;
  late PrescriptionRepository repository;
  late int medicineId;

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

    repository = GetIt.I<PrescriptionRepository>();

    // Seed a medicine
    medicineId = await db.insert('medicines', {
      'name': 'Panadol',
      'generic_name': 'Paracetamol',
      'category_id': 1,
      'unit': 'strip',
      'purchase_price': 10.0,
      'selling_price': 15.0,
      'stock_quantity': 50,
      'reorder_level': 5,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  group('Clean Prescriptions Tests', () {
    test('create prescription and retrieve with items', () async {
      final pItem = PrescriptionItem(
        medicineId: medicineId,
        medicineName: 'Panadol',
        dosage: '1 tablet',
        frequency: 'Three times daily',
        duration: '5 days',
        quantity: 15,
      );

      final prescription = Prescription(
        patientName: 'John Doe',
        patientPhone: '123456789',
        doctorName: 'Dr. Smith',
        prescriptionDate: DateTime.now(),
        notes: 'Take after meals',
        status: 'active',
        storeId: 1,
        createdAt: DateTime.now(),
        items: [pItem],
      );

      final id = await repository.create(prescription);
      expect(id, isPositive);

      final retrieved = await repository.getById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.patientName, 'John Doe');
      expect(retrieved.doctorName, 'Dr. Smith');
      expect(retrieved.items.length, 1);
      expect(retrieved.items.first.medicineName, 'Panadol');
      expect(retrieved.items.first.quantity, 15);
      expect(retrieved.status, 'active');
      expect(retrieved.isExpired, isFalse);
    });

    test('isExpired returns true for prescriptions older than 30 days', () async {
      final oldDate = DateTime.now().subtract(const Duration(days: 31));
      final p = Prescription(
        patientName: 'Old Patient',
        prescriptionDate: oldDate,
        createdAt: oldDate,
      );
      expect(p.isExpired, isTrue);

      final newP = Prescription(
        patientName: 'New Patient',
        prescriptionDate: DateTime.now(),
        createdAt: DateTime.now(),
      );
      expect(newP.isExpired, isFalse);
    });

    test('updateStatus changes status successfully', () async {
      final prescription = Prescription(
        patientName: 'Jane Doe',
        prescriptionDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final id = await repository.create(prescription);
      await repository.updateStatus(id, 'completed');

      final retrieved = await repository.getById(id);
      expect(retrieved!.status, 'completed');
    });

    test('getAll with status filtering works', () async {
      final p1 = Prescription(
        patientName: 'Patient A',
        prescriptionDate: DateTime.now(),
        createdAt: DateTime.now(),
        status: 'active',
      );

      final p2 = Prescription(
        patientName: 'Patient B',
        prescriptionDate: DateTime.now(),
        createdAt: DateTime.now(),
        status: 'cancelled',
      );

      await repository.create(p1);
      await repository.create(p2);

      final allActive = await repository.getAll(1, status: 'active');
      expect(allActive.any((p) => p.patientName == 'Patient A'), isTrue);
      expect(allActive.any((p) => p.patientName == 'Patient B'), isFalse);

      final allCancelled = await repository.getAll(1, status: 'cancelled');
      expect(allCancelled.any((p) => p.patientName == 'Patient A'), isFalse);
      expect(allCancelled.any((p) => p.patientName == 'Patient B'), isTrue);
    });
  });
}
