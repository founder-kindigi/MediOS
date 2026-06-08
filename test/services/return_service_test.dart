import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import '../../lib/features/returns/services/return_service.dart';
import '../../lib/models/return_model.dart';

void main() {
  late Database db;
  late ReturnService service;

  setUp(() async {
    db = await createAndSetTestDb();
    service = ReturnService();
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  test('processReturn creates return with items', () async {
    final id = await service.processReturn(ReturnModel(
      billNumber: 'BIL-001', returnNumber: 'RET-001',
      totalRefund: 200,
    ), [ReturnItemModel(
      medicineId: 1, medicineName: 'Panadol',
      quantity: 2, unitPrice: 100, totalRefund: 200,
    )]);
    expect(id, greaterThan(0));
    await service.loadReturns();
    expect(service.returns.length, 1);
    expect(service.returns.first.returnNumber, 'RET-001');
  });

  test('loadReturns returns empty when none', () async {
    await service.loadReturns();
    expect(service.returns, isEmpty);
  });

  test('getTotalReturns returns 0 when none', () async {
    final total = await service.getTotalReturns();
    expect(total, 0);
  });
}
