# API Reference

## Core Services

### DatabaseHelper (`lib/core/database/database_helper.dart`)

```dart
Future<Database> get database;
static void setTestDatabase(Database? db);
Future<int> insert(String table, Map<String, dynamic> values);
Future<int> update(String table, Map<String, dynamic> values, {String? where, List<dynamic>? whereArgs});
Future<int> delete(String table, {String? where, List<dynamic>? whereArgs});
Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy, int? limit, int? offset});
Future<Map<String, dynamic>?> getById(String table, int id);
Future<int> getCount(String table, {String? where, List<dynamic>? whereArgs});
Future<double> getSum(String table, String column, {String? where, List<dynamic>? whereArgs});
```

### AuthService (`lib/features/auth/services/auth_service.dart`)

```dart
UserModel? get currentUser;
bool get isLoggedIn;
bool get isLoading;
bool get isAdmin;
Future<bool> login(String username, String password);
Future<void> logout();
Future<bool> loginByUsername(String username);
Future<int> createUser(UserModel user);
Future<List<UserModel>> getAllUsers();
```

### BiometricAuthService (`lib/features/auth/services/biometric_auth_service.dart`)

```dart
static Future<bool> isBiometricAvailable();
static Future<bool> authenticate(String reason);
static Future<void> enableBiometricLogin();
static Future<bool> isBiometricEnabled();
static Future<bool> tryAutoLogin();
```

### InventoryService (`lib/features/inventory/services/inventory_service.dart`)

```dart
List<MedicineModel> get medicines;
List<CategoryModel> get categories;
bool get isLoading;
List<MedicineModel> get lowStockMedicines;
List<MedicineModel> get nearExpiryMedicines;
int get totalStock;
int get expiredCount;
int get lowStockCount;
Future<void> loadMedicines();
Future<void> loadCategories();
Future<int> addMedicine(MedicineModel medicine);
Future<int> updateMedicine(MedicineModel medicine);
Future<void> deleteMedicine(int id);
Future<void> updateStock(int medicineId, int quantity, String type, {int? saleId, int? poId});
Future<List<InventoryTransactionModel>> getTransactionHistory({int? medicineId, String? type});
Future<int> addCategory(CategoryModel category);
Future<void> deleteCategory(int id);
List<MedicineModel> searchMedicines(String query);
```

### SalesService (`lib/features/sales/services/sales_service.dart`)

```dart
List<SaleModel> get sales;
bool get isLoading;
Future<void> loadSales();
Future<int> createSale(SaleModel sale, List<SaleItemModel> items, {bool isWholesale = false});
Future<SaleModel?> getSaleByBillNumber(String billNumber);
Future<void> deleteSale(int id);
```

### SupplierService (`lib/features/suppliers/services/supplier_service.dart`)

```dart
List<SupplierModel> get suppliers;
bool get isLoading;
Future<void> loadSuppliers();
Future<int> addSupplier(SupplierModel supplier);
Future<int> updateSupplier(SupplierModel supplier);
Future<void> deleteSupplier(int id);
List<SupplierModel> searchSuppliers(String query);
```

### CustomerService (`lib/features/customers/services/customer_service.dart`)

```dart
List<CustomerModel> get customers;
bool get isLoading;
Future<void> loadCustomers();
Future<int> addCustomer(CustomerModel customer);
Future<int> updateCustomer(CustomerModel customer);
Future<void> deleteCustomer(int id);
List<CustomerModel> searchCustomers(String query);
```

### PurchaseOrderService (`lib/features/purchases/services/purchase_order_service.dart`)

```dart
List<PurchaseOrderModel> get purchaseOrders;
bool get isLoading;
Future<void> loadPurchaseOrders({String? status});
Future<int> createPurchaseOrder(PurchaseOrderModel order);
Future<void> updateStatus(int id, String status);
```

### ReportsService (`lib/features/reports/services/reports_service.dart`)

```dart
bool get isLoading;
Future<Map<String, double>> getMonthlyRevenue();
Future<List<Map<String, dynamic>>> getTopMedicines({int limit = 10});
Future<Map<String, double>> getSalesByPaymentMethod();
Future<Map<String, double>> getSalesSummary();
Future<Map<String, dynamic>> getInventoryStats();
Future<Map<String, int>> getDailySalesCount({int days = 7});
Future<Map<String, double>> getWeeklyRevenue();
```

### ReturnService (`lib/features/returns/services/return_service.dart`)

```dart
List<ReturnModel> get returns;
bool get isLoading;
Future<void> loadReturns();
Future<int> createReturn(ReturnModel returnModel);
```

### DashboardService (`lib/features/dashboard/services/dashboard_service.dart`)

```dart
int get totalMedicines;
int get totalSales;
int get lowStockCount;
double get todayRevenue;
bool get isLoading;
Future<void> loadDashboard();
```

### StoreService (`lib/features/stores/services/store_service.dart`)

```dart
List<StoreModel> get stores;
int get selectedStoreId;
bool get isLoading;
StoreModel? get selectedStore;
void selectStore(int id);
Future<void> loadStores();
Future<int> addStore(StoreModel store);
Future<void> updateStore(StoreModel store);
```

### PrescriptionService (`lib/features/prescriptions/services/prescription_service.dart`)

```dart
List<PrescriptionModel> get prescriptions;
bool get isLoading;
Future<void> loadPrescriptions({String? status});
Future<int> createPrescription(PrescriptionModel prescription);
Future<void> updateStatus(int id, String status);
Future<PrescriptionModel?> getById(int id);
```

### OrderService (`lib/features/orders/services/order_service.dart`)

```dart
List<CustomerOrderModel> get orders;
bool get isLoading;
static String generateOrderNumber();
Future<void> loadOrders({String? status});
Future<int> createOrder(CustomerOrderModel order);
Future<void> updateStatus(int id, String status);
```

### SettingsService (`lib/features/settings/services/settings_service.dart`)

```dart
double get defaultTaxRate;
List<CouponCode> get coupons;
Future<void> loadSettings();
Future<void> setDefaultTaxRate(double rate);
Future<void> addCoupon(CouponCode coupon);
Future<void> removeCoupon(String code);
CouponCode? validateCoupon(String code);
```

### NotificationService (`lib/core/services/notification_service.dart`)

```dart
static Future<void> init();
static Future<void> checkAndNotify(InventoryService inventory);
```

### InvoiceService (`lib/core/services/invoice_service.dart`)

```dart
static Future<Uint8List> generateInvoice(SaleModel sale, List<SaleItemModel> items);
```

### SeedDataService (`lib/core/services/seed_data_service.dart`)

```dart
static Future<void> seedIfEmpty();
```

## Models

All models in `lib/models/` provide:
- `fromMap(Map<String, dynamic> map)` — factory constructor
- `Map<String, dynamic> toMap()` — serialization

Models: `MedicineModel`, `CategoryModel`, `SaleModel`/`SaleItemModel`, `SupplierModel`, `CustomerModel`, `UserModel`, `StoreModel`, `PrescriptionModel`/`PrescriptionItem`, `CustomerOrderModel`/`CustomerOrderItemModel`, `PurchaseOrderModel`/`PurchaseOrderItemModel`, `ReturnModel`/`ReturnItemModel`, `InventoryTransactionModel`.
