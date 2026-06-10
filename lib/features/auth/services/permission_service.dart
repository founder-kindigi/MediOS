import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import '../../../core/security/permissions.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/user_model.dart';

/// Service for managing user permissions and role-based access control.
class PermissionService extends ChangeNotifier {
  final DatabaseHelper _db;
  
  UserModel? _currentUser;
  Role? _currentRole;
  
  PermissionService({DatabaseHelper? databaseHelper})
      : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>();

  /// Gets the current user's role.
  Role? get currentRole => _currentRole;
  
  /// Gets the current user.
  UserModel? get currentUser => _currentUser;
  
  /// Checks if a user has a specific permission.
  bool hasPermission(AppPermission permission) {
    if (_currentRole == null) {
      return false;
    }
    
    return _currentRole!.hasPermission(permission);
  }
  
  /// Checks if a user has all specified permissions.
  bool hasAllPermissions(Set<AppPermission> permissions) {
    if (_currentRole == null) {
      return false;
    }
    
    return _currentRole!.hasAllPermissions(permissions);
  }
  
  /// Checks if a user has any of the specified permissions.
  bool hasAnyPermission(Set<AppPermission> permissions) {
    if (_currentRole == null) {
      return false;
    }
    
    return _currentRole!.hasAnyPermission(permissions);
  }
  
  /// Asserts that the current user has a specific permission.
  /// Throws PermissionDeniedException if permission is missing.
  void checkPermission(AppPermission permission) {
    if (_currentRole == null) {
      throw PermissionDeniedException(
        permission: permission,
        message: 'No user logged in',
      );
    }
    
    if (!_currentRole!.hasPermission(permission)) {
      throw PermissionDeniedException(
        permission: permission,
        message: 'User "${_currentUser?.username}" (role: ${_currentRole!.name}) does not have permission: $permission',
      );
    }
  }
  
  /// Asserts that the current user has all specified permissions.
  /// Throws PermissionDeniedException if any permission is missing.
  void checkAllPermissions(Set<AppPermission> permissions) {
    if (_currentRole == null) {
      throw PermissionDeniedException(
        permission: permissions.first,
        message: 'No user logged in',
      );
    }
    
    for (final permission in permissions) {
      if (!_currentRole!.hasPermission(permission)) {
        throw PermissionDeniedException(
          permission: permission,
          message: 'User "${_currentUser?.username}" (role: ${_currentRole!.name}) does not have permission: $permission',
        );
      }
    }
  }
  
  /// Sets the current user and loads their role.
  Future<void> setCurrentUser(UserModel? user) async {
    _currentUser = user;
    
    if (user != null) {
      await _loadUserRole(user);
    } else {
      _currentRole = null;
    }
    
    notifyListeners();
  }
  
  /// Loads a user's role from the database.
  Future<void> _loadUserRole(UserModel user) async {
    try {
      // Try to get role from user's role field
      final userRoleName = user.role?.toLowerCase() ?? 'cashier'; // Default to cashier
      
      // Get role from predefined roles
      _currentRole = AppRoles.getRoleByName(userRoleName) ?? AppRoles.cashier;
      
      // If user has a custom role in database, we could load it here
      // For now, using predefined roles based on user.role field
    } catch (e) {
      // Fallback to cashier role on error
      _currentRole = AppRoles.cashier;
    }
  }
  
  /// Gets all available roles in the system.
  List<Role> getAvailableRoles() {
    return AppRoles.allRoles;
  }
  
  /// Updates a user's role in the database.
  Future<void> updateUserRole(int userId, String roleName) async {
    try {
      final db = await _db.database;
      await db.update(
        'users',
        {'role': roleName},
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      // If this is the current user, reload the role
      if (_currentUser?.id == userId) {
        _currentUser = _currentUser?.copyWith(role: roleName);
        await _loadUserRole(_currentUser!);
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }
  
  /// Gets permission descriptions for the current user.
  List<String> getCurrentUserPermissions() {
    if (_currentRole == null) {
      return [];
    }
    
    return _currentRole!.permissions
        .map(PermissionUtils.getPermissionDescription)
        .toList();
  }
  
  /// Gets permission categories and permissions for display.
  Map<String, List<AppPermission>> getPermissionCategories() {
    final categories = <String, List<AppPermission>>{};
    
    for (final permission in AppPermission.values) {
      final category = PermissionUtils.getPermissionCategory(permission);
      categories.putIfAbsent(category, () => []).add(permission);
    }
    
    return categories;
  }
  
  /// Checks if the current user can perform a specific action.
  /// Returns true if allowed, false otherwise.
  bool canPerformAction(String action) {
    // Map actions to permissions
    final actionToPermission = {
      'create_sale': AppPermission.canCreateSale,
      'delete_sale': AppPermission.canDeleteSale,
      'refund_sale': AppPermission.canRefundSale,
      'edit_stock': AppPermission.canEditStock,
      'adjust_stock': AppPermission.canAdjustStock,
      'create_purchase': AppPermission.canCreatePurchase,
      'manage_customers': AppPermission.canManageCustomers,
      'manage_credit': AppPermission.canManageCustomerCredit,
      'view_profit': AppPermission.canViewProfit,
      'export_reports': AppPermission.canExportReports,
      'manage_users': AppPermission.canManageUsers,
      'restore_backup': AppPermission.canRestoreBackup,
      'manage_settings': AppPermission.canManageSettings,
    };
    
    final permission = actionToPermission[action];
    if (permission == null) {
      // If action not mapped, assume allowed for backward compatibility
      return true;
    }
    
    return hasPermission(permission);
  }
  
  @override
  void dispose() {
    _currentUser = null;
    _currentRole = null;
    super.dispose();
  }
}

/// Permission-aware widget builder.
typedef PermissionWidgetBuilder = Widget Function(
  BuildContext context,
  bool hasPermission,
);

/// Permission middleware for service methods.
class PermissionMiddleware {
  /// Wraps a service method with permission checking.
  static Future<T> withPermission<T>(
    AppPermission permission,
    Future<T> Function() action, {
    PermissionService? permissionService,
  }) async {
    final service = permissionService ?? GetIt.instance<PermissionService>();
    
    // Check permission
    service.checkPermission(permission);
    
    // Execute action
    return await action();
  }
  
  /// Wraps a service method with multiple permission checks.
  static Future<T> withAllPermissions<T>(
    Set<AppPermission> permissions,
    Future<T> Function() action, {
    PermissionService? permissionService,
  }) async {
    final service = permissionService ?? GetIt.instance<PermissionService>();
    
    // Check all permissions
    service.checkAllPermissions(permissions);
    
    // Execute action
    return await action();
  }
}