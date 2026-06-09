import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/store_service.dart';
import '../../../core/constants/app_colors.dart';

import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/utils/validators.dart';
import '../../../models/store_model.dart';

class StoreListScreen extends StatefulWidget {
  const StoreListScreen({super.key});

  @override
  State<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreService>().loadStores();
    });
  }

  Future<void> _addStore() async {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Store'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Store Name *', hintText: 'Enter store name', prefixIcon: Icon(Icons.store)), autofocus: true, onChanged: (_) => formKey.currentState?.validate(), validator: (v) => Validators.required(v, 'Store name')),
              const SizedBox(height: 8),
              TextFormField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address', hintText: 'Enter store address', prefixIcon: Icon(Icons.location_on))),
              const SizedBox(height: 8),
              TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', hintText: 'Enter phone number', prefixIcon: Icon(Icons.phone)), validator: (v) => v != null && v.isNotEmpty ? Validators.phone(v) : null),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(ctx, true); }, child: const Text('Save')),
        ],
      ),
    );
    if (result == true) {
      await context.read<StoreService>().addStore(
        StoreModel(name: nameCtrl.text.trim(), address: addressCtrl.text.trim(), phone: phoneCtrl.text.trim()),
      );
      if (context.mounted) AppSnackbar.showSuccess(context, 'Store added');
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<StoreService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Stores')),

      floatingActionButton: FloatingActionButton(
        onPressed: _addStore,
        child: const Icon(Icons.add),
      ),
      body: service.isLoading
          ? const ShimmerList(itemCount: 3)
          : service.stores.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.store_rounded,
                  title: 'No stores yet',
                  subtitle: 'Add your first store location',
                  actionLabel: 'Add Store',
                  onAction: _addStore,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: service.stores.length,
                  itemBuilder: (context, index) {
                    final store = service.stores[index];
                    final isSelected = store.id == service.selectedStoreId;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.2),
                          child: Icon(Icons.store, color: isSelected ? Colors.white : AppColors.textSecondary),
                        ),
                        title: Text(store.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        subtitle: Text(store.address ?? store.phone ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              const Chip(label: Text('Active', style: TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
                            if (!isSelected)
                              TextButton(
                                onPressed: () => service.selectStore(store.id!),
                                child: const Text('Select'),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
