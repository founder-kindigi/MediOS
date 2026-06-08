import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import '../../lib/features/prescriptions/services/prescription_service.dart';
import '../../lib/models/prescription_model.dart';

void main() {
  late Database db;
  late PrescriptionService service;

  setUp(() async {
    db = await createAndSetTestDb();
    service = PrescriptionService();
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  test('loadPrescriptions returns empty initially', () async {
    await service.loadPrescriptions();
    expect(service.prescriptions, isEmpty);
  });

  test('createPrescription inserts with items', () async {
    await service.createPrescription(PrescriptionModel(
      patientName: 'Ali', doctorName: 'Dr. Khan',
      prescriptionDate: DateTime.now(),
      items: [PrescriptionItem(
        medicineId: 1, medicineName: 'Panadol',
        dosage: '500mg', frequency: '3x/day', quantity: 10,
      )],
    ));
    await service.loadPrescriptions();
    expect(service.prescriptions.length, 1);
    expect(service.prescriptions.first.patientName, 'Ali');
    expect(service.prescriptions.first.items?.length, 1);
  });

  test('updateStatus changes status', () async {
    final id = await service.createPrescription(PrescriptionModel(
      patientName: 'Sara', prescriptionDate: DateTime.now(),
    ));
    await service.updateStatus(id, 'completed');
    final updated = await service.getById(id);
    expect(updated?.status, 'completed');
  });

  test('loadPrescriptions filters by status', () async {
    await service.createPrescription(PrescriptionModel(patientName: 'A', prescriptionDate: DateTime.now()));
    await service.createPrescription(PrescriptionModel(patientName: 'B', prescriptionDate: DateTime.now()));
    await service.loadPrescriptions(status: 'active');
    expect(service.prescriptions.length, 2);
    await service.loadPrescriptions(status: 'completed');
    expect(service.prescriptions, isEmpty);
  });
}
