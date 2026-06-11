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

// Data Sources & Repository Implementations
import '../../data/datasources/local/medicine_local_data_source.dart';
import '../../data/repositories/medicine_repository_impl.dart';

import '../../data/datasources/local/customer_local_data_source.dart';
import '../../data/repositories/customer_repository_impl.dart';

import '../../data/datasources/local/supplier_local_data_source.dart';
import '../../data/repositories/supplier_repository_impl.dart';

import '../../data/datasources/local/sale_local_data_source.dart';
import '../../data/repositories/sale_repository_impl.dart';

// Use Cases
import '../../domain/usecases/medicine_usecases.dart';
import '../../domain/usecases/customer_usecases.dart';
import '../../domain/usecases/supplier_usecases.dart';
import '../../domain/usecases/sale_usecases.dart';

// Presentation Providers
import '../../presentation/providers/medicine_provider.dart';
import '../../presentation/providers/customer_provider.dart';
import '../../presentation/providers/supplier_provider.dart';
import '../../presentation/providers/sales_provider.dart';

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
