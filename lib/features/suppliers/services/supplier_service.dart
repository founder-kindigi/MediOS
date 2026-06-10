import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/errors/app_error.dart';
import '../../../models/supplier_model.dart';

class SupplierService extends ChangeNotifier {
  final DatabaseHelper _db;

  SupplierService({DatabaseHelper? databaseHelper})
      : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>();
  List<SupplierModel> _suppliers = [];
  bool _isLoading = false;

  List<SupplierModel> get suppliers => _suppliers;
  bool get isLoading => _isLoading;

  Future<void> loadSuppliers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final maps = await _db.query('suppliers', orderBy: 'name ASC');
      _suppliers = maps.map((m) => SupplierModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Failed to load suppliers: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<int> addSupplier(SupplierModel supplier) async {
    final id = await _db.insert('suppliers', supplier.toMap());
    await loadSuppliers();
    return id;
  }

  Future<int> updateSupplier(SupplierModel supplier) async {
    if (supplier.id == null) {
      throw const AppError(
        message: 'Cannot update supplier with null ID',
        type: ErrorType.validation,
      );
    }
    final result = await _db.update('suppliers', supplier.toMap(),
        where: 'id = ?', whereArgs: [supplier.id]);
    if (result == 0) {
      throw const AppError(
        message: 'Supplier not found',
        type: ErrorType.database,
      );
    }
    await loadSuppliers();
    return result;
  }

  Future<void> deleteSupplier(int id) async {
    final poCount = await _db.getCount('purchase_orders', where: 'supplier_id = ?', whereArgs: [id]);
    if (poCount > 0) {
      throw const AppError(
        message: 'Cannot delete supplier: they have associated purchase orders.',
        type: ErrorType.validation,
      );
    }
    final result = await _db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
    if (result == 0) {
      throw const AppError(
        message: 'Supplier not found',
        type: ErrorType.database,
      );
    }
    await loadSuppliers();
  }

  List<SupplierModel> searchSuppliers(String query) {
    final q = query.toLowerCase();
    return _suppliers.where((s) =>
        s.name.toLowerCase().contains(q) ||
        s.phone.contains(q) ||
        (s.contactPerson?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  @override
  void dispose() {
    // Clear suppliers data to prevent memory leaks
    _suppliers = [];
    super.dispose();
  }
}
