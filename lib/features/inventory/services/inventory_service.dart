import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/medicine_model.dart';
import '../../../models/category_model.dart';
import '../../../models/inventory_transaction_model.dart';
import '../../stores/services/store_service.dart';
import '../../../core/errors/app_error.dart';

class InventoryService extends ChangeNotifier {
  final DatabaseHelper _db;
  final StoreService _storeService;

  InventoryService({DatabaseHelper? databaseHelper, StoreService? storeService})
      : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>(),
        _storeService = storeService ?? GetIt.instance<StoreService>();
  List<MedicineModel> _medicines = [];
  List<CategoryModel> _categories = [];
  List<MedicineModel> _lowStockMedicines = [];
  List<MedicineModel> _nearExpiryMedicines = [];
  bool _isLoading = false;

  List<MedicineModel> get medicines => _medicines;
  List<CategoryModel> get categories => _categories;
  List<MedicineModel> get lowStockMedicines => _lowStockMedicines;
  List<MedicineModel> get nearExpiryMedicines => _nearExpiryMedicines;
  bool get isLoading => _isLoading;

  Future<void> loadMedicines() async {
    _isLoading = true;
    notifyListeners();

    final db = await _db.database;
    final storeId = _storeService.selectedStoreId;
    final maps = await db.rawQuery(
      'SELECT m.*, c.name as category_name FROM medicines m LEFT JOIN categories c ON m.category_id = c.id WHERE m.store_id = ? ORDER BY m.name ASC',
      [storeId],
    );
    _medicines = maps.map((m) => MedicineModel.fromMap(m)).toList();
    _lowStockMedicines = _medicines.where((m) => m.isLowStock).toList();
    _nearExpiryMedicines = _medicines.where((m) => m.isNearExpiry).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    final maps = await _db.query('categories', orderBy: 'name ASC');
    _categories = maps.map((m) => CategoryModel.fromMap(m)).toList();
    notifyListeners();
  }

  Future<int> getStockQuantity(int medicineId) async {
    final db = await _db.database;
    final maps = await db.query('medicines', columns: ['stock_quantity'], where: 'id = ?', whereArgs: [medicineId]);
    if (maps.isNotEmpty) {
      return maps.first['stock_quantity'] as int? ?? 0;
    }
    return 0;
  }

  Future<int> addMedicine(MedicineModel medicine) async {
    final storeId = _storeService.selectedStoreId;
    final modelMap = medicine.toMap()..['store_id'] = storeId;
    final id = await _db.insert('medicines', modelMap);
    await _logTransaction(medicine.id ?? id, 'in', medicine.stockQuantity, 'initial', null);
    await loadMedicines();
    return id;
  }

  Future<int> updateMedicine(MedicineModel medicine) async {
    if (medicine.id != null) {
      final db = await _db.database;
      final maps = await db.query('medicines', columns: ['stock_quantity'], where: 'id = ?', whereArgs: [medicine.id]);
      if (maps.isNotEmpty) {
        final oldQty = maps.first['stock_quantity'] as int? ?? 0;
        final diff = medicine.stockQuantity - oldQty;
        if (diff != 0) {
          final type = diff > 0 ? 'in' : 'out';
          await _logTransaction(medicine.id!, type, diff.abs(), 'adjustment', null, notes: 'Stock quantity changed via edit form');
        }
      }
    }

    final storeId = _storeService.selectedStoreId;
    final modelMap = medicine.toMap()..['store_id'] = storeId;
    final result = await _db.update('medicines', modelMap,
        where: 'id = ?', whereArgs: [medicine.id]);
    await loadMedicines();
    return result;
  }

