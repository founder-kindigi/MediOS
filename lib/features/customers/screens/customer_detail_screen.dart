import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/customer_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../sales/services/sales_service.dart';

class CustomerDetailScreen extends StatefulWidget {
  final CustomerModel customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  List<dynamic>? _sales;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSales());
  }

  Future<void> _loadSales() async {
    final salesService = context.read<SalesService>();
    await salesService.loadSales();
    final customerSales = salesService.sales
        .where((s) => s.customerId == widget.customer.id)
        .toList();
    setState(() => _sales = customerSales);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    return Scaffold(
      appBar: AppBar(title: Text(c.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.purple.withValues(alpha: 0.1),
                        child: const Icon(Icons.person, size: 30, color: Colors.purple),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(c.phone, style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (c.email != null && c.email!.isNotEmpty)
                    _infoRow(Icons.email, c.email!),
                  if (c.address != null && c.address!.isNotEmpty)
                    _infoRow(Icons.location_on, c.address!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Purchase History', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_sales == null)
            const Center(child: CircularProgressIndicator())
          else if (_sales!.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No purchases yet')))
          else
            ..._sales!.map((sale) => Card(
              child: ListTile(
                title: Text(sale.billNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(Helpers.formatDate(sale.saleDate)),
                trailing: Text(Helpers.formatCurrency(sale.netAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
              ),
            )),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
