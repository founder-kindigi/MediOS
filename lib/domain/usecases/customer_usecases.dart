import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class GetAllCustomersUseCase {
  final CustomerRepository _repository;
  GetAllCustomersUseCase({required CustomerRepository repository}) : _repository = repository;

  Future<List<Customer>> call({String? searchQuery}) async {
    return await _repository.getAll(searchQuery: searchQuery);
  }
}

class GetCustomerByIdUseCase {
  final CustomerRepository _repository;
  GetCustomerByIdUseCase({required CustomerRepository repository}) : _repository = repository;

  Future<Customer?> call(int id) async {
    return await _repository.getById(id);
  }
}

class AddCustomerUseCase {
  final CustomerRepository _repository;
  AddCustomerUseCase({required CustomerRepository repository}) : _repository = repository;

  Future<Customer> call(Customer customer) async {
    return await _repository.add(customer);
  }
}

class UpdateCustomerUseCase {
  final CustomerRepository _repository;
  UpdateCustomerUseCase({required CustomerRepository repository}) : _repository = repository;

  Future<Customer> call(Customer customer) async {
    return await _repository.update(customer);
  }
}

class DeleteCustomerUseCase {
  final CustomerRepository _repository;
  DeleteCustomerUseCase({required CustomerRepository repository}) : _repository = repository;

  Future<void> call(int id) async {
    await _repository.delete(id);
  }
}

class UpdateCustomerCreditLimitUseCase {
  final CustomerRepository _repository;
  UpdateCustomerCreditLimitUseCase({required CustomerRepository repository}) : _repository = repository;

  Future<void> call(int customerId, double creditLimit) async {
    await _repository.updateCreditLimit(customerId, creditLimit);
  }
}

class SetCustomerOpeningBalanceUseCase {
  final CustomerRepository _repository;
  SetCustomerOpeningBalanceUseCase({required CustomerRepository repository}) : _repository = repository;

  Future<void> call({required int customerId, required double amount, String? notes}) async {
    await _repository.setOpeningBalance(customerId: customerId, amount: amount, notes: notes);
  }
}

class GetCustomerLedgerUseCase {
  final CustomerRepository _repository;
  GetCustomerLedgerUseCase({required CustomerRepository repository}) : _repository = repository;

  Future<List<CreditTransaction>> call(
    int customerId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    return await _repository.getLedger(customerId, startDate: startDate, endDate: endDate, limit: limit, offset: offset);
  }
}

class GetCustomerPaymentsUseCase {
  final CustomerRepository _repository;
  GetCustomerPaymentsUseCase({required CustomerRepository repository}) : _repository = repository;

  Future<List<CustomerPayment>> call(
    int customerId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    return await _repository.getPayments(customerId, startDate: startDate, endDate: endDate, limit: limit, offset: offset);
  }
}

class GetCustomerCreditSummaryUseCase {
  final CustomerRepository _repository;
  GetCustomerCreditSummaryUseCase({required CustomerRepository repository}) : _repository = repository;

  Future<CustomerCreditSummary> call(int customerId) async {
    return await _repository.getCreditSummary(customerId);
  }
}

class GetOverdueCustomersUseCase {
  final CustomerRepository _repository;
  GetOverdueCustomersUseCase({required CustomerRepository repository}) : _repository = repository;

  Future<List<CustomerCreditSummary>> call() async {
    return await _repository.getOverdueCustomers();
  }
}

class GetRecentCreditTransactionsUseCase {
  final CustomerRepository _repository;
  GetRecentCreditTransactionsUseCase({required CustomerRepository repository}) : _repository = repository;

  Future<List<CreditTransaction>> call({int limit = 20}) async {
    return await _repository.getRecentTransactions(limit: limit);
  }
}

class RecordCustomerPaymentUseCase {
  final CustomerRepository _repository;
  RecordCustomerPaymentUseCase({required CustomerRepository repository}) : _repository = repository;

  Future<PaymentResult> call({
    required int customerId,
    required double amount,
    required String paymentMethod,
    String? referenceNumber,
    String? description,
    String? notes,
  }) async {
    return await _repository.recordPayment(
      customerId: customerId,
      amount: amount,
      paymentMethod: paymentMethod,
      referenceNumber: referenceNumber,
      description: description,
      notes: notes,
    );
  }
}
