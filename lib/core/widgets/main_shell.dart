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

import '../../features/dashboard/screens/admin_users_screen.dart';
import '../../features/inventory/screens/add_medicine_screen.dart';
import '../../features/inventory/screens/transaction_history_screen.dart';
import '../../features/inventory/screens/stock_adjustment_screen.dart';
import '../../features/inventory/screens/expiry_management_screen.dart';
import '../../features/inventory/screens/barcode_scan_screen.dart';
import '../../features/inventory/screens/camera_barcode_screen.dart';
import '../../features/inventory/screens/medicine_detail_screen.dart';
import '../../features/sales/screens/new_sale_screen.dart';
import '../../features/suppliers/screens/suppliers_screen.dart';
import '../../features/suppliers/screens/supplier_detail_screen.dart';
import '../../features/customers/screens/customers_screen.dart';
import '../../features/customers/screens/customer_detail_screen.dart';
import '../../features/purchase_orders/screens/purchase_orders_screen.dart';
import '../../features/purchase_orders/screens/new_purchase_order_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/stores/screens/store_list_screen.dart';
import '../../features/prescriptions/screens/prescription_list_screen.dart';
import '../../features/prescriptions/screens/new_prescription_screen.dart';
import '../../features/orders/screens/order_list_screen.dart';
import '../../features/orders/screens/new_order_screen.dart';
import '../../features/returns/screens/new_return_screen.dart';
import '../../features/returns/screens/returns_history_screen.dart';
import '../../models/medicine_model.dart';
import '../../models/customer_model.dart';
import '../../models/supplier_model.dart';
import '../../routes/app_transitions.dart';


class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  final _tabKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

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
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= AppDimensions.breakpointTablet;
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: SafeArea(
        child: isWide ? _buildWideLayout(auth) : _buildNarrowLayout(auth),
      ),
      drawer: isWide ? null : AppDrawer(
        onTabSelected: _onTabSelected,
        onNavigationRequested: _onNavigationRequested,
      ),
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
            child: Semantics(
              button: true,
              label: 'Logout',
              child: IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
                tooltip: 'Logout',
                onPressed: () async {
                  try {
                    await auth.logout();
                  } catch (e) {
                    // Suppress error to ensure navigation runs
                  }
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pushReplacementNamed(AppRouter.login);
                  }
                },
              ),
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

  void _onNavigationRequested(String route) {
    _tabKeys[_currentIndex].currentState?.pushNamed(route);
  }

  Route? _onGenerateRouteForTab(int tabIndex, RouteSettings settings, AuthService auth) {
    final args = settings.arguments;

    if (settings.name == '/' || settings.name == '') {
      Widget baseScreen;
      switch (tabIndex) {
        case 0:
          baseScreen = const DashboardScreen();
          break;
        case 1:
          baseScreen = const InventoryScreen();
          break;
        case 2:
          baseScreen = const SalesScreen();
          break;
        case 3:
          baseScreen = _PeopleTab(auth: auth);
          break;
        case 4:
          baseScreen = _MoreTab(auth: auth);
          break;
        default:
          baseScreen = const DashboardScreen();
      }
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => baseScreen,
      );
    }

    switch (settings.name) {
      case AppRouter.inventory:
        return buildRoute(settings, const InventoryScreen());
      case AppRouter.medicineDetail:
        return buildRoute(settings, MedicineDetailScreen(medicine: args as MedicineModel), transition: PageTransition.slideRight);
      case '${AppRouter.inventory}/add':
        return buildRoute(settings, AddMedicineScreen(medicine: args as MedicineModel?), transition: PageTransition.slideUp);
      case AppRouter.stockAdjustment:
        return buildRoute(settings, const StockAdjustmentScreen(), transition: PageTransition.slideUp);
      case AppRouter.expiryManagement:
        return buildRoute(settings, const ExpiryManagementScreen());
      case AppRouter.barcodeScan:
        return buildRoute(settings, const BarcodeScanScreen());
      case AppRouter.cameraScan:
        return buildRoute(settings, const CameraBarcodeScreen());
      case AppRouter.stores:
        return buildRoute(settings, const StoreListScreen());
      case AppRouter.prescriptions:
        return buildRoute(settings, const PrescriptionListScreen());
      case '/prescriptions/new':
        return buildRoute(settings, const NewPrescriptionScreen(), transition: PageTransition.slideUp);
      case AppRouter.orders:
        return buildRoute(settings, const OrderListScreen());
      case '/orders/new':
        return buildRoute(settings, const NewOrderScreen(), transition: PageTransition.slideUp);
      case AppRouter.settings:
        return buildRoute(settings, const SettingsScreen());
      case AppRouter.returns:
        return buildRoute(settings, const ReturnsHistoryScreen());
      case AppRouter.newReturn:
        return buildRoute(settings, const NewReturnScreen(), transition: PageTransition.slideUp);
      case AppRouter.sales:
        return buildRoute(settings, const SalesScreen());
      case AppRouter.newSale:
        return buildRoute(settings, const NewSaleScreen(), transition: PageTransition.slideUp);
      case AppRouter.suppliers:
        return buildRoute(settings, const SuppliersScreen());
      case AppRouter.supplierDetail:
        return buildRoute(settings, SupplierDetailScreen(supplier: args as SupplierModel));
      case AppRouter.customers:
        return buildRoute(settings, const CustomersScreen());
      case AppRouter.customerDetail:
        return buildRoute(settings, CustomerDetailScreen(customer: args as CustomerModel));
      case AppRouter.transactions:
        return buildRoute(settings, const TransactionHistoryScreen());
      case AppRouter.reports:
        return buildRoute(settings, const ReportsScreen());
      case AppRouter.purchaseOrders:
        return buildRoute(settings, const PurchaseOrdersScreen());
      case AppRouter.newPurchaseOrder:
        return buildRoute(settings, const NewPurchaseOrderScreen(), transition: PageTransition.slideUp);
      case AppRouter.users:
        return buildRoute(settings, const AdminUsersScreen());
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Page not found'),
            ),
          ),
        );
    }
  }

  Widget _buildCurrentTab(AuthService auth) {
    return IndexedStack(
      index: _currentIndex,
      children: List.generate(5, (index) {
        final isSelected = index == _currentIndex;
        return PopScope(
          canPop: !isSelected || !(_tabKeys[index].currentState?.canPop() ?? false),
          onPopInvoked: (didPop) async {
            if (didPop) return;
            if (isSelected) {
              final navigator = _tabKeys[index].currentState;
              if (navigator != null && navigator.canPop()) {
                navigator.pop();
              }
            }
          },
          child: Navigator(
            key: _tabKeys[index],
            onGenerateRoute: (settings) => _onGenerateRouteForTab(index, settings, auth),
          ),
        );
      }),
    );
  }

  Widget _buildBottomNav() {
    return Semantics(
      explicitChildNodes: true,
      child: Container(
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
          Semantics(
            button: true,
            label: 'Search',
            child: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
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
    return Semantics(
      button: true,
      label: title,
      hint: subtitle,
      child: Card(
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
            Semantics(
              button: true,
              label: 'Logout',
              child: Center(
                child: TextButton.icon(
                  onPressed: () async {
                    try {
                      await auth.logout();
                    } catch (e) {
                      // Suppress error to ensure navigation runs
                    }
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pushReplacementNamed(AppRouter.login);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: const Text('Logout', style: TextStyle(color: AppColors.error)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _menuCard(BuildContext context, IconData icon, String title, Color color, String route, String subtitle) {
    return Semantics(
      button: true,
      label: title,
      hint: subtitle,
      child: Card(
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
      ),
    );
  }
}
