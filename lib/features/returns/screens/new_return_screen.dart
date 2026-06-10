import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/return_service.dart';
import '../../sales/services/sales_service.dart';
import '../../inventory/services/inventory_service.dart';
import '../../../models/return_model.dart';
import '../../../models/sale_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_snackbar.dart';

class NewReturnScreen extends StatefulWidget {
  const NewReturnScreen({super.key});

  @override
  State<NewReturnScreen> createState() => _NewReturnScreenState();
}

class _NewReturnScreenState extends State<NewReturnScreen> {
  final _searchCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  SaleModel? _selectedSale;
  Map<int, int> _returnQtys = {};
  String _reason = 'damaged';
  bool _processing = false;

  final _reasons = ['damaged', 'expired', 'customer_return', 'wrong_item', 'defective', 'other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesService>().loadSales();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _totalRefund {
    if (_selectedSale == null) return 0;
    double total = 0;
    for (final item in _selectedSale!.items) {
      final qty = _returnQtys[item.medicineId] ?? 0;
      if (qty > 0) {
        total += qty * item.unitPrice;
      }
    }
    return total;
  }

  bool get _hasItems => _returnQtys.values.any((q) => q > 0);

  Future<void> _processReturn() async {
    if (_selectedSale == null || !_hasItems) return;

    setState(() => _processing = true);

    final returnService = context.read<ReturnService>();
    final inventory = context.read<InventoryService>();

    final items = <ReturnItemModel>[];
    for (final saleItem in _selectedSale!.items) {
      final qty = _returnQtys[saleItem.medicineId] ?? 0;
      if (qty > 0) {
        items.add(ReturnItemModel(
          medicineId: saleItem.medicineId,
          medicineName: saleItem.medicineName,
          quantity: qty,
          unitPrice: saleItem.unitPrice,
          totalRefund: qty * saleItem.unitPrice,
        ));
      }
    }

    final ret = ReturnModel(
      saleId: _selectedSale!.id,
      billNumber: _selectedSale!.billNumber,
      returnNumber: 'R${_selectedSale!.billNumber.replaceAll('BILL', '')}',
      totalRefund: _totalRefund,
      reason: _reason,
      notes: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
    );

    try {
      await returnService.processReturn(ret, items);
      await inventory.loadMedicines();

      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          'Return processed - refund: ${Helpers.formatCurrency(_totalRefund)}',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Failed to process return: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesService = context.watch<SalesService>();
    final matchingSales = salesService.sales
        .where((s) => _searchCtrl.text.isEmpty ||
            s.billNumber.toLowerCase().contains(_searchCtrl.text.toLowerCase()))
        .toList();
    final displayedSales = matchingSales.take(10).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Process Return')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_selectedSale == null) ...[
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by bill number...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            ...displayedSales.map((s) => ListTile(
                leading: const Icon(Icons.receipt),
                title: Text(s.billNumber),
                subtitle: Text(Helpers.formatDate(s.saleDate)),
                trailing: Text(Helpers.formatCurrency(s.netAmount)),
                onTap: () => _selectSale(s.id!),
              )),
            if (matchingSales.length > 10)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Text(
                    'Showing 10 of ${matchingSales.length} sales. Type more to filter.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
          ] else ...[
            Card(
              color: AppColors.primary.withValues(alpha: 0.05),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.receipt)),
                title: Text(_selectedSale!.billNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${_selectedSale!.customerName ?? 'Walk-in'} | ${Helpers.formatDate(_selectedSale!.saleDate)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _selectedSale = null;
                    _returnQtys.clear();
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select items to return:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._selectedSale!.items.map((item) => Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.medicineName ?? 'Item',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${Helpers.formatCurrency(item.unitPrice)} each',
                              style: const TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            setState(() {
                              final cur = _returnQtys[item.medicineId] ?? 0;
                              if (cur > 0) _returnQtys[item.medicineId] = cur - 1;
                            });
                          },
                        ),
                        Text('${_returnQtys[item.medicineId] ?? 0}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            setState(() {
                              final cur = _returnQtys[item.medicineId] ?? 0;
                              if (cur < item.quantity) _returnQtys[item.medicineId] = cur + 1;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _reason,
              decoration: const InputDecoration(labelText: 'Reason'),
              items: _reasons.map((r) => DropdownMenuItem(
                value: r,
                child: Text(r.replaceAll('_', ' ').toUpperCase()),
              )).toList(),
              onChanged: (v) => setState(() => _reason = v ?? 'damaged'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Refund:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(Helpers.formatCurrency(_totalRefund),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.error)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _hasItems && !_processing ? _processReturn : null,
                icon: const Icon(Icons.replay),
                label: Text(_processing ? 'Processing...' : 'Process Return'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _selectSale(int saleId) async {
    final sale = await context.read<SalesService>().getSaleWithItems(saleId);
    if (sale != null && mounted) {
      setState(() {
        _selectedSale = sale;
        _returnQtys = {for (final item in sale.items) item.medicineId: 0};
      });
    }
  }
}
