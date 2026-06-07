import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/dashboard_service.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
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
      appBar: AppBar(title: Text('Welcome, ${user?.fullName ?? 'User'}')),
      drawer: const AppDrawer(),
      body: dashboard.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => dashboard.loadDashboard(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryGrid(dashboard),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _buildAlertsSection(dashboard),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryGrid(DashboardService dashboard) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _summaryCard('Total Revenue', Helpers.formatCurrency(dashboard.totalRevenue), Icons.trending_up, AppColors.primary),
        _summaryCard('Total Sales', '${dashboard.totalSales}', Icons.receipt, AppColors.accent),
        _summaryCard('Medicines', '${dashboard.totalMedicines}', Icons.medication, AppColors.success),
        _summaryCard('Suppliers', '${dashboard.totalSuppliers}', Icons.people, Colors.orange),
        _summaryCard('Customers', '${dashboard.totalCustomers}', Icons.person, Colors.purple),
        _summaryCard('Low Stock', '${dashboard.lowStockCount}', Icons.warning, AppColors.warning),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            _actionButton(context, 'New Sale', Icons.add_shopping_cart, AppRouter.newSale),
            const SizedBox(width: 12),
            _actionButton(context, 'Add Medicine', Icons.medication, '${AppRouter.inventory}/add'),
            const SizedBox(width: 12),
            _actionButton(context, 'New Order', Icons.add_business, AppRouter.newPurchaseOrder),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(BuildContext context, String label, IconData icon, String route) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, route),
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildAlertsSection(DashboardService dashboard) {
    if (dashboard.lowStockCount == 0 && dashboard.expiredCount == 0) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (dashboard.lowStockCount > 0)
          Card(
            color: AppColors.warning.withValues(alpha: 0.1),
            child: ListTile(
              leading: const Icon(Icons.inventory, color: AppColors.warning),
              title: Text('${dashboard.lowStockCount} medicines are low on stock'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pushNamed(context, AppRouter.inventory),
            ),
          ),
        if (dashboard.expiredCount > 0) ...[
          const SizedBox(height: 8),
          Card(
            color: AppColors.error.withValues(alpha: 0.1),
            child: ListTile(
              leading: const Icon(Icons.warning_amber, color: AppColors.error),
              title: Text('${dashboard.expiredCount} medicines have expired'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pushNamed(context, AppRouter.inventory),
            ),
          ),
        ],
      ],
    );
  }
}
