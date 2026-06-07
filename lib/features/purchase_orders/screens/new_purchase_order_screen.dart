import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/purchase_order_service.dart';
import '../../inventory/services/inventory_service.dart';
import '../../../models/purchase_order_model.dart';
import '../../../models/medicine_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';

class NewPurchaseOrderScreen extends StatefulWidget {
  const NewPurchaseOrderScreen({super.key});

  @override
  State<NewPurchaseOrderScreen> createState() => _NewPurchaseOrderScreenState();
}

class _NewPurchaseOrderScreenState extends State<NewPurchaseOrderScreen> {
  final _searchCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  List<PurchaseItem> _items = [];
  int? _selectedSupplierId;
  String? _selectedSupplierName;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _totalAmount => _items.fold(0, (sum, item) => sum + item.total);

  void _addItem(MedicineModel medicine) {
    setState(() {
      final existing = _items.where((i) => i.medicineId == medicine.id).firstOrNull;
      if (existing != null) {
        existing.quantity++;
      } else {
        _items.add(PurchaseItem(
          medicineId: medicine.id!,
          medicineName: medicine.name,
          unitPrice: medicine.purchasePrice,
          quantity: 1,
        ));
      }
    });
  }

  Future<void> _placeOrder() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item')),
      );
      return;
    }

    final poService = context.read<PurchaseOrderService>();
    final inventory = context.read<InventoryService>();

    final order = PurchaseOrderModel(
      supplierId: _selectedSupplierId,
      supplierName: _selectedSupplierName,
      orderNumber: Helpers.generateOrderNumber(),
      totalAmount: _totalAmount,
      notes: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
    );

    final items = _items.map((i) => PurchaseOrderItemModel(
      medicineId: i.medicineId,
      medicineName: i.medicineName,
      quantity: i.quantity,
      unitPrice: i.unitPrice,
      totalPrice: i.total,
    )).toList();

    final orderId = await poService.createOrder(order, items);

    for (final item in _items) {
      await inventory.updateStock(
        item.medicineId,
        item.quantity,
        'in',
        poId: orderId,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order placed - ${order.orderNumber}')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryService>();
    final searchResults = _searchCtrl.text.isNotEmpty
        ? inventory.searchMedicines(_searchCtrl.text)
        : <MedicineModel>[];

    return Scaffold(
      appBar: AppBar(title: const Text('New Purchase Order')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search medicine to order...',
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
                        subtitle: Text('${Helpers.formatCurrency(m.purchasePrice)} | Stock: ${m.stockQuantity}'),
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
                ? const Center(child: Text('Search and add medicines to order'))
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
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 16)),
                    Text(Helpers.formatCurrency(_totalAmount),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 12),
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

class PurchaseItem {
  final int medicineId;
  final String medicineName;
  final double unitPrice;
  int quantity;

  PurchaseItem({
    required this.medicineId,
    required this.medicineName,
    required this.unitPrice,
    this.quantity = 1,
  });

  double get total => unitPrice * quantity;
}
