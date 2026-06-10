import 'package:sqflite_common/sqlite_api.dart';
import '../../../core/database/database_helper.dart';
import '../../models/medicine_model.dart';

/// Local data source for medicine data (SQLite).
abstract class MedicineLocalDataSource {
  Future<List<MedicineDataModel>> getAllMedicines({
    int? limit,
    int? offset,
    int? categoryId,
    String? searchQuery,
  });
  
  Future<MedicineDataModel?> getMedicineById(int id);
  Future<List<MedicineDataModel>> getMedicinesByBarcode(String barcode);
  Future<List<MedicineDataModel>> getLowStockMedicines();
  Future<List<MedicineDataModel>> getNearExpiryMedicines();
  Future<List<MedicineDataModel>> getExpiredMedicines();
  Future<int> insertMedicine(MedicineDataModel medicine);
  Future<void> updateMedicine(MedicineDataModel medicine);
  Future<void> deleteMedicine(int id);
  Future<void> updateStock(int medicineId, int newQuantity);
  Future<List<MedicineDataModel>> searchMedicines(String query);
  Future<int> getMedicineCount({int? categoryId, String? searchQuery});
  Future<double> getInventoryValue();
  Future<Map<int, int>> getMedicineCountByCategory();
}

class MedicineLocalDataSourceImpl implements MedicineLocalDataSource {
  final DatabaseHelper _databaseHelper;

