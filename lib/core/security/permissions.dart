import 'package:flutter/foundation.dart';

/// Application permissions enum.
/// Each permission corresponds to a specific action in the system.
@immutable
enum AppPermission {
  // Sales permissions
  canCreateSale,
  canDeleteSale,
  canRefundSale,
  canViewSales,
  
  // Inventory permissions
  canEditStock,
  canAdjustStock,
  canViewStock,
  canManageCategories,
  
  // Purchases permissions
  canCreatePurchase,
  canEditPurchase,
  canApprovePurchase,
  canViewPurchases,
  
  // Customers permissions
  canManageCustomers,
  canManageCustomerCredit,
  canViewCustomerLedger,
  
  // Suppliers permissions
  canManageSuppliers,
  canViewSupplierLedger,
  
  // Reports permissions
  canViewProfit,
  canViewReports,
  canExportReports,
  
  // User management permissions
  canManageUsers,
  canManageRoles,
  canViewAuditLog,
  
  // System permissions
  canRestoreBackup,
  canExportData,
  canImportData,
  canManageSettings,
  
  // Prescriptions permissions
  canManagePrescriptions,
  canViewPrescriptions,
  
  // Orders permissions
  canManageOrders,
  canViewOrders,
}

/// Role definition with associated permissions.
@immutable
class Role {
  final String name;
  final String description;
  final Set<AppPermission> permissions;
  final int level; // Higher level = more permissions

  const Role({
    required this.name,
    required this.permissions,
    this.description = '',
    this.level = 0,
  });

  /// Checks if this role has a specific permission.
  bool hasPermission(AppPermission permission) {
    return permissions.contains(permission);
  }

  /// Checks if this role has all the specified permissions.
  bool hasAllPermissions(Set<AppPermission> requiredPermissions) {
    return requiredPermissions.every((p) => permissions.contains(p));
  }

  /// Checks if this role has any of the specified permissions.
  bool hasAnyPermission(Set<AppPermission> requiredPermissions) {
    return requiredPermissions.any((p) => permissions.contains(p));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Role &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          setEquals(permissions, other.permissions);

  @override
  int get hashCode => name.hashCode ^ permissions.hashCode;

  @override
  String toString() {
    return 'Role(name: $name, permissions: ${permissions.length})';
  }
}

/// Predefined roles for MediOS.
class AppRoles {
  /// System administrator with full access.
  static const Role admin = Role(
    name: 'Admin',
    description: 'Full system access including user management and backups',
    level: 100,
    permissions: {
      // Sales
      AppPermission.canCreateSale,
      AppPermission.canDeleteSale,
      AppPermission.canRefundSale,
      AppPermission.canViewSales,
      
      // Inventory
      AppPermission.canEditStock,
      AppPermission.canAdjustStock,
      AppPermission.canViewStock,
      AppPermission.canManageCategories,
      
      // Purchases
      AppPermission.canCreatePurchase,
      AppPermission.canEditPurchase,
      AppPermission.canApprovePurchase,
      AppPermission.canViewPurchases,
      
      // Customers
      AppPermission.canManageCustomers,
      AppPermission.canManageCustomerCredit,
      AppPermission.canViewCustomerLedger,
      
      // Suppliers
      AppPermission.canManageSuppliers,
      AppPermission.canViewSupplierLedger,
      
      // Reports
      AppPermission.canViewProfit,
      AppPermission.canViewReports,
      AppPermission.canExportReports,
      
      // User management
      AppPermission.canManageUsers,
      AppPermission.canManageRoles,
      AppPermission.canViewAuditLog,
      
      // System
      AppPermission.canRestoreBackup,
      AppPermission.canExportData,
      AppPermission.canImportData,
      AppPermission.canManageSettings,
      
      // Prescriptions
      AppPermission.canManagePrescriptions,
      AppPermission.canViewPrescriptions,
      
      // Orders
      AppPermission.canManageOrders,
      AppPermission.canViewOrders,
    },
  );

