import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/customer_model.dart';

class CustomerService extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<CustomerModel> _customers = [];
  bool _isLoading = false;

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();

    final maps = await _db.query('customers', orderBy: 'name ASC');
    _customers = maps.map((m) => CustomerModel.fromMap(m)).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<int> addCustomer(CustomerModel customer) async {
    final id = await _db.insert('customers', customer.toMap());
    await loadCustomers();
    return id;
  }

  Future<int> updateCustomer(CustomerModel customer) async {
    final result = await _db.update('customers', customer.toMap(),
        where: 'id = ?', whereArgs: [customer.id]);
    await loadCustomers();
    return result;
  }

  Future<void> deleteCustomer(int id) async {
    await _db.delete('customers', where: 'id = ?', whereArgs: [id]);
    await loadCustomers();
  }

  List<CustomerModel> searchCustomers(String query) {
    final q = query.toLowerCase();
    return _customers.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.phone.contains(q)
    ).toList();
  }
}
