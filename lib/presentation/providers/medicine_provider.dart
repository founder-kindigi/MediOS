import 'package:flutter/foundation.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/repositories/medicine_repository.dart';
import '../../domain/usecases/medicine_usecases.dart';
import '../../core/utils/disposal_helper.dart';

/// Provider for medicine state management with pagination support.
///
/// This separates UI state from business logic and data access.
class MedicineProvider extends ChangeNotifier with DisposableMixin {
  final GetAllMedicinesUseCase _getAllMedicines;
  final GetMedicineByIdUseCase _getMedicineById;
  final AddMedicineUseCase _addMedicine;
  final UpdateMedicineUseCase _updateMedicine;
  final DeleteMedicineUseCase _deleteMedicine;
  final UpdateMedicineStockUseCase _updateStock;
  final SearchMedicinesUseCase _searchMedicines;
  final GetLowStockMedicinesUseCase _getLowStockMedicines;
  final GetNearExpiryMedicinesUseCase _getNearExpiryMedicines;
  final GetExpiredMedicinesUseCase _getExpiredMedicines;
  final GetMedicineCountByCategoryUseCase _getCountByCategory;
  final GetInventoryValueUseCase _getInventoryValue;

  // Pagination state
  List<Medicine> _medicines = [];
  List<Medicine> _filteredMedicines = [];
  Medicine? _selectedMedicine;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _searchQuery = '';
  
  // Pagination metadata
  int _currentPage = 1;
  int _pageSize = 50;
  int _totalItems = 0;
  bool _hasMore = true;
  bool _isInitialLoad = true;

  MedicineProvider({
    required GetAllMedicinesUseCase getAllMedicines,
    required GetMedicineByIdUseCase getMedicineById,
    required AddMedicineUseCase addMedicine,
    required UpdateMedicineUseCase updateMedicine,
    required DeleteMedicineUseCase deleteMedicine,
    required UpdateMedicineStockUseCase updateStock,
    required SearchMedicinesUseCase searchMedicines,
    required GetLowStockMedicinesUseCase getLowStockMedicines,
    required GetNearExpiryMedicinesUseCase getNearExpiryMedicines,
    required GetExpiredMedicinesUseCase getExpiredMedicines,
    required GetMedicineCountByCategoryUseCase getCountByCategory,
    required GetInventoryValueUseCase getInventoryValue,
  })  : _getAllMedicines = getAllMedicines,
        _getMedicineById = getMedicineById,
        _addMedicine = addMedicine,
        _updateMedicine = updateMedicine,
        _deleteMedicine = deleteMedicine,
        _updateStock = updateStock,
        _searchMedicines = searchMedicines,
        _getLowStockMedicines = getLowStockMedicines,
        _getNearExpiryMedicines = getNearExpiryMedicines,
        _getExpiredMedicines = getExpiredMedicines,
        _getCountByCategory = getCountByCategory,
        _getInventoryValue = getInventoryValue;

  List<Medicine> get medicines => _filteredMedicines;
  List<Medicine> get allMedicines => _medicines;
  Medicine? get selectedMedicine => _selectedMedicine;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  
  // Pagination getters
  int get currentPage => _currentPage;
  int get totalItems => _totalItems;
  int get totalPages => (_totalItems / _pageSize).ceil();
  bool get hasMore => _hasMore;
  bool get isInitialLoad => _isInitialLoad;

  List<Medicine> get lowStockMedicines =>
      _medicines.where((m) => m.isLowStock).toList();

  List<Medicine> get nearExpiryMedicines =>
      _medicines.where((m) => m.isNearExpiry).toList();

  List<Medicine> get expiredMedicines =>
      _medicines.where((m) => m.isExpired).toList();

