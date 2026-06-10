import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/search_bar_widget.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/animated_list_item.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../../core/utils/helpers.dart';
import '../../../routes/app_router.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<InventoryService>().loadMedicines();
      } catch (e) {
        if (mounted) {
          AppSnackbar.showError(context, 'Failed to load inventory: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryService>();
    var medicines = inventory.medicines;

    if (_searchController.text.isNotEmpty) {
      medicines = inventory.searchMedicines(_searchController.text);
    }
    if (_filter == 'low') {
      medicines = medicines.where((m) => m.isLowStock).toList();
    } else if (_filter == 'expired') {
      medicines = medicines.where((m) => m.isExpired).toList();
    } else if (_filter == 'near_expiry') {
      medicines = medicines.where((m) => m.isNearExpiry).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Barcode',
            onPressed: () => Navigator.pushNamed(context, AppRouter.barcodeScan),
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'Stock Adjustment',
            onPressed: () => Navigator.pushNamed(context, AppRouter.stockAdjustment),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '${AppRouter.inventory}/add'),
        child: const Icon(Icons.add),
      ),
      body: ResponsiveWrapper(
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SearchBarWidget(
                  controller: _searchController,
                  hintText: 'Search medicines...',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('All', 'all'),
                      _filterChip('Low Stock', 'low'),
                      _filterChip('Near Expiry', 'near_expiry'),
                      _filterChip('Expired', 'expired'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: inventory.isLoading
                ? const ShimmerList()
                : medicines.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.medication_rounded,
                        title: 'No medicines found',
                        subtitle: _searchController.text.isNotEmpty
                            ? 'No results for "${_searchController.text}"'
                            : _filter != 'all'
                                ? 'No medicines match the selected filter'
                                : 'Add your first medicine to get started',
                        actionLabel: _searchController.text.isNotEmpty || _filter != 'all' ? null : 'Add Medicine',
                        onAction: _searchController.text.isNotEmpty || _filter != 'all' ? null : () => Navigator.pushNamed(context, '${AppRouter.inventory}/add'),
                      )
                    : RefreshIndicator(
                        onRefresh: () => inventory.loadMedicines(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: medicines.length,
                          itemBuilder: (context, index) {
                            final medicine = medicines[index];
                            return AnimatedListItem(
                              index: index,
                              child: Card(
                                key: ValueKey(medicine.id),
                                child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: medicine.isLowStock
                                      ? AppColors.warning.withValues(alpha: 0.2)
                                      : AppColors.primary.withValues(alpha: 0.1),
                                  child: Icon(Icons.medication,
                                      color: medicine.isLowStock ? AppColors.warning : AppColors.primary),
                                ),
                                title: Text(medicine.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  '${medicine.genericName} | ${medicine.manufacturer}\nStock: ${medicine.stockQuantity} ${medicine.unit} | ${Helpers.formatCurrency(medicine.sellingPrice)}',
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (medicine.isLowStock)
                                      const Text('LOW', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 11)),
                                    if (medicine.isExpired)
                                      const Text('EXPIRED', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 11)),
                                    if (medicine.isNearExpiry && !medicine.isExpired)
                                      const Text('EXPIRING', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
                                  ],
                                ),
                                onTap: () => Navigator.pushNamed(context, AppRouter.medicineDetail, arguments: medicine),
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

  Widget _filterChip(String label, String value) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
      ),
    );
  }

}
