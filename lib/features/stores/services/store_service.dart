import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/errors/app_error.dart';
import '../../../models/store_model.dart';

class StoreService extends ChangeNotifier {
  final DatabaseHelper _db;

  StoreService({DatabaseHelper? databaseHelper})
      : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>();
  List<StoreModel> _stores = [];
  int _selectedStoreId = 1;
  bool _isLoading = false;

  List<StoreModel> get stores => _stores;
  int get selectedStoreId => _selectedStoreId;
  bool get isLoading => _isLoading;

  StoreModel? get selectedStore {
    try {
      return _stores.firstWhere((s) => s.id == _selectedStoreId);
    } catch (_) {
      return _stores.isNotEmpty ? _stores.first : null;
    }
  }

  @override
  void dispose() {
    // Clear data to prevent memory leaks
    _stores = [];
    super.dispose();
  }

  Future<void> selectStore(int id) async {
    if (!_stores.any((s) => s.id == id)) {
      throw AppError(
        message: 'Store with ID $id does not exist',
        type: ErrorType.validation,
      );
    }
    _selectedStoreId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_store_id', id);
    notifyListeners();
  }

  Future<void> loadStores() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final maps = await _db.query('stores', orderBy: 'name ASC');
      _stores = maps.map((m) => StoreModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Failed to load stores: $e');
      _stores = [];
    }
    
    final prefs = await SharedPreferences.getInstance();
    final savedStoreId = prefs.getInt('selected_store_id');
    
    if (_stores.isEmpty) {
      final id = await _db.insert('stores', {
        'name': 'Main Store', 'address': '', 'phone': '', 'is_active': 1,
      });
      _stores = [StoreModel(id: id, name: 'Main Store')];
      _selectedStoreId = id;
      await prefs.setInt('selected_store_id', id);
    } else {
      if (savedStoreId != null && _stores.any((s) => s.id == savedStoreId)) {
        _selectedStoreId = savedStoreId;
      } else {
        _selectedStoreId = _stores.first.id!;
        await prefs.setInt('selected_store_id', _selectedStoreId);
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addStore(StoreModel store) async {
    final id = await _db.insert('stores', store.toMap());
    await loadStores();
    return id;
  }

  Future<void> updateStore(StoreModel store) async {
    if (store.id == null) {
      throw const AppError(
        message: 'Cannot update store with null ID',
        type: ErrorType.validation,
      );
    }
    final db = await _db.database;
    final rowsAffected = await db.update(
      'stores',
      store.toMap(),
      where: 'id = ?',
      whereArgs: [store.id],
    );
    if (rowsAffected == 0) {
      throw const AppError(
        message: 'Store not found',
        type: ErrorType.database,
      );
    }
    await loadStores();
  }

  Future<void> deleteStore(int id) async {
    if (id == _selectedStoreId) {
      throw const AppError(
        message: 'Cannot delete the currently active store',
        type: ErrorType.validation,
      );
    }
    if (_stores.length <= 1) {
      throw const AppError(
        message: 'Cannot delete the only remaining store',
        type: ErrorType.validation,
      );
    }

    final db = await _db.database;
    final medicinesCount = await _db.getCount('medicines', where: 'store_id = ?', whereArgs: [id]);
    final salesCount = await _db.getCount('sales', where: 'store_id = ?', whereArgs: [id]);
    final poCount = await _db.getCount('purchase_orders', where: 'store_id = ?', whereArgs: [id]);
    final ordersCount = await _db.getCount('customer_orders', where: 'store_id = ?', whereArgs: [id]);
    final prescriptionsCount = await _db.getCount('prescriptions', where: 'store_id = ?', whereArgs: [id]);

    if (medicinesCount > 0 || salesCount > 0 || poCount > 0 || ordersCount > 0 || prescriptionsCount > 0) {
      throw const AppError(
        message: 'Cannot delete store: it has active records (medicines, sales, orders, or prescriptions)',
        type: ErrorType.validation,
      );
    }

    final rowsAffected = await db.delete('stores', where: 'id = ?', whereArgs: [id]);
    if (rowsAffected == 0) {
      throw const AppError(
        message: 'Store not found',
        type: ErrorType.database,
      );
    }
    await loadStores();
  }
}
