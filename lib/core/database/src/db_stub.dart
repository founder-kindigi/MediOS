import 'package:sqflite_common/sqflite.dart' show Database;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static void setTestDatabase(Database? db) {
    _database = db;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    throw UnsupportedError('Database not supported on this platform');
  }
  Future<int> insert(String table, Map<String, dynamic> values) => throw UnsupportedError('');
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<dynamic>? whereArgs}) => throw UnsupportedError('');
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) => throw UnsupportedError('');
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy, int? limit, int? offset}) => throw UnsupportedError('');
  Future<Map<String, dynamic>?> getById(String table, int id) => throw UnsupportedError('');
  Future<int> getCount(String table, {String? where, List<dynamic>? whereArgs}) => throw UnsupportedError('');
  Future<double> getSum(String table, String column, {String? where, List<dynamic>? whereArgs}) => throw UnsupportedError('');
}
