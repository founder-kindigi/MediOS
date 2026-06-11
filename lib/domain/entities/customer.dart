/// Core domain entity representing a customer.
class Customer {
  final int? id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final double creditLimit;
  final double openingBalance;
  final double currentBalance;
  final DateTime? lastCreditUpdate;
  final DateTime createdAt;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.creditLimit = 0.0,
    this.openingBalance = 0.0,
    this.currentBalance = 0.0,
    this.lastCreditUpdate,
    required this.createdAt,
  });

  /// Check if the customer has an outstanding balance.
  bool get hasOutstandingBalance => currentBalance > 0.0;

  /// Check if the customer has exceeded their credit limit.
  bool get isOverCreditLimit => creditLimit > 0.0 && currentBalance > creditLimit;

  /// Calculate credit utilization percentage.
  double get creditUtilization {
    if (creditLimit <= 0.0) return 0.0;
    return (currentBalance / creditLimit) * 100.0;
  }

  /// Validate customer entity.
  List<String> validate() {
    final errors = <String>[];
    if (name.trim().isEmpty) {
      errors.add('Customer name is required');
    }
    if (phone.trim().isEmpty) {
      errors.add('Customer phone is required');
    }
    if (creditLimit < 0.0) {
      errors.add('Credit limit cannot be negative');
    }
    if (openingBalance < 0.0) {
      errors.add('Opening balance cannot be negative');
    }
    return errors;
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? creditLimit,
    double? openingBalance,
    double? currentBalance,
    DateTime? lastCreditUpdate,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      creditLimit: creditLimit ?? this.creditLimit,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      lastCreditUpdate: lastCreditUpdate ?? this.lastCreditUpdate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Enum for credit transaction types.
enum CreditTransactionType {
  sale,
  payment,
  adjustment,
  opening,
}

/// Domain entity representing a customer's credit/khata transaction.
class CreditTransaction {
  final int? id;
  final int customerId;
  final String customerName;
  final DateTime transactionDate;
  final CreditTransactionType type;
  final int? referenceId; // e.g. saleId, paymentId
  final String? referenceType; // e.g. 'sale', 'payment'
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

  String get transactionType => switch (type) {
    CreditTransactionType.sale => 'sale',
    CreditTransactionType.payment => 'payment',
    CreditTransactionType.adjustment => 'adjustment',
    CreditTransactionType.opening => 'opening',
  };

  double get balanceAfter => runningBalance;

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
}

/// Domain entity representing a customer payment.
class CustomerPayment {
  final int? id;
  final int customerId;
  final DateTime paymentDate;
  final double amount;
  final String paymentMethod;
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
}

/// Domain entity representing a customer's credit summary.
class CustomerCreditSummary {
  final int customerId;
  final String customerName;
  final String? phone;
  final String? email;
  final double openingBalance;
  final double totalSales;
  final double totalPayments;
  final double currentBalance;
  final double creditLimit;
  final DateTime? lastTransactionDate;
  final DateTime? lastPaymentDate;
  final DateTime? lastCreditUpdate;
  final int daysOverdue;

  const CustomerCreditSummary({
    required this.customerId,
    required this.customerName,
    this.phone,
    this.email,
    required this.openingBalance,
    required this.totalSales,
    required this.totalPayments,
    required this.currentBalance,
    required this.creditLimit,
    this.lastTransactionDate,
    this.lastPaymentDate,
    this.lastCreditUpdate,
    required this.daysOverdue,
  });

  bool get isOverLimit => creditLimit > 0.0 && currentBalance > creditLimit;
  bool get hasOverdue => daysOverdue > 0;
  double get utilizationPercentage => creditLimit <= 0.0 ? 0.0 : (currentBalance / creditLimit) * 100.0;
  double get availableCredit => creditLimit - currentBalance;

  String get status {
    if (currentBalance <= 0.0) return 'No Balance';
    if (isOverLimit) return 'Over Limit';
    if (hasOverdue) return 'Overdue';
    if (utilizationPercentage > 80.0) return 'High Utilization';
    return 'Active';
  }

  String get statusColor {
    return switch (status) {
      'No Balance' => 'green',
      'Over Limit' => 'red',
      'Overdue' => 'red',
      'High Utilization' => 'orange',
      _ => 'blue',
    };
  }
}
