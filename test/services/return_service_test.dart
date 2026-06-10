import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import 'package:medios/features/returns/services/return_service.dart';
import 'package:medios/models/return_model.dart';

void main() {
  late Database db;
  late ReturnService service;

  late int saleId;

  setUp(() async {
    db = await createAndSetTestDb();
    service = ReturnService();

    // Insert test medicine
    await db.insert('medicines', {
      'id': 1,
      'name': 'Panadol',
      'generic_name': 'Paracetamol',
      'category_id': 1,
      'stock_quantity': 100,
      'purchase_price': 80,
      'selling_price': 100,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Insert test sale
    saleId = await db.insert('sales', {
      'id': 1,
      'bill_number': 'BIL-001',
      'sale_date': DateTime.now().toIso8601String(),
      'total_amount': 200,
      'net_amount': 200,
      'payment_method': 'cash',
      'store_id': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Insert test sale item
    await db.insert('sale_items', {
      'sale_id': saleId,
      'medicine_id': 1,
      'medicine_name': 'Panadol',
      'quantity': 10,
      'unit_price': 100,
      'total_price': 1000,
    });
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  test('processReturn creates return with items', () async {
    final id = await service.processReturn(ReturnModel(
      saleId: saleId,
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
