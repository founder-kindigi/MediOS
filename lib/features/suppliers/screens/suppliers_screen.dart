import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supplier_service.dart';
import '../../../core/constants/app_colors.dart';

import '../../../core/widgets/search_bar_widget.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/animated_list_item.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../../core/utils/validators.dart';
import '../../../routes/app_router.dart';
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

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierForm(),
        child: const Icon(Icons.add),
      ),
      body: ResponsiveWrapper(
        child: Column(
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
                            return AnimatedListItem(
                              index: index,
                              child: Card(
                                child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  child: const Icon(Icons.business, color: AppColors.primary),
                                ),
                                title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${supplier.contactPerson ?? ''}\n${supplier.phone}'),
                                onTap: () => Navigator.pushNamed(context, AppRouter.supplierDetail, arguments: supplier),
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
                            ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      ),
    );
  }

  void _showSupplierForm({SupplierModel? supplier}) {
    final nameCtrl = TextEditingController(text: supplier?.name ?? '');
    final contactCtrl = TextEditingController(text: supplier?.contactPerson ?? '');
    final phoneCtrl = TextEditingController(text: supplier?.phone ?? '');
    final emailCtrl = TextEditingController(text: supplier?.email ?? '');
    final addressCtrl = TextEditingController(text: supplier?.address ?? '');

    bool hasChanges() {
      return nameCtrl.text != (supplier?.name ?? '') ||
             contactCtrl.text != (supplier?.contactPerson ?? '') ||
             phoneCtrl.text != (supplier?.phone ?? '') ||
             emailCtrl.text != (supplier?.email ?? '') ||
             addressCtrl.text != (supplier?.address ?? '');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
          title: Text(supplier == null ? 'Add Supplier' : 'Edit Supplier'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *', hintText: 'Enter supplier name'), onChanged: (_) => formKey.currentState?.validate(), validator: (v) => Validators.required(v, 'Name')),
                  TextFormField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact Person', hintText: 'Enter contact person')),
                  TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone *', hintText: 'Enter phone number'), onChanged: (_) => formKey.currentState?.validate(), validator: (v) => Validators.phone(v)),
                  TextFormField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', hintText: 'Enter email address'), validator: (v) => v != null && v.isNotEmpty ? Validators.email(v) : null),
                  TextFormField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address', hintText: 'Enter address'), maxLines: 2),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (hasChanges()) {
                  final discard = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Discard Changes'),
                      content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
                      ],
                    ),
                  );
                  if (discard == true && context.mounted) {
                    Navigator.pop(context);
                  }
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final svc = context.read<SupplierService>();
                  final model = SupplierModel(
                    id: supplier?.id,
                    name: nameCtrl.text.trim(),
                    contactPerson: contactCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                  );
                  if (supplier == null) {
                    await svc.addSupplier(model);
                    if (context.mounted) AppSnackbar.showSuccess(context, 'Supplier added successfully');
                  } else {
                    await svc.updateSupplier(model);
                    if (context.mounted) AppSnackbar.showSuccess(context, 'Supplier updated successfully');
                  }
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) AppSnackbar.showError(context, 'Error saving supplier: $e');
                }
              },
              child: Text(supplier == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    ).then((_) {
      nameCtrl.dispose();
      contactCtrl.dispose();
      phoneCtrl.dispose();
      emailCtrl.dispose();
      addressCtrl.dispose();
    });
  }

  void _deleteSupplier(SupplierModel supplier) {
    if (supplier.id == null) {
      AppSnackbar.showError(context, 'Invalid supplier ID');
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Delete ${supplier.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<SupplierService>().deleteSupplier(supplier.id!);
                if (context.mounted) {
                  AppSnackbar.showSuccess(context, 'Supplier deleted successfully');
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  AppSnackbar.showError(context, 'Failed to delete supplier: $e');
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
