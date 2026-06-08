import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import '../../lib/features/sales/services/sales_service.dart';
import '../../lib/models/sale_model.dart';

void main() {
  late Database db;
  late SalesService sales;

  setUp(() async {
    db = await createAndSetTestDb();
    sales = SalesService();
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  test('createSale inserts sale and items', () async {
    final sale = SaleModel(
      billNumber: 'BIL-001', totalAmount: 200,
      discount: 0, netAmount: 200, paymentMethod: 'cash',
    );
    final items = [SaleItemModel(
      medicineId: 1, medicineName: 'Panadol',
      quantity: 2, unitPrice: 100, totalPrice: 200,
    )];
    final id = await sales.createSale(sale, items);
    expect(id, greaterThan(0));
    await sales.loadSales();
    expect(sales.sales.length, 1);
    expect(sales.sales.first.billNumber, 'BIL-001');
  });

  test('loadSales returns empty when no sales', () async {
    await sales.loadSales();
    expect(sales.sales, isEmpty);
  });

  test('createSale stores discount and tax', () async {
    await sales.createSale(SaleModel(
      billNumber: 'BIL-002', totalAmount: 200,
      discount: 10, tax: 5, netAmount: 195, paymentMethod: 'card',
    ), []);
    await sales.loadSales();
    expect(sales.sales.first.discount, 10);
    expect(sales.sales.first.tax, 5);
    expect(sales.sales.first.paymentMethod, 'card');
  });

  test('getSaleWithItems returns sale with items', () async {
    final saleId = await sales.createSale(SaleModel(
      billNumber: 'BIL-003', totalAmount: 300, netAmount: 300,
    ), [SaleItemModel(medicineId: 1, medicineName: 'Test', quantity: 1, unitPrice: 300, totalPrice: 300)]);
    final loaded = await sales.getSaleWithItems(saleId);
    expect(loaded, isNotNull);
    expect(loaded!.billNumber, 'BIL-003');
  });

  test('getTodaySales returns 0 when no sales today', () async {
    final today = await sales.getTodaySales();
    expect(today, 0);
  });
}
