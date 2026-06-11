import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/utils/utils.dart' show firstIntValue;
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart' show compute, debugPrint;
import '../../constants/app_constants.dart' show AppConstants;
import '../../errors/app_error.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  static void setTestDatabase(Database? db) {
    _database = db;
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    sqfliteFfiInit();
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, AppConstants.dbName);
    return await databaseFactoryFfi.openDatabase(
      path,
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
    if (oldVersion < 8) {
      final rows = await db.rawQuery('SELECT id, password_hash FROM users');
      for (final row in rows) {
        final id = row['id'] as int;
        final pw = row['password_hash'] as String;
        if (!pw.startsWith(r'$2')) {
          final hash = await compute(_computeBcryptHash, pw);
          await db.update('users', {'password_hash': hash}, where: 'id = ?', whereArgs: [id]);
        }
      }
    }
    if (oldVersion < 9) {
      await _createPerformanceIndexes(db);
    }
    if (oldVersion < 10) {
      await db.execute("ALTER TABLE prescriptions ADD COLUMN store_id INTEGER DEFAULT 1 REFERENCES stores(id)");
    }
    if (oldVersion < 11) {
      // Add credit_limit column to customers table
      await db.execute("ALTER TABLE customers ADD COLUMN credit_limit REAL DEFAULT 0");
      await db.execute("ALTER TABLE customers ADD COLUMN opening_balance REAL DEFAULT 0");
      await db.execute("ALTER TABLE customers ADD COLUMN current_balance REAL DEFAULT 0");
      await db.execute("ALTER TABLE customers ADD COLUMN last_credit_update TEXT");
      
      // Create credit_transactions table
      await db.execute('''
        CREATE TABLE credit_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id INTEGER NOT NULL,
          transaction_date TEXT NOT NULL,
          transaction_type TEXT NOT NULL,
          reference_id INTEGER,
          reference_type TEXT,
          amount REAL NOT NULL,
          balance_after REAL NOT NULL,
          description TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
        )
      ''');
      
      // Create customer_payments table
      await db.execute('''
        CREATE TABLE customer_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id INTEGER NOT NULL,
          payment_date TEXT NOT NULL,
          amount REAL NOT NULL,
          payment_method TEXT NOT NULL DEFAULT 'cash',
          reference_number TEXT,
          description TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
        )
      ''');
      
      // Create indexes for credit tables
      await db.execute('CREATE INDEX idx_credit_transactions_customer_id ON credit_transactions(customer_id)');
      await db.execute('CREATE INDEX idx_credit_transactions_date ON credit_transactions(transaction_date)');
      await db.execute('CREATE INDEX idx_customer_payments_customer_id ON customer_payments(customer_id)');
      await db.execute('CREATE INDEX idx_customer_payments_date ON customer_payments(payment_date)');
      
      // Initialize current_balance from existing sales (if any)
      await _initializeCustomerBalances(db);
    }
  }

  /// Initializes customer balances from existing sales data during migration.
  Future<void> _initializeCustomerBalances(Database db) async {
    try {
      // Get all customers
      final customers = await db.query('customers');
      
      for (final customer in customers) {
        final customerId = customer['id'] as int;
        
        // Calculate total sales for customer
        final salesResult = await db.rawQuery('''
          SELECT COALESCE(SUM(net_amount), 0) as total_sales 
          FROM sales 
          WHERE customer_id = ? AND payment_method = 'credit'
        ''', [customerId]);
        
        final totalSales = (salesResult.first['total_sales'] as num?)?.toDouble() ?? 0;
        
        // Calculate total payments for customer (if payments table exists)
        double totalPayments = 0;
        try {
          final paymentsResult = await db.rawQuery('''
            SELECT COALESCE(SUM(amount), 0) as total_payments 
            FROM customer_payments 
            WHERE customer_id = ?
          ''', [customerId]);
          totalPayments = (paymentsResult.first['total_payments'] as num?)?.toDouble() ?? 0;
        } catch (e) {
          // Payments table might not exist yet
        }
        
        // Calculate current balance
        final currentBalance = totalSales - totalPayments;
        
        // Update customer record
        await db.update(
          'customers',
          {
            'current_balance': currentBalance,
            'last_credit_update': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [customerId],
        );
        
        // Create initial transaction record if balance > 0
        if (currentBalance > 0) {
          await db.insert('credit_transactions', {
            'customer_id': customerId,
            'transaction_date': DateTime.now().toIso8601String(),
            'transaction_type': 'migration',
            'amount': currentBalance,
            'balance_after': currentBalance,
            'description': 'Initial balance from migration',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      // Log error but don't fail migration
      debugPrint('Error initializing customer balances: $e');
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL UNIQUE, password_hash TEXT NOT NULL, full_name TEXT NOT NULL, role TEXT NOT NULL DEFAULT 'pharmacist', created_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, description TEXT, created_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE medicines (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, generic_name TEXT, category_id INTEGER, manufacturer TEXT, unit TEXT NOT NULL DEFAULT 'strip', purchase_price REAL NOT NULL DEFAULT 0, selling_price REAL NOT NULL DEFAULT 0, wholesale_price REAL NOT NULL DEFAULT 0, stock_quantity INTEGER NOT NULL DEFAULT 0, reorder_level INTEGER NOT NULL DEFAULT 10, expiry_date TEXT, barcode TEXT, description TEXT, store_id INTEGER DEFAULT 1, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL)''');
    await db.execute('''CREATE TABLE suppliers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, contact_person TEXT, phone TEXT NOT NULL, email TEXT, address TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE customers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT NOT NULL, email TEXT, address TEXT, credit_limit REAL DEFAULT 0, opening_balance REAL DEFAULT 0, current_balance REAL DEFAULT 0, last_credit_update TEXT, created_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE sales (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, customer_name TEXT, bill_number TEXT NOT NULL UNIQUE, sale_date TEXT NOT NULL, total_amount REAL NOT NULL DEFAULT 0, discount REAL, tax REAL, net_amount REAL NOT NULL DEFAULT 0, payment_method TEXT NOT NULL DEFAULT 'cash', notes TEXT, store_id INTEGER DEFAULT 1, created_at TEXT NOT NULL, FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL)''');
    await db.execute('''CREATE TABLE sale_items (id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, quantity INTEGER NOT NULL, unit_price REAL NOT NULL, total_price REAL NOT NULL, FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE, FOREIGN KEY (medicine_id) REFERENCES medicines(id))''');
    await db.execute('''CREATE TABLE purchase_orders (id INTEGER PRIMARY KEY AUTOINCREMENT, supplier_id INTEGER, supplier_name TEXT, order_number TEXT NOT NULL UNIQUE, order_date TEXT NOT NULL, total_amount REAL NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'pending', notes TEXT, store_id INTEGER DEFAULT 1, created_at TEXT NOT NULL, FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL)''');
    await db.execute('''CREATE TABLE purchase_order_items (id INTEGER PRIMARY KEY AUTOINCREMENT, purchase_order_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, quantity INTEGER NOT NULL, unit_price REAL NOT NULL, total_price REAL NOT NULL, FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE, FOREIGN KEY (medicine_id) REFERENCES medicines(id))''');
    await db.execute('''CREATE TABLE stores (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, address TEXT, phone TEXT, is_active INTEGER NOT NULL DEFAULT 1)''');
    await db.execute('''CREATE TABLE inventory_transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, medicine_id INTEGER NOT NULL, medicine_name TEXT, type TEXT NOT NULL, quantity INTEGER NOT NULL, reference_type TEXT, reference_id INTEGER, store_id INTEGER DEFAULT 1, notes TEXT, created_at TEXT NOT NULL, FOREIGN KEY (medicine_id) REFERENCES medicines(id))''');
    await db.execute('''CREATE TABLE returns (id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER, bill_number TEXT, return_number TEXT NOT NULL UNIQUE, return_date TEXT NOT NULL, total_refund REAL NOT NULL DEFAULT 0, reason TEXT NOT NULL DEFAULT 'damaged', notes TEXT, created_at TEXT NOT NULL, FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE SET NULL)''');
    await db.execute('''CREATE TABLE return_items (id INTEGER PRIMARY KEY AUTOINCREMENT, return_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, quantity INTEGER NOT NULL, unit_price REAL NOT NULL, total_refund REAL NOT NULL, FOREIGN KEY (return_id) REFERENCES returns(id) ON DELETE CASCADE, FOREIGN KEY (medicine_id) REFERENCES medicines(id))''');
    await db.execute('''CREATE TABLE prescriptions (id INTEGER PRIMARY KEY AUTOINCREMENT, patient_name TEXT NOT NULL, patient_phone TEXT, doctor_name TEXT, prescription_date TEXT NOT NULL, notes TEXT, status TEXT NOT NULL DEFAULT 'active', store_id INTEGER DEFAULT 1 REFERENCES stores(id), created_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE prescription_items (id INTEGER PRIMARY KEY AUTOINCREMENT, prescription_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, dosage TEXT, frequency TEXT, duration TEXT, quantity INTEGER NOT NULL, FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE, FOREIGN KEY (medicine_id) REFERENCES medicines(id))''');
    await db.execute('''CREATE TABLE customer_orders (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, customer_name TEXT, order_number TEXT NOT NULL UNIQUE, order_date TEXT NOT NULL, total_amount REAL NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'pending', notes TEXT, store_id INTEGER DEFAULT 1, created_at TEXT NOT NULL, FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL)''');
    await db.execute('''CREATE TABLE customer_order_items (id INTEGER PRIMARY KEY AUTOINCREMENT, order_id INTEGER NOT NULL, medicine_id INTEGER NOT NULL, medicine_name TEXT, quantity INTEGER NOT NULL, unit_price REAL NOT NULL, total_price REAL NOT NULL, FOREIGN KEY (order_id) REFERENCES customer_orders(id) ON DELETE CASCADE, FOREIGN KEY (medicine_id) REFERENCES medicines(id))''');
    
    // Create credit system tables
    await db.execute('''
      CREATE TABLE credit_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        transaction_date TEXT NOT NULL,
        transaction_type TEXT NOT NULL,
        reference_id INTEGER,
        reference_type TEXT,
        amount REAL NOT NULL,
        balance_after REAL NOT NULL,
        description TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE customer_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        payment_date TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'cash',
        reference_number TEXT,
        description TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');
    
    // Create performance indexes
    await _createPerformanceIndexes(db);
  }
  
  Future<void> _createPerformanceIndexes(Database db) async {
    // Medicines table indexes (most queried table)
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_medicines_store_id 
      ON medicines(store_id)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_medicines_category_id 
      ON medicines(category_id)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_medicines_expiry_date 
      ON medicines(expiry_date)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_medicines_barcode 
      ON medicines(barcode)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_medicines_name 
      ON medicines(name)
    ''');
    
    // Composite indexes for common query patterns
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_medicines_store_expiry 
      ON medicines(store_id, expiry_date)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_medicines_store_category 
      ON medicines(store_id, category_id)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_medicines_store_stock 
      ON medicines(store_id, stock_quantity)
    ''');
    
    // Sales table indexes
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sales_store_id 
      ON sales(store_id)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sales_created_at 
      ON sales(created_at)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sales_customer_id 
      ON sales(customer_id)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sales_store_date 
      ON sales(store_id, created_at)
    ''');
    
    // Inventory transactions
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_inv_trans_medicine_id 
      ON inventory_transactions(medicine_id)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_inv_trans_created_at 
      ON inventory_transactions(created_at)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_inv_trans_store_id 
      ON inventory_transactions(store_id)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_inv_trans_store_medicine 
      ON inventory_transactions(store_id, medicine_id)
    ''');
    
    // Sale items
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id 
      ON sale_items(sale_id)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sale_items_medicine_id 
      ON sale_items(medicine_id)
    ''');
    
    // Purchase orders
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_purchase_orders_store_id 
      ON purchase_orders(store_id)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_purchase_orders_status 
      ON purchase_orders(status)
    ''');
    
    // Users table
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_users_username 
      ON users(username)
    ''');
    
    // Customers table
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_customers_phone 
      ON customers(phone)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_customers_name 
      ON customers(name)
    ''');
    
    // Suppliers table
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_suppliers_name 
      ON suppliers(name)
    ''');
  }

  Future<void> _seedDefaultData(Database db) async {
    final now = DateTime.now().toIso8601String();
    
    // Create default store
    await db.insert('stores', {
      'name': 'Main Pharmacy', 
      'address': 'Update your pharmacy address', 
      'phone': '', 
      'is_active': 1
    });
    
    // Create default categories (no users - first-time setup required)
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
    
    // Note: No default admin user is created
    // First user must be created through first-time setup wizard
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    try {
      final db = await database;
      return await db.insert(table, values);
    } catch (e) {
      throw AppError(message: 'Failed to insert $table record', type: ErrorType.database, originalError: e);
    }
  }

  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<dynamic>? whereArgs}) async {
    try {
      final db = await database;
      return await db.update(table, values, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw AppError(message: 'Failed to update $table record', type: ErrorType.database, originalError: e);
    }
  }

  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    try {
      final db = await database;
      return await db.delete(table, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw AppError(message: 'Failed to delete $table record', type: ErrorType.database, originalError: e);
    }
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy, int? limit, int? offset}) async {
    try {
      final db = await database;
      return await db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy, limit: limit, offset: offset);
    } catch (e) {
      throw AppError(message: 'Failed to query $table', type: ErrorType.database, originalError: e);
    }
  }

  Future<Map<String, dynamic>?> getById(String table, int id) async {
    try {
      final db = await database;
      final results = await db.query(table, where: 'id = ?', whereArgs: [id]);
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      throw AppError(message: 'Failed to fetch $table record', type: ErrorType.database, originalError: e);
    }
  }

  void _validateIdentifier(String name) {
    final regex = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
    if (!regex.hasMatch(name)) {
      throw ArgumentError('Invalid database identifier: $name');
    }
  }

  Future<int> getCount(String table, {String? where, List<dynamic>? whereArgs}) async {
    try {
      _validateIdentifier(table);
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table${where != null ? ' WHERE $where' : ''}', whereArgs);
      return firstIntValue(result) ?? 0;
    } catch (e) {
      throw AppError(message: 'Failed to count $table records', type: ErrorType.database, originalError: e);
    }
  }

  Future<double> getSum(String table, String column, {String? where, List<dynamic>? whereArgs}) async {
    try {
      _validateIdentifier(table);
      _validateIdentifier(column);
      final db = await database;
      final result = await db.rawQuery('SELECT COALESCE(SUM($column), 0) as total FROM $table${where != null ? ' WHERE $where' : ''}', whereArgs);
      return (result.first['total'] as num?)?.toDouble() ?? 0;
    } catch (e) {
      throw AppError(message: 'Failed to sum $table.$column', type: ErrorType.database, originalError: e);
    }
  }

  /// Opens a database at a specific file path.
  /// Used for backup verification and restore operations.
  Future<Database> openDatabaseAtPath(String filePath) async {
    try {
      final database = await databaseFactoryFfi.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: AppConstants.dbVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onDowngrade: onDatabaseDowngradeDelete,
        ),
      );
      
      return database;
    } catch (e) {
      throw AppError(
        message: 'Failed to open database at path: $filePath',
        type: ErrorType.database,
        originalError: e,
      );
    }
  }

  /// Gets the current database file path.
  Future<String> get databasePath async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, AppConstants.dbName);
  }

  /// Gets the current database version.
  Future<int> getVersion() async {
    final db = await database;
    return await db.getVersion();
  }
}

String _computeBcryptHash(String password) {
  return BCrypt.hashpw(password, BCrypt.gensalt());
}

