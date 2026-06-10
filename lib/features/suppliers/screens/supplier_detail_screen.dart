import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/supplier_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../purchase_orders/services/purchase_order_service.dart';

class SupplierDetailScreen extends StatefulWidget {
  final SupplierModel supplier;
  const SupplierDetailScreen({super.key, required this.supplier});

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  List<dynamic>? _orders;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  Future<void> _loadOrders() async {
    if (widget.supplier.id == null) {
      if (mounted) setState(() => _orders = []);
      return;
    }
    final svc = context.read<PurchaseOrderService>();
    try {
      final supplierOrders = await svc.getOrdersBySupplier(widget.supplier.id!);
      if (mounted) setState(() => _orders = supplierOrders);
    } catch (e) {
      if (mounted) {
        setState(() => _orders = []);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading orders: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.supplier;
    return Scaffold(
      appBar: AppBar(title: Text(s.name)),
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
                        radius: 28,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.business_rounded, size: 28, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(s.phone, style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (s.contactPerson != null && s.contactPerson!.isNotEmpty)
                    _row(Icons.person, s.contactPerson!),
                  if (s.email != null && s.email!.isNotEmpty)
                    _row(Icons.email, s.email!),
                  if (s.address != null && s.address!.isNotEmpty)
                    _row(Icons.location_on, s.address!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Purchase Orders', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_orders == null)
            const Center(child: CircularProgressIndicator())
          else if (_orders!.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No purchase orders yet')))
          else
            ..._orders!.map((o) => Card(
              child: ListTile(
                title: Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(Helpers.formatDate(o.orderDate)),
                trailing: Text(Helpers.formatCurrency(o.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
              ),
            )),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
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
