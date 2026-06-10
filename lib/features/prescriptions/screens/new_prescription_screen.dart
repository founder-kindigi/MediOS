import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/prescription_service.dart';
import '../../inventory/services/inventory_service.dart';
import '../../../models/prescription_model.dart';
import '../../../models/medicine_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';

class _PrescItem {
  final int medicineId;
  final String medicineName;
  int quantity;
  String dosage;
  String frequency;
  String duration;

  _PrescItem({
    required this.medicineId,
    required this.medicineName,
    int quantity = 1,
    String dosage = '',
    String frequency = '',
    String duration = '',
  }) : quantity = quantity,
       dosage = dosage,
       frequency = frequency,
       duration = duration;
}

class NewPrescriptionScreen extends StatefulWidget {
  const NewPrescriptionScreen({super.key});

  @override
  State<NewPrescriptionScreen> createState() => _NewPrescriptionScreenState();
}

class _NewPrescriptionScreenState extends State<NewPrescriptionScreen> {
  final _patientCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _doctorCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<_PrescItem> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryService>().loadMedicines();
    });
  }

  @override
  void dispose() {
    _patientCtrl.dispose();
    _phoneCtrl.dispose();
    _doctorCtrl.dispose();
    _noteCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _addMedicine(MedicineModel med) {
    setState(() {
      final existing = _items.where((i) => i.medicineId == med.id).firstOrNull;
      if (existing != null) {
        existing.quantity++;
      } else {
        _items.add(_PrescItem(medicineId: med.id!, medicineName: med.name));
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      AppSnackbar.showError(context, 'Add at least one medicine');
      return;
    }
    try {
      final service = context.read<PrescriptionService>();
      await service.createPrescription(PrescriptionModel(
        patientName: _patientCtrl.text.trim(),
        patientPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        doctorName: _doctorCtrl.text.trim().isEmpty ? null : _doctorCtrl.text.trim(),
        prescriptionDate: DateTime.now(),
        notes: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        items: _items.map((i) => PrescriptionItem(
          medicineId: i.medicineId,
          medicineName: i.medicineName,
          dosage: i.dosage.isEmpty ? null : i.dosage,
          frequency: i.frequency.isEmpty ? null : i.frequency,
          duration: i.duration.isEmpty ? null : i.duration,
          quantity: i.quantity,
        )).toList(),
      ));
      if (mounted) {
        AppSnackbar.showSuccess(context, 'Prescription created');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Failed to create prescription: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryService>();
    final searchResults = _searchCtrl.text.isEmpty
        ? <MedicineModel>[]
        : inv.medicines.where((m) =>
            m.name.toLowerCase().contains(_searchCtrl.text.toLowerCase())).take(10).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('New Prescription')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _patientCtrl,
              decoration: const InputDecoration(labelText: 'Patient Name', prefixIcon: Icon(Icons.person)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Patient Phone', prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _doctorCtrl,
              decoration: const InputDecoration(labelText: 'Doctor Name', prefixIcon: Icon(Icons.medical_services)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Notes', prefixIcon: Icon(Icons.notes)),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text('Medicines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    subtitle: Text('₨${m.sellingPrice.toStringAsFixed(0)} | Stock: ${m.stockQuantity}'),
                    trailing: const Icon(Icons.add_circle, color: AppColors.primary),
                    onTap: () {
                      _addMedicine(m);
                      _searchCtrl.clear();
                      setState(() {});
                    },
                  )).toList(),
                ),
              ),
            const SizedBox(height: 8),
            ..._items.asMap().entries.map((entry) {
              final i = entry.value;
              final idx = entry.key;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(i.medicineName, style: const TextStyle(fontWeight: FontWeight.w600))),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: AppColors.error, size: 20),
                            onPressed: () => setState(() => _items.removeAt(idx)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: i.dosage,
                              decoration: const InputDecoration(labelText: 'Dosage', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                              onChanged: (v) => i.dosage = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: i.frequency,
                              decoration: const InputDecoration(labelText: 'Frequency', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                              onChanged: (v) => i.frequency = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: TextFormField(
                              initialValue: i.quantity.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Qty', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                              onChanged: (v) => i.quantity = int.tryParse(v) ?? 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save Prescription', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
