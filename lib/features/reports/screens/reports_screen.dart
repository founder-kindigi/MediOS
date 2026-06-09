import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/reports_service.dart';
import '../../inventory/services/inventory_service.dart';
import '../../../core/constants/app_colors.dart';

import '../../../core/utils/helpers.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, double>? _monthlyRevenue;
  List<Map<String, dynamic>>? _topMedicines;
  Map<String, double>? _paymentMethods;
  Map<String, double>? _salesSummary;
  Map<String, dynamic>? _inventoryStats;
  bool _loading = true;
  String _selectedTab = 'sales';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final rs = context.read<ReportsService>();
    final inv = context.read<InventoryService>();

    try {
      final results = await Future.wait([
        rs.getMonthlyRevenue(),
        rs.getTopMedicines(),
        rs.getSalesByPaymentMethod(),
        rs.getSalesSummary(),
        rs.getInventoryStats(),
        inv.loadMedicines(),
      ]);

      if (!mounted) return;
      setState(() {
        _monthlyRevenue = results[0] as Map<String, double>;
        _topMedicines = results[1] as List<Map<String, dynamic>>;
        _paymentMethods = results[2] as Map<String, double>;
        _salesSummary = results[3] as Map<String, double>;
        _inventoryStats = results[4] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTabSelector(),
                  const SizedBox(height: 16),
                  if (_selectedTab == 'sales') _buildSalesReport(),
                  if (_selectedTab == 'inventory') _buildInventoryReport(),
                ],
              ),
            ),
    );
  }

  Widget _buildTabSelector() {
    return Row(
      children: [
        Expanded(child: _tabButton('Sales', 'sales')),
        const SizedBox(width: 8),
        Expanded(child: _tabButton('Inventory', 'inventory')),
      ],
    );
  }

  Widget _tabButton(String label, String value) {
    final selected = _selectedTab == value;
    return ElevatedButton(
      onPressed: () => setState(() => _selectedTab = value),
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? AppColors.primary : Colors.grey.shade200,
        foregroundColor: selected ? Colors.white : AppColors.textPrimary,
      ),
      child: Text(label),
    );
  }

  Widget _buildSalesReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow(),
        const SizedBox(height: 24),
        const Text('Monthly Revenue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(height: 220, child: _buildRevenueChart()),
        const SizedBox(height: 24),
        const Text('Top Selling Medicines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._buildTopMedicinesList(),
        const SizedBox(height: 24),
        if (_paymentMethods != null && _paymentMethods!.isNotEmpty) ...[
          const Text('Payment Methods', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._paymentMethods!.entries.map((e) => Card(
            child: ListTile(
              title: Text(e.key.toUpperCase()),
              trailing: Text(Helpers.formatCurrency(e.value),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildSummaryRow() {
    if (_salesSummary == null) return const SizedBox.shrink();
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: [
        _miniCard('Today', Helpers.formatCurrency(_salesSummary!['today'] ?? 0), AppColors.primary),
        _miniCard('This Week', Helpers.formatCurrency(_salesSummary!['week'] ?? 0), AppColors.secondary),
        _miniCard('This Month', Helpers.formatCurrency(_salesSummary!['month'] ?? 0), AppColors.success),
        _miniCard('Total', Helpers.formatCurrency(_salesSummary!['total'] ?? 0), Colors.orange),
      ],
    );
  }

  Widget _miniCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (_monthlyRevenue == null || _monthlyRevenue!.isEmpty) {
      return const Center(child: Text('No revenue data'));
    }

    final sortedMonths = _monthlyRevenue!.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxY = sortedMonths.fold(0.0, (max, e) => e.value > max ? e.value : max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * 1.2,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    '${(value / 1000).toInt()}k',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= sortedMonths.length) return const SizedBox();
                    final monthNum = int.tryParse(sortedMonths[idx].key) ?? 0;
                    return Text(
                      ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][monthNum],
                      style: const TextStyle(fontSize: 9),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: true, drawVerticalLine: false),
            barGroups: sortedMonths.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.value,
                    color: AppColors.primary,
                    width: 16,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTopMedicinesList() {
    if (_topMedicines == null || _topMedicines!.isEmpty) {
      return [const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No sales data')))];
    }
    return _topMedicines!.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final item = entry.value;
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text('$i', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
          title: Text(item['medicine_name'] as String? ?? 'Unknown'),
          subtitle: Text('${item['total_qty']} units sold'),
          trailing: Text(Helpers.formatCurrency((item['total_revenue'] as num).toDouble()),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }).toList();
  }

  Widget _buildInventoryReport() {
    if (_inventoryStats == null) return const SizedBox.shrink();
    final stats = _inventoryStats!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.3,
          children: [
            _miniCard('Total Items', '${stats['totalMedicines']}', AppColors.primary),
            _miniCard('Stock Qty', '${stats['totalStockQty']}', AppColors.secondary),
            _miniCard('Stock Value', Helpers.formatCurrency(stats['totalValue']), AppColors.success),
            _miniCard('Low Stock', '${stats['lowStock']}', AppColors.warning),
            _miniCard('Out of Stock', '${stats['outOfStock']}', AppColors.error),
            _miniCard('Expired', '${stats['expired']}', Colors.red.shade700),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Value Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _legendItem(AppColors.primary, 'In Stock'),
                const SizedBox(width: 16),
                _legendItem(AppColors.warning, 'Low Stock'),
                const SizedBox(width: 16),
                _legendItem(AppColors.error, 'Out/Expired'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