  MedicineLocalDataSourceImpl({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  @override
  Future<List<MedicineDataModel>> getAllMedicines({
    int? limit,
    int? offset,
    int? categoryId,
    String? searchQuery,
  }) async {
    final db = await _databaseHelper.database;
    
    var whereClause = '';
    final whereArgs = <dynamic>[];
    
    if (categoryId != null) {
      whereClause = 'WHERE m.category_id = ?';
      whereArgs.add(categoryId);
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause = whereClause.isEmpty ? 'WHERE' : '$whereClause AND';
      whereClause = '$whereClause (m.name LIKE ? OR m.generic_name LIKE ?)';
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }
    
    var limitClause = '';
    if (limit != null) {
      limitClause = 'LIMIT $limit';
      if (offset != null) {
        limitClause = '$limitClause OFFSET $offset';
      }
    }
    
    final sql = '''
      SELECT m.*, c.name as category_name 
      FROM medicines m 
      LEFT JOIN categories c ON m.category_id = c.id
      $whereClause
      ORDER BY m.name ASC
      $limitClause
    '''.trim();
    
    final maps = await db.rawQuery(sql, whereArgs);
    return maps.map(MedicineDataModel.fromMap).toList();
  }

  @override
  Future<MedicineDataModel?> getMedicineById(int id) async {
    final db = await _databaseHelper.database;
    
    final sql = '''
      SELECT m.*, c.name as category_name 
      FROM medicines m 
      LEFT JOIN categories c ON m.category_id = c.id
      WHERE m.id = ?
    ''';
    
    final maps = await db.rawQuery(sql, [id]);
    if (maps.isEmpty) return null;
    
    return MedicineDataModel.fromMap(maps.first);
  }

  @override
  Future<List<MedicineDataModel>> getMedicinesByBarcode(String barcode) async {
    final db = await _databaseHelper.database;
    
    final maps = await db.query(
      'medicines',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    
    return maps.map(MedicineDataModel.fromMap).toList();
  }

  @override
  Future<List<MedicineDataModel>> getLowStockMedicines() async {
    final db = await _databaseHelper.database;
    
    final sql = '''
      SELECT m.*, c.name as category_name 
      FROM medicines m 
      LEFT JOIN categories c ON m.category_id = c.id
      WHERE m.stock_quantity <= m.reorder_level
      ORDER BY m.stock_quantity ASC
    ''';
    
    final maps = await db.rawQuery(sql);
    return maps.map(MedicineDataModel.fromMap).toList();
  }

  @override
  Future<List<MedicineDataModel>> getNearExpiryMedicines() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    
    final sql = '''
      SELECT m.*, c.name as category_name 
      FROM medicines m 
      LEFT JOIN categories c ON m.category_id = c.id
      WHERE m.expiry_date IS NOT NULL 
        AND m.expiry_date > ?
        AND m.expiry_date < ?
      ORDER BY m.expiry_date ASC
    ''';
    
    final maps = await db.rawQuery(sql, [
      now.toIso8601String(),
      thirtyDaysFromNow.toIso8601String(),
    ]);
    
    return maps.map(MedicineDataModel.fromMap).toList();
  }

  @override
  Future<List<MedicineDataModel>> getExpiredMedicines() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    
    final sql = '''
      SELECT m.*, c.name as category_name 
      FROM medicines m 
      LEFT JOIN categories c ON m.category_id = c.id
      WHERE m.expiry_date IS NOT NULL 
        AND m.expiry_date < ?
      ORDER BY m.expiry_date ASC
    ''';
    
    final maps = await db.rawQuery(sql, [now.toIso8601String()]);
    return maps.map(MedicineDataModel.fromMap).toList();
  }

  @override
  Future<int> insertMedicine(MedicineDataModel medicine) async {
    final db = await _databaseHelper.database;
    return await db.insert('medicines', medicine.toMap());
  }

  @override
  Future<void> updateMedicine(MedicineDataModel medicine) async {
    final db = await _databaseHelper.database;
    await db.update(
      'medicines',
      medicine.toMap(),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
  }

  @override
  Future<void> deleteMedicine(int id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'medicines',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateStock(int medicineId, int newQuantity) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'medicines',
      {
        'stock_quantity': newQuantity,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [medicineId],
    );
  }

  @override
  Future<List<MedicineDataModel>> searchMedicines(String query) async {
    if (query.isEmpty) {
      return await getAllMedicines();
    }
    
    final db = await _databaseHelper.database;
    
    final sql = '''
      SELECT m.*, c.name as category_name 
      FROM medicines m 
      LEFT JOIN categories c ON m.category_id = c.id
      WHERE m.name LIKE ? OR m.generic_name LIKE ?
      ORDER BY m.name ASC
    ''';
    
    final searchTerm = '%$query%';
    final maps = await db.rawQuery(sql, [searchTerm, searchTerm]);
    return maps.map(MedicineDataModel.fromMap).toList();
  }

  @override
  Future<int> getMedicineCount({int? categoryId, String? searchQuery}) async {
    final db = await _databaseHelper.database;
    
    var whereClause = '';
    final whereArgs = <dynamic>[];
    
    if (categoryId != null) {
      whereClause = 'WHERE category_id = ?';
      whereArgs.add(categoryId);
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (whereClause.isEmpty) {
        whereClause = 'WHERE';
      } else {
        whereClause = '$whereClause AND';
      }
      whereClause = '$whereClause (name LIKE ? OR generic_name LIKE ?)';
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM medicines $whereClause',
      whereArgs,
    );
    
    return result.first['count'] as int;
  }

  @override
  Future<double> getInventoryValue() async {
    final db = await _databaseHelper.database;
    
    final result = await db.rawQuery('''
      SELECT SUM(stock_quantity * purchase_price) as total_value 
      FROM medicines 
      WHERE stock_quantity > 0
    ''');
    
    final total = result.first['total_value'];
    return total != null ? (total as num).toDouble() : 0;
  }

  @override
  Future<Map<int, int>> getMedicineCountByCategory() async {
    final db = await _databaseHelper.database;
    
    final result = await db.rawQuery('''
      SELECT category_id, COUNT(*) as count 
      FROM medicines 
      WHERE category_id IS NOT NULL
      GROUP BY category_id
    ''');
    
    final map = <int, int>{};
    for (final row in result) {
      final categoryId = row['category_id'] as int;
      final count = row['count'] as int;
      map[categoryId] = count;
    }
    
    return map;
  }
}