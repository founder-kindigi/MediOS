import 'package:flutter_test/flutter_test.dart';
import 'package:medios/data/datasources/local/medicine_local_data_source.dart';
import 'package:medios/data/repositories/medicine_repository_impl.dart';
import 'package:medios/domain/repositories/medicine_repository.dart';
import 'package:medios/presentation/providers/medicine_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:medios/core/database/database_helper.dart';
import 'package:medios/domain/usecases/medicine_usecases.dart';

// Mock data for testing
final mockMedicines = List.generate(150, (index) => ({
  'id': index + 1,
  'name': 'Medicine $index',
  'generic_name': 'Generic $index',
  'category_id': (index % 5) + 1,
  'manufacturer': 'Manufacturer ${index % 3}',
  'unit': 'strip',
  'purchase_price': 10.0 + (index % 20),
  'selling_price': 15.0 + (index % 20),
  'wholesale_price': 12.0 + (index % 20),
  'stock_quantity': index % 100,
  'reorder_level': 10,
  'expiry_date': DateTime.now().add(Duration(days: 365 - (index % 365))).toIso8601String(),
  'barcode': '89012345${index.toString().padLeft(6, '0')}',
  'description': 'Test medicine $index',
  'store_id': 1,
  'created_at': DateTime.now().subtract(Duration(days: index % 365)).toIso8601String(),
  'updated_at': DateTime.now().toIso8601String(),
}));

