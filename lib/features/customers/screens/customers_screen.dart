import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/customer_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/search_bar_widget.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/customer.dart';
import '../../../routes/app_router.dart';
import 'customer_credit_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final customers = _searchController.text.isNotEmpty
        ? customerProvider.searchCustomers(_searchController.text)
        : customerProvider.customers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.credit_card),
            tooltip: 'Credit Management',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomerCreditScreen(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCustomerForm(),
        child: const Icon(Icons.add),
      ),
      body: ResponsiveWrapper(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SearchBarWidget(
                controller: _searchController,
                hintText: 'Search customers...',
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: customerProvider.isLoading
                  ? const ShimmerList()
                  : customers.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.people_rounded,
                          title: 'No customers found',
                          subtitle: _searchController.text.isNotEmpty
                              ? 'No results for "${_searchController.text}"'
                              : 'Add your first customer',
                          actionLabel: _searchController.text.isNotEmpty ? null : 'Add Customer',
                          onAction: _searchController.text.isNotEmpty ? null : () => _showCustomerForm(),
                        )
                      : RefreshIndicator(
                          onRefresh: () => customerProvider.loadCustomers(),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: customers.length,
                            itemBuilder: (context, index) {
                              final customer = customers[index];
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.purple.withValues(alpha: 0.1),
                                    child: const Icon(Icons.person, color: Colors.purple),
                                  ),
                                  title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text('${customer.phone}\n${customer.email ?? ''}'),
                                  trailing: PopupMenuButton(
                                    icon: const Icon(Icons.more_vert),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'view',
                                        child: Row(
                                          children: [
                                            Icon(Icons.visibility, size: 18),
                                            SizedBox(width: 8),
                                            Text('View'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 18),
                                            SizedBox(width: 8),
                                            Text('Delete'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (v) {
                                      if (v == 'view') Navigator.pushNamed(context, AppRouter.customerDetail, arguments: customer);
                                      if (v == 'edit') _showCustomerForm(customer: customer);
                                      if (v == 'delete') _deleteCustomer(customer);
                                    },
                                  ),
                                  onTap: () => Navigator.pushNamed(context, AppRouter.customerDetail, arguments: customer),
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

  void _showCustomerForm({Customer? customer}) {
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final emailCtrl = TextEditingController(text: customer?.email ?? '');
    final addressCtrl = TextEditingController(text: customer?.address ?? '');

    bool hasChanges() {
      return nameCtrl.text != (customer?.name ?? '') ||
             phoneCtrl.text != (customer?.phone ?? '') ||
             emailCtrl.text != (customer?.email ?? '') ||
             addressCtrl.text != (customer?.address ?? '');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
          title: Text(customer == null ? 'Add Customer' : 'Edit Customer'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name *', hintText: 'Enter customer name'),
                    onChanged: (_) => formKey.currentState?.validate(),
                    validator: (v) => Validators.required(v, 'Name'),
                  ),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone *', hintText: 'Enter phone number'),
                    onChanged: (_) => formKey.currentState?.validate(),
                    validator: (v) => Validators.phone(v),
                  ),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email', hintText: 'Enter email address'),
                    validator: (v) => v != null && v.isNotEmpty ? Validators.email(v) : null,
                  ),
                  TextFormField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: 'Address', hintText: 'Enter address'),
                    maxLines: 2,
                  ),
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
                  final provider = context.read<CustomerProvider>();
                  final model = Customer(
                    id: customer?.id,
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                    creditLimit: customer?.creditLimit ?? 0.0,
                    openingBalance: customer?.openingBalance ?? 0.0,
                    currentBalance: customer?.currentBalance ?? 0.0,
                    createdAt: customer?.createdAt ?? DateTime.now(),
                  );
                  if (customer == null) {
                    await provider.addCustomer(model);
                    if (context.mounted) AppSnackbar.showSuccess(context, 'Customer added successfully');
                  } else {
                    await provider.updateCustomer(model);
                    if (context.mounted) AppSnackbar.showSuccess(context, 'Customer updated successfully');
                  }
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) AppSnackbar.showError(context, 'Error saving customer: $e');
                }
              },
              child: Text(customer == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    ).then((_) {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      emailCtrl.dispose();
      addressCtrl.dispose();
    });
  }

  void _deleteCustomer(Customer customer) {
    if (customer.id == null) {
      AppSnackbar.showError(context, 'Invalid customer ID');
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Delete ${customer.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<CustomerProvider>().deleteCustomer(customer.id!);
                if (context.mounted) {
                  AppSnackbar.showSuccess(context, 'Customer deleted successfully');
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  AppSnackbar.showError(context, 'Failed to delete customer: $e');
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
