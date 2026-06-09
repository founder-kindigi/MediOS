import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/return_model.dart';

class ReturnService extends ChangeNotifier {
  final DatabaseHelper _db;

  ReturnService({DatabaseHelper? databaseHelper})
      : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>();
  List<ReturnModel> _returns = [];
  bool _isLoading = false;

  List<ReturnModel> get returns => _returns;
  bool get isLoading => _isLoading;

  Future<void> loadReturns() async {
    _isLoading = true;
    notifyListeners();

    final maps = await _db.query('returns', orderBy: 'return_date DESC');
    _returns = maps.map((m) => ReturnModel.fromMap(m)).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<int> processReturn(ReturnModel ret, List<ReturnItemModel> items) async {
    final db = await _db.database;
    final returnId = await db.transaction((txn) async {
      final id = await txn.insert('returns', ret.toMap());
      for (final item in items) {
        await txn.insert('return_items', {
          'return_id': id,
          'medicine_id': item.medicineId,
          'medicine_name': item.medicineName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total_refund': item.totalRefund,
        });
        await txn.rawUpdate(
          'UPDATE medicines SET stock_quantity = stock_quantity + ?, updated_at = ? WHERE id = ?',
          [item.quantity, DateTime.now().toIso8601String(), item.medicineId],
        );
        await txn.insert('inventory_transactions', {
          'medicine_id': item.medicineId,
          'medicine_name': item.medicineName,
          'type': 'in',
          'quantity': item.quantity,
          'reference_type': 'return',
          'reference_id': id,
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
    return ReturnModel(
      id: ret.id,
      saleId: ret.saleId,
      billNumber: ret.billNumber,
      returnNumber: ret.returnNumber,
      returnDate: ret.returnDate,
      totalRefund: ret.totalRefund,
      reason: ret.reason,
      notes: ret.notes,
      createdAt: ret.createdAt,
      items: items,
    );
  }

  Future<double> getTotalReturns() async {
    return await _db.getSum('returns', 'total_refund');
  }
}
