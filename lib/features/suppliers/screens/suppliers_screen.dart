import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supplier_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/search_bar_widget.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/supplier_model.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierService>().loadSuppliers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supplierService = context.watch<SupplierService>();
    final suppliers = _searchController.text.isNotEmpty
        ? supplierService.searchSuppliers(_searchController.text)
        : supplierService.suppliers;

    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchBarWidget(
              controller: _searchController,
              hintText: 'Search suppliers...',
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: supplierService.isLoading
                ? const ShimmerList()
                : suppliers.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.business_rounded,
                        title: 'No suppliers found',
                        subtitle: _searchController.text.isNotEmpty
                            ? 'No results for "${_searchController.text}"'
                            : 'Add your first supplier',
                        actionLabel: _searchController.text.isNotEmpty ? null : 'Add Supplier',
                        onAction: _searchController.text.isNotEmpty ? null : () => _showSupplierForm(),
                      )
                    : RefreshIndicator(
                        onRefresh: () => supplierService.loadSuppliers(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: suppliers.length,
                          itemBuilder: (context, index) {
                            final supplier = suppliers[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  child: const Icon(Icons.business, color: AppColors.primary),
                                ),
                                title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${supplier.contactPerson ?? ''}\n${supplier.phone}'),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                  onSelected: (v) {
                                    if (v == 'edit') _showSupplierForm(supplier: supplier);
                                    if (v == 'delete') _deleteSupplier(supplier);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showSupplierForm({SupplierModel? supplier}) {
    final nameCtrl = TextEditingController(text: supplier?.name ?? '');
    final contactCtrl = TextEditingController(text: supplier?.contactPerson ?? '');
    final phoneCtrl = TextEditingController(text: supplier?.phone ?? '');
    final emailCtrl = TextEditingController(text: supplier?.email ?? '');
    final addressCtrl = TextEditingController(text: supplier?.address ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(supplier == null ? 'Add Supplier' : 'Edit Supplier'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
              TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact Person')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone *')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
              final svc = context.read<SupplierService>();
              final model = SupplierModel(
                id: supplier?.id,
                name: nameCtrl.text,
                contactPerson: contactCtrl.text,
                phone: phoneCtrl.text,
                email: emailCtrl.text,
                address: addressCtrl.text,
              );
              if (supplier == null) {
                await svc.addSupplier(model);
              } else {
                await svc.updateSupplier(model);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(supplier == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _deleteSupplier(SupplierModel supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Delete ${supplier.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<SupplierService>().deleteSupplier(supplier.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
