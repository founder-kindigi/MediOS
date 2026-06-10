import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/return_model.dart';
import '../../stores/services/store_service.dart';
import '../../../core/errors/app_error.dart';

class ReturnService extends ChangeNotifier {
  final DatabaseHelper _db;
  final StoreService _storeService;

  ReturnService({DatabaseHelper? databaseHelper, StoreService? storeService})
      : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>(),
        _storeService = storeService ?? GetIt.instance<StoreService>();
  List<ReturnModel> _returns = [];
  bool _isLoading = false;

  List<ReturnModel> get returns => _returns;
  bool get isLoading => _isLoading;

  Future<void> loadReturns() async {
    _isLoading = true;
    notifyListeners();

    try {
      final storeId = _storeService.selectedStoreId;
      final db = await _db.database;
      final maps = await db.rawQuery('''
        SELECT r.* FROM returns r
        LEFT JOIN sales s ON r.sale_id = s.id
        WHERE s.store_id = ? OR r.sale_id IS NULL
        ORDER BY r.return_date DESC
      ''', [storeId]);
      _returns = maps.map((m) => ReturnModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Failed to load returns: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<int> processReturn(ReturnModel ret, List<ReturnItemModel> items) async {
    final db = await _db.database;
    final returnId = await db.transaction((txn) async {
      if (ret.saleId == null) {
        throw AppError(
          message: 'Cannot process a return without an associated sale.',
          type: ErrorType.validation,
        );
      }

      // Get store_id from the sale
      final saleRows = await txn.query('sales', columns: ['store_id'], where: 'id = ?', whereArgs: [ret.saleId]);
      if (saleRows.isEmpty) {
        throw AppError(
          message: 'Associated sale not found. Cannot process return.',
          type: ErrorType.validation,
        );
      }
      final saleStoreId = saleRows.first['store_id'] as int? ?? _storeService.selectedStoreId ?? 1;

      final id = await txn.insert('returns', ret.toMap());

      for (final item in items) {
        // 1. Get original sale item quantity and name
        final saleItemRows = await txn.query(
          'sale_items',
          columns: ['quantity', 'medicine_name'],
          where: 'sale_id = ? AND medicine_id = ?',
          whereArgs: [ret.saleId, item.medicineId],
        );
        if (saleItemRows.isEmpty) {
          throw AppError(
            message: 'Item "${item.medicineName ?? 'Item'}" was not found in the original sale.',
            type: ErrorType.validation,
          );
        }
        final originalQty = saleItemRows.first['quantity'] as int;
        final medName = saleItemRows.first['medicine_name'] as String? ?? item.medicineName;

        // 2. Get cumulative previously returned quantity for this sale item
        final prevReturnedRows = await txn.rawQuery('''
          SELECT COALESCE(SUM(ri.quantity), 0) as returned_qty
          FROM return_items ri
          INNER JOIN returns r ON ri.return_id = r.id
          WHERE r.sale_id = ? AND ri.medicine_id = ?
        ''', [ret.saleId, item.medicineId]);
        final prevReturnedQty = (prevReturnedRows.first['returned_qty'] as num?)?.toInt() ?? 0;

        if (prevReturnedQty + item.quantity > originalQty) {
          throw AppError(
            message: 'Cannot return ${item.quantity} items of "$medName". '
                     'Original sold: $originalQty, already returned: $prevReturnedQty.',
            type: ErrorType.validation,
          );
        }

        await txn.insert('return_items', {
          'return_id': id,
          'medicine_id': item.medicineId,
          'medicine_name': item.medicineName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total_refund': item.totalRefund,
        });

        final changes = await txn.rawUpdate(
          'UPDATE medicines SET stock_quantity = stock_quantity + ?, updated_at = ? WHERE id = ?',
          [item.quantity, DateTime.now().toIso8601String(), item.medicineId],
        );
        if (changes == 0) {
          throw AppError(
            message: 'Medicine "$medName" was not found or deleted. Stock cannot be restored.',
            type: ErrorType.validation,
          );
        }

        await txn.insert('inventory_transactions', {
          'medicine_id': item.medicineId,
          'medicine_name': item.medicineName,
          'type': 'in',
          'quantity': item.quantity,
          'reference_type': 'return',
          'reference_id': id,
          'store_id': saleStoreId,
          'notes': 'Return: ${ret.reason}',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      return id;
    });

    await loadReturns();
    return returnId;
  }

  Future<ReturnModel?> getReturnWithItems(int returnId) async {
    final retMap = await _db.getById('returns', returnId);
    if (retMap == null) return null;

    final itemMaps = await _db.query('return_items',
        where: 'return_id = ?', whereArgs: [returnId]);

    final ret = ReturnModel.fromMap(retMap);
    final items = itemMaps.map((m) => ReturnItemModel.fromMap(m)).toList();
    return ret.copyWith(items: items);
  }

  Future<double> getTotalReturns() async {
    final storeId = _storeService.selectedStoreId;
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(r.total_refund), 0) as total
      FROM returns r
      LEFT JOIN sales s ON r.sale_id = s.id
      WHERE s.store_id = ? OR r.sale_id IS NULL
    ''', [storeId]);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  @override
  void dispose() {
    _returns = [];
    super.dispose();
  }
}
