import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show debugPrint;
import '../database/database_helper.dart';
import '../errors/app_error.dart';

class SeedDataService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<void> seedMedicinesIfEmpty() async {
    try {
      final count = await _db.getCount('medicines');
      if (count > 0) return;

      final jsonStr = await rootBundle.loadString('assets/data/medicines.json');
      final List<dynamic> products = jsonDecode(jsonStr);

      final now = DateTime.now().toIso8601String();
      const batchSize = 500;

      for (var i = 0; i < products.length; i += batchSize) {
        final batch = products.skip(i).take(batchSize).toList();
        final db = await _db.database;
        await db.transaction((txn) async {
          for (final p in batch) {
            await txn.insert('medicines', {
              'name': p['name'] as String? ?? '',
              'generic_name': p['generic_name'] as String? ?? '',
              'manufacturer': p['manufacturer'] as String? ?? '',
              'unit': 'strip',
              'barcode': p['barcode'] as String?,
              'purchase_price': (p['original_price'] as num?)?.toDouble() ?? 0,
              'selling_price': (p['selling_price'] as num?)?.toDouble() ?? 0,
              'stock_quantity': 0,
              'reorder_level': 10,
              'description': p['pack_size'] as String? ?? '',
              'created_at': now,
              'updated_at': now,
            });
          }
        });
      }
    } on AppError {
      debugPrint('Seeding skipped: database already populated or unhandled error');
    } catch (e) {
      debugPrint('Failed to seed medicines data: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }
}
