import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../routes/app_router.dart';
import '../../features/auth/services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  final void Function(int tabIndex)? onTabSelected;
  final void Function(String route)? onNavigationRequested;
  const AppDrawer({super.key, this.onTabSelected, this.onNavigationRequested});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Drawer(
      width: AppDimensions.drawerWidth,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_pharmacy, size: 28, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  auth.currentUser?.fullName ?? 'User',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  auth.currentUser?.role.toUpperCase() ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          _sectionHeader('Main'),
          _navItem(context, Icons.dashboard_rounded, 'Dashboard', 0),
          _navItem(context, Icons.bar_chart_rounded, 'Reports', null, route: AppRouter.reports),
          _sectionHeader('Inventory'),
          _navItem(context, Icons.medication_rounded, 'All Medicines', 1),
          _navItem(context, Icons.qr_code_scanner_rounded, 'Barcode Scan', null, route: AppRouter.barcodeScan),
          _navItem(context, Icons.calendar_today_rounded, 'Expiry Management', null, route: AppRouter.expiryManagement),
          _navItem(context, Icons.compare_arrows_rounded, 'Stock Adjustment', null, route: AppRouter.stockAdjustment),
          _navItem(context, Icons.swap_vert_rounded, 'Transactions', null, route: AppRouter.transactions),
          _sectionHeader('Sales'),
          _navItem(context, Icons.shopping_cart_rounded, 'Sales', 2),
          _navItem(context, Icons.replay_rounded, 'Returns', null, route: AppRouter.returns),
          _navItem(context, Icons.receipt_long_rounded, 'Orders', null, route: AppRouter.orders),
          _sectionHeader('Relations'),
          _navItem(context, Icons.people_rounded, 'People', 3),
          _navItem(context, Icons.business_rounded, 'Suppliers', null, route: AppRouter.suppliers),
          _navItem(context, Icons.description_rounded, 'Prescriptions', null, route: AppRouter.prescriptions),
          _sectionHeader('System'),
          _navItem(context, Icons.receipt_long_rounded, 'Purchase Orders', null, route: AppRouter.purchaseOrders),
          _navItem(context, Icons.store_rounded, 'Stores', null, route: AppRouter.stores),
          if (auth.isAdmin)
            _navItem(context, Icons.people_outline_rounded, 'Users', null, route: AppRouter.users),
          _navItem(context, Icons.settings_rounded, 'Settings', 4),
          const Divider(),
          Semantics(
            button: true,
            label: 'Logout',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.sm),
              child: TextButton.icon(
                onPressed: () async {
                  try {
                    await auth.logout();
                  } catch (e) {
                    // Suppress error to ensure navigation runs
                  }
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: AppDimensions.iconMd),
                label: const Text('Logout', style: TextStyle(color: AppColors.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDimensions.lg, AppDimensions.md, AppDimensions.lg, AppDimensions.xs),
      child: Text(title, style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textHint,
        letterSpacing: 1.2,
      )),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String title, int? tabIndex, {String? route}) {
    return Semantics(
      button: true,
      label: title,
      child: ListTile(
        leading: Icon(icon, size: AppDimensions.iconMd, color: AppColors.textSecondary),
        title: Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        dense: true,
        onTap: () {
          Navigator.pop(context);
          if (tabIndex != null && onTabSelected != null) {
            onTabSelected!(tabIndex);
          } else if (route != null) {
            if (onNavigationRequested != null) {
              onNavigationRequested!(route);
            } else {
              Navigator.pushNamed(context, route);
            }
          }
        },
      ),
    );
  }
}
