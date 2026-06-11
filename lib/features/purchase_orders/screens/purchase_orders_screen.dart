import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/purchase_order_provider.dart';
import '../../../domain/entities/purchase_order.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/utils/helpers.dart';
import '../../../routes/app_router.dart';
import '../../../presentation/providers/medicine_provider.dart';

class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseOrderProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final poProvider = context.watch<PurchaseOrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Orders')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRouter.newPurchaseOrder),
        child: const Icon(Icons.add),
      ),
      body: poProvider.isLoading
          ? const ShimmerList()
          : poProvider.orders.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.receipt_long_rounded,
                  title: 'No purchase orders yet',
                  subtitle: 'Create a purchase order to track supplier deliveries',
                  actionLabel: 'New Purchase Order',
                  onAction: () => Navigator.pushNamed(context, AppRouter.newPurchaseOrder),
                )
              : RefreshIndicator(
                  onRefresh: () => poProvider.loadOrders(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: poProvider.orders.length,
                    itemBuilder: (context, index) {
                      final order = poProvider.orders[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _statusColor(order.status).withValues(alpha: 0.1),
                            child: Icon(Icons.receipt_long, color: _statusColor(order.status)),
                          ),
                          title: Text(order.orderNumber,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${order.supplierName ?? 'Unknown Supplier'}\n${Helpers.formatDate(order.orderDate)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(Helpers.formatCurrency(order.totalAmount),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(order.status.toUpperCase(),
                                  style: TextStyle(fontSize: 11, color: _statusColor(order.status))),
                            ],
                          ),
                          onTap: order.id == null ? null : () => _showOrderDetail(order.id!),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'received': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  void _showOrderDetail(int orderId) async {
    final poProvider = context.read<PurchaseOrderProvider>();
    final order = await poProvider.getOrderWithItems(orderId);
    if (!mounted || order == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.orderNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(order.status.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: _statusColor(order.status),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const Divider(),
            Text('Supplier: ${order.supplierName ?? 'N/A'}'),
            Text('Date: ${Helpers.formatDate(order.orderDate)}'),
            const SizedBox(height: 8),
            const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text('${item.medicineName ?? 'Item'} x${item.quantity} = ${Helpers.formatCurrency(item.totalPrice)}'),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(Helpers.formatCurrency(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            if (order.status == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        await poProvider.updateStatus(order.id!, 'received');
                        if (context.mounted) {
                          context.read<MedicineProvider>().refreshMedicines();
                          AppSnackbar.showSuccess(context, 'Order marked as received');
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppSnackbar.showError(context, 'Failed to update status: $e');
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.success),
                    child: const Text('Mark Received'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        await poProvider.updateStatus(order.id!, 'cancelled');
                        if (context.mounted) {
                          context.read<MedicineProvider>().refreshMedicines();
                          AppSnackbar.showWarning(context, 'Purchase order cancelled');
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppSnackbar.showError(context, 'Failed to update status: $e');
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
