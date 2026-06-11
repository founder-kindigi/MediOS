import '../../../../core/errors/app_error.dart';
import '../../../../features/auth/services/permission_service.dart';
import '../../../../core/security/permissions.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/local/customer_local_data_source.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerLocalDataSource _localDataSource;
  final PermissionService _permissionService;

  CustomerRepositoryImpl({
    required CustomerLocalDataSource localDataSource,
    required PermissionService permissionService,
  })  : _localDataSource = localDataSource,
        _permissionService = permissionService;

  @override
  Future<List<Customer>> getAll({String? searchQuery}) async {
    try {
      final models = await _localDataSource.getAllCustomers(searchQuery: searchQuery);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw AppError(
        message: 'Failed to load customers: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<Customer?> getById(int id) async {
    try {
      final model = await _localDataSource.getCustomerById(id);
      return model?.toEntity();
    } catch (e) {
      throw AppError(
        message: 'Failed to get customer: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<Customer> add(Customer customer) async {
    try {
      final errors = customer.validate();
      if (errors.isNotEmpty) {
        throw AppError(
          message: 'Customer validation failed: ${errors.join(", ")}',
          type: ErrorType.validation,
        );
      }

      final dataModel = CustomerDataModel.fromEntity(customer);
      final id = await _localDataSource.insertCustomer(dataModel);
      return customer.copyWith(id: id);
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to add customer: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<Customer> update(Customer customer) async {
    try {
      if (customer.id == null) {
        throw const AppError(
          message: 'Cannot update customer with null ID',
          type: ErrorType.validation,
        );
      }

      final errors = customer.validate();
      if (errors.isNotEmpty) {
        throw AppError(
          message: 'Customer validation failed: ${errors.join(", ")}',
          type: ErrorType.validation,
        );
      }

      final dataModel = CustomerDataModel.fromEntity(customer);
      final result = await _localDataSource.updateCustomer(dataModel);
      if (result == 0) {
        throw const AppError(
          message: 'Customer not found',
          type: ErrorType.database,
        );
      }
      return customer;
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to update customer: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      final salesCount = await _localDataSource.getCustomerSalesCount(id);
      final ordersCount = await _localDataSource.getCustomerOrdersCount(id);
      if (salesCount > 0 || ordersCount > 0) {
        throw const AppError(
          message: 'Cannot delete customer: they have associated sales or orders.',
          type: ErrorType.validation,
        );
      }

      final result = await _localDataSource.deleteCustomer(id);
      if (result == 0) {
        throw const AppError(
          message: 'Customer not found',
          type: ErrorType.database,
        );
      }
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to delete customer: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateCreditLimit(int customerId, double creditLimit) async {
    _permissionService.checkPermission(AppPermission.canManageCustomerCredit);
    try {
      final customer = await getById(customerId);
      if (customer == null) {
        throw const AppError(
          message: 'Customer not found',
          type: ErrorType.notFound,
        );
      }

      final updated = customer.copyWith(
        creditLimit: creditLimit,
        lastCreditUpdate: DateTime.now(),
      );
      await update(updated);
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to update credit limit: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<void> setOpeningBalance({
    required int customerId,
    required double amount,
    String? notes,
  }) async {
    _permissionService.checkPermission(AppPermission.canManageCustomerCredit);
    try {
      await _localDataSource.executeOpeningBalanceTransaction(customerId, amount, notes);
    } catch (e) {
      throw AppError(
        message: 'Failed to set opening balance: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<List<CreditTransaction>> getLedger(
    int customerId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final startStr = startDate?.toIso8601String();
      final endStr = endDate?.toIso8601String();
      final maps = await _localDataSource.getLedger(
        customerId,
        startDate: startStr,
        endDate: endStr,
        limit: limit,
        offset: offset,
      );
      
      return maps.map((map) {
        final typeString = map['transaction_type'] as String;
        final type = switch (typeString) {
          'sale' => CreditTransactionType.sale,
          'payment' => CreditTransactionType.payment,
          'adjustment' => CreditTransactionType.adjustment,
          'opening' => CreditTransactionType.opening,
          _ => CreditTransactionType.sale,
        };
        return CreditTransaction(
          id: map['id'] as int?,
          customerId: map['customer_id'] as int,
          customerName: map['customer_name'] as String? ?? '',
          transactionDate: DateTime.parse(map['transaction_date'] as String),
          type: type,
          referenceId: map['reference_id'] as int?,
          referenceType: map['reference_type'] as String?,
          amount: (map['amount'] as num).toDouble(),
          runningBalance: (map['balance_after'] as num).toDouble(),
          description: map['description'] as String?,
          notes: map['notes'] as String?,
          createdAt: DateTime.parse(map['created_at'] as String),
        );
      }).toList();
    } catch (e) {
      throw AppError(
        message: 'Failed to get customer ledger: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<List<CustomerPayment>> getPayments(
    int customerId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final startStr = startDate?.toIso8601String();
      final endStr = endDate?.toIso8601String();
      final maps = await _localDataSource.getPayments(
        customerId,
        startDate: startStr,
        endDate: endStr,
        limit: limit,
        offset: offset,
      );
      
      return maps.map((map) => CustomerPayment(
        id: map['id'] as int?,
        customerId: map['customer_id'] as int,
        paymentDate: DateTime.parse(map['payment_date'] as String),
        amount: (map['amount'] as num).toDouble(),
        paymentMethod: map['payment_method'] as String,
        referenceNumber: map['reference_number'] as String?,
        description: map['description'] as String?,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      )).toList();
    } catch (e) {
      throw AppError(
        message: 'Failed to get customer payments: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<CustomerCreditSummary> getCreditSummary(int customerId) async {
    try {
      final customer = await getById(customerId);
      if (customer == null) {
        throw const AppError(
          message: 'Customer not found',
          type: ErrorType.notFound,
        );
      }

      final totals = await _localDataSource.getCreditSalesAndPaymentsTotals(customerId);
      final totalSales = (totals?['total_sales'] as num?)?.toDouble() ?? 0.0;
      final totalPayments = (totals?['total_payments'] as num?)?.toDouble() ?? 0.0;
      final lastTxDate = totals?['last_transaction_date'] != null ? DateTime.parse(totals!['last_transaction_date'] as String) : null;
      final lastPayDate = totals?['last_payment_date'] != null ? DateTime.parse(totals!['last_payment_date'] as String) : null;

      // Calculate days overdue
      int daysOverdue = 0;
      if (customer.currentBalance > 0 && lastPayDate != null) {
        final daysSincePayment = DateTime.now().difference(lastPayDate).inDays;
        if (daysSincePayment > 30) {
          daysOverdue = daysSincePayment - 30;
        }
      }

      return CustomerCreditSummary(
        customerId: customerId,
        customerName: customer.name,
        phone: customer.phone,
        email: customer.email,
        openingBalance: customer.openingBalance,
        totalSales: totalSales,
        totalPayments: totalPayments,
        currentBalance: customer.currentBalance,
        creditLimit: customer.creditLimit,
        lastTransactionDate: lastTxDate,
        lastPaymentDate: lastPayDate,
        lastCreditUpdate: customer.lastCreditUpdate,
        daysOverdue: daysOverdue,
      );
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to get credit summary: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<List<CustomerCreditSummary>> getOverdueCustomers() async {
    try {
      final maps = await _localDataSource.getOverdueCustomers();
      final summaries = <CustomerCreditSummary>[];
      for (final map in maps) {
        final customerId = map['customer_id'] as int;
        try {
          final summary = await getCreditSummary(customerId);
          summaries.add(summary);
        } catch (_) {}
      }
      return summaries;
    } catch (e) {
      throw AppError(
        message: 'Failed to get overdue customers: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<List<CreditTransaction>> getRecentTransactions({int limit = 20}) async {
    try {
      final maps = await _localDataSource.getRecentCreditTransactions(limit);
      return maps.map((map) {
        final typeString = map['transaction_type'] as String;
        final type = switch (typeString) {
          'sale' => CreditTransactionType.sale,
          'payment' => CreditTransactionType.payment,
          'adjustment' => CreditTransactionType.adjustment,
          'opening' => CreditTransactionType.opening,
          _ => CreditTransactionType.sale,
        };
        return CreditTransaction(
          id: map['id'] as int?,
          customerId: map['customer_id'] as int,
          customerName: map['customer_name'] as String? ?? '',
          transactionDate: DateTime.parse(map['transaction_date'] as String),
          type: type,
          referenceId: map['reference_id'] as int?,
          referenceType: map['reference_type'] as String?,
          amount: (map['amount'] as num).toDouble(),
          runningBalance: (map['balance_after'] as num).toDouble(),
          description: map['description'] as String?,
          notes: map['notes'] as String?,
          createdAt: DateTime.parse(map['created_at'] as String),
        );
      }).toList();
    } catch (e) {
      throw AppError(
        message: 'Failed to get recent transactions: $e',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  @override
  Future<PaymentResult> recordPayment({
    required int customerId,
    required double amount,
    required String paymentMethod,
    String? referenceNumber,
    String? description,
    String? notes,
  }) async {
    _permissionService.checkPermission(AppPermission.canManageCustomerCredit);
    try {
      final res = await _localDataSource.executePaymentTransaction(
        customerId,
        amount,
        paymentMethod,
        referenceNumber,
        description,
        notes,
      );
      return PaymentResult.success(
        paymentId: res['paymentId'] as int,
        newBalance: res['newBalance'] as double,
        message: 'Payment recorded successfully',
      );
    } catch (e) {
      return PaymentResult.failure(error: e.toString().replaceAll('Exception: ', ''));
    }
  }
}
