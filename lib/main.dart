import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/database_helper.dart';
import 'core/services/seed_data_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
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
import 'routes/app_transitions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await DatabaseHelper().database;
    await SeedDataService().seedMedicinesIfEmpty();
    NotificationService().checkAndNotify();
  } catch (e) {
    debugPrint('Database init error: $e');
  }
  final themeProvider = ThemeProvider();
  await themeProvider.load();
  runApp(MediOSApp(themeProvider: themeProvider));
}

class MediOSApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  const MediOSApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
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
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
        title: 'MediOS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeProvider.mode,
        initialRoute: AppRouter.login,
        onGenerateRoute: (settings) {
          final args = settings.arguments;
          switch (settings.name) {
            case AppRouter.login:
              return buildRoute(settings, const LoginScreen(), transition: PageTransition.fade);
            case AppRouter.dashboard:
              return buildRoute(settings, const MainShell(initialIndex: 0));
            case AppRouter.inventory:
              return buildRoute(settings, const InventoryScreen());
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
              return MaterialPageRoute(settings: settings, builder: (_) => const SizedBox());
          }
        },
      ),
      ),
    );
  }
}
