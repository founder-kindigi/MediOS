import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/customer_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/search_bar_widget.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../../core/utils/validators.dart';
import '../../../models/customer_model.dart';
import '../../../routes/app_router.dart';

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
      context.read<CustomerService>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerService = context.watch<CustomerService>();
    final customers = _searchController.text.isNotEmpty
        ? customerService.searchCustomers(_searchController.text)
        : customerService.customers;

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      drawer: const AppDrawer(),
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
            child: customerService.isLoading
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
                        onRefresh: () => customerService.loadCustomers(),
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
                                    const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('View')])),
                                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18), SizedBox(width: 8), Text('Delete')])),
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

  void _showCustomerForm({CustomerModel? customer}) {
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final emailCtrl = TextEditingController(text: customer?.email ?? '');
    final addressCtrl = TextEditingController(text: customer?.address ?? '');

    showDialog(
      context: context,
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
                  TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *'), validator: (v) => Validators.required(v, 'Name')),
                  TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone *'), validator: (v) => Validators.phone(v)),
                  TextFormField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v != null && v.isNotEmpty ? Validators.email(v) : null),
                  TextFormField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final svc = context.read<CustomerService>();
                final model = CustomerModel(
                  id: customer?.id,
                  name: nameCtrl.text,
                  phone: phoneCtrl.text,
                  email: emailCtrl.text,
                  address: addressCtrl.text,
                );
                if (customer == null) {
                  await svc.addCustomer(model);
                  if (context.mounted) AppSnackbar.showSuccess(context, 'Customer added successfully');
                } else {
                  await svc.updateCustomer(model);
                  if (context.mounted) AppSnackbar.showSuccess(context, 'Customer updated successfully');
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(customer == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCustomer(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Delete ${customer.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<CustomerService>().deleteCustomer(customer.id!);
              AppSnackbar.showSuccess(context, 'Customer deleted');
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
