import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../../core/database/database_helper.dart';
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

  void selectStore(int id) {
    _selectedStoreId = id;
    notifyListeners();
  }

  Future<void> loadStores() async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.query('stores', orderBy: 'name ASC');
    _stores = maps.map((m) => StoreModel.fromMap(m)).toList();
    if (_stores.isEmpty) {
      final id = await _db.insert('stores', {
        'name': 'Main Store', 'address': '', 'phone': '', 'is_active': 1,
      });
      _stores = [StoreModel(id: id, name: 'Main Store')];
      _selectedStoreId = id;
    } else if (!_stores.any((s) => s.id == _selectedStoreId)) {
      _selectedStoreId = _stores.first.id!;
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
    await _db.update('stores', store.toMap(), where: 'id = ?', whereArgs: [store.id]);
    await loadStores();
  }
}
