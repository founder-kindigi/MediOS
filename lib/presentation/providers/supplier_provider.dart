import 'package:flutter/foundation.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/usecases/supplier_usecases.dart';
import '../../core/utils/disposal_helper.dart';

class SupplierProvider extends ChangeNotifier with DisposableMixin {
  final GetAllSuppliersUseCase _getAllSuppliers;
  final GetSupplierByIdUseCase _getSupplierById;
  final AddSupplierUseCase _addSupplier;
  final UpdateSupplierUseCase _updateSupplier;
  final DeleteSupplierUseCase _deleteSupplier;

  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  SupplierProvider({
    required GetAllSuppliersUseCase getAllSuppliers,
    required GetSupplierByIdUseCase getSupplierById,
    required AddSupplierUseCase addSupplier,
    required UpdateSupplierUseCase updateSupplier,
    required DeleteSupplierUseCase deleteSupplier,
  })  : _getAllSuppliers = getAllSuppliers,
        _getSupplierById = getSupplierById,
        _addSupplier = addSupplier,
        _updateSupplier = updateSupplier,
        _deleteSupplier = deleteSupplier;

  List<Supplier> get suppliers => _filteredSuppliers.isNotEmpty ? _filteredSuppliers : _suppliers;
  List<Supplier> get allSuppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  Future<void> loadSuppliers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _suppliers = await _getAllSuppliers.call(searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null);
      _applySearchFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load suppliers: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> addSupplier(Supplier supplier) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newSupplier = await _addSupplier.call(supplier);
      _suppliers = [newSupplier, ..._suppliers];
      _applySearchFilter();
      _isLoading = false;
      notifyListeners();
      return newSupplier.id ?? 0;
    } catch (e) {
      _error = 'Failed to add supplier: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<int> updateSupplier(Supplier supplier) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedSupplier = await _updateSupplier.call(supplier);
      final index = _suppliers.indexWhere((s) => s.id == supplier.id);
      if (index != -1) {
        _suppliers[index] = updatedSupplier;
      }
      _applySearchFilter();
      _isLoading = false;
      notifyListeners();
      return updatedSupplier.id ?? 0;
    } catch (e) {
      _error = 'Failed to update supplier: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSupplier(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _deleteSupplier.call(id);
      _suppliers.removeWhere((s) => s.id == id);
      _applySearchFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete supplier: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  List<Supplier> searchSuppliers(String query) {
    _searchQuery = query;
    _applySearchFilter();
    notifyListeners();
    return _filteredSuppliers;
  }

  Future<Supplier?> getSupplierById(int id) async {
    return await _getSupplierById.call(id);
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredSuppliers = [];
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredSuppliers = _suppliers.where((supplier) {
        return supplier.name.toLowerCase().contains(query) ||
            supplier.phone.contains(query) ||
            (supplier.contactPerson?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
  }

  @override
  void dispose() {
    _suppliers = [];
    _filteredSuppliers = [];
    super.dispose();
  }
}
