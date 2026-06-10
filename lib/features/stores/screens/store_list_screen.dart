import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/store_service.dart';
import '../../../core/constants/app_colors.dart';

import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/utils/validators.dart';
import '../../../models/store_model.dart';
import '../../inventory/services/inventory_service.dart';
import '../../sales/services/sales_service.dart';
import '../../purchase_orders/services/purchase_order_service.dart';
import '../../orders/services/order_service.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../returns/services/return_service.dart';

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
    final service = context.read<StoreService>();
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    try {
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
        await service.addStore(
          StoreModel(name: nameCtrl.text.trim(), address: addressCtrl.text.trim(), phone: phoneCtrl.text.trim()),
        );
        if (mounted) AppSnackbar.showSuccess(context, 'Store added');
      }
    } finally {
      nameCtrl.dispose();
      addressCtrl.dispose();
      phoneCtrl.dispose();
    }
  }

  Future<void> _editStore(StoreModel store) async {
    final service = context.read<StoreService>();
    final nameCtrl = TextEditingController(text: store.name);
    final addressCtrl = TextEditingController(text: store.address);
    final phoneCtrl = TextEditingController(text: store.phone);
    final formKey = GlobalKey<FormState>();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Edit Store'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Store Name *', prefixIcon: Icon(Icons.store)), autofocus: true, validator: (v) => Validators.required(v, 'Store name')),
                const SizedBox(height: 8),
                TextFormField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on))),
                const SizedBox(height: 8),
                TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)), validator: (v) => v != null && v.isNotEmpty ? Validators.phone(v) : null),
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
        try {
          await service.updateStore(
            store.copyWith(name: nameCtrl.text.trim(), address: addressCtrl.text.trim(), phone: phoneCtrl.text.trim()),
          );
          if (mounted) AppSnackbar.showSuccess(context, 'Store updated');
        } catch (e) {
          if (mounted) AppSnackbar.showError(context, 'Failed to update store: $e');
        }
      }
    } finally {
      nameCtrl.dispose();
      addressCtrl.dispose();
      phoneCtrl.dispose();
    }
  }

  Future<void> _deleteStore(StoreModel store) async {
    final service = context.read<StoreService>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Store'),
        content: Text('Are you sure you want to delete "${store.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await service.deleteStore(store.id!);
        if (mounted) AppSnackbar.showSuccess(context, 'Store deleted');
      } catch (e) {
        if (mounted) AppSnackbar.showError(context, 'Failed to delete store: $e');
      }
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
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                              onPressed: () => _editStore(store),
                            ),
                            if (!isSelected) ...[
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
                                onPressed: () => _deleteStore(store),
                              ),
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await service.selectStore(store.id!);
                                    if (context.mounted) {
                                      await Future.wait([
                                        context.read<InventoryService>().loadMedicines(),
                                        context.read<SalesService>().loadSales(),
                                        context.read<PurchaseOrderService>().loadOrders(),
                                        context.read<OrderService>().loadOrders(),
                                        context.read<DashboardService>().loadDashboard(),
                                        context.read<ReturnService>().loadReturns(),
                                      ]);
                                      if (context.mounted) {
                                        AppSnackbar.showSuccess(context, 'Store switched to ${store.name}');
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      AppSnackbar.showError(context, 'Error switching store: $e');
                                    }
                                  }
                                },
                                child: const Text('Select'),
                              ),
                            ],
                            if (isSelected)
                              const Chip(label: Text('Active', style: TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
