import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/supplier_model.dart';

class SupplierService extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<SupplierModel> _suppliers = [];
  bool _isLoading = false;

  List<SupplierModel> get suppliers => _suppliers;
  bool get isLoading => _isLoading;

  Future<void> loadSuppliers() async {
    _isLoading = true;
    notifyListeners();

    final maps = await _db.query('suppliers', orderBy: 'name ASC');
    _suppliers = maps.map((m) => SupplierModel.fromMap(m)).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<int> addSupplier(SupplierModel supplier) async {
    final id = await _db.insert('suppliers', supplier.toMap());
    await loadSuppliers();
    return id;
  }

  Future<int> updateSupplier(SupplierModel supplier) async {
    final result = await _db.update('suppliers', supplier.toMap(),
        where: 'id = ?', whereArgs: [supplier.id]);
    await loadSuppliers();
    return result;
  }

  Future<void> deleteSupplier(int id) async {
    await _db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
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
}
