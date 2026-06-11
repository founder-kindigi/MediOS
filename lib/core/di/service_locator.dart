import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../services/first_time_setup_service.dart';
import '../services/backup_service.dart';
import '../security/secure_storage_service.dart';
import '../security/rate_limiter.dart';
import '../../features/auth/services/biometric_auth_service.dart';
import '../../features/auth/services/permission_service.dart';
import '../../features/customers/services/customer_credit_service.dart';

// Domain Repositories
import '../../domain/repositories/medicine_repository.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/repositories/purchase_order_repository.dart';
import '../../domain/repositories/return_repository.dart';
import '../../domain/repositories/customer_order_repository.dart';
import '../../domain/repositories/prescription_repository.dart';

// Data Sources & Repository Implementations
import '../../data/datasources/local/medicine_local_data_source.dart';
import '../../data/repositories/medicine_repository_impl.dart';

import '../../data/datasources/local/customer_local_data_source.dart';
import '../../data/repositories/customer_repository_impl.dart';

import '../../data/datasources/local/supplier_local_data_source.dart';
import '../../data/repositories/supplier_repository_impl.dart';

import '../../data/datasources/local/sale_local_data_source.dart';
import '../../data/repositories/sale_repository_impl.dart';

import '../../data/datasources/local/purchase_order_local_data_source.dart';
import '../../data/repositories/purchase_order_repository_impl.dart';

import '../../data/datasources/local/return_local_data_source.dart';
import '../../data/repositories/return_repository_impl.dart';

import '../../data/datasources/local/customer_order_local_data_source.dart';
import '../../data/repositories/customer_order_repository_impl.dart';

import '../../data/datasources/local/prescription_local_data_source.dart';
import '../../data/repositories/prescription_repository_impl.dart';

// Use Cases
import '../../domain/usecases/medicine_usecases.dart';
import '../../domain/usecases/customer_usecases.dart';
import '../../domain/usecases/supplier_usecases.dart';
import '../../domain/usecases/sale_usecases.dart';
import '../../domain/usecases/purchase_order_usecases.dart';
import '../../domain/usecases/return_usecases.dart';
import '../../domain/usecases/customer_order_usecases.dart';
import '../../domain/usecases/prescription_usecases.dart';

// Presentation Providers
import '../../presentation/providers/medicine_provider.dart';
import '../../presentation/providers/customer_provider.dart';
import '../../presentation/providers/supplier_provider.dart';
import '../../presentation/providers/sales_provider.dart';
import '../../presentation/providers/purchase_order_provider.dart';
import '../../presentation/providers/return_provider.dart';
import '../../presentation/providers/customer_order_provider.dart';
import '../../presentation/providers/prescription_provider.dart';

