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

// Domain
import '../../domain/repositories/medicine_repository.dart';

// Data
import '../../data/datasources/local/medicine_local_data_source.dart';
import '../../data/repositories/medicine_repository_impl.dart';

// Use Cases
import '../../domain/usecases/medicine_usecases.dart';

// Presentation
import '../../presentation/providers/medicine_provider.dart';

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
  
  // Repositories
  getIt.registerLazySingleton<MedicineRepository>(
    () => MedicineRepositoryImpl(
      localDataSource: getIt<MedicineLocalDataSource>(),
    ),
  );
  
  // Use Cases
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
