import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'core/database/database_helper.dart';
import 'core/di/service_locator.dart';
import 'core/services/first_time_setup_service.dart';
import 'core/services/seed_data_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/first_time_setup_screen.dart';
import 'features/dashboard/services/dashboard_service.dart';
import 'features/inventory/services/inventory_service.dart';
import 'features/sales/services/sales_service.dart';
import 'features/suppliers/services/supplier_service.dart';
import 'features/customers/services/customer_service.dart';
import 'features/purchase_orders/services/purchase_order_service.dart';
import 'features/reports/services/reports_service.dart';
import 'features/returns/services/return_service.dart';
import 'features/stores/services/store_service.dart';
import 'features/prescriptions/services/prescription_service.dart';
import 'features/orders/services/order_service.dart';
import 'features/settings/services/settings_service.dart';
import 'routes/app_router.dart';
import 'routes/app_transitions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize dependencies
    setupServiceLocator();
    
    // Initialize shared preferences
    final prefs = await SharedPreferences.getInstance();
    
    // Initialize database
    await DatabaseHelper().database;
    
    // Load stores
    await GetIt.instance<StoreService>().loadStores();
    
    // Seed medicines if empty
    await SeedDataService().seedMedicinesIfEmpty();
    
    // Check notifications
    NotificationService().checkAndNotify();
    
    // Load theme preferences
    final themeProvider = ThemeProvider();
    await themeProvider.load();
    
    // Check if first-time setup is required
    final authService = AuthService();
    final setupService = FirstTimeSetupService(
      db: DatabaseHelper(),
      prefs: prefs,
      authService: authService,
    );
    
    final setupRequired = await setupService.checkIfSetupRequired();
    
    runApp(MediOSApp(
      themeProvider: themeProvider,
      authService: authService,
      setupService: setupService,
      setupRequired: setupRequired,
    ));
  } catch (e) {
    debugPrint('Application initialization error: $e');
    // Fallback to basic app if initialization fails
    runApp(const FallbackApp());
  }
}

class MediOSApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  final AuthService authService;
  final FirstTimeSetupService setupService;
  final bool setupRequired;

  const MediOSApp({
    super.key,
    required this.themeProvider,
    required this.authService,
    required this.setupService,
    required this.setupRequired,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: setupService),
        ChangeNotifierProvider(create: (_) => InventoryService()),
        ChangeNotifierProvider(create: (_) => SalesService()),
        ChangeNotifierProvider(create: (_) => SupplierService()),
        ChangeNotifierProvider(create: (_) => CustomerService()),
        ChangeNotifierProvider(create: (_) => DashboardService()),
        ChangeNotifierProvider(create: (_) => PurchaseOrderService()),
        ChangeNotifierProvider(create: (_) => ReportsService()),
        ChangeNotifierProvider(create: (_) => ReturnService()),
        ChangeNotifierProvider(create: (_) => GetIt.instance<StoreService>()),
        ChangeNotifierProvider(create: (_) => PrescriptionService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
        ChangeNotifierProvider(create: (_) => SettingsService()),
      ],
      child: Consumer3<ThemeProvider, AuthService, FirstTimeSetupService>(
        builder: (context, themeProvider, authService, setupService, _) {
          // Determine initial route based on setup status and authentication
          String initialRoute = AppRouter.login;
          
          if (setupRequired) {
            initialRoute = AppRouter.firstTimeSetup;
          } else if (authService.isLoggedIn) {
            initialRoute = AppRouter.dashboard;
          }
          
          return MaterialApp(
            title: 'MediOS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.mode,
            initialRoute: initialRoute,
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(
                    mediaQuery.textScaler.textScaleFactor.clamp(0.8, 1.5),
                  ),
                ),
                child: child!,
              );
            },
            onGenerateRoute: (settings) {
              final args = settings.arguments;
              switch (settings.name) {
                case AppRouter.firstTimeSetup:
                  return buildRoute(
                    settings,
                    const FirstTimeSetupScreen(),
                    transition: PageTransition.fade,
                  );
                case AppRouter.login:
                  return buildRoute(
                    settings,
                    const LoginScreen(),
                    transition: PageTransition.fade,
                  );
                case AppRouter.dashboard:
                  // Return dashboard route - implementation continues...
                  return buildRoute(
                    settings,
                    const LoginScreen(), // Placeholder
                    transition: PageTransition.fade,
                  );
                default:
                  return null;
              }
            },
          );
        },
      ),
    );
  }
}

/// Fallback app if initialization fails
class FallbackApp extends StatelessWidget {
  const FallbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'Application Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Unable to initialize the application. Please try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // In a real app, you might want to restart or show diagnostics
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}