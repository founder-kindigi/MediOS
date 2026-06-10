import 'package:flutter/foundation.dart';

/// Enum for credit transaction types.
enum CreditTransactionType {
  sale,
  payment,
  adjustment,
  opening,
}

/// Customer credit information.
class CustomerCredit {
  final int customerId;
  final String customerName;
  final String? phone;
  final String? email;
  final double creditLimit;
  final double openingBalance;
  final double currentBalance;
  final DateTime? lastCreditUpdate;
  final DateTime createdAt;

  const CustomerCredit({
    required this.customerId,
    required this.customerName,
    this.phone,
    this.email,
    required this.creditLimit,
    required this.openingBalance,
    required this.currentBalance,
    this.lastCreditUpdate,
    required this.createdAt,
  });

  factory CustomerCredit.fromMap(Map<String, dynamic> map) {
    return CustomerCredit(
      customerId: map['customer_id'] as int,
      customerName: map['customer_name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      creditLimit: (map['credit_limit'] as num).toDouble(),
      openingBalance: (map['opening_balance'] as num).toDouble(),
      currentBalance: (map['current_balance'] as num).toDouble(),
      lastCreditUpdate: map['last_credit_update'] != null
          ? DateTime.parse(map['last_credit_update'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      'credit_limit': creditLimit,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
      'last_credit_update': lastCreditUpdate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Gets the available credit.
  double get availableCredit => creditLimit - currentBalance;

  /// Checks if customer is over credit limit.
  bool get isOverLimit => currentBalance > creditLimit;

  /// Gets credit utilization percentage.
  double get utilizationPercentage {
    if (creditLimit == 0) return 0;
    return (currentBalance / creditLimit) * 100;
  }
}

/// Represents a customer's credit transaction.
@immutable
class CreditTransaction {
  final int? id;
  final int customerId;
  final String customerName;
  final DateTime transactionDate;
  final CreditTransactionType type;
  final int? referenceId; // sale_id, payment_id, etc.
  final String? referenceType; // 'sale', 'payment', etc.
  final double amount;
  final double runningBalance;
  final String? description;
  final String? notes;
  final DateTime createdAt;

  const CreditTransaction({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.transactionDate,
    required this.type,
    this.referenceId,
    this.referenceType,
    required this.amount,
    required this.runningBalance,
    this.description,
    this.notes,
    required this.createdAt,
  });

  factory CreditTransaction.fromMap(Map<String, dynamic> map) {
    // Parse transaction type string to enum
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
  }

  Map<String, dynamic> toMap() {
    // Convert enum back to string
    final typeString = switch (type) {
      CreditTransactionType.sale => 'sale',
      CreditTransactionType.payment => 'payment',
      CreditTransactionType.adjustment => 'adjustment',
      CreditTransactionType.opening => 'opening',
    };

    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      'transaction_date': transactionDate.toIso8601String(),
      'transaction_type': typeString,
      if (referenceId != null) 'reference_id': referenceId,
      if (referenceType != null) 'reference_type': referenceType,
      'amount': amount,
      'balance_after': runningBalance,
      if (description != null) 'description': description,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a sale transaction.
  factory CreditTransaction.sale({
    required int customerId,
    required String customerName,
    required int saleId,
    required double amount,
    required double previousBalance,
    String? notes,
  }) {
    final balanceAfter = previousBalance + amount;
    return CreditTransaction(
      customerId: customerId,
      customerName: customerName,
      transactionDate: DateTime.now(),
      type: CreditTransactionType.sale,
      referenceId: saleId,
      referenceType: 'sale',
      amount: amount,
      runningBalance: balanceAfter,
      description: 'Credit Sale',
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  /// Creates a payment transaction.
  factory CreditTransaction.payment({
    required int customerId,
    required String customerName,
    required double amount,
    required double previousBalance,
    String? description,
    String? notes,
  }) {
    final balanceAfter = previousBalance - amount;
    return CreditTransaction(
      customerId: customerId,
      customerName: customerName,
      transactionDate: DateTime.now(),
      type: CreditTransactionType.payment,
      amount: amount,
      runningBalance: balanceAfter,
      description: description ?? 'Payment Received',
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  /// Creates an opening balance transaction.
  factory CreditTransaction.openingBalance({
    required int customerId,
    required String customerName,
    required double amount,
    String? notes,
  }) {
    return CreditTransaction(
      customerId: customerId,
      customerName: customerName,
      transactionDate: DateTime.now(),
      type: CreditTransactionType.opening,
      amount: amount,
      runningBalance: amount,
      description: 'Opening Balance',
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  /// Creates an adjustment transaction.
  factory CreditTransaction.adjustment({
    required int customerId,
    required String customerName,
    required double amount,
    required double previousBalance,
    required String description,
    String? notes,
  }) {
    final balanceAfter = previousBalance + amount;
    return CreditTransaction(
      customerId: customerId,
      customerName: customerName,
      transactionDate: DateTime.now(),
      type: CreditTransactionType.adjustment,
      amount: amount,
      runningBalance: balanceAfter,
      description: description,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  String get transactionType => switch (type) {
        CreditTransactionType.sale => 'sale',
        CreditTransactionType.payment => 'payment',
        CreditTransactionType.adjustment => 'adjustment',
        CreditTransactionType.opening => 'opening',
      };

  double get balanceAfter => runningBalance;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          customerId == other.customerId &&
          transactionDate == other.transactionDate &&
          type == other.type &&
          amount == other.amount;

  @override
  int get hashCode =>
      id.hashCode ^
      customerId.hashCode ^
      transactionDate.hashCode ^
      type.hashCode ^
      amount.hashCode;

  CreditTransaction copyWith({
    int? id,
    int? customerId,
    String? customerName,
    DateTime? transactionDate,
    CreditTransactionType? type,
    int? referenceId,
    String? referenceType,
    double? amount,
    double? runningBalance,
    String? description,
    String? notes,
    DateTime? createdAt,
  }) {
    return CreditTransaction(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      transactionDate: transactionDate ?? this.transactionDate,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      amount: amount ?? this.amount,
      runningBalance: runningBalance ?? this.runningBalance,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'CreditTransaction(id: $id, customerId: $customerId, type: $type, amount: $amount, balance: $runningBalance)';
  }
}

/// Customer credit summary information.
class CustomerCreditSummary {
  final int customerId;
  final String customerName;
  final double openingBalance;
  final double totalSales;
  final double totalPayments;
  final double currentBalance;
  final double creditLimit;
  final DateTime? lastTransactionDate;
  final DateTime? lastPaymentDate;
  final int daysOverdue;

  const CustomerCreditSummary({
    required this.customerId,
    required this.customerName,
    required this.openingBalance,
    required this.totalSales,
    required this.totalPayments,
    required this.currentBalance,
    required this.creditLimit,
    this.lastTransactionDate,
    this.lastPaymentDate,
    required this.daysOverdue,
  });

  /// Gets the available credit (credit limit - current balance).
  double get availableCredit => creditLimit - currentBalance;

  /// Checks if customer is over credit limit.
  bool get isOverLimit => currentBalance > creditLimit;

  /// Checks if customer has overdue payments.
  bool get hasOverdue => daysOverdue > 0;

  /// Gets credit utilization percentage.
  double get utilizationPercentage {
    if (creditLimit == 0) return 0;
    return (currentBalance / creditLimit) * 100;
  }

  /// Gets credit status category.
  String get status {
    if (currentBalance <= 0) return 'No Balance';
    if (isOverLimit) return 'Over Limit';
    if (hasOverdue) return 'Overdue';
    if (utilizationPercentage > 80) return 'High Utilization';
    return 'Active';
  }

  /// Gets status color for UI.
  String get statusColor {
    return switch (status) {
      'No Balance' => 'green',
      'Over Limit' => 'red',
      'Overdue' => 'red',
      'High Utilization' => 'orange',
      _ => 'blue',
    };
  }

  factory CustomerCreditSummary.fromMap(Map<String, dynamic> map) {
    return CustomerCreditSummary(
      customerId: map['customer_id'] as int,
      customerName: map['customer_name'] as String,
      openingBalance: (map['opening_balance'] as num).toDouble(),
      totalSales: (map['total_sales'] as num).toDouble(),
      totalPayments: (map['total_payments'] as num).toDouble(),
      currentBalance: (map['current_balance'] as num).toDouble(),
      creditLimit: (map['credit_limit'] as num).toDouble(),
      lastTransactionDate: map['last_transaction_date'] != null
          ? DateTime.parse(map['last_transaction_date'] as String)
          : null,
      lastPaymentDate: map['last_payment_date'] != null
          ? DateTime.parse(map['last_payment_date'] as String)
          : null,
      daysOverdue: map['days_overdue'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'opening_balance': openingBalance,
      'total_sales': totalSales,
      'total_payments': totalPayments,
      'current_balance': currentBalance,
      'credit_limit': creditLimit,
      'last_transaction_date': lastTransactionDate?.toIso8601String(),
      'last_payment_date': lastPaymentDate?.toIso8601String(),
      'days_overdue': daysOverdue,
    };
  }
}

/// Customer payment information.
class CustomerPayment {
  final int? id;
  final int customerId;
  final DateTime paymentDate;
  final double amount;
  final String paymentMethod; // 'cash', 'bank', 'cheque', 'online'
  final String? referenceNumber;
  final String? description;
  final String? notes;
  final DateTime createdAt;

  const CustomerPayment({
    this.id,
    required this.customerId,
    required this.paymentDate,
    required this.amount,
    required this.paymentMethod,
    this.referenceNumber,
    this.description,
    this.notes,
    required this.createdAt,
  });

  factory CustomerPayment.fromMap(Map<String, dynamic> map) {
    return CustomerPayment(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      paymentDate: DateTime.parse(map['payment_date'] as String),
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String,
      referenceNumber: map['reference_number'] as String?,
      description: map['description'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      'payment_date': paymentDate.toIso8601String(),
      'amount': amount,
      'payment_method': paymentMethod,
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (description != null) 'description': description,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Result of a credit sale operation.
sealed class CreditSaleResult {
  const CreditSaleResult();

  factory CreditSaleResult.success({
    required int saleId,
    required double newBalance,
    String message = 'Credit sale completed successfully',
  }) {
    return CreditSaleSuccess(
      saleId: saleId,
      newBalance: newBalance,
      message: message,
    );
  }

  factory CreditSaleResult.failure({
    required String error,
    StackTrace? stackTrace,
  }) = CreditSaleFailure;

  bool get isSuccess => this is CreditSaleSuccess;
  bool get isFailure => this is CreditSaleFailure;

  int? get saleId => switch (this) {
    CreditSaleSuccess(:final saleId) => saleId,
    _ => null,
  };

  String? get errorMessage => switch (this) {
    CreditSaleFailure(:final error) => error,
    _ => null,
  };

  String? get successMessage => switch (this) {
    CreditSaleSuccess(:final message) => message,
    _ => null,
  };
}

class CreditSaleSuccess extends CreditSaleResult {
  final int saleId;
  final double newBalance;
  final String message;

  const CreditSaleSuccess({
    required this.saleId,
    required this.newBalance,
    required this.message,
  });
}

class CreditSaleFailure extends CreditSaleResult {
  final String error;
  final StackTrace? stackTrace;

  const CreditSaleFailure({
    required this.error,
    this.stackTrace,
  });
}

/// Result of a payment operation.
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
    StackTrace? stackTrace,
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
  final int paymentId;
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
  final StackTrace? stackTrace;

  const PaymentFailure({
    required this.error,
    this.stackTrace,
  });
}