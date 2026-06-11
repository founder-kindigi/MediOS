import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/customer_order_provider.dart';
import '../../../domain/entities/customer_order.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../presentation/providers/medicine_provider.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerOrderProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerOrderProvider>();
    final filtered = _filter == 'all'
        ? provider.orders
        : provider.orders.where((o) => o.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/orders/new').then((_) {
              provider.loadOrders();
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _chip('All', 'all'), const SizedBox(width: 8),
                _chip('Pending', 'pending'), const SizedBox(width: 8),
                _chip('Fulfilled', 'fulfilled'), const SizedBox(width: 8),
                _chip('Cancelled', 'cancelled'),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const ShimmerList()
                : filtered.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.receipt_long_rounded,
                        title: 'No orders found',
                        subtitle: _filter != 'all' ? 'No orders with status "$_filter"' : 'Create your first customer order',
                        actionLabel: _filter != 'all' ? null : 'New Order',
                        onAction: _filter != 'all' ? null : () => Navigator.pushNamed(context, '/orders/new').then((_) {
                          if (mounted) {
                            context.read<CustomerOrderProvider>().loadOrders();
                          }
                        }),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final o = filtered[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _statusColor(o.status).withValues(alpha: 0.2),
                                child: Icon(Icons.receipt_long, color: _statusColor(o.status), size: 20),
                              ),
                              title: Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${o.customerName ?? "Walk-in"} · ${Helpers.formatCurrency(o.totalAmount)} · ${o.items.length} items'),
                              trailing: Chip(
                                label: Text(o.status, style: const TextStyle(fontSize: 11, color: Colors.white)),
                                backgroundColor: _statusColor(o.status),
                                visualDensity: VisualDensity.compact,
                              ),
                              onTap: o.id == null ? null : () => _showDetail(o),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'fulfilled': return Colors.green;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  void _showDetail(CustomerOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _OrderDetailSheet(order: order, provider: context.read<CustomerOrderProvider>()),
    );
  }
}

class _OrderDetailSheet extends StatelessWidget {
  final CustomerOrder order;
  final CustomerOrderProvider provider;

  const _OrderDetailSheet({required this.order, required this.provider});

  @override
  Widget build(BuildContext context) {
    final items = order.items;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          controller: scrollController,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(order.orderNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            _field('Customer', order.customerName ?? 'Walk-in'),
            _field('Date', '${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}'),
            _field('Status', order.status),
            _field('Total', Helpers.formatCurrency(order.totalAmount)),
            if (order.notes != null) _field('Notes', order.notes!),
            const Divider(),
            const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(item.medicineName)),
                  Expanded(flex: 1, child: Text('x${item.quantity}', textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text(Helpers.formatCurrency(item.totalPrice), textAlign: TextAlign.right)),
                ],
              ),
            )),
            const SizedBox(height: 16),
            if (order.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await provider.updateStatus(order.id!, 'fulfilled');
                          if (ctx.mounted) {
                            context.read<MedicineProvider>().refreshMedicines();
                            AppSnackbar.showSuccess(context, 'Order fulfilled');
                            Navigator.pop(ctx);
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            AppSnackbar.showError(context, 'Failed to fulfill order: $e');
                          }
                        }
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Mark Fulfilled'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await provider.updateStatus(order.id!, 'cancelled');
                          if (ctx.mounted) {
                            context.read<MedicineProvider>().refreshMedicines();
                            AppSnackbar.showWarning(context, 'Order cancelled');
                            Navigator.pop(ctx);
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            AppSnackbar.showError(context, 'Failed to cancel order: $e');
                          }
                        }
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
