import 'package:flutter/material.dart';
import '../../../models/medicine_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../routes/app_router.dart';

class MedicineDetailScreen extends StatelessWidget {
  final MedicineModel medicine;
  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    final m = medicine;
    return Scaffold(
      appBar: AppBar(
        title: Text(m.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(context, '${AppRouter.inventory}/add', arguments: m),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(context, m),
          const SizedBox(height: 16),
          _infoCard(context, m),
          const SizedBox(height: 16),
          _statusCard(context, m),
        ],
      ),
    );
  }

  Widget _headerCard(BuildContext context, MedicineModel m) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: m.isExpired
                  ? AppColors.error.withValues(alpha: 0.15)
                  : m.isLowStock
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.medication_rounded,
                size: 28,
                color: m.isExpired
                    ? AppColors.error
                    : m.isLowStock
                        ? AppColors.warning
                        : AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  if (m.genericName.isNotEmpty)
                    Text(m.genericName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('${m.stockQuantity} ${m.unit} in stock',
                      style: TextStyle(color: m.isLowStock ? AppColors.warning : AppColors.success, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, MedicineModel m) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Medicine Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(),
            _row('Generic Name', m.genericName.isNotEmpty ? m.genericName : '-'),
            _row('Manufacturer', m.manufacturer.isNotEmpty ? m.manufacturer : '-'),
            _row('Category', m.categoryName ?? '-'),
            if (m.barcode != null && m.barcode!.isNotEmpty) _row('Barcode', m.barcode!),
            _row('Unit', m.unit),
            const SizedBox(height: 8),
            Text('Pricing', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            _row('Purchase Price', Helpers.formatCurrency(m.purchasePrice)),
            _row('Selling Price', Helpers.formatCurrency(m.sellingPrice)),
            if (m.wholesalePrice > 0) _row('Wholesale Price', Helpers.formatCurrency(m.wholesalePrice)),
            const SizedBox(height: 8),
            Text('Stock', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            _row('Current Stock', '${m.stockQuantity} ${m.unit}'),
            _row('Reorder Level', '${m.reorderLevel}'),
            _row('Expiry', m.expiryDate != null ? Helpers.formatDate(m.expiryDate!) : 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(BuildContext context, MedicineModel m) {
    final warnings = <Widget>[];
    if (m.isExpired) {
      warnings.add(_chip(Icons.warning_rounded, 'Expired', AppColors.error));
    }
    if (m.isNearExpiry && !m.isExpired) {
      warnings.add(_chip(Icons.schedule_rounded, 'Near expiry', AppColors.warning));
    }
    if (m.isLowStock) {
      warnings.add(_chip(Icons.inventory_2_rounded, 'Low stock (${m.stockQuantity} ${m.unit})', AppColors.warning));
    }
    if (warnings.isEmpty) {
      return Card(
        color: AppColors.successLight,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
              SizedBox(width: 12),
              Text('All good — no issues', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alerts', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...warnings,
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
