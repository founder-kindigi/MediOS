# PRODUCTION HARDENING SPRINT 1
**Objective**: Close highest-risk production gaps identified after architecture refactor  
**Status**: IN PROGRESS  
**Do NOT add unrelated features**  
**Focus**: Backup/Restore, Quality Gates, Customer Credit, Permissions, Critical Tests

## 🎯 TASK 1: Secure Backup and Restore Functionality

### **Status**: Started
### **Files Created/Modified**:
1. `lib/core/services/backup_service.dart` - New backup/restore service
2. `lib/features/backup/screens/backup_screen.dart` - Backup UI screen  
3. `lib/features/backup/screens/restore_screen.dart` - Restore UI screen
4. `lib/features/backup/widgets/backup_card.dart` - Backup card widget
5. `lib/models/backup_metadata.dart` - Backup metadata model

### **Code Implementation**:
```dart
// BackupService - Core backup logic
class BackupService {
  static const String backupExtension = '.mediosbackup';
  static const int backupVersion = 1;
  
  Future<BackupResult> createBackup() async {
    try {
      final dbPath = await DatabaseHelper().databasePath;
      final backupFile = await _createBackupFile(dbPath);
      final metadata = await _createMetadata(backupFile);
      
      return BackupResult.success(
        file: backupFile,
        metadata: metadata,
        message: 'Backup created successfully',
      );
    } catch (e, stackTrace) {
      return BackupResult.failure(
        error: 'Failed to create backup: $e',
        stackTrace: stackTrace,
      );
    }
  }
  
  Future<RestoreResult> restoreBackup(File backupFile) async {
    // Validate backup before restoring
    final validation = await validateBackup(backupFile);
    if (!validation.isValid) {
      return RestoreResult.failure(
        error: 'Invalid backup: ${validation.error}',
      );
    }
    
    // Create temporary copy of current database
    final currentDbBackup = await _createTemporaryBackup();
    
    try {
      await _performRestore(backupFile);
      return RestoreResult.success(
        message: 'Restore completed successfully',
        originalBackup: currentDbBackup,
      );
    } catch (e, stackTrace) {
      // Restore from temporary backup if restore fails
      await _restoreFromBackup(currentDbBackup);
      return RestoreResult.failure(
        error: 'Restore failed, original database restored: $e',
        stackTrace: stackTrace,
      );
    }
  }
}
```

### **Backup File Format**:
```json
{
  "metadata": {
    "app": "MediOS",
    "backupVersion": 1,
    "databaseVersion": 10,
    "createdAt": "2026-06-09T21:00:00Z",
    "storeId": "STORE_UUID",
    "checksum": "sha256:abc123...",
    "recordCounts": {
      "medicines": 125,
      "customers": 45,
      "sales": 320
    }
  },
  "database": "Base64-encoded encrypted database file"
}
```

### **Remaining Risks**:
- File encryption implementation pending
- Large database backup performance
- Cross-platform file path compatibility

### **Recommended Next Action**:
Complete encryption implementation and add backup scheduling.

## 🎯 TASK 2: Run Quality Gates

### **Status**: In Progress
### **Commands to Run**:
1. `flutter clean`
2. `flutter pub get` 
3. `flutter analyze`
4. `flutter test`
5. `flutter build apk`
6. `flutter build windows`
7. `flutter build web` (if supported)

### **Current Results**:
**Note**: Unable to run Flutter commands directly in this environment. Need to verify locally.

### **Estimated Issues Based on Code Analysis**:
1. **Potential Null Safety Issues**: Some older code may have null safety violations
2. **Unused Imports**: Likely some unused imports after refactoring
3. **Missing Dependencies**: May need additional packages for backup functionality
4. **Platform-Specific Code**: Web build may have issues with SQLite

### **Remaining Risks**:
- Unknown compilation errors without actual build
- Platform-specific issues undetected
- Performance regressions in new code

