import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/database_helper.dart';
import 'core/services/seed_data_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/dashboard/screens/admin_users_screen.dart';
import 'features/dashboard/services/dashboard_service.dart';
import 'features/inventory/screens/inventory_screen.dart';
import 'features/inventory/screens/add_medicine_screen.dart';
import 'features/inventory/screens/transaction_history_screen.dart';
import 'features/inventory/services/inventory_service.dart';
import 'features/sales/screens/sales_screen.dart';
import 'features/sales/screens/new_sale_screen.dart';
import 'features/sales/services/sales_service.dart';
import 'features/suppliers/screens/suppliers_screen.dart';
import 'features/suppliers/services/supplier_service.dart';
import 'features/customers/screens/customers_screen.dart';
import 'features/customers/screens/customer_detail_screen.dart';
import 'features/customers/services/customer_service.dart';
import 'features/purchase_orders/screens/purchase_orders_screen.dart';
import 'features/purchase_orders/screens/new_purchase_order_screen.dart';
import 'features/purchase_orders/services/purchase_order_service.dart';
import 'models/medicine_model.dart';
import 'models/customer_model.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await DatabaseHelper().database;
    await SeedDataService().seedMedicinesIfEmpty();
  } catch (e) {
    debugPrint('Database init error: $e');
  }
  runApp(const MediOSApp());
}

class MediOSApp extends StatelessWidget {
  const MediOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => InventoryService()),
        ChangeNotifierProvider(create: (_) => SalesService()),
        ChangeNotifierProvider(create: (_) => SupplierService()),
        ChangeNotifierProvider(create: (_) => CustomerService()),
        ChangeNotifierProvider(create: (_) => DashboardService()),
        ChangeNotifierProvider(create: (_) => PurchaseOrderService()),
      ],
      child: MaterialApp(
        title: 'MediOS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRouter.login,
        routes: {
          AppRouter.login: (_) => const LoginScreen(),
          AppRouter.dashboard: (_) => const DashboardScreen(),
          AppRouter.inventory: (_) => const InventoryScreen(),
          '${AppRouter.inventory}/add': (ctx) => AddMedicineScreen(medicine: ModalRoute.of(ctx)?.settings.arguments as MedicineModel?),
          AppRouter.sales: (_) => const SalesScreen(),
          AppRouter.newSale: (_) => const NewSaleScreen(),
          AppRouter.suppliers: (_) => const SuppliersScreen(),
          AppRouter.customers: (_) => const CustomersScreen(),
          AppRouter.customerDetail: (ctx) => CustomerDetailScreen(customer: ModalRoute.of(ctx)?.settings.arguments as CustomerModel),
          AppRouter.transactions: (_) => const TransactionHistoryScreen(),
          AppRouter.purchaseOrders: (_) => const PurchaseOrdersScreen(),
          AppRouter.newPurchaseOrder: (_) => const NewPurchaseOrderScreen(),
          AppRouter.users: (_) => const AdminUsersScreen(),
        },
      ),
    );
  }
}
