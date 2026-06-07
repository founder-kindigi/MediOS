import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../../routes/app_router.dart';
import '../../features/auth/services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.local_pharmacy, size: 35, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  auth.currentUser?.fullName ?? 'User',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  auth.currentUser?.role.toUpperCase() ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          _drawerItem(context, Icons.dashboard, 'Dashboard', AppRouter.dashboard),
          _drawerItem(context, Icons.medication, 'Inventory', AppRouter.inventory),
          _drawerItem(context, Icons.shopping_cart, 'Sales', AppRouter.sales),
          _drawerItem(context, Icons.people, 'Suppliers', AppRouter.suppliers),
          _drawerItem(context, Icons.receipt_long, 'Purchase Orders', AppRouter.purchaseOrders),
          _drawerItem(context, Icons.swap_vert, 'Transactions', AppRouter.transactions),
          _drawerItem(context, Icons.person, 'Customers', AppRouter.customers),
          if (auth.isAdmin)
            _drawerItem(context, Icons.people_outline, 'Users', AppRouter.users),
          const Divider(),
          _drawerItem(context, Icons.logout, 'Logout', null, onTap: () {
            auth.logout();
            Navigator.pushReplacementNamed(context, AppRouter.login);
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, String? route, {VoidCallback? onTap}) {
    final isActive = route != null && ModalRoute.of(context)?.settings.name == route;
    return ListTile(
      leading: Icon(icon, color: isActive ? AppColors.primary : null),
      title: Text(title, style: TextStyle(
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        color: isActive ? AppColors.primary : null,
      )),
      selected: isActive,
      onTap: onTap ?? () {
        Navigator.pop(context);
        if (route != null) Navigator.pushReplacementNamed(context, route);
      },
    );
  }
}
