import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sales_service.dart';
import '../../inventory/services/inventory_service.dart';
import '../../../models/sale_model.dart';
import '../../../models/medicine_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _searchCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  List<_SaleItem> _items = [];
  int? _selectedCustomerId;
  String _paymentMethod = 'cash';
  double _discount = 0;
  double _tax = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _taxAmount => _subtotal * (_tax / 100);
  double get _netAmount => _subtotal + _taxAmount - _discount;

  void _addItem(MedicineModel medicine) {
    setState(() {
      final existing = _items.where((i) => i.medicineId == medicine.id).firstOrNull;
      if (existing != null) {
        existing.quantity++;
      } else {
        _items.add(_SaleItem(
          medicineId: medicine.id!,
          medicineName: medicine.name,
          unitPrice: medicine.sellingPrice,
          quantity: 1,
        ));
      }
    });
  }

  Future<void> _completeSale() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item')),
      );
      return;
    }

    final salesService = context.read<SalesService>();
    final inventoryService = context.read<InventoryService>();

    final sale = SaleModel(
      customerId: _selectedCustomerId,
      billNumber: Helpers.generateBillNumber(),
      totalAmount: _subtotal,
      discount: _discount,
      tax: _tax,
      netAmount: _netAmount,
      paymentMethod: _paymentMethod,
      notes: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
    );

    final items = _items.map((i) => SaleItemModel(
      medicineId: i.medicineId,
      medicineName: i.medicineName,
      quantity: i.quantity,
      unitPrice: i.unitPrice,
      totalPrice: i.total,
    )).toList();

    final saleId = await salesService.createSale(sale, items);

    for (final item in _items) {
      await inventoryService.updateStock(
        item.medicineId,
        item.quantity,
        'out',
        saleId: saleId,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sale completed - ${sale.billNumber}')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryService>();
    final searchResults = _searchCtrl.text.isNotEmpty
        ? inventory.searchMedicines(_searchCtrl.text)
            .where((m) => m.stockQuantity > 0 && !m.isExpired)
            .toList()
        : <MedicineModel>[];

    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search medicine to add...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          })
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (searchResults.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: searchResults.map((m) => ListTile(
                        dense: true,
                        title: Text(m.name),
                        subtitle: Text('${Helpers.formatCurrency(m.sellingPrice)} | Stock: ${m.stockQuantity}'),
                        trailing: const Icon(Icons.add_circle, color: AppColors.primary),
                        onTap: () => _addItem(m),
                      )).toList(),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('Search and add medicines'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.medicineName),
                          subtitle: Text('${Helpers.formatCurrency(item.unitPrice)} each'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: () {
                                  setState(() {
                                    if (item.quantity <= 1) {
                                      _items.removeAt(index);
                                    } else {
                                      item.quantity--;
                                    }
                                  });
                                },
                              ),
                              Text('${item.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                onPressed: () => setState(() => item.quantity++),
                              ),
                              const SizedBox(width: 8),
                              Text(Helpers.formatCurrency(item.total),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Payment:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _paymentMethod,
                      items: ['cash', 'card', 'upi', 'credit'].map((m) =>
                        DropdownMenuItem(value: m, child: Text(m.toUpperCase()))).toList(),
                      onChanged: (v) => setState(() => _paymentMethod = v ?? 'cash'),
                    ),
                    const Spacer(),
                    Text('Total: ', style: const TextStyle(fontSize: 16)),
                    Text(Helpers.formatCurrency(_netAmount),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _items.isEmpty ? null : _completeSale,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Complete Sale', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleItem {
  final int medicineId;
  final String medicineName;
  final double unitPrice;
  int quantity;

  _SaleItem({
    required this.medicineId,
    required this.medicineName,
    required this.unitPrice,
    this.quantity = 1,
  });

  double get total => unitPrice * quantity;
}
