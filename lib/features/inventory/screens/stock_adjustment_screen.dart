import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../models/medicine_model.dart';

class StockAdjustmentScreen extends StatefulWidget {
  const StockAdjustmentScreen({super.key});

  @override
  State<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  MedicineModel? _selectedMedicine;
  String _adjustmentType = 'out';
  String _reason = 'Breakage';

  final _reasons = ['Breakage', 'Theft', 'Expiry Disposal', 'Correction', 'Donation', 'Sample', 'Other'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedMedicine == null) {
      AppSnackbar.showError(context, 'Select a medicine');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final qty = int.parse(_qtyCtrl.text);
    if (_adjustmentType == 'out' && qty > _selectedMedicine!.stockQuantity) {
      AppSnackbar.showError(context, 'Not enough stock (available: ${_selectedMedicine!.stockQuantity})');
      return;
    }

    final inventory = context.read<InventoryService>();
    await inventory.updateStock(
      _selectedMedicine!.id!,
      qty,
      _adjustmentType,
    );

    await inventory.getTransactionHistory(); // no-op, just to refresh

    if (mounted) {
      AppSnackbar.showSuccess(context, 'Stock adjusted successfully');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryService>();
    final searchResults = _searchCtrl.text.isNotEmpty && _selectedMedicine == null
        ? inventory.searchMedicines(_searchCtrl.text)
        : <MedicineModel>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Adjustment')),
      body: Form(
        key: _formKey,
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_selectedMedicine == null) ...[
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search medicine...',
                prefixIcon: const Icon(Icons.search),
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
                    subtitle: Text('Stock: ${m.stockQuantity} | ${Helpers.formatCurrency(m.sellingPrice)}'),
                    onTap: () => setState(() => _selectedMedicine = m),
                  )).toList(),
                ),
              ),
          ] else ...[
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.medication)),
                title: Text(_selectedMedicine!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Stock: ${_selectedMedicine!.stockQuantity} ${_selectedMedicine!.unit}'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _selectedMedicine = null;
                    _searchCtrl.clear();
                  }),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _typeButton('Stock In', 'in', AppColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _typeButton('Stock Out', 'out', AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _qtyCtrl,
            decoration: const InputDecoration(labelText: 'Quantity *'),
            keyboardType: TextInputType.number,
            validator: (v) => Validators.positiveNumber(v, 'Quantity'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _reason,
            decoration: const InputDecoration(labelText: 'Reason'),
            items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setState(() => _reason = v ?? 'Breakage'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _selectedMedicine != null ? _save : null,
              icon: const Icon(Icons.check),
              label: const Text('Save Adjustment'),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _typeButton(String label, String value, Color color) {
    final selected = _adjustmentType == value;
    return ElevatedButton(
      onPressed: () => setState(() => _adjustmentType = value),
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? color : Colors.grey.shade200,
        foregroundColor: selected ? Colors.white : AppColors.textPrimary,
      ),
      child: Text(label),
    );
  }
}
