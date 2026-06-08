import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common/sqflite.dart' show Database, OpenDatabaseOptions;
import 'package:sqflite_common/utils/utils.dart' show firstIntValue;
import '../../constants/app_constants.dart' show AppConstants;

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
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    return await databaseFactoryFfiWeb.openDatabase(
      AppConstants.dbName,
      options: OpenDatabaseOptions(
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _seedDefaultData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''CREATE TABLE returns (id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER, bill_number TEXT, return_number TEXT NOT NULL UNIQUE, return_date TEXT NOT NULL, total_refund REAL NOT NULL DEFAULT 0, reason TEXT NOT NULL DEFAULT 'damaged', notes TEXT, created_at TEXT NOT NULL, FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE SET NULL)''');
    await db.execute('''CREATE TABLE return_items (id INTEGER PRIMARY KEY AUTOINCREMENT, return_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, quantity INTEGER NOT NULL, unit_price REAL NOT NULL, total_refund REAL NOT NULL, FOREIGN KEY (return_id) REFERENCES returns(id) ON DELETE CASCADE, FOREIGN KEY (medicine_id) REFERENCES medicines(id))''');
    await db.execute('''CREATE TABLE prescriptions (id INTEGER PRIMARY KEY AUTOINCREMENT, patient_name TEXT NOT NULL, patient_phone TEXT, doctor_name TEXT, prescription_date TEXT NOT NULL, notes TEXT, status TEXT NOT NULL DEFAULT 'active', created_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE prescription_items (id INTEGER PRIMARY KEY AUTOINCREMENT, prescription_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, dosage TEXT, frequency TEXT, duration TEXT, quantity INTEGER NOT NULL, FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE, FOREIGN KEY (medicine_id) REFERENCES medicines(id))''');
    await db.execute('''CREATE TABLE customer_orders (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, customer_name TEXT, order_number TEXT NOT NULL UNIQUE, order_date TEXT NOT NULL, total_amount REAL NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'pending', notes TEXT, store_id INTEGER DEFAULT 1, created_at TEXT NOT NULL, FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL)''');
    await db.execute('''CREATE TABLE customer_order_items (id INTEGER PRIMARY KEY AUTOINCREMENT, order_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, quantity INTEGER NOT NULL, unit_price REAL NOT NULL, total_price REAL NOT NULL, FOREIGN KEY (order_id) REFERENCES customer_orders(id) ON DELETE CASCADE, FOREIGN KEY (medicine_id) REFERENCES medicines(id))''');
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE medicines ADD COLUMN barcode TEXT");
    }
    if (oldVersion < 4) {
      await db.execute('''CREATE TABLE IF NOT EXISTS stores (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, address TEXT, phone TEXT, is_active INTEGER NOT NULL DEFAULT 1)''');
      await db.execute("ALTER TABLE medicines ADD COLUMN store_id INTEGER DEFAULT 1 REFERENCES stores(id)");
      await db.execute("ALTER TABLE sales ADD COLUMN store_id INTEGER DEFAULT 1 REFERENCES stores(id)");
      await db.execute("ALTER TABLE purchase_orders ADD COLUMN store_id INTEGER DEFAULT 1 REFERENCES stores(id)");
      await db.execute("ALTER TABLE inventory_transactions ADD COLUMN store_id INTEGER DEFAULT 1 REFERENCES stores(id)");
      await db.insert('stores', {'name': 'Main Store', 'address': '', 'phone': '', 'is_active': 1});
    }
    if (oldVersion < 5) {
      await db.execute('''CREATE TABLE IF NOT EXISTS prescriptions (id INTEGER PRIMARY KEY AUTOINCREMENT, patient_name TEXT NOT NULL, patient_phone TEXT, doctor_name TEXT, prescription_date TEXT NOT NULL, notes TEXT, status TEXT NOT NULL DEFAULT 'active', created_at TEXT NOT NULL)''');
      await db.execute('''CREATE TABLE IF NOT EXISTS prescription_items (id INTEGER PRIMARY KEY AUTOINCREMENT, prescription_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, dosage TEXT, frequency TEXT, duration TEXT, quantity INTEGER NOT NULL, FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE, FOREIGN KEY (medicine_id) REFERENCES medicines(id))''');
    }
    if (oldVersion < 6) {
      await db.execute("ALTER TABLE medicines ADD COLUMN wholesale_price REAL DEFAULT 0");
    }
    if (oldVersion < 7) {
      await db.execute('''CREATE TABLE IF NOT EXISTS customer_orders (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, customer_name TEXT, order_number TEXT NOT NULL UNIQUE, order_date TEXT NOT NULL, total_amount REAL NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'pending', notes TEXT, store_id INTEGER DEFAULT 1, created_at TEXT NOT NULL, FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL)''');
      await db.execute('''CREATE TABLE IF NOT EXISTS customer_order_items (id INTEGER PRIMARY KEY AUTOINCREMENT, order_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, quantity INTEGER NOT NULL, unit_price REAL NOT NULL, total_price REAL NOT NULL, FOREIGN KEY (order_id) REFERENCES customer_orders(id) ON DELETE CASCADE, FOREIGN KEY (medicine_id) REFERENCES medicines(id))''');
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL UNIQUE, password_hash TEXT NOT NULL, full_name TEXT NOT NULL, role TEXT NOT NULL DEFAULT 'pharmacist', created_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, description TEXT, created_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE stores (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, address TEXT, phone TEXT, is_active INTEGER NOT NULL DEFAULT 1)''');
    await db.execute('''CREATE TABLE medicines (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, generic_name TEXT, category_id INTEGER, manufacturer TEXT, unit TEXT NOT NULL DEFAULT 'strip', purchase_price REAL NOT NULL DEFAULT 0, selling_price REAL NOT NULL DEFAULT 0, wholesale_price REAL NOT NULL DEFAULT 0, stock_quantity INTEGER NOT NULL DEFAULT 0, reorder_level INTEGER NOT NULL DEFAULT 10, expiry_date TEXT, barcode TEXT, description TEXT, store_id INTEGER DEFAULT 1, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL)''');
    await db.execute('''CREATE TABLE suppliers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, contact_person TEXT, phone TEXT NOT NULL, email TEXT, address TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE customers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT NOT NULL, email TEXT, address TEXT, created_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE sales (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, customer_name TEXT, bill_number TEXT NOT NULL UNIQUE, sale_date TEXT NOT NULL, total_amount REAL NOT NULL DEFAULT 0, discount REAL, tax REAL, net_amount REAL NOT NULL DEFAULT 0, payment_method TEXT NOT NULL DEFAULT 'cash', notes TEXT, store_id INTEGER DEFAULT 1, created_at TEXT NOT NULL, FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL)''');
    await db.execute('''CREATE TABLE sale_items (id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, quantity INTEGER NOT NULL, unit_price REAL NOT NULL, total_price REAL NOT NULL, FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE, FOREIGN KEY (medicine_id) REFERENCES medicines(id))''');
    await db.execute('''CREATE TABLE purchase_orders (id INTEGER PRIMARY KEY AUTOINCREMENT, supplier_id INTEGER, supplier_name TEXT, order_number TEXT NOT NULL UNIQUE, order_date TEXT NOT NULL, total_amount REAL NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'pending', notes TEXT, store_id INTEGER DEFAULT 1, created_at TEXT NOT NULL, FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL)''');
    await db.execute('''CREATE TABLE purchase_order_items (id INTEGER PRIMARY KEY AUTOINCREMENT, purchase_order_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, quantity INTEGER NOT NULL, unit_price REAL NOT NULL, total_price REAL NOT NULL, FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE, FOREIGN KEY (medicine_id) REFERENCES medicines(id))''');
    await db.execute('''CREATE TABLE inventory_transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, medicine_id INTEGER NOT NULL, medicine_name TEXT, type TEXT NOT NULL, quantity INTEGER NOT NULL, reference_type TEXT, reference_id INTEGER, store_id INTEGER DEFAULT 1, notes TEXT, created_at TEXT NOT NULL, FOREIGN KEY (medicine_id) REFERENCES medicines(id))''');
    await db.execute('''CREATE TABLE returns (id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER, bill_number TEXT, return_number TEXT NOT NULL UNIQUE, return_date TEXT NOT NULL, total_refund REAL NOT NULL DEFAULT 0, reason TEXT NOT NULL DEFAULT 'damaged', notes TEXT, created_at TEXT NOT NULL, FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE SET NULL)''');
    await db.execute('''CREATE TABLE return_items (id INTEGER PRIMARY KEY AUTOINCREMENT, return_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, quantity INTEGER NOT NULL, unit_price REAL NOT NULL, total_refund REAL NOT NULL, FOREIGN KEY (return_id) REFERENCES returns(id) ON DELETE CASCADE, FOREIGN KEY (medicine_id) REFERENCES medicines(id))''');
  }

  Future<void> _seedDefaultData(Database db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert('stores', {'name': 'Main Store', 'address': '', 'phone': '', 'is_active': 1});
    await db.execute("INSERT INTO categories (name, description, created_at) VALUES ('Tablet', 'Solid dosage forms', ?), ('Capsule', 'Gelatin encapsulated medicines', ?), ('Syrup', 'Liquid oral medicines', ?), ('Injection', 'Injectable medicines', ?), ('Ointment', 'Topical applications', ?), ('Drop', 'Eye/ear/nasal drops', ?)", [now, now, now, now, now, now]);
    await db.insert('users', {'username': 'admin', 'password_hash': 'admin123', 'full_name': 'Administrator', 'role': 'admin', 'created_at': now});
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values);
  }

  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy, int? limit, int? offset}) async {
    final db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy, limit: limit, offset: offset);
  }

  Future<Map<String, dynamic>?> getById(String table, int id) async {
    final db = await database;
    final results = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> getCount(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table${where != null ? ' WHERE $where' : ''}', whereArgs);
    return firstIntValue(result) ?? 0;
  }

  Future<double> getSum(String table, String column, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COALESCE(SUM($column), 0) as total FROM $table${where != null ? ' WHERE $where' : ''}', whereArgs);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }
}
