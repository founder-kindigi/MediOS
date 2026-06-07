import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/sale_model.dart';

class SalesService extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<SaleModel> _sales = [];
  bool _isLoading = false;

  List<SaleModel> get sales => _sales;
  bool get isLoading => _isLoading;

  Future<void> loadSales() async {
    _isLoading = true;
    notifyListeners();

    final maps = await _db.query('sales', orderBy: 'sale_date DESC');
    _sales = maps.map((m) => SaleModel.fromMap(m)).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<int> createSale(SaleModel sale, List<SaleItemModel> items) async {
    final saleId = await _db.insert('sales', sale.toMap());

    for (final item in items) {
      await _db.insert('sale_items', {
        'sale_id': saleId,
        'medicine_id': item.medicineId,
        'medicine_name': item.medicineName,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'total_price': item.totalPrice,
      });
    }

    await loadSales();
    return saleId;
  }

  Future<SaleModel?> getSaleWithItems(int saleId) async {
    final saleMap = await _db.getById('sales', saleId);
    if (saleMap == null) return null;

    final itemMaps = await _db.query('sale_items',
        where: 'sale_id = ?', whereArgs: [saleId]);

    final sale = SaleModel.fromMap(saleMap);
    final items = itemMaps.map((m) => SaleItemModel.fromMap(m)).toList();
    return SaleModel(
      id: sale.id,
      customerId: sale.customerId,
      customerName: sale.customerName,
      billNumber: sale.billNumber,
      saleDate: sale.saleDate,
      totalAmount: sale.totalAmount,
      discount: sale.discount,
      tax: sale.tax,
      netAmount: sale.netAmount,
      paymentMethod: sale.paymentMethod,
      notes: sale.notes,
      createdAt: sale.createdAt,
      items: items,
    );
  }

  Future<double> getTodaySales() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await _db.getSum('sales', 'net_amount',
        where: 'sale_date >= ? AND sale_date < ?',
        whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);
  }

  Future<int> getTodayTransactionCount() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await _db.getCount('sales',
        where: 'sale_date >= ? AND sale_date < ?',
        whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);
  }
}
