import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/errors/app_error.dart';
import '../../../models/customer_model.dart';

class CustomerService extends ChangeNotifier {
  final DatabaseHelper _db;

  CustomerService({DatabaseHelper? databaseHelper})
      : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>();
  List<CustomerModel> _customers = [];
  bool _isLoading = false;

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final maps = await _db.query('customers', orderBy: 'name ASC');
      _customers = maps.map((m) => CustomerModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Failed to load customers: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<int> addCustomer(CustomerModel customer) async {
    final id = await _db.insert('customers', customer.toMap());
    await loadCustomers();
    return id;
  }

  Future<int> updateCustomer(CustomerModel customer) async {
    if (customer.id == null) {
      throw AppError(
        message: 'Cannot update customer with null ID',
        type: ErrorType.validation,
      );
    }
    final result = await _db.update('customers', customer.toMap(),
        where: 'id = ?', whereArgs: [customer.id]);
    if (result == 0) {
      throw AppError(
        message: 'Customer not found',
        type: ErrorType.database,
      );
    }
    await loadCustomers();
    return result;
  }

  Future<void> deleteCustomer(int id) async {
    final salesCount = await _db.getCount('sales', where: 'customer_id = ?', whereArgs: [id]);
    final ordersCount = await _db.getCount('customer_orders', where: 'customer_id = ?', whereArgs: [id]);
    if (salesCount > 0 || ordersCount > 0) {
      throw AppError(
        message: 'Cannot delete customer: they have associated sales or orders.',
        type: ErrorType.validation,
      );
    }
    final result = await _db.delete('customers', where: 'id = ?', whereArgs: [id]);
    if (result == 0) {
      throw AppError(
        message: 'Customer not found',
        type: ErrorType.database,
      );
    }
    await loadCustomers();
  }

  List<CustomerModel> searchCustomers(String query) {
    final q = query.toLowerCase();
    return _customers.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.phone.contains(q)
    ).toList();
  }

  @override
  void dispose() {
    // Clear customers data to prevent memory leaks
    _customers = [];
    
    super.dispose();
  }
}
