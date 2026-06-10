import 'package:flutter_test/flutter_test.dart';
import 'package:medios/domain/entities/medicine.dart';
import 'package:medios/models/medicine_model.dart';

void main() {
  group('Medicine Performance Tests', () {
    test('Domain entity cached properties performance', () {
      // Create medicine with expiry in the future
      final expiryDate = DateTime.now().add(const Duration(days: 45));
      final medicine = Medicine(
        id: 1,
        name: 'Test Medicine',
        genericName: 'Test Generic',
        manufacturer: 'Test Manufacturer',
        purchasePrice: 10.0,
        sellingPrice: 15.0,
        wholesalePrice: 12.0,
        stockQuantity: 5,
        reorderLevel: 10,
        expiryDate: expiryDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Measure performance of repeated property access
      final stopwatch = Stopwatch();
      
      // Access properties multiple times (simulating list rendering)
      stopwatch.start();
      for (var i = 0; i < 1000; i++) {
        final lowStock = medicine.isLowStock;
        final expired = medicine.isExpired;
        final nearExpiry = medicine.isNearExpiry;
        final profitMargin = medicine.profitMargin;
        final wholesaleMargin = medicine.wholesaleProfitMargin;
        
        // Verify values are correct
        expect(lowStock, true); // stock 5 <= reorder 10
        expect(expired, false);
        expect(nearExpiry, false); // 45 days > 30 days
        expect(profitMargin, 50.0); // (15-10)/10*100 = 50%
        expect(wholesaleMargin, 20.0); // (12-10)/10*100 = 20%
      }
      stopwatch.stop();
      
      print('Domain entity 1000 property accesses: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Should be very fast with caching
    });

    test('MedicineModel cached properties performance', () {
      // Create medicine model with expiry in the future
      final expiryDate = DateTime.now().add(const Duration(days: 15));
      final medicine = MedicineModel(
        id: 1,
        name: 'Test Medicine',
        genericName: 'Test Generic',
        manufacturer: 'Test Manufacturer',
        purchasePrice: 10.0,
        sellingPrice: 15.0,
        stockQuantity: 15,
        reorderLevel: 10,
        expiryDate: expiryDate,
      );

      // Measure performance of repeated property access
      final stopwatch = Stopwatch();
      
      // Access properties multiple times (simulating list rendering)
      stopwatch.start();
      for (var i = 0; i < 1000; i++) {
        final lowStock = medicine.isLowStock;
        final expired = medicine.isExpired;
        final nearExpiry = medicine.isNearExpiry;
        
        // Verify values are correct
        expect(lowStock, false); // stock 15 > reorder 10
        expect(expired, false);
        expect(nearExpiry, true); // 15 days <= 30 days
      }
      stopwatch.stop();
      
      print('MedicineModel 1000 property accesses: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Should be very fast with caching
    });

    test('Validation performance with currentTime parameter', () {
      final medicine = Medicine(
        id: 1,
        name: 'Test Medicine',
        genericName: 'Test Generic',
        manufacturer: 'Test Manufacturer',
        purchasePrice: 10.0,
        sellingPrice: 15.0,
        stockQuantity: 15,
        reorderLevel: 10,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final stopwatch = Stopwatch();
      final currentTime = DateTime.now();
      
      // Measure validation performance
      stopwatch.start();
      for (var i = 0; i < 100; i++) {
        final errors = medicine.validate(currentTime: currentTime);
        expect(errors, isEmpty);
      }
      stopwatch.stop();
      
      print('100 validations with currentTime: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('CopyWith maintains cached properties', () {
      final original = MedicineModel(
        id: 1,
        name: 'Original',
        genericName: 'Generic',
        manufacturer: 'Manufacturer',
        purchasePrice: 10.0,
        sellingPrice: 15.0,
        stockQuantity: 5,
        reorderLevel: 10,
      );

      final updated = original.copyWith(
        stockQuantity: 20,
        sellingPrice: 18.0,
      );

      // Verify new properties
      expect(updated.stockQuantity, 20);
      expect(updated.sellingPrice, 18.0);
      expect(updated.isLowStock, false); // 20 > 10
      
      // Verify original unchanged
      expect(original.stockQuantity, 5);
      expect(original.sellingPrice, 15.0);
      expect(original.isLowStock, true); // 5 <= 10
    });
  });

  group('Performance Comparison Tests', () {
    test('Compare with and without DateTime.now() caching', () {
      // This test demonstrates the performance impact of DateTime.now() calls
      final medicines = List.generate(100, (index) => MedicineModel(
        id: index,
        name: 'Medicine $index',
        genericName: 'Generic $index',
        manufacturer: 'Manufacturer $index',
        purchasePrice: 10.0 + index,
        sellingPrice: 15.0 + index,
        stockQuantity: index % 20,
        reorderLevel: 10,
        expiryDate: DateTime.now().add(Duration(days: index % 60)),
      ));

      // Simulate list rendering - accessing properties multiple times
      final stopwatch = Stopwatch();
      
      stopwatch.start();
      for (var medicine in medicines) {
        // Each access would call DateTime.now() without caching
        final _ = medicine.isExpired;
        final __ = medicine.isNearExpiry;
        final ___ = medicine.isLowStock;
      }
      stopwatch.stop();
      
      final timeWithCaching = stopwatch.elapsedMilliseconds;
      print('100 medicines with cached DateTime: ${timeWithCaching}ms');
      
      // Expected: Without caching, this would be much slower
      // Each isExpired and isNearExpiry would call DateTime.now() separately
      expect(timeWithCaching, lessThan(10)); // Should be very fast
    });
  });
}