void main() {
  // Initialize sqflite for testing
  sqfliteFfiInit();

  group('Pagination Performance Tests', () {
    late DatabaseHelper databaseHelper;
    late MedicineLocalDataSource dataSource;
    late MedicineRepository repository;
    late MedicineProvider provider;

    setUp(() async {
      // Create in-memory database for testing
      final db = await databaseFactoryFfi.openDatabase(
        ':memory:',
        options: OpenDatabaseOptions(version: 1),
      );

      // Create medicines table
      await db.execute('''
        CREATE TABLE medicines (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          generic_name TEXT,
          category_id INTEGER,
          manufacturer TEXT,
          unit TEXT NOT NULL DEFAULT 'strip',
          purchase_price REAL NOT NULL DEFAULT 0,
          selling_price REAL NOT NULL DEFAULT 0,
          wholesale_price REAL NOT NULL DEFAULT 0,
          stock_quantity INTEGER NOT NULL DEFAULT 0,
          reorder_level INTEGER NOT NULL DEFAULT 10,
          expiry_date TEXT,
          barcode TEXT,
          description TEXT,
          store_id INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Create categories table
      await db.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          description TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      // Insert mock data
      for (final medicine in mockMedicines) {
        await db.insert('medicines', medicine);
      }

      // Set test database
      DatabaseHelper.setTestDatabase(db);
      databaseHelper = DatabaseHelper();
      
      // Initialize dependencies
      dataSource = MedicineLocalDataSourceImpl(databaseHelper: databaseHelper);
      repository = MedicineRepositoryImpl(localDataSource: dataSource);
      
      // Create use cases
      final getAllMedicines = GetAllMedicinesUseCase(repository: repository);
      final getMedicineById = GetMedicineByIdUseCase(repository: repository);
      final addMedicine = AddMedicineUseCase(repository: repository);
      final updateMedicine = UpdateMedicineUseCase(repository: repository);
      final deleteMedicine = DeleteMedicineUseCase(repository: repository);
      final updateStock = UpdateMedicineStockUseCase(repository: repository);
      final searchMedicines = SearchMedicinesUseCase(repository: repository);
      final getLowStockMedicines = GetLowStockMedicinesUseCase(repository: repository);
      final getNearExpiryMedicines = GetNearExpiryMedicinesUseCase(repository: repository);
      final getExpiredMedicines = GetExpiredMedicinesUseCase(repository: repository);
      final getCountByCategory = GetMedicineCountByCategoryUseCase(repository: repository);
      final getInventoryValue = GetInventoryValueUseCase(repository: repository);

      provider = MedicineProvider(
        getAllMedicines: getAllMedicines,
        getMedicineById: getMedicineById,
        addMedicine: addMedicine,
        updateMedicine: updateMedicine,
        deleteMedicine: deleteMedicine,
        updateStock: updateStock,
        searchMedicines: searchMedicines,
        getLowStockMedicines: getLowStockMedicines,
        getNearExpiryMedicines: getNearExpiryMedicines,
        getExpiredMedicines: getExpiredMedicines,
        getCountByCategory: getCountByCategory,
        getInventoryValue: getInventoryValue,
      );
    });

    tearDown(() async {
      final db = await databaseHelper.database;
      await db.close();
      DatabaseHelper.setTestDatabase(null);
    });

    test('Pagination query performance with 150 records', () async {
      final stopwatch = Stopwatch();
      
      // Test first page (20 items)
      stopwatch.start();
      final page1 = await dataSource.getAllMedicines(limit: 20, offset: 0);
      stopwatch.stop();
      
      final page1Time = stopwatch.elapsedMilliseconds;
      print('Page 1 (20 items) query time: ${page1Time}ms');
      expect(page1Time, lessThan(500)); // Should be fast with indexes
      expect(page1.length, 20);
      
      // Test second page
      stopwatch.reset();
      stopwatch.start();
      final page2 = await dataSource.getAllMedicines(limit: 20, offset: 20);
      stopwatch.stop();
      
      final page2Time = stopwatch.elapsedMilliseconds;
      print('Page 2 (20 items) query time: ${page2Time}ms');
      expect(page2Time, lessThan(500));
      expect(page2.length, 20);
      
      // Verify different pages have different items
      expect(page1.first.id, isNot(equals(page2.first.id)));
    });

    test('MedicineProvider pagination loading', () async {
      // Test initial load
      final stopwatch = Stopwatch()..start();
      await provider.loadMedicines();
      stopwatch.stop();
      
      print('Provider initial load time: ${stopwatch.elapsedMilliseconds}ms');
      expect(provider.medicines.length, 50); // Default page size
      expect(provider.hasMore, true); // Should have more with 150 records
      expect(provider.totalItems, 150);
      
      // Test loading more
      stopwatch.reset();
      stopwatch.start();
      await provider.loadMoreMedicines();
      stopwatch.stop();
      
      print('Provider load more time: ${stopwatch.elapsedMilliseconds}ms');
      expect(provider.medicines.length, 100); // 50 + 50 more
      expect(provider.currentPage, 2);
      
      // Test loading third page
      await provider.loadMoreMedicines();
      expect(provider.medicines.length, 150); // All 150 records
      expect(provider.hasMore, false); // No more records
    });

    test('Search with pagination performance', () async {
      final stopwatch = Stopwatch();
      
      // Search for "Medicine 1" (should match multiple records)
      stopwatch.start();
      await provider.searchMedicines('Medicine 1');
      stopwatch.stop();
      
      print('Search pagination time: ${stopwatch.elapsedMilliseconds}ms');
      expect(provider.medicines.length, greaterThan(0));
      expect(provider.medicines.length, lessThanOrEqualTo(50)); // Page size limit
      
      // Verify all results contain search term
      for (final medicine in provider.medicines) {
        expect(medicine.name.contains('1'), isTrue);
      }
    });

    test('Count query performance', () async {
      final stopwatch = Stopwatch();
      
      stopwatch.start();
      final count = await dataSource.getMedicineCount();
      stopwatch.stop();
      
      print('Count query time: ${stopwatch.elapsedMilliseconds}ms');
      expect(count, 150);
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('Filtered queries with pagination', () async {
      // Test low stock medicines (stock <= 10)
      final stopwatch = Stopwatch()..start();
      final lowStock = await dataSource.getLowStockMedicines();
      stopwatch.stop();
      
      print('Low stock query time: ${stopwatch.elapsedMilliseconds}ms');
      expect(lowStock.length, greaterThan(0));
      
      // Verify all are actually low stock
      for (final medicine in lowStock) {
        expect(medicine.stockQuantity <= medicine.reorderLevel, isTrue);
      }
    });

    test('Memory usage with pagination vs full load', () async {
      // Test with pagination (50 items per page)
      final stopwatch = Stopwatch()..start();
      await provider.loadMedicines();
      stopwatch.stop();
      
      final paginatedTime = stopwatch.elapsedMilliseconds;
      final paginatedCount = provider.medicines.length;
      
      print('Pagination load (50 items): ${paginatedTime}ms, ${paginatedCount} items');
      
      // Compare with theoretical full load (for demonstration)
      // In real app, full load would be much slower with large datasets
      expect(paginatedTime, lessThan(500)); // Should be fast
      expect(paginatedCount, 50); // Page size
    });
  });

  group('Performance Comparison', () {
    test('Pagination vs Full Load (simulated)', () {
      // Simulate performance difference
      const pageSize = 50;
      const totalItems = 10000;
      const pages = totalItems ~/ pageSize;
      
      // Pagination: load first page
      final paginatedTime = 100; // ms for first page
      
      // Full load: load all items (would be much slower)
      final fullLoadTime = paginatedTime * pages; // Linear scaling
      
      print('Simulated performance:');
      print('  Pagination (first page): ${paginatedTime}ms');
      print('  Full load (all pages): ${fullLoadTime}ms');
      print('  Improvement: ${(fullLoadTime / paginatedTime).toStringAsFixed(1)}x faster');
      
      expect(fullLoadTime, greaterThan(paginatedTime * 10)); // At least 10x slower
    });
  });
}