  /// Pharmacy manager with most operational permissions.
  static const Role manager = Role(
    name: 'Manager',
    description: 'Manages daily operations, inventory, and reports',
    level: 80,
    permissions: {
      // Sales
      AppPermission.canCreateSale,
      AppPermission.canRefundSale,
      AppPermission.canViewSales,
      
      // Inventory
      AppPermission.canEditStock,
      AppPermission.canAdjustStock,
      AppPermission.canViewStock,
      AppPermission.canManageCategories,
      
      // Purchases
      AppPermission.canCreatePurchase,
      AppPermission.canEditPurchase,
      AppPermission.canViewPurchases,
      
      // Customers
      AppPermission.canManageCustomers,
      AppPermission.canManageCustomerCredit,
      AppPermission.canViewCustomerLedger,
      
      // Suppliers
      AppPermission.canManageSuppliers,
      AppPermission.canViewSupplierLedger,
      
      // Reports
      AppPermission.canViewProfit,
      AppPermission.canViewReports,
      AppPermission.canExportReports,
      
      // Prescriptions
      AppPermission.canManagePrescriptions,
      AppPermission.canViewPrescriptions,
      
      // Orders
      AppPermission.canManageOrders,
      AppPermission.canViewOrders,
    },
  );

  /// Cashier/POS operator with limited sales permissions.
  static const Role cashier = Role(
    name: 'Cashier',
    description: 'Handles sales transactions and customer service',
    level: 50,
    permissions: {
      // Sales
      AppPermission.canCreateSale,
      AppPermission.canViewSales,
      
      // Inventory
      AppPermission.canViewStock,
      
      // Customers
      AppPermission.canManageCustomers, // For creating new customers during sale
      
      // Prescriptions
      AppPermission.canViewPrescriptions,
      
      // Orders
      AppPermission.canViewOrders,
    },
  );

  /// Inventory officer with stock management permissions.
  static const Role inventoryOfficer = Role(
    name: 'Inventory Officer',
    description: 'Manages stock, purchases, and inventory transactions',
    level: 60,
    permissions: {
      // Inventory
      AppPermission.canEditStock,
      AppPermission.canAdjustStock,
      AppPermission.canViewStock,
      AppPermission.canManageCategories,
      
      // Purchases
      AppPermission.canCreatePurchase,
      AppPermission.canEditPurchase,
      AppPermission.canViewPurchases,
      
      // Suppliers
      AppPermission.canManageSuppliers,
      AppPermission.canViewSupplierLedger,
      
      // Reports
      AppPermission.canViewReports,
    },
  );

  /// Accountant with financial reporting permissions.
  static const Role accountant = Role(
    name: 'Accountant',
    description: 'Handles financial reports, ledgers, and exports',
    level: 70,
    permissions: {
      // Sales
      AppPermission.canViewSales,
      
      // Purchases
      AppPermission.canViewPurchases,
      
      // Customers
      AppPermission.canViewCustomerLedger,
      
      // Suppliers
      AppPermission.canViewSupplierLedger,
      
      // Reports
      AppPermission.canViewProfit,
      AppPermission.canViewReports,
      AppPermission.canExportReports,
      
      // System
      AppPermission.canExportData,
    },
  );

  /// Read-only viewer for reports and monitoring.
  static const Role viewer = Role(
    name: 'Viewer',
    description: 'Read-only access for monitoring and reporting',
    level: 10,
    permissions: {
      // Sales
      AppPermission.canViewSales,
      
      // Inventory
      AppPermission.canViewStock,
      
      // Purchases
      AppPermission.canViewPurchases,
      
      // Reports
      AppPermission.canViewReports,
      
      // Prescriptions
      AppPermission.canViewPrescriptions,
      
      // Orders
      AppPermission.canViewOrders,
    },
  );

  /// Gets a role by name.
  static Role? getRoleByName(String name) {
    return _rolesByName[name.toLowerCase()];
  }

  /// Gets all available roles.
  static List<Role> get allRoles => _allRoles;

  /// Private mapping of role names to roles.
  static final Map<String, Role> _rolesByName = {
    'admin': admin,
    'manager': manager,
    'cashier': cashier,
    'inventory officer': inventoryOfficer,
    'inventoryofficer': inventoryOfficer,
    'accountant': accountant,
    'viewer': viewer,
  };

  /// Private list of all roles.
  static const List<Role> _allRoles = [
    admin,
    manager,
    cashier,
    inventoryOfficer,
    accountant,
    viewer,
  ];
}

/// Exception thrown when a user lacks required permissions.
class PermissionDeniedException implements Exception {
  final AppPermission permission;
  final String message;
  final StackTrace? stackTrace;

  PermissionDeniedException({
    required this.permission,
    this.message = 'Permission denied',
    this.stackTrace,
  });

  @override
  String toString() {
    return 'PermissionDeniedException: $message (permission: $permission)';
  }
}

/// Utility class for permission checking and validation.
class PermissionUtils {
  /// Checks if a role has permission to perform an action.
  /// Throws PermissionDeniedException if permission is missing.
  static void checkPermission(Role role, AppPermission permission) {
    if (!role.hasPermission(permission)) {
      throw PermissionDeniedException(
        permission: permission,
        message: 'Role "${role.name}" does not have permission: $permission',
      );
    }
  }

