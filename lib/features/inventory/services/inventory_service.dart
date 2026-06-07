import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/medicine_model.dart';
import '../../../models/category_model.dart';
import '../../../models/inventory_transaction_model.dart';

class InventoryService extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<MedicineModel> _medicines = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  List<MedicineModel> get medicines => _medicines;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;

  List<MedicineModel> get lowStockMedicines =>
      _medicines.where((m) => m.isLowStock).toList();

  List<MedicineModel> get nearExpiryMedicines =>
      _medicines.where((m) => m.isNearExpiry).toList();

  Future<void> loadMedicines() async {
    _isLoading = true;
    notifyListeners();

    final maps = await _db.query(
      'SELECT m.*, c.name as category_name FROM medicines m LEFT JOIN categories c ON m.category_id = c.id',
      orderBy: 'm.name ASC',
    );
    _medicines = maps.map((m) => MedicineModel.fromMap(m)).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    final maps = await _db.query('categories', orderBy: 'name ASC');
    _categories = maps.map((m) => CategoryModel.fromMap(m)).toList();
    notifyListeners();
  }

  Future<int> addMedicine(MedicineModel medicine) async {
    final id = await _db.insert('medicines', medicine.toMap());
    await _logTransaction(medicine.id ?? id, 'in', medicine.stockQuantity, 'initial', null);
    await loadMedicines();
    return id;
  }

  Future<int> updateMedicine(MedicineModel medicine) async {
    final result = await _db.update('medicines', medicine.toMap(),
        where: 'id = ?', whereArgs: [medicine.id]);
    await loadMedicines();
    return result;
  }

  Future<void> deleteMedicine(int id) async {
    await _db.delete('medicines', where: 'id = ?', whereArgs: [id]);
    await loadMedicines();
  }

  Future<void> updateStock(int medicineId, int quantity, String type,
      {int? saleId, int? poId}) async {
    final medicine = _medicines.firstWhere((m) => m.id == medicineId);
    final newQty = type == 'in'
        ? medicine.stockQuantity + quantity
        : medicine.stockQuantity - quantity;

    await _db.update('medicines', {'stock_quantity': newQty, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [medicineId]);

    String? refType;
    int? refId;
    if (saleId != null) {
      refType = 'sale';
      refId = saleId;
    } else if (poId != null) {
      refType = 'purchase_order';
      refId = poId;
    }

    await _logTransaction(medicineId, type, quantity, refType, refId);
    await loadMedicines();
  }

  Future<void> _logTransaction(int medicineId, String type, int quantity,
      String? referenceType, int? referenceId) async {
    final medicine = _medicines.firstWhere(
      (m) => m.id == medicineId,
      orElse: () => MedicineModel(
        name: '', genericName: '', manufacturer: '',
        purchasePrice: 0, sellingPrice: 0, id: medicineId,
      ),
    );

    await _db.insert('inventory_transactions', {
      'medicine_id': medicineId,
      'medicine_name': medicine.name,
      'type': type,
      'quantity': quantity,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<InventoryTransactionModel>> getTransactionHistory(
      {int? medicineId, String? type}) async {
    String? where;
    List<dynamic>? whereArgs;
    final conditions = <String>[];
    if (medicineId != null) {
      conditions.add('medicine_id = ?');
      whereArgs = [medicineId];
    }
    if (type != null && type != 'all') {
      conditions.add('type = ?');
      (whereArgs ??= []).add(type);
    }
    if (conditions.isNotEmpty) {
      where = conditions.join(' AND ');
    }
    final maps = await _db.query('inventory_transactions',
        where: where, whereArgs: whereArgs, orderBy: 'created_at DESC');
    return maps.map((m) => InventoryTransactionModel.fromMap(m)).toList();
  }

  Future<int> addCategory(CategoryModel category) async {
    final id = await _db.insert('categories', category.toMap());
    await loadCategories();
    return id;
  }

  Future<void> deleteCategory(int id) async {
    await _db.delete('categories', where: 'id = ?', whereArgs: [id]);
    await loadCategories();
  }

  List<MedicineModel> searchMedicines(String query) {
    final q = query.toLowerCase();
    return _medicines.where((m) =>
        m.name.toLowerCase().contains(q) ||
        m.genericName.toLowerCase().contains(q) ||
        (m.categoryName?.toLowerCase().contains(q) ?? false) ||
        m.manufacturer.toLowerCase().contains(q)
    ).toList();
  }

  int get totalStock => _medicines.fold(0, (sum, m) => sum + m.stockQuantity);
  int get expiredCount => _medicines.where((m) => m.isExpired).length;
  int get lowStockCount => lowStockMedicines.length;
}
