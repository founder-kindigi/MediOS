import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/database_helper.dart';
import 'core/services/seed_data_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'core/widgets/main_shell.dart';
import 'features/dashboard/screens/admin_users_screen.dart';
import 'features/dashboard/services/dashboard_service.dart';
import 'features/inventory/screens/inventory_screen.dart';
import 'features/inventory/screens/add_medicine_screen.dart';
import 'features/inventory/screens/transaction_history_screen.dart';
import 'features/inventory/screens/stock_adjustment_screen.dart';
import 'features/inventory/screens/expiry_management_screen.dart';
import 'features/inventory/screens/barcode_scan_screen.dart';
import 'features/inventory/screens/camera_barcode_screen.dart';
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
import 'features/reports/screens/reports_screen.dart';
import 'features/reports/services/reports_service.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/settings/services/settings_service.dart';
import 'features/stores/screens/store_list_screen.dart';
import 'features/stores/services/store_service.dart';
import 'features/prescriptions/screens/prescription_list_screen.dart';
import 'features/prescriptions/screens/new_prescription_screen.dart';
import 'features/prescriptions/services/prescription_service.dart';
import 'features/orders/screens/order_list_screen.dart';
import 'features/orders/screens/new_order_screen.dart';
import 'features/orders/services/order_service.dart';
import 'features/returns/screens/new_return_screen.dart';
import 'features/returns/screens/returns_history_screen.dart';
import 'features/returns/services/return_service.dart';
import 'models/medicine_model.dart';
import 'models/customer_model.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await DatabaseHelper().database;
    await SeedDataService().seedMedicinesIfEmpty();
    NotificationService().checkAndNotify();
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
        ChangeNotifierProvider(create: (_) => ReportsService()),
        ChangeNotifierProvider(create: (_) => ReturnService()),
        ChangeNotifierProvider(create: (_) => StoreService()),
        ChangeNotifierProvider(create: (_) => PrescriptionService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
        ChangeNotifierProvider(create: (_) => SettingsService()),
      ],
      child: MaterialApp(
        title: 'MediOS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRouter.login,
        routes: {
          AppRouter.login: (_) => const LoginScreen(),
          AppRouter.dashboard: (_) => const MainShell(initialIndex: 0),
          AppRouter.inventory: (_) => const InventoryScreen(),
          '${AppRouter.inventory}/add': (ctx) => AddMedicineScreen(medicine: ModalRoute.of(ctx)?.settings.arguments as MedicineModel?),
          AppRouter.stockAdjustment: (_) => const StockAdjustmentScreen(),
          AppRouter.expiryManagement: (_) => const ExpiryManagementScreen(),
          AppRouter.barcodeScan: (_) => const BarcodeScanScreen(),
          AppRouter.cameraScan: (_) => const CameraBarcodeScreen(),
          AppRouter.stores: (_) => const StoreListScreen(),
          AppRouter.prescriptions: (_) => const PrescriptionListScreen(),
          '/prescriptions/new': (_) => const NewPrescriptionScreen(),
          AppRouter.orders: (_) => const OrderListScreen(),
          '/orders/new': (_) => const NewOrderScreen(),
          AppRouter.settings: (_) => const SettingsScreen(),
          AppRouter.returns: (_) => const ReturnsHistoryScreen(),
          AppRouter.newReturn: (_) => const NewReturnScreen(),
          AppRouter.sales: (_) => const SalesScreen(),
          AppRouter.newSale: (_) => const NewSaleScreen(),
          AppRouter.suppliers: (_) => const SuppliersScreen(),
          AppRouter.customers: (_) => const CustomersScreen(),
          AppRouter.customerDetail: (ctx) => CustomerDetailScreen(customer: ModalRoute.of(ctx)?.settings.arguments as CustomerModel),
          AppRouter.transactions: (_) => const TransactionHistoryScreen(),
          AppRouter.reports: (_) => const ReportsScreen(),
          AppRouter.purchaseOrders: (_) => const PurchaseOrdersScreen(),
          AppRouter.newPurchaseOrder: (_) => const NewPurchaseOrderScreen(),
          AppRouter.users: (_) => const AdminUsersScreen(),
        },
      ),
    );
  }
}
