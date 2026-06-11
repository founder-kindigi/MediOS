import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/sales_provider.dart';
import '../../inventory/services/inventory_service.dart';
import '../../settings/services/settings_service.dart';
import '../../../domain/entities/sale.dart' as domain;
import '../../../models/medicine_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../models/prescription_model.dart';
import '../../../core/utils/helpers.dart';
import '../../../presentation/providers/customer_provider.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _searchCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _couponCtrl = TextEditingController();
  List<_SaleItem> _items = [];
  int? _selectedCustomerId;
  String? _customerName;
  String _paymentMethod = 'cash';
  double _tax = 0;
  bool _isWholesale = false;
  String _couponCode = '';
  Map<String, dynamic>? _appliedCoupon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
      context.read<InventoryService>().loadMedicines();
      final settings = context.read<SettingsService>();
      setState(() {
        _tax = settings.defaultTaxRate;
      });
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is PrescriptionModel) {
        final inventory = context.read<InventoryService>();
        setState(() {
          _noteCtrl.text = 'Prescription #${args.id}';
          _items = (args.items ?? []).map((item) {
            final med = inventory.medicines.where((m) => m.id == item.medicineId).firstOrNull;
            final price = med != null
                ? (_isWholesale && med.wholesalePrice > 0 ? med.wholesalePrice : med.sellingPrice)
                : 0.0;
            return _SaleItem(
              medicineId: item.medicineId,
              medicineName: item.medicineName,
              unitPrice: price,
              quantity: item.quantity,
            );
          }).toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _noteCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _taxAmount => _subtotal * (_tax / 100);
  
  double get _couponDiscount {
    if (_appliedCoupon == null) return 0.0;
    
    // Validate min_purchase dynamically
    final minPurchase = (_appliedCoupon!['min_purchase'] as num?)?.toDouble() ?? 0.0;
    if (_subtotal < minPurchase) return 0.0;
    
    final value = (_appliedCoupon!['value'] as num).toDouble();
    final type = _appliedCoupon!['type'] as String;
    return type == 'percentage' ? _subtotal * value / 100 : value;
  }

  double get _netAmount => _subtotal + _taxAmount - _couponDiscount;

  void _addItem(MedicineModel medicine) {
    if (medicine.stockQuantity <= 0) {
      AppSnackbar.showError(
        context,
        'Cannot add "${medicine.name}" because it is out of stock.',
      );
      return;
    }
    setState(() {
      final existing = _items.where((i) => i.medicineId == medicine.id).firstOrNull;
      if (existing != null) {
        if (existing.quantity >= medicine.stockQuantity) {
          AppSnackbar.showError(
            context,
            'Cannot add more of "${medicine.name}". Available stock is ${medicine.stockQuantity}.',
          );
          return;
        }
        existing.quantity++;
      } else {
        final price = _isWholesale && medicine.wholesalePrice > 0
            ? medicine.wholesalePrice
            : medicine.sellingPrice;
        _items.add(_SaleItem(
          medicineId: medicine.id!,
          medicineName: medicine.name,
          unitPrice: price,
          quantity: 1,
        ));
      }
    });
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    final settings = context.read<SettingsService>();
    final coupon = await settings.validateCoupon(code, _subtotal);
    if (coupon == null) {
      if (mounted) {
        AppSnackbar.showError(context, 'Invalid or expired coupon, or min purchase limit not met.');
      }
      return;
    }
    setState(() {
      _couponCode = code;
      _appliedCoupon = coupon;
    });
  }

  Future<void> _completeSale() async {
    if (_items.isEmpty) {
      AppSnackbar.showError(context, 'Add at least one item');
      return;
    }

    final salesProvider = context.read<SalesProvider>();
    final inventoryService = context.read<InventoryService>();

    final billNumber = 'BILL-${DateTime.now().millisecondsSinceEpoch}';
    final sale = domain.Sale(
      billNumber: billNumber,
      customerId: _selectedCustomerId,
      customerName: _customerName,
      totalAmount: _subtotal,
      discount: _couponDiscount,
      tax: _tax,
      netAmount: _netAmount,
      paymentMethod: _paymentMethod,
      notes: [
        _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
        if (_couponCode.isNotEmpty) 'Coupon: $_couponCode (-${Helpers.formatCurrency(_couponDiscount)})',
      ].whereType<String>().join(' | '),
    );

    final items = _items.map((i) => domain.SaleItem(
      medicineId: i.medicineId,
      medicineName: i.medicineName,
      quantity: i.quantity,
      unitPrice: i.unitPrice,
      totalPrice: i.total,
    )).toList();

    try {
      await salesProvider.createSale(sale, items);
      
      // Reload the local medicines cache since stock has changed
      await inventoryService.loadMedicines();

      if (mounted) {
        AppSnackbar.showSuccess(context, 'Sale completed - ${sale.billNumber}');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Failed to complete sale: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryService>();
    final customers = context.watch<CustomerProvider>().allCustomers;
    final searchResults = _searchCtrl.text.isNotEmpty
        ? inventory.searchMedicines(_searchCtrl.text)
            .where((m) => !m.isExpired)
            .toList()
        : <MedicineModel>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        actions: [
          Text(_isWholesale ? 'Wholesale' : 'Retail', style: const TextStyle(fontSize: 13)),
          Switch(
            value: _isWholesale,
            onChanged: (v) => setState(() {
              _isWholesale = v;
              _items.clear();
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedCustomerId,
                  decoration: const InputDecoration(
                    labelText: 'Customer (optional)',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedCustomerId = v;
                      _customerName = v != null ? customers.firstWhere((c) => c.id == v).name : null;
                    });
                  },
                ),
                const SizedBox(height: 8),
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
                        subtitle: Text(
                          '${Helpers.formatCurrency(_isWholesale && m.wholesalePrice > 0 ? m.wholesalePrice : m.sellingPrice)} | Stock: ${m.stockQuantity}${_isWholesale && m.wholesalePrice > 0 ? ' (WS)' : ''}'),
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
                                onPressed: () {
                                  final medicine = inventory.medicines.firstWhere((m) => m.id == item.medicineId);
                                  if (item.quantity >= medicine.stockQuantity) {
                                    AppSnackbar.showError(
                                      context,
                                      'Cannot add more of "${medicine.name}". Available stock is ${medicine.stockQuantity}.',
                                    );
                                    return;
                                  }
                                  setState(() => item.quantity++);
                                },
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
                if (_couponCode.isEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Coupon code',
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _applyCoupon,
                        child: const Text('Apply'),
                      ),
                    ],
                  )
                else
                  Chip(
                    label: Text('Coupon: $_couponCode (-${Helpers.formatCurrency(_couponDiscount)})'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() { _couponCode = ''; _appliedCoupon = null; _couponCtrl.clear(); }),
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
  int _quantity;

  _SaleItem({
    required this.medicineId,
    required this.medicineName,
    required this.unitPrice,
    int quantity = 1,
  }) : _quantity = quantity < 1 ? 1 : quantity;

  int get quantity => _quantity;
  set quantity(int val) {
    if (val < 1) {
      _quantity = 1;
    } else {
      _quantity = val;
    }
  }

  double get total => unitPrice * _quantity;
}
