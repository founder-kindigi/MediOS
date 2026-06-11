import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/security/permissions.dart';
import '../../../features/auth/services/permission_service.dart';
import '../../../domain/entities/customer.dart';
import '../../../presentation/providers/customer_provider.dart';

class CustomerCreditScreen extends StatefulWidget {
  const CustomerCreditScreen({super.key});

  @override
  State<CustomerCreditScreen> createState() => _CustomerCreditScreenState();
}

class _CustomerCreditScreenState extends State<CustomerCreditScreen> {
  final PermissionService _permissionService = GetIt.instance<PermissionService>();
  
  List<CustomerCreditSummary> _customerCredits = [];
  List<CreditTransaction> _recentTransactions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  double _totalOutstanding = 0;
  double _totalCreditLimit = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Check permission
      _permissionService.checkPermission(AppPermission.canManageCustomerCredit);

      final customerProvider = context.read<CustomerProvider>();
      final credits = await customerProvider.getAllCustomerCredits();
      final transactions = await customerProvider.getRecentTransactions(limit: 20);
      
      // Calculate totals
      double outstanding = 0;
      double creditLimit = 0;
      
      for (final credit in credits) {
        outstanding += credit.currentBalance;
        creditLimit += credit.creditLimit;
      }
      
      setState(() {
        _customerCredits = credits;
        _recentTransactions = transactions;
        _totalOutstanding = outstanding;
        _totalCreditLimit = creditLimit;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, e is AppError ? e.userMessage : 'Failed to load credit data: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _recordPayment(int customerId, String customerName) async {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Record Payment'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Customer: $customerName', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Payment Amount',
                    prefixText: 'Rs ',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter payment amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid positive amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'e.g., Cash payment, Bank transfer, etc.',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Record Payment'),
            ),
          ],
        ),
      );

      if (result != true) return;

      final amount = double.parse(amountController.text);
      
      await context.read<CustomerProvider>().recordPayment(
        customerId: customerId,
        amount: amount,
        paymentMethod: 'cash',
        notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
      );
      
      if (mounted) {
        AppSnackbar.showSuccess(context, 'Payment recorded successfully');
      }
      
      await _loadData();
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, e is AppError ? e.userMessage : 'Failed to record payment: $e');
      }
    } finally {
      amountController.dispose();
      notesController.dispose();
    }
  }

  Future<void> _updateCreditLimit(int customerId, String customerName, double currentLimit) async {
    final limitController = TextEditingController(text: currentLimit.toString());
    final formKey = GlobalKey<FormState>();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update Credit Limit'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Customer: $customerName', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: limitController,
                  decoration: const InputDecoration(
                    labelText: 'Credit Limit',
                    prefixText: 'Rs ',
                    helperText: 'Set to 0 for unlimited credit',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter limit';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (double.parse(value) < 0) {
                      return 'Limit cannot be negative';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Update Limit'),
            ),
          ],
        ),
      );

      if (result != true) return;

      final newLimit = double.parse(limitController.text);
      
      await context.read<CustomerProvider>().updateCreditLimit(
        customerId,
        newLimit,
      );
      
      if (mounted) {
        AppSnackbar.showSuccess(context, 'Credit limit updated successfully');
      }
      
      await _loadData();
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, e is AppError ? e.userMessage : 'Failed to update credit limit: $e');
      }
    } finally {
      limitController.dispose();
    }
  }

  void _viewLedger(int customerId, String customerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerLedgerScreen(customerId: customerId, customerName: customerName),
      ),
    );
  }

  List<CustomerCreditSummary> get _filteredCredits {
    if (_searchQuery.isEmpty) {
      return _customerCredits;
    }
    
    final query = _searchQuery.toLowerCase();
    return _customerCredits.where((credit) {
      return credit.customerName.toLowerCase().contains(query) ||
             credit.phone?.toLowerCase().contains(query) == true ||
             credit.email?.toLowerCase().contains(query) == true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customer Credit (Khata)'),
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.people), text: 'Customers'),
              Tab(icon: Icon(Icons.receipt), text: 'Recent Transactions'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadData,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Customers Tab
                  Column(
                    children: [
                      // Summary Cards
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Card(
                                color: AppColors.surface,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Total Outstanding',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        Helpers.formatCurrency(_totalOutstanding),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Card(
                                color: AppColors.surface,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Total Credit Limit',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        Helpers.formatCurrency(_totalCreditLimit),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search customers by name, phone, or email...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),

                      // Customers List
                      Expanded(
                        child: _filteredCredits.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No Customers Found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _searchQuery.isEmpty
                                          ? 'Add customers with credit to see them here'
                                          : 'No customers match your search',
                                      style: const TextStyle(color: AppColors.textSecondary),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 16),
                                itemCount: _filteredCredits.length,
                                itemBuilder: (context, index) {
                                  final credit = _filteredCredits[index];
                                  final isOverdue = credit.currentBalance > 0 && 
                                                    credit.lastCreditUpdate != null &&
                                                    DateTime.now().difference(credit.lastCreditUpdate!).inDays > 30;
                                  
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: CircleAvatar(
                                        backgroundColor: credit.currentBalance > 0 
                                            ? AppColors.warning.withOpacity(0.2)
                                            : AppColors.success.withOpacity(0.2),
                                        child: Icon(
                                          credit.currentBalance > 0 ? Icons.money_off : Icons.money,
                                          color: credit.currentBalance > 0 ? AppColors.warning : AppColors.success,
                                        ),
                                      ),
                                      title: Text(
                                        credit.customerName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                                              const SizedBox(width: 4),
                                              Text(credit.phone ?? 'No phone', style: const TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Balance', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                                  Text(
                                                    Helpers.formatCurrency(credit.currentBalance),
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: credit.currentBalance > 0 ? AppColors.warning : AppColors.success,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Limit', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                                  Text(
                                                    Helpers.formatCurrency(credit.creditLimit),
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Available', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                                  Text(
                                                    Helpers.formatCurrency(credit.creditLimit - credit.currentBalance),
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: (credit.creditLimit - credit.currentBalance) < credit.creditLimit * 0.1 
                                                          ? AppColors.error 
                                                          : AppColors.success,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          if (isOverdue)
                                            Container(
                                              margin: const EdgeInsets.only(top: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.error.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.warning, size: 12, color: AppColors.error),
                                                  SizedBox(width: 4),
                                                  Text('Overdue', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert),
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'payment':
                                              _recordPayment(credit.customerId, credit.customerName);
                                              break;
                                            case 'limit':
                                              _updateCreditLimit(credit.customerId, credit.customerName, credit.creditLimit);
                                              break;
                                            case 'ledger':
                                              _viewLedger(credit.customerId, credit.customerName);
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem<String>(
                                            value: 'payment',
                                            child: Row(
                                              children: [
                                                Icon(Icons.payment, size: 20, color: AppColors.primary),
                                                SizedBox(width: 8),
                                                Text('Record Payment'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'limit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.credit_card, size: 20, color: AppColors.secondary),
                                                SizedBox(width: 8),
                                                Text('Update Credit Limit'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'ledger',
                                            child: Row(
                                              children: [
                                                Icon(Icons.receipt_long, size: 20, color: AppColors.success),
                                                SizedBox(width: 8),
                                                Text('View Ledger'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _viewLedger(credit.customerId, credit.customerName),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),

                  // Recent Transactions Tab
                  _recentTransactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long, size: 64, color: AppColors.textSecondary),
                              const SizedBox(height: 16),
                              const Text(
                                'No Transactions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Credit transactions will appear here',
                                style: TextStyle(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _recentTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _recentTransactions[index];
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  backgroundColor: transaction.type == CreditTransactionType.payment
                                      ? AppColors.success.withOpacity(0.2)
                                      : AppColors.warning.withOpacity(0.2),
                                  child: Icon(
                                    transaction.type == CreditTransactionType.payment ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: transaction.type == CreditTransactionType.payment ? AppColors.success : AppColors.warning,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  transaction.customerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      transaction.type == CreditTransactionType.payment 
                                          ? 'Payment Received' 
                                          : 'Credit Sale',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (transaction.notes?.isNotEmpty == true)
                                      Text(
                                        transaction.notes!,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                                      ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      Helpers.formatCurrency(transaction.amount),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: transaction.type == CreditTransactionType.payment ? AppColors.success : AppColors.warning,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Helpers.formatDate(transaction.createdAt),
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
      ),
    );
  }
}

class CustomerLedgerScreen extends StatefulWidget {
  final int customerId;
  final String customerName;

  const CustomerLedgerScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  List<CreditTransaction> _transactions = [];
  CustomerCreditSummary? _creditInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final customerProvider = context.read<CustomerProvider>();
      final creditInfo = await customerProvider.getCustomerCredit(widget.customerId);
      final transactions = await customerProvider.getCustomerTransactions(widget.customerId);
      
      setState(() {
        _creditInfo = creditInfo;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Failed to load ledger: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ledger - ${widget.customerName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadLedger,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Customer Summary Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_creditInfo?.phone != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(_creditInfo!.phone!),
                              ],
                            ),
                          ),
                        if (_creditInfo?.email != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.email, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(_creditInfo!.email!),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _ledgerStat('Current Balance', _creditInfo?.currentBalance ?? 0, 
                                (_creditInfo?.currentBalance ?? 0) > 0 ? AppColors.warning : AppColors.success),
                            _ledgerStat('Credit Limit', _creditInfo?.creditLimit ?? 0, AppColors.secondary),
                            _ledgerStat('Available', (_creditInfo?.creditLimit ?? 0) - (_creditInfo?.currentBalance ?? 0), 
                                ((_creditInfo?.creditLimit ?? 0) - (_creditInfo?.currentBalance ?? 0)) < (_creditInfo?.creditLimit ?? 0) * 0.1 
                                    ? AppColors.error 
                                    : AppColors.success),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Transactions Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaction History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_transactions.length} transaction${_transactions.length == 1 ? '' : 's'}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Transactions List
                Expanded(
                  child: _transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long, size: 64, color: AppColors.textSecondary),
                              const SizedBox(height: 16),
                              const Text(
                                'No Transactions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'This customer has no credit transactions',
                                style: TextStyle(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _transactions[index];
                            final isLast = index == _transactions.length - 1;
                            
                            return Card(
                              margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  backgroundColor: transaction.type == CreditTransactionType.payment
                                      ? AppColors.success.withOpacity(0.2)
                                      : AppColors.warning.withOpacity(0.2),
                                  child: Icon(
                                    transaction.type == CreditTransactionType.payment ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: transaction.type == CreditTransactionType.payment ? AppColors.success : AppColors.warning,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  transaction.type == CreditTransactionType.payment ? 'Payment' : 'Credit Sale',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      Helpers.formatDateTime(transaction.createdAt),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (transaction.notes?.isNotEmpty == true)
                                      Text(
                                        transaction.notes!,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                                      ),
                                    if (transaction.referenceId != null)
                                      Text(
                                        'Ref: #${transaction.referenceId}',
                                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                      ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      Helpers.formatCurrency(transaction.amount),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: transaction.type == CreditTransactionType.payment ? AppColors.success : AppColors.warning,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Balance: ${Helpers.formatCurrency(transaction.runningBalance)}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _ledgerStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          Helpers.formatCurrency(value),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}