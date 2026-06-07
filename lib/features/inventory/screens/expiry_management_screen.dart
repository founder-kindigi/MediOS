import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/utils/helpers.dart';
import '../../../routes/app_router.dart';
import '../../../models/medicine_model.dart';

class ExpiryManagementScreen extends StatefulWidget {
  const ExpiryManagementScreen({super.key});

  @override
  State<ExpiryManagementScreen> createState() => _ExpiryManagementScreenState();
}

class _ExpiryManagementScreenState extends State<ExpiryManagementScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryService>().loadMedicines();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryService>();
    final all = inventory.medicines;
    final medicines = _filtered(all);
    final cExpired = _count(all, 'expired');
    final cSoon = _count(all, 'soon');
    final cWatch = _count(all, 'watch');
    final cNone = _count(all, 'none');

    return Scaffold(
      appBar: AppBar(title: const Text('Expiry Management')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', 'all'),
                  _filterChip('Expired ($cExpired)', 'expired'),
                  _filterChip('Expiring Soon ($cSoon)', 'soon'),
                  _filterChip('Watch ($cWatch)', 'watch'),
                  _filterChip('No Expiry ($cNone)', 'none'),
                ],
              ),
            ),
          ),
          Expanded(
            child: inventory.isLoading
                ? const Center(child: CircularProgressIndicator())
                : medicines.isEmpty
                    ? const Center(child: Text('No medicines match this filter'))
                    : RefreshIndicator(
                        onRefresh: () => inventory.loadMedicines(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: medicines.length,
                          itemBuilder: (context, index) {
                            final m = medicines[index];
                            final days = _daysRemaining(m);
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _expiryColor(days).withValues(alpha: 0.2),
                                  child: Icon(Icons.calendar_today,
                                      color: _expiryColor(days), size: 20),
                                ),
                                title: Text(m.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  '${m.manufacturer} | Stock: ${m.stockQuantity} ${m.unit}',
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (m.expiryDate != null) ...[
                                      Text(Helpers.formatDate(m.expiryDate!),
                                          style: const TextStyle(fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _expiryColor(days).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _daysLabel(days),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _expiryColor(days),
                                          ),
                                        ),
                                      ),
                                    ] else
                                      const Text('No expiry',
                                          style: TextStyle(
                                              fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '${AppRouter.inventory}/add',
                                    arguments: m,
                                  );
                                },
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

  int _count(List<MedicineModel> all, [String? group]) {
    if (group == null) return all.length;
    return _filtered(all, forceGroup: group).length;
  }

  List<MedicineModel> _filtered(List<MedicineModel> all, {String? forceGroup}) {
    final group = forceGroup ?? _filter;
    switch (group) {
      case 'expired':
        return all.where((m) => m.isExpired).toList()
          ..sort((a, b) => (a.expiryDate ?? DateTime(0)).compareTo(b.expiryDate ?? DateTime(0)));
      case 'soon':
        return all.where((m) => m.isNearExpiry && !m.isExpired).toList()
          ..sort((a, b) => (a.expiryDate ?? DateTime(9999)).compareTo(b.expiryDate ?? DateTime(9999)));
      case 'watch':
        return all.where((m) {
          if (m.expiryDate == null) return false;
          final d = m.expiryDate!.difference(DateTime.now()).inDays;
          return d > 30 && d <= 60;
        }).toList()
          ..sort((a, b) => (a.expiryDate ?? DateTime(9999)).compareTo(b.expiryDate ?? DateTime(9999)));
      case 'none':
        return all.where((m) => m.expiryDate == null).toList();
      default:
        return all.where((m) => m.expiryDate != null).toList()
          ..sort((a, b) => (a.expiryDate ?? DateTime(9999)).compareTo(b.expiryDate ?? DateTime(9999)));
    }
  }

  int _daysRemaining(MedicineModel m) {
    if (m.expiryDate == null) return 9999;
    return m.expiryDate!.difference(DateTime.now()).inDays;
  }

  Color _expiryColor(int days) {
    if (days <= 0) return AppColors.error;
    if (days <= 30) return Colors.orange;
    if (days <= 60) return AppColors.warning;
    return AppColors.success;
  }

  String _daysLabel(int days) {
    if (days <= 0) return 'EXPIRED';
    if (days == 1) return '1 day left';
    if (days <= 30) return '$days days';
    if (days <= 60) return '$days days';
    return 'OK';
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
      ),
    );
  }
}
