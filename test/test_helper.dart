import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/utils/utils.dart' show firstIntValue;
import '../lib/core/database/database_helper.dart';

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
  await db.execute('''CREATE TABLE customers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT NOT NULL, email TEXT, address TEXT, created_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE sales (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, customer_name TEXT, bill_number TEXT NOT NULL UNIQUE, sale_date TEXT NOT NULL, total_amount REAL NOT NULL DEFAULT 0, discount REAL, tax REAL, net_amount REAL NOT NULL DEFAULT 0, payment_method TEXT NOT NULL DEFAULT 'cash', notes TEXT, store_id INTEGER DEFAULT 1, created_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE sale_items (id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, quantity INTEGER NOT NULL, unit_price REAL NOT NULL, total_price REAL NOT NULL)''');
  await db.execute('''CREATE TABLE purchase_orders (id INTEGER PRIMARY KEY AUTOINCREMENT, supplier_id INTEGER, supplier_name TEXT, order_number TEXT NOT NULL UNIQUE, order_date TEXT NOT NULL, total_amount REAL NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'pending', notes TEXT, store_id INTEGER DEFAULT 1, created_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE purchase_order_items (id INTEGER PRIMARY KEY AUTOINCREMENT, purchase_order_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, quantity INTEGER NOT NULL, unit_price REAL NOT NULL, total_price REAL NOT NULL)''');
  await db.execute('''CREATE TABLE inventory_transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, medicine_id INTEGER NOT NULL, medicine_name TEXT, type TEXT NOT NULL, quantity INTEGER NOT NULL, reference_type TEXT, reference_id INTEGER, store_id INTEGER DEFAULT 1, notes TEXT, created_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE returns (id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER, bill_number TEXT, return_number TEXT NOT NULL UNIQUE, return_date TEXT NOT NULL, total_refund REAL NOT NULL DEFAULT 0, reason TEXT NOT NULL DEFAULT 'damaged', notes TEXT, created_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE return_items (id INTEGER PRIMARY KEY AUTOINCREMENT, return_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, quantity INTEGER NOT NULL, unit_price REAL NOT NULL, total_refund REAL NOT NULL)''');
  await db.execute('''CREATE TABLE stores (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, address TEXT, phone TEXT, is_active INTEGER NOT NULL DEFAULT 1)''');
  await db.execute('''CREATE TABLE prescriptions (id INTEGER PRIMARY KEY AUTOINCREMENT, patient_name TEXT NOT NULL, patient_phone TEXT, doctor_name TEXT, prescription_date TEXT NOT NULL, notes TEXT, status TEXT NOT NULL DEFAULT 'active', created_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE prescription_items (id INTEGER PRIMARY KEY AUTOINCREMENT, prescription_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, dosage TEXT, frequency TEXT, duration TEXT, quantity INTEGER NOT NULL)''');
  await db.execute('''CREATE TABLE customer_orders (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, customer_name TEXT, order_number TEXT NOT NULL UNIQUE, order_date TEXT NOT NULL, total_amount REAL NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'pending', notes TEXT, store_id INTEGER DEFAULT 1, created_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE customer_order_items (id INTEGER PRIMARY KEY AUTOINCREMENT, order_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, quantity INTEGER NOT NULL, unit_price REAL NOT NULL, total_price REAL NOT NULL)''');
}

Future<Database> createAndSetTestDb() async {
  final db = await createTestDb();
  DatabaseHelper.setTestDatabase(db);
  final now = DateTime.now().toIso8601String();
  await db.insert('stores', {'name': 'Main Store', 'address': '', 'phone': '', 'is_active': 1});
  await db.insert('users', {'username': 'admin', 'password_hash': 'admin123', 'full_name': 'Administrator', 'role': 'admin', 'created_at': now});
  return db;
}

void resetTestDb() {
  DatabaseHelper.setTestDatabase(null);
}