### **Recommended Next Action**:
Run quality gates locally and provide exact error/warning report.

## 🎯 TASK 3: Customer Credit/Khata Management

### **Status**: Started
### **Files Created/Modified**:
1. `lib/features/customers/models/customer_credit.dart` - Credit models
2. `lib/features/customers/services/customer_credit_service.dart` - Credit service
3. `lib/features/sales/services/credit_sale_service.dart` - Credit sale transactions
4. `lib/features/customers/screens/customer_ledger_screen.dart` - Ledger UI
5. `lib/features/reports/screens/outstanding_balance_report.dart` - Reports

### **Code Implementation**:
```dart
// CreditSaleService - Transaction-safe credit sales
class CreditSaleService {
  Future<CreditSaleResult> createCreditSale({
    required SaleModel sale,
    required List<SaleItemModel> items,
    required int customerId,
    double? partialPayment,
  }) async {
    return await db.transaction((txn) async {
      // 1. Stock validation
      for (final item in items) {
        final stock = await _validateStock(txn, item);
        if (!stock.hasSufficient) {
          throw InsufficientStockException(item, stock.available);
        }
      }
      
      // 2. Create sale
      final saleId = await txn.insert('sales', sale.toMap());
      
      // 3. Create sale items
      for (final item in items) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'medicine_id': item.medicineId,
          ...item.toMap(),
        });
        
        // 4. Deduct stock
        await _deductStock(txn, item);
        
        // 5. Inventory transaction log
        await _logInventoryTransaction(txn, item, saleId);
      }
      
      // 6. Update customer balance
      final totalAmount = sale.netAmount;
      await _updateCustomerBalance(
        txn, 
        customerId, 
        totalAmount, 
        partialPayment,
      );
      
      // 7. Create ledger entry
      await _createLedgerEntry(
        txn,
        customerId,
        saleId,
        totalAmount,
        partialPayment,
      );
      
      return CreditSaleResult.success(saleId: saleId);
    });
  }
}
```

### **Remaining Risks**:
- Complex transaction rollback scenarios
- Concurrent credit updates handling
- Partial payment edge cases
- Ledger reconciliation logic

### **Recommended Next Action**:
Complete ledger reporting and add credit limit enforcement.

## 🎯 TASK 4: Role-Based Permissions

### **Status**: Started
### **Files Created/Modified**:
1. `lib/core/security/permissions.dart` - Permission definitions
2. `lib/core/security/role_manager.dart` - Role management
3. `lib/models/user_role.dart` - Role models
4. `lib/features/auth/services/permission_service.dart` - Permission checking
5. `lib/middleware/permission_middleware.dart` - Permission enforcement

### **Code Implementation**:
```dart
// Permission definitions
enum AppPermission {
  canCreateSale,
  canDeleteSale,
  canRefundSale,
  canEditStock,
  canViewProfit,
  canManageUsers,
  canExportReports,
  canRestoreBackup,
  canEditPurchase,
  canManageCredit,
  canViewAuditLog,
}

// Role definitions
class UserRole {
  static const Role admin = Role(
    name: 'Admin',
    permissions: AppPermission.values,
  );
  
  static const Role manager = Role(
    name: 'Manager',
    permissions: [
      AppPermission.canCreateSale,
      AppPermission.canEditStock,
      AppPermission.canViewProfit,
      AppPermission.canExportReports,
      AppPermission.canEditPurchase,
      AppPermission.canManageCredit,
    ],
  );
  
  static const Role cashier = Role(
    name: 'Cashier',
    permissions: [
      AppPermission.canCreateSale,
    ],
  );
  
  static const Role inventoryOfficer = Role(
    name: 'Inventory Officer',
    permissions: [
      AppPermission.canEditStock,
      AppPermission.canEditPurchase,
    ],
  );
}

// Permission checking in services
class PermissionService {
  static bool checkPermission(AppPermission permission) {
    final userRole = _getCurrentUserRole();
    final userPermissions = _getUserPermissions(userRole);
    
    if (!userPermissions.contains(permission)) {
      throw PermissionDeniedException(
        permission: permission,
        requiredRole: _getRequiredRole(permission),
      );
    }
    
    return true;
  }
}
```

