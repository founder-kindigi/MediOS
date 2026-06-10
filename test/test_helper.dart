import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:medios/core/database/database_helper.dart';
import 'package:medios/core/di/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

DatabaseFactory get factory => databaseFactoryFfi;

Future<Database> createTestDb() async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
    options: OpenDatabaseOptions(version: 1, onCreate: (db, v) async {
      await _createTables(db);
    }),
  );
  return db;
}

Future<void> _createTables(Database db) async {
  await db.execute('''CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL UNIQUE, password_hash TEXT NOT NULL, full_name TEXT NOT NULL, role TEXT NOT NULL DEFAULT 'pharmacist', created_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, description TEXT, created_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE medicines (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, generic_name TEXT, category_id INTEGER, manufacturer TEXT, unit TEXT NOT NULL DEFAULT 'strip', purchase_price REAL NOT NULL DEFAULT 0, selling_price REAL NOT NULL DEFAULT 0, wholesale_price REAL NOT NULL DEFAULT 0, stock_quantity INTEGER NOT NULL DEFAULT 0, reorder_level INTEGER NOT NULL DEFAULT 10, expiry_date TEXT, barcode TEXT, description TEXT, store_id INTEGER DEFAULT 1, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE suppliers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, contact_person TEXT, phone TEXT NOT NULL, email TEXT, address TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE customers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT NOT NULL, email TEXT, address TEXT, credit_limit REAL DEFAULT 0, opening_balance REAL DEFAULT 0, current_balance REAL DEFAULT 0, last_credit_update TEXT, created_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE sales (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, customer_name TEXT, bill_number TEXT NOT NULL UNIQUE, sale_date TEXT NOT NULL, total_amount REAL NOT NULL DEFAULT 0, discount REAL, tax REAL, net_amount REAL NOT NULL DEFAULT 0, payment_method TEXT NOT NULL DEFAULT 'cash', notes TEXT, store_id INTEGER DEFAULT 1, created_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE sale_items (id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, quantity INTEGER NOT NULL, unit_price REAL NOT NULL, total_price REAL NOT NULL)''');
  await db.execute('''CREATE TABLE purchase_orders (id INTEGER PRIMARY KEY AUTOINCREMENT, supplier_id INTEGER, supplier_name TEXT, order_number TEXT NOT NULL UNIQUE, order_date TEXT NOT NULL, total_amount REAL NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'pending', notes TEXT, store_id INTEGER DEFAULT 1, created_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE purchase_order_items (id INTEGER PRIMARY KEY AUTOINCREMENT, purchase_order_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, quantity INTEGER NOT NULL, unit_price REAL NOT NULL, total_price REAL NOT NULL)''');
  await db.execute('''CREATE TABLE inventory_transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, medicine_id INTEGER NOT NULL, medicine_name TEXT, type TEXT NOT NULL, quantity INTEGER NOT NULL, reference_type TEXT, reference_id INTEGER, store_id INTEGER DEFAULT 1, notes TEXT, created_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE returns (id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER, bill_number TEXT, return_number TEXT NOT NULL UNIQUE, return_date TEXT NOT NULL, total_refund REAL NOT NULL DEFAULT 0, reason TEXT NOT NULL DEFAULT 'damaged', notes TEXT, created_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE return_items (id INTEGER PRIMARY KEY AUTOINCREMENT, return_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, quantity INTEGER NOT NULL, unit_price REAL NOT NULL, total_refund REAL NOT NULL)''');
  await db.execute('''CREATE TABLE stores (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, address TEXT, phone TEXT, is_active INTEGER NOT NULL DEFAULT 1)''');
  await db.execute('''CREATE TABLE prescriptions (id INTEGER PRIMARY KEY AUTOINCREMENT, patient_name TEXT NOT NULL, patient_phone TEXT, doctor_name TEXT, prescription_date TEXT NOT NULL, notes TEXT, status TEXT NOT NULL DEFAULT 'active', store_id INTEGER DEFAULT 1, created_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE prescription_items (id INTEGER PRIMARY KEY AUTOINCREMENT, prescription_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, dosage TEXT, frequency TEXT, duration TEXT, quantity INTEGER NOT NULL)''');
  await db.execute('''CREATE TABLE customer_orders (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, customer_name TEXT, order_number TEXT NOT NULL UNIQUE, order_date TEXT NOT NULL, total_amount REAL NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'pending', notes TEXT, store_id INTEGER DEFAULT 1, created_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE customer_order_items (id INTEGER PRIMARY KEY AUTOINCREMENT, order_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, quantity INTEGER NOT NULL, unit_price REAL NOT NULL, total_price REAL NOT NULL)''');
  await db.execute('''CREATE TABLE credit_transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER NOT NULL, transaction_date TEXT NOT NULL, transaction_type TEXT NOT NULL, reference_id INTEGER, reference_type TEXT, amount REAL NOT NULL, balance_after REAL NOT NULL, description TEXT, notes TEXT, created_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE customer_payments (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER NOT NULL, payment_date TEXT NOT NULL, amount REAL NOT NULL, payment_method TEXT NOT NULL DEFAULT 'cash', reference_number TEXT, description TEXT, notes TEXT, created_at TEXT NOT NULL)''');
}

Future<Database> createAndSetTestDb() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  setupServiceLocator();
  final db = await createTestDb();
  DatabaseHelper.setTestDatabase(db);
  final now = DateTime.now().toIso8601String();
  
  // Create test store
  await db.insert('stores', {
    'name': 'Test Store', 
    'address': '123 Test Street', 
    'phone': '555-0123', 
    'is_active': 1
  });
  
  // Create test categories
  await db.execute("""
    INSERT INTO categories (name, description, created_at) 
    VALUES 
      ('Tablet', 'Solid dosage forms', ?),
      ('Capsule', 'Gelatin encapsulated medicines', ?),
      ('Syrup', 'Liquid oral medicines', ?),
      ('Injection', 'Injectable medicines', ?),
      ('Ointment', 'Topical applications', ?),
      ('Drop', 'Eye/ear/nasal drops', ?)
  """, [now, now, now, now, now, now]);
  
  // Create test users with strong passwords
  final testUsers = [
    {
      'username': 'test_admin',
      'password_hash': BCrypt.hashpw('TestAdmin@Secure123', BCrypt.gensalt()),
      'full_name': 'Test Administrator',
      'role': 'admin',
      'created_at': now,
    },
    {
      'username': 'test_pharmacist',
      'password_hash': BCrypt.hashpw('Pharmacist@Secure456', BCrypt.gensalt()),
      'full_name': 'Test Pharmacist',
      'role': 'pharmacist',
      'created_at': now,
    },
  ];
  
  for (final user in testUsers) {
    await db.insert('users', user);
  }
  
  return db;
}

void resetTestDb() {
  DatabaseHelper.setTestDatabase(null);
  GetIt.I.reset();
}
