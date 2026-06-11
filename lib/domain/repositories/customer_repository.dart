import '../entities/customer.dart';

/// Repository interface for Customer data operations.
abstract class CustomerRepository {
  /// Get all customers, optionally filtered by search query.
  Future<List<Customer>> getAll({String? searchQuery});

  /// Get customer by ID.
  Future<Customer?> getById(int id);

  /// Add a new customer.
  Future<Customer> add(Customer customer);

  /// Update an existing customer.
  Future<Customer> update(Customer customer);

  /// Delete a customer.
  Future<void> delete(int id);

  /// Update customer credit limit.
  Future<void> updateCreditLimit(int customerId, double creditLimit);

  /// Sets customer opening balance.
  Future<void> setOpeningBalance({
    required int customerId,
    required double amount,
    String? notes,
  });

  /// Gets customer credit transactions (ledger).
  Future<List<CreditTransaction>> getLedger(
    int customerId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  });

  /// Gets all customer payments.
  Future<List<CustomerPayment>> getPayments(
    int customerId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  });

  /// Gets customer credit summary.
  Future<CustomerCreditSummary> getCreditSummary(int customerId);

  /// Gets overdue customers.
  Future<List<CustomerCreditSummary>> getOverdueCustomers();

  /// Gets recent credit transactions across all customers.
  Future<List<CreditTransaction>> getRecentTransactions({int limit = 20});

  /// Records a customer payment.
  Future<PaymentResult> recordPayment({
    required int customerId,
    required double amount,
    required String paymentMethod,
    String? referenceNumber,
    String? description,
    String? notes,
  });
}

/// Result of a payment recording operation.
sealed class PaymentResult {
  const PaymentResult();

  factory PaymentResult.success({
    required int paymentId,
    required double newBalance,
    String message = 'Payment recorded successfully',
  }) {
    return PaymentSuccess(
      paymentId: paymentId,
      newBalance: newBalance,
      message: message,
    );
  }

  factory PaymentResult.failure({
    required String error,
  }) = PaymentFailure;

  bool get isSuccess => this is PaymentSuccess;
  bool get isFailure => this is PaymentFailure;

  String? get errorMessage => switch (this) {
    PaymentFailure(:final error) => error,
    _ => null,
  };

  double? get newBalance => switch (this) {
    PaymentSuccess(:final newBalance) => newBalance,
    _ => null,
  };

  int? get paymentId => switch (this) {
    PaymentSuccess(:final paymentId) => paymentId,
    _ => null,
  };
}

class PaymentSuccess extends PaymentResult {
  @override
  final int paymentId;
  @override
  final double newBalance;
  final String message;

  const PaymentSuccess({
    required this.paymentId,
    required this.newBalance,
    required this.message,
  });
}

class PaymentFailure extends PaymentResult {
  final String error;

  const PaymentFailure({
    required this.error,
  });
}