  /// Checks if a role has all required permissions.
  /// Throws PermissionDeniedException if any permission is missing.
  static void checkAllPermissions(Role role, Set<AppPermission> permissions) {
    for (final permission in permissions) {
      if (!role.hasPermission(permission)) {
        throw PermissionDeniedException(
          permission: permission,
          message: 'Role "${role.name}" does not have permission: $permission',
        );
      }
    }
  }

  /// Gets a descriptive name for a permission.
  static String getPermissionDescription(AppPermission permission) {
    return switch (permission) {
      // Sales
      AppPermission.canCreateSale => 'Create new sales',
      AppPermission.canDeleteSale => 'Delete sales',
      AppPermission.canRefundSale => 'Process refunds',
      AppPermission.canViewSales => 'View sales history',
      
      // Inventory
      AppPermission.canEditStock => 'Edit medicine stock',
      AppPermission.canAdjustStock => 'Adjust stock quantities',
      AppPermission.canViewStock => 'View inventory',
      AppPermission.canManageCategories => 'Manage medicine categories',
      
      // Purchases
      AppPermission.canCreatePurchase => 'Create purchase orders',
      AppPermission.canEditPurchase => 'Edit purchase orders',
      AppPermission.canApprovePurchase => 'Approve purchase orders',
      AppPermission.canViewPurchases => 'View purchase history',
      
      // Customers
      AppPermission.canManageCustomers => 'Manage customer information',
      AppPermission.canManageCustomerCredit => 'Manage customer credit',
      AppPermission.canViewCustomerLedger => 'View customer ledger',
      
      // Suppliers
      AppPermission.canManageSuppliers => 'Manage supplier information',
      AppPermission.canViewSupplierLedger => 'View supplier ledger',
      
      // Reports
      AppPermission.canViewProfit => 'View profit reports',
      AppPermission.canViewReports => 'View all reports',
      AppPermission.canExportReports => 'Export reports to file',
      
      // User management
      AppPermission.canManageUsers => 'Manage user accounts',
      AppPermission.canManageRoles => 'Manage user roles',
      AppPermission.canViewAuditLog => 'View audit logs',
      
      // System
      AppPermission.canRestoreBackup => 'Restore from backup',
      AppPermission.canExportData => 'Export system data',
      AppPermission.canImportData => 'Import data',
      AppPermission.canManageSettings => 'Manage system settings',
      
      // Prescriptions
      AppPermission.canManagePrescriptions => 'Manage prescriptions',
      AppPermission.canViewPrescriptions => 'View prescriptions',
      
      // Orders
      AppPermission.canManageOrders => 'Manage customer orders',
      AppPermission.canViewOrders => 'View customer orders',
    };
  }

  /// Gets the category/group for a permission.
  static String getPermissionCategory(AppPermission permission) {
    return switch (permission) {
      AppPermission.canCreateSale ||
      AppPermission.canDeleteSale ||
      AppPermission.canRefundSale ||
      AppPermission.canViewSales => 'Sales',
      
      AppPermission.canEditStock ||
      AppPermission.canAdjustStock ||
      AppPermission.canViewStock ||
      AppPermission.canManageCategories => 'Inventory',
      
      AppPermission.canCreatePurchase ||
      AppPermission.canEditPurchase ||
      AppPermission.canApprovePurchase ||
      AppPermission.canViewPurchases => 'Purchases',
      
      AppPermission.canManageCustomers ||
      AppPermission.canManageCustomerCredit ||
      AppPermission.canViewCustomerLedger => 'Customers',
      
      AppPermission.canManageSuppliers ||
      AppPermission.canViewSupplierLedger => 'Suppliers',
      
      AppPermission.canViewProfit ||
      AppPermission.canViewReports ||
      AppPermission.canExportReports => 'Reports',
      
      AppPermission.canManageUsers ||
      AppPermission.canManageRoles ||
      AppPermission.canViewAuditLog => 'User Management',
      
      AppPermission.canRestoreBackup ||
      AppPermission.canExportData ||
      AppPermission.canImportData ||
      AppPermission.canManageSettings => 'System',
      
      AppPermission.canManagePrescriptions ||
      AppPermission.canViewPrescriptions => 'Prescriptions',
      
      AppPermission.canManageOrders ||
      AppPermission.canViewOrders => 'Orders',
    };
  }
}