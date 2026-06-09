import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/dashboard_service.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/animated_list_item.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../../core/utils/helpers.dart';
import '../../../routes/app_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardService>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardService>();
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${user?.fullName.split(' ').first ?? 'User'}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text('Today\'s Revenue: ${Helpers.formatCurrency(dashboard.todayRevenue)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => dashboard.loadDashboard(),
          ),
        ],
      ),
      body: ResponsiveWrapper(
        child: dashboard.isLoading
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  const ShimmerGrid(),
                  const SizedBox(height: 20),
                  ShimmerSkeleton(
                    child: Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBase,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => dashboard.loadDashboard(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _buildKpiGrid(dashboard),
                  const SizedBox(height: 20),
                  _buildRevenueChart(dashboard),
                  const SizedBox(height: 20),
                  _buildQuickActions(context),
                  const SizedBox(height: 20),
                  _buildRecentSales(dashboard),
                  const SizedBox(height: 20),
                  _buildAlertsSection(dashboard),
                ],
              ),
            ),
        ),
    );
  }

  // ─── KPI Grid ───────────────────────────────────────────────────────────

  Widget _buildKpiGrid(DashboardService dashboard) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    return GridView.count(
      crossAxisCount: isWide ? 3 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _kpiCard('Revenue', Helpers.formatCurrency(dashboard.totalRevenue), Icons.trending_up_rounded,
            const [Color(0xFF1565C0), Color(0xFF1E88E5)], dashboard.totalRevenue),
        _kpiCard('Sales', '${dashboard.totalSales}', Icons.shopping_cart_rounded,
            const [Color(0xFF00897B), Color(0xFF26A69A)], dashboard.totalSales.toDouble()),
        _kpiCard('Medicines', '${dashboard.totalMedicines}', Icons.medication_rounded,
            const [Color(0xFF10B981), Color(0xFF34D399)], dashboard.totalMedicines.toDouble()),
        _kpiCard('Suppliers', '${dashboard.totalSuppliers}', Icons.business_rounded,
            const [Color(0xFFF59E0B), Color(0xFFFBBF24)], dashboard.totalSuppliers.toDouble()),
        _kpiCard('Customers', '${dashboard.totalCustomers}', Icons.people_rounded,
            const [Color(0xFF8B5CF6), Color(0xFFA78BFA)], dashboard.totalCustomers.toDouble()),
        _kpiCard('Low Stock', '${dashboard.lowStockCount}', Icons.warning_rounded,
            const [Color(0xFFEF4444), Color(0xFFF87171)], dashboard.lowStockCount.toDouble()),
      ],
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, List<Color> gradientColors, double rawValue) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(color: gradientColors.last.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
                  _counterWidget(rawValue),
                ],
              ),
              Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
              Text(title,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _counterWidget(double value) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        if (v >= 1000) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: Text('+${v.toInt()}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 9, fontWeight: FontWeight.w600)),
        );
      },
    );
  }

  // ─── Revenue Chart ──────────────────────────────────────────────────────

  Widget _buildRevenueChart(DashboardService dashboard) {
    final data = dashboard.weeklyRevenue;
    if (data.isEmpty) return const SizedBox.shrink();

    final entries = data.entries.toList();
    final maxY = entries.fold(0.0, (m, e) => e.value > m ? e.value : m);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Weekly Revenue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(Helpers.formatCurrency(dashboard.totalRevenue),
                    style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY * 1.4,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final idx = group.x.toInt();
                        if (idx < 0 || idx >= entries.length) return null;
                        return BarTooltipItem(
                          '${entries[idx].key}\n${Helpers.formatCurrency(rod.toY)}',
                          const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox();
                          return Text('${(value / 1000).toInt()}k',
                              style: const TextStyle(fontSize: 10, color: AppColors.textHint));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= entries.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(entries[idx].key,
                                style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.border.withValues(alpha: 0.5),
                      strokeWidth: 0.5,
                    ),
                  ),
                  barGroups: entries.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value,
                          color: entry.value.value > 0 ? AppColors.primary : AppColors.border,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: entry.value.value > 0,
                            toY: maxY * 1.4,
                            color: AppColors.primary.withValues(alpha: 0.06),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Quick Actions ──────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
        Row(
          children: [
            Expanded(child: _actionCard(context, 'New Sale', Icons.add_shopping_cart_rounded, AppColors.primary, AppRouter.newSale)),
            const SizedBox(width: 12),
            Expanded(child: _actionCard(context, 'Add Medicine', Icons.medication_rounded, AppColors.success, '${AppRouter.inventory}/add')),
            const SizedBox(width: 12),
            Expanded(child: _actionCard(context, 'Purchase', Icons.receipt_long_rounded, AppColors.warning, AppRouter.newPurchaseOrder)),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(BuildContext context, String label, IconData icon, Color color, String route) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Recent Sales ───────────────────────────────────────────────────────

  Widget _buildRecentSales(DashboardService dashboard) {
    final sales = dashboard.recentSales;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Sales', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRouter.sales),
                child: const Text('View All', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
        if (sales.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 40, color: AppColors.textHint.withValues(alpha: 0.4)),
                    const SizedBox(height: 8),
                    Text('No sales yet', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Create your first sale to see it here', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                  ],
                ),
              ),
            ),
          )
        else
          ...sales.asMap().entries.map((e) => _saleRow(e.value, index: e.key)),
      ],
    );
  }

  Widget _saleRow(Map<String, dynamic> sale, {int index = 0}) {
    final amount = (sale['net_amount'] as num?)?.toDouble() ?? 0;
    return AnimatedListItem(
      index: index,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          dense: true,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: const Icon(Icons.receipt_rounded, color: AppColors.primary, size: 18),
          ),
          title: Text(sale['bill_number'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          subtitle: Text(sale['customer_name'] as String? ?? 'Walk-in', style: const TextStyle(fontSize: 12)),
          trailing: Text(Helpers.formatCurrency(amount),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.success)),
        ),
      ),
    );
  }

  // ─── Alerts ─────────────────────────────────────────────────────────────

  Widget _buildAlertsSection(DashboardService dashboard) {
    if (dashboard.lowStockCount == 0 && dashboard.expiredCount == 0) {
      return Card(
        margin: EdgeInsets.zero,
        color: AppColors.successLight,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
              SizedBox(width: 12),
              Text('All clear — no alerts', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w500, fontSize: 14)),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Notifications', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
        if (dashboard.lowStockCount > 0)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: AppColors.warningLight,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: AppColors.warning, size: 20),
              ),
              title: Text('${dashboard.lowStockCount} medicines low on stock',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              subtitle: const Text('Reorder to maintain inventory levels', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textHint),
              onTap: () => Navigator.pushNamed(context, AppRouter.inventory),
            ),
          ),
        if (dashboard.expiredCount > 0)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: AppColors.errorLight,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
              ),
              title: Text('${dashboard.expiredCount} medicines have expired',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              subtitle: const Text('Remove from active inventory', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textHint),
              onTap: () => Navigator.pushNamed(context, AppRouter.inventory),
            ),
          ),
      ],
    );
  }
}
