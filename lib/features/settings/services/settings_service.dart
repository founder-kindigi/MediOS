import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/constants/app_constants.dart';

class SettingsService extends ChangeNotifier {
  final DatabaseHelper _db;

  SettingsService({DatabaseHelper? databaseHelper})
      : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>();
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;

  Future<Map<String, dynamic>> getAppInfo() async {
    final medCount = await _db.getCount('medicines');
    final saleCount = await _db.getCount('sales');
    final supCount = await _db.getCount('suppliers');
    final custCount = await _db.getCount('customers');
    final userCount = await _db.getCount('users');

    return {
      'appName': 'MediOS',
      'appVersion': '1.0.0',
      'dbVersion': AppConstants.dbVersion,
      'medicines': medCount,
      'sales': saleCount,
      'suppliers': supCount,
      'customers': custCount,
      'users': userCount,
    };
  }

  Future<String?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_sync_time');
  }

  Future<void> setLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_time', DateTime.now().toIso8601String());
  }

  Future<void> importDatabase() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null) return;

      _isProcessing = true;
      notifyListeners();

      final dir = await getApplicationDocumentsDirectory();
      final targetPath = '${dir.path}/medios.db';
      final sourceFile = File(file.path!);
      await sourceFile.copy(targetPath);

      await setLastSyncTime();

      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> exportDatabase() async {
    _isProcessing = true;
    notifyListeners();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File('${dir.path}/medios.db');

      if (!await dbFile.exists()) {
        throw Exception('Database file not found');
      }

      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/medios_backup_${DateTime.now().millisecondsSinceEpoch}.db');
      await dbFile.copy(backupFile.path);

      await Share.shareXFiles(
        [XFile(backupFile.path)],
        text: 'MediOS Database Backup',
      );
    } catch (e) {
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> exportMedicinesCsv() async {
    _isProcessing = true;
    notifyListeners();

    try {
      final db = await _db.database;
      final rows = await db.rawQuery('''
        SELECT m.id, m.name, m.generic_name, c.name as category, m.manufacturer,
               m.unit, m.purchase_price, m.selling_price, m.stock_quantity,
               m.reorder_level, m.expiry_date, m.barcode
        FROM medicines m LEFT JOIN categories c ON m.category_id = c.id
        ORDER BY m.name ASC
      ''');

      final header = 'ID,Name,Generic Name,Category,Manufacturer,Unit,Purchase Price,Selling Price,Stock,Reorder Level,Expiry Date,Barcode';
      final csvRows = [header];
      for (final row in rows) {
        csvRows.add([
          row['id'], _csvEscape(row['name'] as String? ?? ''),
          _csvEscape(row['generic_name'] as String? ?? ''),
          _csvEscape(row['category'] as String? ?? ''),
          _csvEscape(row['manufacturer'] as String? ?? ''),
          row['unit'], row['purchase_price'], row['selling_price'],
          row['stock_quantity'], row['reorder_level'],
          row['expiry_date'] ?? '', row['barcode'] ?? '',
        ].join(','));
      }

      final tempDir = await getTemporaryDirectory();
      final csvFile = File('${tempDir.path}/medicines_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await csvFile.writeAsString(csvRows.join('\n'), encoding: utf8);

      await Share.shareXFiles(
        [XFile(csvFile.path)],
        text: 'MediOS Medicines Export',
      );
    } catch (e) {
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> clearAllData() async {
    _isProcessing = true;
    notifyListeners();

    try {
      final db = await _db.database;
      await db.transaction((txn) async {
        await txn.delete('return_items');
        await txn.delete('returns');
        await txn.delete('inventory_transactions');
        await txn.delete('purchase_order_items');
        await txn.delete('purchase_orders');
        await txn.delete('sale_items');
        await txn.delete('sales');
        await txn.delete('customers');
        await txn.delete('suppliers');
        await txn.delete('medicines');
        await txn.delete('categories');
      });
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<double> getDefaultTaxRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('default_tax_rate') ?? 0;
  }

  Future<void> setDefaultTaxRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('default_tax_rate', rate);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getCoupons() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('coupons');
    if (json == null) return [];
    return (jsonDecode(json) as List).cast<Map<String, dynamic>>();
  }

  Future<void> addCoupon(Map<String, dynamic> coupon) async {
    final coupons = await getCoupons();
    coupons.add(coupon);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('coupons', jsonEncode(coupons));
    notifyListeners();
  }

  Future<void> removeCoupon(String code) async {
    final coupons = await getCoupons();
    coupons.removeWhere((c) => c['code'] == code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('coupons', jsonEncode(coupons));
    notifyListeners();
  }

  Future<Map<String, dynamic>?> validateCoupon(String code, double total) async {
    final coupons = await getCoupons();
    for (final c in coupons) {
      if (c['code'] == code && c['is_active'] == true) {
        final minPurchase = (c['min_purchase'] as num?)?.toDouble() ?? 0;
        if (total < minPurchase) return null;
        return c;
      }
    }
    return null;
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