// Features (legacy services - to be refactored)
import '../../features/auth/services/auth_service.dart';
import '../../features/stores/services/store_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Core services
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
  
  // Async initialization
  getIt.registerSingletonAsync<SharedPreferences>(
    () => SharedPreferences.getInstance(),
  );
  
  // Data Sources
  getIt.registerLazySingleton<MedicineLocalDataSource>(
    () => MedicineLocalDataSourceImpl(databaseHelper: getIt<DatabaseHelper>()),
  );
  getIt.registerLazySingleton<CustomerLocalDataSource>(
    () => CustomerLocalDataSource(databaseHelper: getIt<DatabaseHelper>()),
  );
  getIt.registerLazySingleton<SupplierLocalDataSource>(
    () => SupplierLocalDataSource(databaseHelper: getIt<DatabaseHelper>()),
  );
  getIt.registerLazySingleton<SaleLocalDataSource>(
    () => SaleLocalDataSource(databaseHelper: getIt<DatabaseHelper>()),
  );
  getIt.registerLazySingleton<PurchaseOrderLocalDataSource>(
    () => PurchaseOrderLocalDataSource(getIt<DatabaseHelper>()),
  );
  getIt.registerLazySingleton<ReturnLocalDataSource>(
    () => ReturnLocalDataSource(getIt<DatabaseHelper>()),
  );
  getIt.registerLazySingleton<CustomerOrderLocalDataSource>(
    () => CustomerOrderLocalDataSource(getIt<DatabaseHelper>()),
  );
  getIt.registerLazySingleton<PrescriptionLocalDataSource>(
    () => PrescriptionLocalDataSource(getIt<DatabaseHelper>()),
  );
  
  // Repositories
  getIt.registerLazySingleton<MedicineRepository>(
    () => MedicineRepositoryImpl(
      localDataSource: getIt<MedicineLocalDataSource>(),
    ),
  );
  getIt.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(
      localDataSource: getIt<CustomerLocalDataSource>(),
      permissionService: getIt<PermissionService>(),
    ),
  );
  getIt.registerLazySingleton<SupplierRepository>(
    () => SupplierRepositoryImpl(
      localDataSource: getIt<SupplierLocalDataSource>(),
      permissionService: getIt<PermissionService>(),
    ),
  );
  getIt.registerLazySingleton<SaleRepository>(
    () => SaleRepositoryImpl(
      localDataSource: getIt<SaleLocalDataSource>(),
      permissionService: getIt<PermissionService>(),
    ),
  );
  getIt.registerLazySingleton<PurchaseOrderRepository>(
    () => PurchaseOrderRepositoryImpl(
      localDataSource: getIt<PurchaseOrderLocalDataSource>(),
      permissionService: getIt<PermissionService>(),
    ),
  );
  getIt.registerLazySingleton<ReturnRepository>(
    () => ReturnRepositoryImpl(
      localDataSource: getIt<ReturnLocalDataSource>(),
      permissionService: getIt<PermissionService>(),
    ),
  );
  getIt.registerLazySingleton<CustomerOrderRepository>(
    () => CustomerOrderRepositoryImpl(
      localDataSource: getIt<CustomerOrderLocalDataSource>(),
      permissionService: getIt<PermissionService>(),
    ),
  );
  getIt.registerLazySingleton<PrescriptionRepository>(
    () => PrescriptionRepositoryImpl(
      localDataSource: getIt<PrescriptionLocalDataSource>(),
      permissionService: getIt<PermissionService>(),
    ),
  );
  
  // Medicine Use Cases
  getIt.registerLazySingleton<GetAllMedicinesUseCase>(
    () => GetAllMedicinesUseCase(repository: getIt<MedicineRepository>()),
  );
  getIt.registerLazySingleton<GetMedicineByIdUseCase>(
    () => GetMedicineByIdUseCase(repository: getIt<MedicineRepository>()),
  );
  getIt.registerLazySingleton<AddMedicineUseCase>(
    () => AddMedicineUseCase(repository: getIt<MedicineRepository>()),
  );
  getIt.registerLazySingleton<UpdateMedicineUseCase>(
    () => UpdateMedicineUseCase(repository: getIt<MedicineRepository>()),
  );
  getIt.registerLazySingleton<DeleteMedicineUseCase>(
    () => DeleteMedicineUseCase(repository: getIt<MedicineRepository>()),
  );
  getIt.registerLazySingleton<UpdateMedicineStockUseCase>(
    () => UpdateMedicineStockUseCase(repository: getIt<MedicineRepository>()),
  );
  getIt.registerLazySingleton<SearchMedicinesUseCase>(
    () => SearchMedicinesUseCase(repository: getIt<MedicineRepository>()),
  );
  getIt.registerLazySingleton<GetLowStockMedicinesUseCase>(
    () => GetLowStockMedicinesUseCase(repository: getIt<MedicineRepository>()),
  );
  getIt.registerLazySingleton<GetNearExpiryMedicinesUseCase>(
    () => GetNearExpiryMedicinesUseCase(repository: getIt<MedicineRepository>()),
  );
  getIt.registerLazySingleton<GetExpiredMedicinesUseCase>(
    () => GetExpiredMedicinesUseCase(repository: getIt<MedicineRepository>()),
  );
  getIt.registerLazySingleton<GetMedicineCountByCategoryUseCase>(
    () => GetMedicineCountByCategoryUseCase(repository: getIt<MedicineRepository>()),
  );
  getIt.registerLazySingleton<GetInventoryValueUseCase>(
    () => GetInventoryValueUseCase(repository: getIt<MedicineRepository>()),
  );
  
  // Customer Use Cases
  getIt.registerLazySingleton<GetAllCustomersUseCase>(
    () => GetAllCustomersUseCase(repository: getIt<CustomerRepository>()),
  );
  getIt.registerLazySingleton<GetCustomerByIdUseCase>(
    () => GetCustomerByIdUseCase(repository: getIt<CustomerRepository>()),
  );
  getIt.registerLazySingleton<AddCustomerUseCase>(
    () => AddCustomerUseCase(repository: getIt<CustomerRepository>()),
  );
  getIt.registerLazySingleton<UpdateCustomerUseCase>(
    () => UpdateCustomerUseCase(repository: getIt<CustomerRepository>()),
  );
  getIt.registerLazySingleton<DeleteCustomerUseCase>(
    () => DeleteCustomerUseCase(repository: getIt<CustomerRepository>()),
  );
  getIt.registerLazySingleton<UpdateCustomerCreditLimitUseCase>(
    () => UpdateCustomerCreditLimitUseCase(repository: getIt<CustomerRepository>()),
  );
  getIt.registerLazySingleton<SetCustomerOpeningBalanceUseCase>(
    () => SetCustomerOpeningBalanceUseCase(repository: getIt<CustomerRepository>()),
  );
  getIt.registerLazySingleton<GetCustomerLedgerUseCase>(
    () => GetCustomerLedgerUseCase(repository: getIt<CustomerRepository>()),
  );
  getIt.registerLazySingleton<GetCustomerPaymentsUseCase>(
    () => GetCustomerPaymentsUseCase(repository: getIt<CustomerRepository>()),
  );
  getIt.registerLazySingleton<GetCustomerCreditSummaryUseCase>(
    () => GetCustomerCreditSummaryUseCase(repository: getIt<CustomerRepository>()),
  );
  getIt.registerLazySingleton<GetOverdueCustomersUseCase>(
    () => GetOverdueCustomersUseCase(repository: getIt<CustomerRepository>()),
  );
  getIt.registerLazySingleton<GetRecentCreditTransactionsUseCase>(
    () => GetRecentCreditTransactionsUseCase(repository: getIt<CustomerRepository>()),
  );
  getIt.registerLazySingleton<RecordCustomerPaymentUseCase>(
    () => RecordCustomerPaymentUseCase(repository: getIt<CustomerRepository>()),
  );

  // Supplier Use Cases
  getIt.registerLazySingleton<GetAllSuppliersUseCase>(
    () => GetAllSuppliersUseCase(repository: getIt<SupplierRepository>()),
  );
  getIt.registerLazySingleton<GetSupplierByIdUseCase>(
    () => GetSupplierByIdUseCase(repository: getIt<SupplierRepository>()),
  );
  getIt.registerLazySingleton<AddSupplierUseCase>(
    () => AddSupplierUseCase(repository: getIt<SupplierRepository>()),
  );
  getIt.registerLazySingleton<UpdateSupplierUseCase>(
    () => UpdateSupplierUseCase(repository: getIt<SupplierRepository>()),
  );
  getIt.registerLazySingleton<DeleteSupplierUseCase>(
    () => DeleteSupplierUseCase(repository: getIt<SupplierRepository>()),
  );

  // Sale Use Cases
  getIt.registerLazySingleton<GetSalesUseCase>(
    () => GetSalesUseCase(repository: getIt<SaleRepository>()),
  );
  getIt.registerLazySingleton<GetSalesByCustomerUseCase>(
    () => GetSalesByCustomerUseCase(repository: getIt<SaleRepository>()),
  );
  getIt.registerLazySingleton<CreateSaleUseCase>(
    () => CreateSaleUseCase(repository: getIt<SaleRepository>()),
  );
  getIt.registerLazySingleton<GetSaleWithItemsUseCase>(
    () => GetSaleWithItemsUseCase(repository: getIt<SaleRepository>()),
  );
  getIt.registerLazySingleton<GetTodaySalesSummaryUseCase>(
    () => GetTodaySalesSummaryUseCase(repository: getIt<SaleRepository>()),
  );

  // Purchase Order Use Cases
  getIt.registerLazySingleton<LoadPurchaseOrdersUseCase>(
    () => LoadPurchaseOrdersUseCase(getIt<PurchaseOrderRepository>()),
  );
  getIt.registerLazySingleton<GetOrdersBySupplierUseCase>(
    () => GetOrdersBySupplierUseCase(getIt<PurchaseOrderRepository>()),
  );
  getIt.registerLazySingleton<CreatePurchaseOrderUseCase>(
    () => CreatePurchaseOrderUseCase(getIt<PurchaseOrderRepository>()),
  );
  getIt.registerLazySingleton<GetPurchaseOrderWithItemsUseCase>(
    () => GetPurchaseOrderWithItemsUseCase(getIt<PurchaseOrderRepository>()),
  );
  getIt.registerLazySingleton<UpdatePurchaseOrderStatusUseCase>(
    () => UpdatePurchaseOrderStatusUseCase(getIt<PurchaseOrderRepository>()),
  );
  getIt.registerLazySingleton<DeletePurchaseOrderUseCase>(
    () => DeletePurchaseOrderUseCase(getIt<PurchaseOrderRepository>()),
  );

  // Return Use Cases
  getIt.registerLazySingleton<LoadReturnsUseCase>(
    () => LoadReturnsUseCase(getIt<ReturnRepository>()),
  );
  getIt.registerLazySingleton<ProcessReturnUseCase>(
    () => ProcessReturnUseCase(getIt<ReturnRepository>()),
  );
  getIt.registerLazySingleton<GetReturnWithItemsUseCase>(
    () => GetReturnWithItemsUseCase(getIt<ReturnRepository>()),
  );
  getIt.registerLazySingleton<GetTotalReturnsUseCase>(
    () => GetTotalReturnsUseCase(getIt<ReturnRepository>()),
  );

  // Customer Order Use Cases
  getIt.registerLazySingleton<LoadCustomerOrdersUseCase>(
    () => LoadCustomerOrdersUseCase(getIt<CustomerOrderRepository>()),
  );
  getIt.registerLazySingleton<GetCustomerOrderWithItemsUseCase>(
    () => GetCustomerOrderWithItemsUseCase(getIt<CustomerOrderRepository>()),
  );
  getIt.registerLazySingleton<CreateCustomerOrderUseCase>(
    () => CreateCustomerOrderUseCase(getIt<CustomerOrderRepository>()),
  );
  getIt.registerLazySingleton<UpdateCustomerOrderStatusUseCase>(
    () => UpdateCustomerOrderStatusUseCase(getIt<CustomerOrderRepository>()),
  );

  // Prescription Use Cases
  getIt.registerLazySingleton<LoadPrescriptionsUseCase>(
    () => LoadPrescriptionsUseCase(getIt<PrescriptionRepository>()),
  );
  getIt.registerLazySingleton<CreatePrescriptionUseCase>(
    () => CreatePrescriptionUseCase(getIt<PrescriptionRepository>()),
  );
  getIt.registerLazySingleton<UpdatePrescriptionStatusUseCase>(
    () => UpdatePrescriptionStatusUseCase(getIt<PrescriptionRepository>()),
  );
  getIt.registerLazySingleton<GetPrescriptionByIdUseCase>(
    () => GetPrescriptionByIdUseCase(getIt<PrescriptionRepository>()),
  );

  // Presentation Providers
  getIt.registerFactory<MedicineProvider>(
    () => MedicineProvider(
      getAllMedicines: getIt<GetAllMedicinesUseCase>(),
      getMedicineById: getIt<GetMedicineByIdUseCase>(),
      addMedicine: getIt<AddMedicineUseCase>(),
      updateMedicine: getIt<UpdateMedicineUseCase>(),
      deleteMedicine: getIt<DeleteMedicineUseCase>(),
      updateStock: getIt<UpdateMedicineStockUseCase>(),
      searchMedicines: getIt<SearchMedicinesUseCase>(),
      getLowStockMedicines: getIt<GetLowStockMedicinesUseCase>(),
      getNearExpiryMedicines: getIt<GetNearExpiryMedicinesUseCase>(),
      getExpiredMedicines: getIt<GetExpiredMedicinesUseCase>(),
      getCountByCategory: getIt<GetMedicineCountByCategoryUseCase>(),
      getInventoryValue: getIt<GetInventoryValueUseCase>(),
    ),
  );
  
  getIt.registerFactory<CustomerProvider>(
    () => CustomerProvider(
      getAllCustomers: getIt<GetAllCustomersUseCase>(),
      addCustomer: getIt<AddCustomerUseCase>(),
      updateCustomer: getIt<UpdateCustomerUseCase>(),
      deleteCustomer: getIt<DeleteCustomerUseCase>(),
      updateCreditLimit: getIt<UpdateCustomerCreditLimitUseCase>(),
      setOpeningBalance: getIt<SetCustomerOpeningBalanceUseCase>(),
      getLedger: getIt<GetCustomerLedgerUseCase>(),
      getPayments: getIt<GetCustomerPaymentsUseCase>(),
      getCreditSummary: getIt<GetCustomerCreditSummaryUseCase>(),
      getOverdueCustomers: getIt<GetOverdueCustomersUseCase>(),
      getRecentTransactions: getIt<GetRecentCreditTransactionsUseCase>(),
      recordPayment: getIt<RecordCustomerPaymentUseCase>(),
    ),
  );

  getIt.registerFactory<SupplierProvider>(
    () => SupplierProvider(
      getAllSuppliers: getIt<GetAllSuppliersUseCase>(),
      getSupplierById: getIt<GetSupplierByIdUseCase>(),
      addSupplier: getIt<AddSupplierUseCase>(),
      updateSupplier: getIt<UpdateSupplierUseCase>(),
      deleteSupplier: getIt<DeleteSupplierUseCase>(),
    ),
  );

  getIt.registerFactory<SalesProvider>(
    () => SalesProvider(
      getSales: getIt<GetSalesUseCase>(),
      getSalesByCustomer: getIt<GetSalesByCustomerUseCase>(),
      createSale: getIt<CreateSaleUseCase>(),
      getSaleWithItems: getIt<GetSaleWithItemsUseCase>(),
      getTodaySummary: getIt<GetTodaySalesSummaryUseCase>(),
      storeService: getIt<StoreService>(),
    ),
  );

  getIt.registerFactory<PurchaseOrderProvider>(
    () => PurchaseOrderProvider(
      loadOrdersUseCase: getIt<LoadPurchaseOrdersUseCase>(),
      getOrdersBySupplierUseCase: getIt<GetOrdersBySupplierUseCase>(),
      createOrderUseCase: getIt<CreatePurchaseOrderUseCase>(),
      getOrderWithItemsUseCase: getIt<GetPurchaseOrderWithItemsUseCase>(),
      updateStatusUseCase: getIt<UpdatePurchaseOrderStatusUseCase>(),
      deleteOrderUseCase: getIt<DeletePurchaseOrderUseCase>(),
      storeService: getIt<StoreService>(),
    ),
  );
  
  getIt.registerFactory<ReturnProvider>(
    () => ReturnProvider(
      loadReturnsUseCase: getIt<LoadReturnsUseCase>(),
      processReturnUseCase: getIt<ProcessReturnUseCase>(),
      getReturnWithItemsUseCase: getIt<GetReturnWithItemsUseCase>(),
      getTotalReturnsUseCase: getIt<GetTotalReturnsUseCase>(),
      storeService: getIt<StoreService>(),
    ),
  );

  getIt.registerFactory<CustomerOrderProvider>(
    () => CustomerOrderProvider(
      loadOrdersUseCase: getIt<LoadCustomerOrdersUseCase>(),
      getOrderWithItemsUseCase: getIt<GetCustomerOrderWithItemsUseCase>(),
      createOrderUseCase: getIt<CreateCustomerOrderUseCase>(),
      updateStatusUseCase: getIt<UpdateCustomerOrderStatusUseCase>(),
      storeService: getIt<StoreService>(),
    ),
  );

  getIt.registerFactory<PrescriptionProvider>(
    () => PrescriptionProvider(
      loadPrescriptionsUseCase: getIt<LoadPrescriptionsUseCase>(),
      createPrescriptionUseCase: getIt<CreatePrescriptionUseCase>(),
      updateStatusUseCase: getIt<UpdatePrescriptionStatusUseCase>(),
      getPrescriptionByIdUseCase: getIt<GetPrescriptionByIdUseCase>(),
      storeService: getIt<StoreService>(),
    ),
  );
  
  // Legacy Services (to be refactored)
  getIt.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  getIt.registerLazySingleton<RateLimiter>(() => RateLimiter());
  getIt.registerLazySingleton<BiometricAuthService>(() => BiometricAuthService(
    secureStorage: getIt<SecureStorageService>(),
  ));
  getIt.registerLazySingleton<AuthService>(() => AuthService(
    databaseHelper: getIt<DatabaseHelper>(),
    rateLimiter: getIt<RateLimiter>(),
  ));
  getIt.registerLazySingleton<StoreService>(() => StoreService());
  
  // New Production Hardening Services
  getIt.registerLazySingleton<BackupService>(() => BackupService(
    databaseHelper: getIt<DatabaseHelper>(),
  ));
  
  getIt.registerLazySingleton<PermissionService>(() => PermissionService(
    databaseHelper: getIt<DatabaseHelper>(),
  ));
  
  getIt.registerLazySingleton<CustomerCreditService>(() => CustomerCreditService(
    databaseHelper: getIt<DatabaseHelper>(),
    permissionService: getIt<PermissionService>(),
  ));
  
  // Setup service (registered after async initialization)
  getIt.registerSingletonWithDependencies<FirstTimeSetupService>(
    () {
      final db = getIt<DatabaseHelper>();
      final prefs = getIt<SharedPreferences>();
      final auth = getIt<AuthService>();
      return FirstTimeSetupService(
        db: db,
        prefs: prefs,
        authService: auth,
      );
    },
    dependsOn: [SharedPreferences],
  );
}
