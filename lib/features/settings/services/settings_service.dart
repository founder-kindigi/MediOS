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
import '../../../core/security/secure_storage_service.dart';
import '../../../core/errors/app_error.dart';
import '../../stores/services/store_service.dart';

class SettingsService extends ChangeNotifier {
  final DatabaseHelper _db;
  final SecureStorageService _secureStorage;
  bool _isProcessing = false;
  double _defaultTaxRate = 0.0;
  String? _lastSyncTime;

  SettingsService({
    DatabaseHelper? databaseHelper,
    SecureStorageService? secureStorage,
  })  : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>(),
        _secureStorage = secureStorage ?? GetIt.instance<SecureStorageService>() {
    final hasPrefs = GetIt.instance.isRegistered<SharedPreferences>();
    if (hasPrefs) {
      try {
        final prefs = GetIt.instance<SharedPreferences>();
        _defaultTaxRate = prefs.getDouble('default_tax_rate') ?? 0.0;
        _lastSyncTime = prefs.getString('last_sync_time');
        return;
      } catch (_) {}
    }
    loadSettings();
  }

  bool get isProcessing => _isProcessing;
  double get defaultTaxRate => _defaultTaxRate;
  String? get lastSyncTime => _lastSyncTime;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultTaxRate = prefs.getDouble('default_tax_rate') ?? 0.0;
    _lastSyncTime = prefs.getString('last_sync_time');
    notifyListeners();
  }

  Future<double> getDefaultTaxRate() async {
    return _defaultTaxRate;
  }

  Future<String?> getLastSyncTime() async {
    return _lastSyncTime;
  }

  Future<Map<String, dynamic>> getAppInfo() async {
    final storeId = GetIt.instance<StoreService>().selectedStoreId;
    final medCount = await _db.getCount('medicines', where: 'store_id = ?', whereArgs: [storeId]);
    final saleCount = await _db.getCount('sales', where: 'store_id = ?', whereArgs: [storeId]);
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

  Future<void> setLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = DateTime.now().toIso8601String();
    await prefs.setString('last_sync_time', timeStr);
    _lastSyncTime = timeStr;
    notifyListeners();
  }

  Future<void> importDatabase() async {
    if (kIsWeb) {
      throw const AppError(message: 'Database import is not supported on Web', type: ErrorType.validation);
    }
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

      await _db.closeDatabase();

      final dir = await getApplicationDocumentsDirectory();
      final targetPath = '${dir.path}/medios.db';
      final sourceFile = File(file.path!);
      await sourceFile.copy(targetPath);

      await _db.database;

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
    if (kIsWeb) {
      throw const AppError(message: 'Database export is not supported on Web', type: ErrorType.validation);
    }
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
      final storeId = GetIt.instance<StoreService>().selectedStoreId;
      final rows = await db.rawQuery('''
        SELECT m.id, m.name, m.generic_name, c.name as category, m.manufacturer,
               m.unit, m.purchase_price, m.selling_price, m.stock_quantity,
               m.reorder_level, m.expiry_date, m.barcode
        FROM medicines m LEFT JOIN categories c ON m.category_id = c.id
        WHERE m.store_id = ?
        ORDER BY m.name ASC
      ''', [storeId]);

      const header = 'ID,Name,Generic Name,Category,Manufacturer,Unit,Purchase Price,Selling Price,Stock,Reorder Level,Expiry Date,Barcode';
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

      final csvString = '\uFEFF${csvRows.join('\n')}';
      final csvData = utf8.encode(csvString);
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(csvData),
            name: 'medicines_export_${DateTime.now().millisecondsSinceEpoch}.csv',
            mimeType: 'text/csv',
          )
        ],
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
        await txn.delete('prescription_items');
        await txn.delete('prescriptions');
        await txn.delete('customer_order_items');
        await txn.delete('customer_orders');
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
      });
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> setDefaultTaxRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('default_tax_rate', rate);
    _defaultTaxRate = rate;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getCoupons() async {
    final storeId = GetIt.instance<StoreService>().selectedStoreId;
    final key = 'coupons_store_$storeId';
    try {
      final decrypted = await _secureStorage.retrieve(key);
      if (decrypted == null) {
        final prefs = await SharedPreferences.getInstance();
        final legacyJson = prefs.getString('coupons');
        if (legacyJson != null) {
          final List legacyCoupons = jsonDecode(legacyJson);
          final scoped = legacyCoupons.cast<Map<String, dynamic>>();
          await _secureStorage.store(key, jsonEncode(scoped));
          await prefs.remove('coupons');
          return scoped;
        }
        return [];
      }
      return (jsonDecode(decrypted) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error loading secure coupons: $e');
      return [];
    }
  }

  Future<void> addCoupon(Map<String, dynamic> coupon) async {
    final coupons = await getCoupons();
    coupons.add(coupon);
    final storeId = GetIt.instance<StoreService>().selectedStoreId;
    final key = 'coupons_store_$storeId';
    await _secureStorage.store(key, jsonEncode(coupons));
    notifyListeners();
  }

  Future<void> removeCoupon(String code) async {
    final coupons = await getCoupons();
    coupons.removeWhere((c) => c['code'] == code);
    final storeId = GetIt.instance<StoreService>().selectedStoreId;
    final key = 'coupons_store_$storeId';
    await _secureStorage.store(key, jsonEncode(coupons));
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

  @override
  void dispose() {
    // Clear data to prevent memory leaks
    _lastSyncTime = null;
    super.dispose();
  }
}
