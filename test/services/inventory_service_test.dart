import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import '../../lib/features/inventory/services/inventory_service.dart';
import '../../lib/models/medicine_model.dart';

void main() {
  late Database db;
  late InventoryService inventory;

  setUp(() async {
    db = await createAndSetTestDb();
    inventory = InventoryService();
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  test('addMedicine inserts', () async {
    await inventory.addMedicine(MedicineModel(
      name: 'Panadol', genericName: 'Paracetamol',
      manufacturer: 'GSK', unit: 'strip',
      purchasePrice: 50, sellingPrice: 80, stockQuantity: 100,
    ));
    await inventory.loadMedicines();
    expect(inventory.medicines.length, 1);
    expect(inventory.medicines.first.name, 'Panadol');
  });

  test('searchMedicines finds by name', () async {
    await inventory.addMedicine(MedicineModel(
      name: 'Panadol', genericName: 'Paracetamol',
      manufacturer: 'GSK', unit: 'strip',
      purchasePrice: 50, sellingPrice: 80, stockQuantity: 100,
    ));
    await inventory.loadMedicines();
    final results = inventory.searchMedicines('panadol');
    expect(results.length, 1);
  });

  test('searchMedicines finds by barcode', () async {
    await inventory.addMedicine(MedicineModel(
      name: 'Panadol', genericName: 'Paracetamol',
      manufacturer: 'GSK', unit: 'strip',
      purchasePrice: 50, sellingPrice: 80, stockQuantity: 100, barcode: '89012345',
    ));
    await inventory.loadMedicines();
    final results = inventory.searchMedicines('89012345');
    expect(results.length, 1);
  });

  test('updateStock reduces quantity', () async {
    await inventory.addMedicine(MedicineModel(
      name: 'Test', genericName: 'T', manufacturer: 'X', unit: 'strip',
      purchasePrice: 10, sellingPrice: 20, stockQuantity: 50,
    ));
    await inventory.loadMedicines();
    final med = inventory.medicines.first;
    await inventory.updateStock(med.id!, 5, 'out');
    await inventory.loadMedicines();
    expect(inventory.medicines.first.stockQuantity, 45);
  });

  test('updateStock increases quantity', () async {
    await inventory.addMedicine(MedicineModel(
      name: 'Test', genericName: 'T', manufacturer: 'X', unit: 'strip',
      purchasePrice: 10, sellingPrice: 20, stockQuantity: 50,
    ));
    await inventory.loadMedicines();
    final med = inventory.medicines.first;
    await inventory.updateStock(med.id!, 10, 'in');
    await inventory.loadMedicines();
    expect(inventory.medicines.first.stockQuantity, 60);
  });

  test('updateMedicine edits fields', () async {
    await inventory.addMedicine(MedicineModel(
      name: 'Old', genericName: 'G', manufacturer: 'M', unit: 'strip',
      purchasePrice: 10, sellingPrice: 20, stockQuantity: 50,
    ));
    await inventory.loadMedicines();
    final med = inventory.medicines.first;
    await inventory.updateMedicine(med.copyWith(stockQuantity: 99, sellingPrice: 25));
    await inventory.loadMedicines();
    expect(inventory.medicines.first.stockQuantity, 99);
    expect(inventory.medicines.first.sellingPrice, 25);
  });

  test('getTransactionHistory returns records', () async {
    await inventory.addMedicine(MedicineModel(
      name: 'T', genericName: 'T', manufacturer: 'M', unit: 'strip',
      purchasePrice: 10, sellingPrice: 20, stockQuantity: 50,
    ));
    await inventory.loadMedicines();
    final med = inventory.medicines.first;
    await inventory.updateStock(med.id!, 5, 'out');
    final txns = await inventory.getTransactionHistory();
    expect(txns.length, 2);
    expect(txns.any((t) => t.type == 'out'), true);
    expect(txns.any((t) => t.type == 'in'), true);
  });

  test('lowStockMedicines getter works', () async {
    await inventory.addMedicine(MedicineModel(
      name: 'Low', genericName: 'T', manufacturer: 'M', unit: 'strip',
      purchasePrice: 10, sellingPrice: 20, stockQuantity: 3, reorderLevel: 10,
    ));
    await inventory.loadMedicines();
    expect(inventory.lowStockMedicines.length, 1);
  });

  test('deleteMedicine removes record', () async {
    await inventory.addMedicine(MedicineModel(
      name: 'Del', genericName: 'T', manufacturer: 'M', unit: 'strip',
      purchasePrice: 10, sellingPrice: 20, stockQuantity: 5,
    ));
    await inventory.loadMedicines();
    await inventory.deleteMedicine(inventory.medicines.first.id!);
    await inventory.loadMedicines();
    expect(inventory.medicines, isEmpty);
  });
}
