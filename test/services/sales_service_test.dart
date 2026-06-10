import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:get_it/get_it.dart';
import '../test_helper.dart';
import 'package:medios/features/sales/services/sales_service.dart';
import 'package:medios/models/sale_model.dart';
import 'package:medios/models/user_model.dart';
import 'package:medios/features/auth/services/permission_service.dart';

void main() {
  late Database db;
  late SalesService sales;

  setUp(() async {
    db = await createAndSetTestDb();
    
    // Set up active user with permissions
    final permissionService = GetIt.instance<PermissionService>();
    await permissionService.setCurrentUser(UserModel(
      id: 1,
      username: 'test_admin',
      fullName: 'Test Admin',
      role: 'admin',
      passwordHash: '',
    ));

    sales = SalesService();
    
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