  Future<void> deleteMedicine(int id) async {
    try {
      final db = await _db.database;
      
      // Check related sales count
      final sales = await db.rawQuery('SELECT COUNT(*) as count FROM sale_items WHERE medicine_id = ?', [id]);
      final salesCount = (sales.first['count'] as num?)?.toInt() ?? 0;

      // Check related purchase order items count
      final pos = await db.rawQuery('SELECT COUNT(*) as count FROM purchase_order_items WHERE medicine_id = ?', [id]);
      final posCount = (pos.first['count'] as num?)?.toInt() ?? 0;

      if (salesCount > 0 || posCount > 0) {
        throw AppError(
          message: 'Cannot delete medicine because it is referenced in sales or purchase orders.',
          type: ErrorType.database,
        );
      }

      await db.transaction((txn) async {
        await txn.delete('inventory_transactions', where: 'medicine_id = ?', whereArgs: [id]);
        await txn.delete('medicines', where: 'id = ?', whereArgs: [id]);
      });
      await loadMedicines();
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to delete medicine: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  Future<void> updateStock(int medicineId, int quantity, String type,
      {int? saleId, int? poId, String? notes}) async {
    final db = await _db.database;
    final operator = type == 'in' ? '+' : '-';
    final storeId = _storeService.selectedStoreId;

    await db.transaction((txn) async {
      final changes = await txn.rawUpdate(
        'UPDATE medicines SET stock_quantity = stock_quantity $operator ?, updated_at = ? WHERE id = ?${operator == '-' ? ' AND stock_quantity >= ?' : ''}',
        operator == '-' ? [quantity, DateTime.now().toIso8601String(), medicineId, quantity] : [quantity, DateTime.now().toIso8601String(), medicineId],
      );
      if (operator == '-' && changes == 0) {
        throw AppError(
          message: 'Insufficient stock to complete this operation.',
          type: ErrorType.validation,
        );
      }

      final maps = await txn.query('medicines', columns: ['name'], where: 'id = ?', whereArgs: [medicineId]);
      final medicineName = maps.isNotEmpty ? (maps.first['name'] as String? ?? 'Unknown Medicine') : 'Deleted Medicine';

      String? refType;
      int? refId;
      if (saleId != null) {
        refType = 'sale';
        refId = saleId;
      } else if (poId != null) {
        refType = 'purchase_order';
        refId = poId;
      }

      await txn.insert('inventory_transactions', {
        'medicine_id': medicineId,
        'medicine_name': medicineName,
        'type': type,
        'quantity': quantity,
        'reference_type': refType,
        'reference_id': refId,
        'notes': notes,
        'store_id': storeId,
        'created_at': DateTime.now().toIso8601String(),
      });
    });

    await loadMedicines();
  }

  Future<void> _logTransaction(int medicineId, String type, int quantity,
      String? referenceType, int? referenceId, {String? notes}) async {
    final db = await _db.database;
    final maps = await db.query('medicines', columns: ['name'], where: 'id = ?', whereArgs: [medicineId]);
    final medicineName = maps.isNotEmpty ? (maps.first['name'] as String? ?? 'Unknown Medicine') : 'Deleted Medicine';

    final storeId = _storeService.selectedStoreId;

    await _db.insert('inventory_transactions', {
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'type': type,
      'quantity': quantity,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'notes': notes,
      'store_id': storeId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<InventoryTransactionModel>> getTransactionHistory(
      {int? medicineId, String? type}) async {
    final storeId = _storeService.selectedStoreId;
    final conditions = <String>['store_id = ?'];
    final whereArgs = <dynamic>[storeId];
    if (medicineId != null) {
      conditions.add('medicine_id = ?');
      whereArgs.add(medicineId);
    }
    if (type != null && type != 'all') {
      conditions.add('type = ?');
      whereArgs.add(type);
    }
    final where = conditions.join(' AND ');
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
        m.manufacturer.toLowerCase().contains(q) ||
        (m.barcode?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  int get totalStock => _medicines.fold(0, (sum, m) => sum + m.stockQuantity);
  int get expiredCount => _medicines.where((m) => m.isExpired).length;
  int get lowStockCount => lowStockMedicines.length;

  @override
  void dispose() {
    // Clear large lists to free memory
    _medicines = [];
    _categories = [];
    _lowStockMedicines = [];
    _nearExpiryMedicines = [];
    
    super.dispose();
  }
}