  /// Load initial medicines (first page).
  Future<void> loadMedicines({
    int? categoryId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isLoading) return;
    
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    _isInitialLoad = true;
    notifyListeners();

    try {
      final result = await _getAllMedicines.call(
        page: _currentPage,
        limit: _pageSize,
        categoryId: categoryId,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      _medicines = result.items;
      _totalItems = result.totalItems;
      _hasMore = result.hasNext;
      _applySearchFilter();
      _isLoading = false;
      _isInitialLoad = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load medicines: $e';
      _isLoading = false;
      _isInitialLoad = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Load more medicines (pagination).
  Future<void> loadMoreMedicines({
    int? categoryId,
  }) async {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    
    _isLoadingMore = true;
    _error = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final result = await _getAllMedicines.call(
        page: nextPage,
        limit: _pageSize,
        categoryId: categoryId,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      _medicines.addAll(result.items);
      _totalItems = result.totalItems;
      _hasMore = result.hasNext;
      _currentPage = nextPage;
      _applySearchFilter();
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load more medicines: $e';
      _isLoadingMore = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Refresh medicines (reload from first page).
  Future<void> refreshMedicines({
    int? categoryId,
  }) async {
    await loadMedicines(
      categoryId: categoryId,
      forceRefresh: true,
    );
  }

  /// Get a medicine by ID.
  Future<Medicine?> getMedicineById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final medicine = await _getMedicineById.call(id);
      _selectedMedicine = medicine;
      _isLoading = false;
      notifyListeners();
      return medicine;
    } catch (e) {
      _error = 'Failed to get medicine: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Add a new medicine.
  Future<Medicine> addMedicine(Medicine medicine) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newMedicine = await _addMedicine.call(medicine);
      
      // Add to beginning of list and update total count
      _medicines = [newMedicine, ..._medicines];
      _totalItems += 1;
      _applySearchFilter();
      
      // If we're on paginated view and list exceeds page size,
      // remove the last item to maintain page size
      if (_medicines.length > _pageSize) {
        _medicines = _medicines.take(_pageSize).toList();
      }
      
      _isLoading = false;
      notifyListeners();
      return newMedicine;
    } catch (e) {
      _error = 'Failed to add medicine: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update an existing medicine.
  Future<Medicine> updateMedicine(Medicine medicine) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedMedicine = await _updateMedicine.call(medicine);
      
      // Update in the list
      final index = _medicines.indexWhere((m) => m.id == medicine.id);
      if (index != -1) {
        _medicines[index] = updatedMedicine;
      }
      
      // Update selected medicine if it's the same one
      if (_selectedMedicine?.id == medicine.id) {
        _selectedMedicine = updatedMedicine;
      }
      
      _applySearchFilter();
      _isLoading = false;
      notifyListeners();
      return updatedMedicine;
    } catch (e) {
      _error = 'Failed to update medicine: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a medicine.
  Future<void> deleteMedicine(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _deleteMedicine.call(id);
      
      // Remove from the list
      _medicines.removeWhere((m) => m.id == id);
      
      // Clear selected medicine if it's the same one
      if (_selectedMedicine?.id == id) {
        _selectedMedicine = null;
      }
      
      _applySearchFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete medicine: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update medicine stock.
  Future<Medicine> updateStock({
    required int medicineId,
    required int newQuantity,
    required String reason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedMedicine = await _updateStock.call(
        medicineId: medicineId,
        newQuantity: newQuantity,
        reason: reason,
      );
      
      // Update in the list
      final index = _medicines.indexWhere((m) => m.id == medicineId);
      if (index != -1) {
        _medicines[index] = updatedMedicine;
      }
      
      // Update selected medicine if it's the same one
      if (_selectedMedicine?.id == medicineId) {
        _selectedMedicine = updatedMedicine;
      }
      
      _applySearchFilter();
      _isLoading = false;
      notifyListeners();
      return updatedMedicine;
    } catch (e) {
      _error = 'Failed to update stock: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Search medicines with pagination support.
  Future<void> searchMedicines(String query) async {
    _searchQuery = query;
    
    if (query.isEmpty) {
      // If search is cleared, reload all medicines from first page
      await loadMedicines();
    } else {
      // Reset pagination for new search
      _currentPage = 1;
      _hasMore = true;
      _isLoading = true;
      notifyListeners();

      try {
        // Use the paginated getAll method with search query
        final result = await _getAllMedicines.call(
          page: _currentPage,
          limit: _pageSize,
          searchQuery: query,
        );

        _medicines = result.items;
        _totalItems = result.totalItems;
        _hasMore = result.hasNext;
        _applySearchFilter();
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _error = 'Failed to search medicines: $e';
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Load more search results.
  Future<void> loadMoreSearchResults() async {
    if (!_hasMore || _isLoadingMore || _isLoading || _searchQuery.isEmpty) return;
    
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final result = await _getAllMedicines.call(
        page: nextPage,
        limit: _pageSize,
        searchQuery: _searchQuery,
      );

      _medicines.addAll(result.items);
      _totalItems = result.totalItems;
      _hasMore = result.hasNext;
      _currentPage = nextPage;
      _applySearchFilter();
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load more search results: $e';
      _isLoadingMore = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Get low stock medicines.
  Future<List<Medicine>> getLowStockMedicines() async {
    try {
      return await _getLowStockMedicines.call();
    } catch (e) {
      _error = 'Failed to get low stock medicines: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Get near expiry medicines.
  Future<List<Medicine>> getNearExpiryMedicines() async {
    try {
      return await _getNearExpiryMedicines.call();
    } catch (e) {
      _error = 'Failed to get near expiry medicines: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Get expired medicines.
  Future<List<Medicine>> getExpiredMedicines() async {
    try {
      return await _getExpiredMedicines.call();
    } catch (e) {
      _error = 'Failed to get expired medicines: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Get medicine count by category.
  Future<Map<int, int>> getMedicineCountByCategory() async {
    try {
      return await _getCountByCategory.call();
    } catch (e) {
      _error = 'Failed to get medicine count by category: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Get total inventory value.
  Future<double> getInventoryValue() async {
    try {
      return await _getInventoryValue.call();
    } catch (e) {
      _error = 'Failed to get inventory value: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Clear error message.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear search query.
  void clearSearch() {
    _searchQuery = '';
    _filteredMedicines = _medicines;
    notifyListeners();
  }

  /// Clear selected medicine.
  void clearSelectedMedicine() {
    _selectedMedicine = null;
    notifyListeners();
  }

  // Private methods

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredMedicines = _medicines;
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredMedicines = _medicines.where((medicine) {
        return medicine.name.toLowerCase().contains(query) ||
            medicine.genericName.toLowerCase().contains(query);
      }).toList();
    }
  }
}