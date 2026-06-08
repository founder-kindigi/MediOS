import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_drawer.dart';
import '../../routes/app_router.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/inventory/screens/inventory_screen.dart';
import '../../features/sales/screens/sales_screen.dart';


class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  final _tabKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  static final List<_TabConfig> _tabs = [
    _TabConfig(0, 'Dashboard', Icons.dashboard_rounded),
    _TabConfig(1, 'Inventory', Icons.medication_rounded),
    _TabConfig(2, 'Sales', Icons.shopping_cart_rounded),
    _TabConfig(3, 'People', Icons.people_rounded),
    _TabConfig(4, 'More', Icons.more_horiz_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) {
      _tabKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= AppDimensions.breakpointTablet;
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: SafeArea(
        child: isWide ? _buildWideLayout(auth) : _buildNarrowLayout(auth),
      ),
      drawer: isWide ? null : AppDrawer(onTabSelected: _onTabSelected),
      bottomNavigationBar: isWide ? null : _buildBottomNav(),
    );
  }

  Widget _buildWideLayout(AuthService auth) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabSelected,
          labelType: NavigationRailLabelType.all,
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                const Icon(Icons.local_pharmacy, size: 32, color: AppColors.primary),
                const SizedBox(height: 4),
                Text('MediOS', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          destinations: _tabs.map((t) => NavigationRailDestination(
            icon: Icon(t.icon),
            selectedIcon: Icon(t.icon, color: AppColors.primary),
            label: Text(t.label, style: const TextStyle(fontSize: 12)),
          )).toList(),
          trailing: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
              tooltip: 'Logout',
              onPressed: () {
                auth.logout();
                Navigator.pushReplacementNamed(context, AppRouter.login);
              },
            ),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: _buildCurrentTab(auth)),
      ],
    );
  }

  Widget _buildNarrowLayout(AuthService auth) {
    return _buildCurrentTab(auth);
  }

  Widget _buildCurrentTab(AuthService auth) {
    switch (_currentIndex) {
      case 0: return DashboardScreen();
      case 1: return InventoryScreen();
      case 2: return SalesScreen();
      case 3: return _PeopleTab(auth: auth);
      case 4: return _MoreTab(auth: auth);
      default: return DashboardScreen();
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: _tabs.map((t) => BottomNavigationBarItem(
          icon: Icon(t.icon),
          activeIcon: Icon(t.icon, size: 26),
          label: t.label,
        )).toList(),
      ),
    );
  }
}

class _TabConfig {
  final int index;
  final String label;
  final IconData icon;
  const _TabConfig(this.index, this.label, this.icon);
}

// --- People Tab ---
class _PeopleTab extends StatelessWidget {
  final AuthService auth;
  const _PeopleTab({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        children: [
          _menuCard(context, Icons.person_rounded, 'Customers', AppColors.primary, AppRouter.customers, 'Manage customer records'),
          const SizedBox(height: 12),
          _menuCard(context, Icons.business_rounded, 'Suppliers', AppColors.secondary, AppRouter.suppliers, 'Manage supplier records'),
          const SizedBox(height: 12),
          _menuCard(context, Icons.description_rounded, 'Prescriptions', const Color(0xFF8B5CF6), AppRouter.prescriptions, 'Patient prescriptions'),
          if (auth.isAdmin) ...[
            const SizedBox(height: 12),
            _menuCard(context, Icons.people_outline_rounded, 'Users', Colors.amber, AppRouter.users, 'Manage system users'),
          ],
        ],
      ),
    );
  }

  Widget _menuCard(BuildContext context, IconData icon, String title, Color color, String route, String subtitle) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}

// --- More Tab ---
class _MoreTab extends StatelessWidget {
  final AuthService auth;
  const _MoreTab({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        children: [
          _menuCard(context, Icons.bar_chart_rounded, 'Reports', AppColors.info, AppRouter.reports, 'Analytics and insights'),
          const SizedBox(height: 12),
          _menuCard(context, Icons.receipt_long_rounded, 'Purchase Orders', Colors.orange, AppRouter.purchaseOrders, 'Supplier purchase orders'),
          const SizedBox(height: 12),
          _menuCard(context, Icons.replay_rounded, 'Returns', AppColors.error, AppRouter.returns, 'Sale returns and refunds'),
          const SizedBox(height: 12),
          _menuCard(context, Icons.store_rounded, 'Stores', const Color(0xFF6D4C41), AppRouter.stores, 'Manage store locations'),
          const SizedBox(height: 12),
          _menuCard(context, Icons.settings_rounded, 'Settings', AppColors.textSecondary, AppRouter.settings, 'App configuration'),
          if (auth.isLoggedIn) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  auth.logout();
                  Navigator.pushReplacementNamed(context, AppRouter.login);
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text('Logout', style: TextStyle(color: AppColors.error)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _menuCard(BuildContext context, IconData icon, String title, Color color, String route, String subtitle) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
