import 'package:flutter/foundation.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/customer_usecases.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../core/utils/disposal_helper.dart';

class CustomerProvider extends ChangeNotifier with DisposableMixin {
  final GetAllCustomersUseCase _getAllCustomers;
  final AddCustomerUseCase _addCustomer;
  final UpdateCustomerUseCase _updateCustomer;
  final DeleteCustomerUseCase _deleteCustomer;
  final UpdateCustomerCreditLimitUseCase _updateCreditLimit;
  final SetCustomerOpeningBalanceUseCase _setOpeningBalance;
  final GetCustomerLedgerUseCase _getLedger;
  // ignore: unused_field
  final GetCustomerPaymentsUseCase _getPayments;
  final GetCustomerCreditSummaryUseCase _getCreditSummary;
  final GetOverdueCustomersUseCase _getOverdueCustomers;
  final GetRecentCreditTransactionsUseCase _getRecentTransactions;
  final RecordCustomerPaymentUseCase _recordPayment;

  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  CustomerProvider({
    required GetAllCustomersUseCase getAllCustomers,
    required AddCustomerUseCase addCustomer,
    required UpdateCustomerUseCase updateCustomer,
    required DeleteCustomerUseCase deleteCustomer,
    required UpdateCustomerCreditLimitUseCase updateCreditLimit,
    required SetCustomerOpeningBalanceUseCase setOpeningBalance,
    required GetCustomerLedgerUseCase getLedger,
    required GetCustomerPaymentsUseCase getPayments,
    required GetCustomerCreditSummaryUseCase getCreditSummary,
    required GetOverdueCustomersUseCase getOverdueCustomers,
    required GetRecentCreditTransactionsUseCase getRecentTransactions,
    required RecordCustomerPaymentUseCase recordPayment,
  })  : _getAllCustomers = getAllCustomers,
        _addCustomer = addCustomer,
        _updateCustomer = updateCustomer,
        _deleteCustomer = deleteCustomer,
        _updateCreditLimit = updateCreditLimit,
        _setOpeningBalance = setOpeningBalance,
        _getLedger = getLedger,
        _getPayments = getPayments,
        _getCreditSummary = getCreditSummary,
        _getOverdueCustomers = getOverdueCustomers,
        _getRecentTransactions = getRecentTransactions,
        _recordPayment = recordPayment;

  List<Customer> get customers => _filteredCustomers.isNotEmpty ? _filteredCustomers : _customers;
  List<Customer> get allCustomers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _customers = await _getAllCustomers.call(searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null);
      _applySearchFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load customers: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> addCustomer(Customer customer) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newCustomer = await _addCustomer.call(customer);
      _customers = [newCustomer, ..._customers];
      _applySearchFilter();
      _isLoading = false;
      notifyListeners();
      return newCustomer.id ?? 0;
    } catch (e) {
      _error = 'Failed to add customer: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<int> updateCustomer(Customer customer) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedCustomer = await _updateCustomer.call(customer);
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = updatedCustomer;
      }
      _applySearchFilter();
      _isLoading = false;
      notifyListeners();
      return updatedCustomer.id ?? 0;
    } catch (e) {
      _error = 'Failed to update customer: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCustomer(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _deleteCustomer.call(id);
      _customers.removeWhere((c) => c.id == id);
      _applySearchFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete customer: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  List<Customer> searchCustomers(String query) {
    _searchQuery = query;
    _applySearchFilter();
    notifyListeners();
    return _filteredCustomers;
  }

  Future<List<CreditTransaction>> getCustomerLedger(
    int customerId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    return await _getLedger.call(customerId, startDate: startDate, endDate: endDate, limit: limit, offset: offset);
  }

  Future<CustomerCreditSummary> getCustomerCredit(int customerId) async {
    return await _getCreditSummary.call(customerId);
  }

  Future<CustomerCreditSummary> getCustomerCreditSummary(int customerId) async {
    return await _getCreditSummary.call(customerId);
  }

  Future<List<CreditTransaction>> getRecentTransactions({int limit = 20}) async {
    return await _getRecentTransactions.call(limit: limit);
  }

  Future<List<CreditTransaction>> getCustomerTransactions(int customerId) async {
    return await _getLedger.call(customerId);
  }

  Future<PaymentResult> recordPayment({
    required int customerId,
    required double amount,
    required String paymentMethod,
    String? referenceNumber,
    String? description,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _recordPayment.call(
        customerId: customerId,
        amount: amount,
        paymentMethod: paymentMethod,
        referenceNumber: referenceNumber,
        description: description,
        notes: notes,
      );
      _isLoading = false;
      await loadCustomers(); // Refresh outstanding balances
      notifyListeners();
      return res;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return PaymentResult.failure(error: e.toString());
    }
  }

  Future<void> updateCreditLimit(int customerId, double creditLimit) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _updateCreditLimit.call(customerId, creditLimit);
      _isLoading = false;
      await loadCustomers();
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setOpeningBalance({
    required int customerId,
    required double amount,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _setOpeningBalance.call(customerId: customerId, amount: amount, notes: notes);
      _isLoading = false;
      await loadCustomers();
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<CustomerCreditSummary>> getOverdueCustomers() async {
    return await _getOverdueCustomers.call();
  }

  Future<List<CustomerCreditSummary>> getAllCustomerCredits() async {
    // Return all customer credit summaries
    final List<CustomerCreditSummary> summaries = [];
    for (final customer in _customers) {
      try {
        final summary = await getCustomerCreditSummary(customer.id!);
        summaries.add(summary);
      } catch (_) {}
    }
    return summaries;
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredCustomers = [];
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredCustomers = _customers.where((customer) {
        return customer.name.toLowerCase().contains(query) ||
            customer.phone.contains(query);
      }).toList();
    }
  }

  @override
  void dispose() {
    _customers = [];
    _filteredCustomers = [];
    super.dispose();
  }
}
