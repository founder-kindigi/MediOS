import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/search_bar_widget.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/animated_list_item.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../../core/widgets/paginated_list_view.dart';
import '../../../core/utils/helpers.dart';
import '../../../routes/app_router.dart';
import '../../../presentation/providers/medicine_provider.dart';

/// Inventory screen with pagination support.
///
/// This screen uses the new MedicineProvider with clean architecture
/// and implements pagination for better performance with large datasets.
class InventoryScreenPaginated extends StatefulWidget {
  const InventoryScreenPaginated({super.key});

  @override
  State<InventoryScreenPaginated> createState() => _InventoryScreenPaginatedState();
}

class _InventoryScreenPaginatedState extends State<InventoryScreenPaginated> 
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _filter = 'all';
  String _currentSearch = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load initial medicines
      final provider = context.read<MedicineProvider>();
      provider.loadMedicines();
    });
    
    // Setup search debouncing
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _currentSearch) {
      _currentSearch = query;
      
      // Debounce search to avoid too many requests
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _currentSearch == query) {
          final provider = context.read<MedicineProvider>();
          provider.searchMedicines(query);
        }
      });
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _filter = filter;
    });
  }

  List<Widget> _getFilteredMedicines(List medicines) {
    List filtered = medicines;
    
    if (_filter == 'low') {
      filtered = medicines.where((m) => m.isLowStock).toList();
    } else if (_filter == 'expired') {
      filtered = medicines.where((m) => m.isExpired).toList();
    } else if (_filter == 'near_expiry') {
      filtered = medicines.where((m) => m.isNearExpiry).toList();
    }
    
    return filtered.map((medicine) {
      return AnimatedListItem(
        key: ValueKey(medicine.id),
        child: _buildMedicineCard(medicine),
      );
    }).toList();
  }

  Widget _buildMedicineCard(medicine) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRouter.medicineDetail,
          arguments: medicine,
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: medicine.isLowStock
                    ? AppColors.warning.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.medication,
                    color: medicine.isLowStock ? AppColors.warning : AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(medicine.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (medicine.genericName.isNotEmpty)
                      Text(medicine.genericName,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('${medicine.stockQuantity} ${medicine.unit} in stock',
                            style: TextStyle(
                                color: medicine.isLowStock ? AppColors.warning : AppColors.success,
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        if (medicine.isLowStock)
                          const Text('LOW',
                              style: TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11)),
                        if (medicine.isExpired)
                          const Text('EXPIRED',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _filter == 'all',
            onSelected: (_) => _applyFilter('all'),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Low Stock'),
            selected: _filter == 'low',
            onSelected: (_) => _applyFilter('low'),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Near Expiry'),
            selected: _filter == 'near_expiry',
            onSelected: (_) => _applyFilter('near_expiry'),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Expired'),
            selected: _filter == 'expired',
            onSelected: (_) => _applyFilter('expired'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                ShimmerSkeleton.circle(radius: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerSkeleton(width: 150, height: 16),
                      SizedBox(height: 4),
                      ShimmerSkeleton(width: 100, height: 12),
                      SizedBox(height: 4),
                      ShimmerSkeleton(width: 80, height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Barcode',
            onPressed: () => Navigator.pushNamed(context, AppRouter.cameraScan),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Medicine',
            onPressed: () => Navigator.pushNamed(
              context,
              '${AppRouter.inventory}/add',
              arguments: null,
            ),
          ),
        ],
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          final medicines = provider.medicines;
          
          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SearchBarWidget(
                  controller: _searchController,
                  hintText: 'Search medicines...',
                  onChanged: (value) {
                    // Handled by listener
                  },
                ),
              ),
              
              // Filter chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildFilterChips(),
              ),
              
              // Statistics (optional - can be loaded separately)
              if (medicines.isNotEmpty && _filter == 'all') ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Chip(
                        label: Text('${medicines.length} items'),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      const SizedBox(width: 8),
                      if (provider.lowStockMedicines.isNotEmpty)
                        Chip(
                          label: Text('${provider.lowStockMedicines.length} low stock'),
                          backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                        ),
                    ],
                  ),
                ),
              ],
              
              // Main list with pagination
              Expanded(
                child: PaginatedListView(
                  items: medicines,
                  itemBuilder: (context, medicine, index) {
                    return _buildMedicineCard(medicine);
                  },
                  isLoading: provider.isLoading && provider.isInitialLoad,
                  isLoadingMore: provider.isLoadingMore,
                  hasMore: provider.hasMore,
                  onLoadMore: () => provider.loadMoreMedicines(),
                  onRefresh: () => provider.refreshMedicines(),
                  errorMessage: provider.error,
                  onRetry: () => provider.loadMedicines(),
                  scrollController: _scrollController,
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                  emptyWidget: EmptyStateWidget(
                    icon: Icons.inventory_2_outlined,
                    title: 'No Medicines Found',
                    subtitle: _currentSearch.isNotEmpty
                        ? 'Try a different search term'
                        : 'Add your first medicine to get started',
                    actionLabel: 'Add Medicine',
                    onAction: () => Navigator.pushNamed(
                      context,
                      '${AppRouter.inventory}/add',
                      arguments: null,
                    ),
                  ),
                  errorWidget: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          provider.error ?? 'Failed to load medicines',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadMedicines(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      
      // Quick actions floating button
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(
          context,
          '${AppRouter.inventory}/add',
          arguments: null,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}