### **Remaining Risks**:
- Permission caching and invalidation
- Role inheritance complexity
- Permission checking performance
- Audit logging completeness

### **Recommended Next Action**:
Implement permission middleware for all service methods.

## 🎯 TASK 5: Minimum Business-Critical Tests

### **Status**: Started
### **Test Files Created**:
1. `test/features/sales/credit_sale_test.dart` - Credit sale transactions
2. `test/features/backup/backup_service_test.dart` - Backup/restore tests
3. `test/features/auth/permission_test.dart` - Permission enforcement tests
4. `test/features/customers/customer_credit_test.dart` - Credit management tests
5. `test/features/inventory/stock_transaction_test.dart` - Stock transaction safety

### **Test Coverage Goals**:
```dart
// Example test structure
test('Credit sale with insufficient stock should fail transaction', () async {
  // Setup
  final service = CreditSaleService();
  final customer = CustomerModel(id: 1, name: 'Test Customer');
  final medicine = MedicineModel(id: 1, name: 'Test Med', stockQuantity: 5);
  final sale = SaleModel(totalAmount: 100);
  final items = [SaleItemModel(medicineId: 1, quantity: 10)]; // Request 10, only 5 available
  
  // Execute & Verify
  expect(
    () => service.createCreditSale(
      sale: sale,
      items: items,
      customerId: customer.id,
    ),
    throwsA(isA<InsufficientStockException>()),
  );
  
  // Verify stock unchanged
  final updatedMedicine = await medicineRepository.getById(1);
  expect(updatedMedicine.stockQuantity, equals(5));
});

test('Backup restore should preserve all data', () async {
  // Setup with test data
  await _seedTestData();
  
  // Create backup
  final backupService = BackupService();
  final backupResult = await backupService.createBackup();
  expect(backupResult.isSuccess, isTrue);
  
  // Modify data
  await _modifyTestData();
  
  // Restore from backup
  final restoreResult = await backupService.restoreBackup(backupResult.file!);
  expect(restoreResult.isSuccess, isTrue);
  
  // Verify original data restored
  final restoredData = await _getAllTestData();
  expect(restoredData, equals(_originalTestData));
});
```

### **Remaining Risks**:
- Test data isolation
- Async test timing issues
- Platform-specific test failures
- Test maintenance overhead

### **Recommended Next Action**:
Complete test suite and add CI/CD pipeline configuration.

## 📊 SPRINT 1 PROGRESS SUMMARY

### **Completed**:
- Backup service architecture designed
- Credit sale transaction pattern defined
- Permission system structure created
- Test framework expanded

### **In Progress**:
- Backup file encryption implementation
- Quality gates execution
- Credit ledger reporting
- Permission middleware

### **Blocked**:
- Actual Flutter command execution (environment limitation)
- Platform-specific build verification

### **Next Immediate Actions**:
1. Complete backup encryption implementation
2. Create permission enforcement middleware
3. Finish credit ledger reporting
4. Write comprehensive test suite

### **Risk Assessment**:
- **HIGH**: Backup/restore without proper testing
- **MEDIUM**: Permission system complexity
- **MEDIUM**: Credit transaction edge cases
- **LOW**: Test coverage gaps

## 🎯 EVIDENCE-BASED STATUS

**Current Sprint Status**: Production hardening in progress  
**Evidence Collected**: Architecture designs, code patterns, test plans  
**Missing Evidence**: Actual build results, test execution reports  
**Confidence Level**: 🔶 MODERATE (designs complete, implementation pending)  
**Risk Level**: 🟡 MODERATE (critical features being implemented)

**Do not describe as enterprise-ready** - Focus on completing hardening tasks first.
