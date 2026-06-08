import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sales_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/animated_list_item.dart';
import '../../../core/utils/helpers.dart';
import '../../../routes/app_router.dart';
import '../../../core/services/invoice_service.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesService>().loadSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    final salesService = context.watch<SalesService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Sales History')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRouter.newSale),
        child: const Icon(Icons.add),
      ),
      body: salesService.isLoading
          ? const ShimmerList()
          : salesService.sales.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.shopping_cart_rounded,
                  title: 'No sales yet',
                  subtitle: 'Create your first sale to start tracking revenue',
                  actionLabel: 'New Sale',
                  onAction: () => Navigator.pushNamed(context, AppRouter.newSale),
                )
              : RefreshIndicator(
                  onRefresh: () => salesService.loadSales(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: salesService.sales.length,
                    itemBuilder: (context, index) {
                      final sale = salesService.sales[index];
                      return AnimatedListItem(
                        index: index,
                        child: Card(
                          child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.receipt, color: AppColors.primary),
                          ),
                          title: Text(sale.billNumber,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${sale.customerName ?? 'Walk-in'} | ${Helpers.formatDate(sale.saleDate)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(Helpers.formatCurrency(sale.netAmount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                              Text(sale.paymentMethod.toUpperCase(),
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                          onTap: () => _showSaleDetail(sale.id!),
                        ),
                      ),
                    );
                    },
                  ),
                ),
    );
  }

  void _showSaleDetail(int saleId) async {
    final salesService = context.read<SalesService>();
    final sale = await salesService.getSaleWithItems(saleId);
    if (!mounted || sale == null) return;

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
                Text(sale.billNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(Helpers.formatDate(sale.saleDate)),
              ],
            ),
            const Divider(),
            Text('Customer: ${sale.customerName ?? 'Walk-in'}'),
            const SizedBox(height: 8),
            const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...sale.items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text('${item.medicineName ?? 'Item'} x${item.quantity} = ${Helpers.formatCurrency(item.totalPrice)}'),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(Helpers.formatCurrency(sale.netAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.print, color: AppColors.primary),
                      tooltip: 'Print Invoice',
                      onPressed: () => InvoiceService().printInvoice(sale),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: AppColors.primary),
                      tooltip: 'Share Invoice',
                      onPressed: () => InvoiceService().shareInvoice(sale),
                    ),
                  ],
                ),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
