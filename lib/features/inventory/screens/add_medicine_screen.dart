import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/inventory_service.dart';
import '../../../models/medicine_model.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snackbar.dart';

class AddMedicineScreen extends StatefulWidget {
  final MedicineModel? medicine;
  const AddMedicineScreen({super.key, this.medicine});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _genericCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController();
  final _sellingPriceCtrl = TextEditingController();
  final _wholesalePriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _reorderCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  int? _selectedCategoryId;
  DateTime? _expiryDate;
  String _unit = 'strip';
  bool _isEditing = false;

  final _units = ['strip', 'tablet', 'bottle', 'box', 'ampoule', 'vial', 'tube', 'pack'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryService>().loadCategories();
    });
    if (widget.medicine != null) {
      _isEditing = true;
      _populateForm(widget.medicine!);
    }
  }

  void _populateForm(MedicineModel m) {
    _nameCtrl.text = m.name;
    _genericCtrl.text = m.genericName;
    _manufacturerCtrl.text = m.manufacturer;
    _purchasePriceCtrl.text = m.purchasePrice.toString();
    _sellingPriceCtrl.text = m.sellingPrice.toString();
    _wholesalePriceCtrl.text = m.wholesalePrice.toString();
    _stockCtrl.text = m.stockQuantity.toString();
    _reorderCtrl.text = m.reorderLevel.toString();
    _barcodeCtrl.text = m.barcode ?? '';
    _descCtrl.text = m.description ?? '';
    _selectedCategoryId = m.categoryId;
    _expiryDate = m.expiryDate;
    _unit = m.unit;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _genericCtrl.dispose();
    _manufacturerCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _wholesalePriceCtrl.dispose();
    _stockCtrl.dispose();
    _reorderCtrl.dispose();
    _barcodeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final inventory = context.read<InventoryService>();
    final medicine = MedicineModel(
      id: widget.medicine?.id,
      name: _nameCtrl.text.trim(),
      genericName: _genericCtrl.text.trim(),
      categoryId: _selectedCategoryId,
      manufacturer: _manufacturerCtrl.text.trim(),
      unit: _unit,
      purchasePrice: double.parse(_purchasePriceCtrl.text),
      sellingPrice: double.parse(_sellingPriceCtrl.text),
      wholesalePrice: double.tryParse(_wholesalePriceCtrl.text) ?? 0,
      stockQuantity: int.parse(_stockCtrl.text),
      reorderLevel: int.parse(_reorderCtrl.text),
      expiryDate: _expiryDate,
      barcode: _barcodeCtrl.text.trim().isNotEmpty ? _barcodeCtrl.text.trim() : null,
      description: _descCtrl.text.trim(),
    );

    if (_isEditing) {
      await inventory.updateMedicine(medicine);
      if (mounted) AppSnackbar.showSuccess(context, 'Medicine updated successfully');
    } else {
      await inventory.addMedicine(medicine);
      if (mounted) AppSnackbar.showSuccess(context, 'Medicine added successfully');
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryService>();
    final categories = inventory.categories;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Medicine' : 'Add Medicine')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Medicine Name *'),
                validator: (v) => Validators.required(v, 'Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _genericCtrl,
                decoration: const InputDecoration(labelText: 'Generic Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                )).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _manufacturerCtrl,
                decoration: const InputDecoration(labelText: 'Manufacturer'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _unit,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setState(() => _unit = v ?? 'strip'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceCtrl,
                      decoration: const InputDecoration(labelText: 'Purchase Price *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.positiveNumber(v, 'Purchase price'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceCtrl,
                      decoration: const InputDecoration(labelText: 'Selling Price *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.positiveNumber(v, 'Selling price'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _wholesalePriceCtrl,
                decoration: const InputDecoration(labelText: 'Wholesale Price'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      decoration: const InputDecoration(labelText: 'Stock Quantity *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.positiveNumber(v, 'Stock'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _reorderCtrl,
                      decoration: const InputDecoration(labelText: 'Reorder Level'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (date != null) setState(() => _expiryDate = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Expiry Date'),
                  child: Text(_expiryDate != null
                      ? DateFormat('dd-MM-yyyy').format(_expiryDate!)
                      : 'Select date'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barcodeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Barcode',
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(_isEditing ? 'Update Medicine' : 'Add Medicine'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

