import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<dynamic>? _transactions;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final txns = await context.read<InventoryService>().getTransactionHistory(type: _filter);
    setState(() => _transactions = txns);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),

      body: _transactions == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('All', 'all'),
                        _filterChip('Stock In', 'in'),
                        _filterChip('Stock Out', 'out'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _transactions!.isEmpty
                      ? const Center(child: Text('No transactions yet'))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _transactions!.length,
                            itemBuilder: (context, index) {
                              final t = _transactions![index];
                              final isIn = t.type == 'in';
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: (isIn ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                                    child: Icon(
                                      isIn ? Icons.add_circle : Icons.remove_circle,
                                      color: isIn ? AppColors.success : AppColors.error,
                                    ),
                                  ),
                                  title: Text(t.medicineName ?? 'Medicine #${t.medicineId}'),
                                  subtitle: Text(
                                    '${isIn ? "Received" : "Sold"} ${t.quantity} units\n${Helpers.formatDate(t.createdAt)}',
                                  ),
                                  trailing: Text(
                                    isIn ? '+${t.quantity}' : '-${t.quantity}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isIn ? AppColors.success : AppColors.error,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _filter = value);
          _load();
        },
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
      ),
    );
  }
}
