import '../../domain/entities/customer.dart';

class CustomerDataModel extends Customer {
  CustomerDataModel({
    super.id,
    required super.name,
    required super.phone,
    super.email,
    super.address,
    super.creditLimit,
    super.openingBalance,
    super.currentBalance,
    super.lastCreditUpdate,
    required super.createdAt,
  });

  factory CustomerDataModel.fromEntity(Customer customer) {
    return CustomerDataModel(
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      address: customer.address,
      creditLimit: customer.creditLimit,
      openingBalance: customer.openingBalance,
      currentBalance: customer.currentBalance,
      lastCreditUpdate: customer.lastCreditUpdate,
      createdAt: customer.createdAt,
    );
  }

  factory CustomerDataModel.fromMap(Map<String, dynamic> map) {
    return CustomerDataModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      address: map['address'] as String?,
      creditLimit: (map['credit_limit'] as num?)?.toDouble() ?? 0.0,
      openingBalance: (map['opening_balance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (map['current_balance'] as num?)?.toDouble() ?? 0.0,
      lastCreditUpdate: map['last_credit_update'] != null
          ? DateTime.parse(map['last_credit_update'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'credit_limit': creditLimit,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
      'last_credit_update': lastCreditUpdate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Customer toEntity() {
    return Customer(
      id: id,
      name: name,
      phone: phone,
      email: email,
      address: address,
      creditLimit: creditLimit,
      openingBalance: openingBalance,
      currentBalance: currentBalance,
      lastCreditUpdate: lastCreditUpdate,
      createdAt: createdAt,
    );
  }
}
