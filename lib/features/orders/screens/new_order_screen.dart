import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/order_service.dart';
import '../../inventory/services/inventory_service.dart';
import '../../customers/services/customer_service.dart';
import '../../../models/customer_order_model.dart';
import '../../../models/medicine_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';

class _OrdItem {
  final int medicineId;
  final String medicineName;
  final double unitPrice;
  int quantity;

  _OrdItem({required this.medicineId, required this.medicineName, required this.unitPrice, int quantity = 1}) : quantity = quantity;
  double get total => unitPrice * quantity;
}

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final _searchCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  List<_OrdItem> _items = [];
  int? _selectedCustomerId;
  String? _customerName;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _total => _items.fold(0, (sum, i) => sum + i.total);

  void _addItem(MedicineModel med) {
    setState(() {
      final existing = _items.where((i) => i.medicineId == med.id).firstOrNull;
      if (existing != null) {
        existing.quantity++;
      } else {
        _items.add(_OrdItem(medicineId: med.id!, medicineName: med.name, unitPrice: med.sellingPrice));
      }
    });
  }

  Future<void> _placeOrder() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }
    final service = context.read<OrderService>();
    await service.createOrder(CustomerOrderModel(
      customerId: _selectedCustomerId,
      customerName: _customerName,
      orderNumber: OrderService.generateOrderNumber(),
      orderDate: DateTime.now(),
      totalAmount: _total,
      notes: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
      items: _items.map((i) => CustomerOrderItemModel(
        medicineId: i.medicineId,
        medicineName: i.medicineName,
        quantity: i.quantity,
        unitPrice: i.unitPrice,
        totalPrice: i.total,
      )).toList(),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryService>();
    final customers = context.watch<CustomerService>().customers;
    final searchResults = _searchCtrl.text.isNotEmpty
        ? inv.searchMedicines(_searchCtrl.text).where((m) => m.stockQuantity > 0).toList()
        : <MedicineModel>[];

    return Scaffold(
      appBar: AppBar(title: const Text('New Order')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedCustomerId,
                  decoration: const InputDecoration(labelText: 'Customer (optional)', prefixIcon: Icon(Icons.person)),
                  items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedCustomerId = v;
                      _customerName = customers.firstWhere((c) => c.id == v).name;
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search medicines...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() {}); })
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (searchResults.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 160),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
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
                ? const Center(child: Text('Add items to the order'))
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
                              IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: () {
                                setState(() { if (item.quantity <= 1) _items.removeAt(index); else item.quantity--; });
                              }),
                              Text('${item.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: () => setState(() => item.quantity++)),
                              const SizedBox(width: 8),
                              Text(Helpers.formatCurrency(item.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]),
            child: Column(
              children: [
                Row(
                  children: [
                    const Spacer(),
                    Text('Total: ', style: const TextStyle(fontSize: 16)),
                    Text(Helpers.formatCurrency(_total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: _noteCtrl, decoration: const InputDecoration(labelText: 'Notes', isDense: true, border: OutlineInputBorder())),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _items.isEmpty ? null : _placeOrder,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Place Order', style: TextStyle(fontSize: 16)),
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
