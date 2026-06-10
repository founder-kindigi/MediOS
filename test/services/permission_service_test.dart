import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:medios/core/database/database_helper.dart';
import 'package:medios/core/security/permissions.dart';
import 'package:medios/features/auth/services/permission_service.dart';
import 'package:medios/models/user_model.dart';
import '../test_helper.dart';

void main() {
  late Database db;
  late PermissionService service;

  setUp(() async {
    db = await createAndSetTestDb();
    service = PermissionService(databaseHelper: DatabaseHelper());
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  group('PermissionService Tests', () {
    test('Initial state has no user and role', () {
      expect(service.currentUser, isNull);
      expect(service.currentRole, isNull);
    });

    test('setCurrentUser loads correct role and permissions', () async {
      final user = UserModel(
        id: 1,
        username: 'test_admin',
        fullName: 'Test Admin',
        role: 'admin',
        passwordHash: 'dummy',
      );

      await service.setCurrentUser(user);
      expect(service.currentUser, equals(user));
      expect(service.currentRole, equals(AppRoles.admin));
      expect(service.hasPermission(AppPermission.canManageUsers), isTrue);
      expect(service.hasPermission(AppPermission.canRestoreBackup), isTrue);
    });

    test('setCurrentUser with null clears role and user', () async {
      final user = UserModel(
        id: 1,
        username: 'test_admin',
        fullName: 'Test Admin',
        role: 'admin',
        passwordHash: 'dummy',
      );

      await service.setCurrentUser(user);
      expect(service.currentUser, isNotNull);

      await service.setCurrentUser(null);
      expect(service.currentUser, isNull);
      expect(service.currentRole, isNull);
      expect(service.hasPermission(AppPermission.canManageUsers), isFalse);
    });

    test('checkPermission throws exception if role is null or permission missing', () async {
      // 1. Null user
      expect(
        () => service.checkPermission(AppPermission.canCreateSale),
        throwsA(isA<PermissionDeniedException>()),
      );

      // 2. User with limited permissions (cashier)
      final cashier = UserModel(
        id: 2,
        username: 'test_cashier',
        fullName: 'Test Cashier',
        role: 'cashier',
        passwordHash: 'dummy',
      );

      await service.setCurrentUser(cashier);
      expect(service.hasPermission(AppPermission.canCreateSale), isTrue);
      expect(service.hasPermission(AppPermission.canManageUsers), isFalse);

      // Should not throw for canCreateSale
      expect(() => service.checkPermission(AppPermission.canCreateSale), returnsNormally);

      // Should throw for canManageUsers
      expect(
        () => service.checkPermission(AppPermission.canManageUsers),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('hasAllPermissions and hasAnyPermission verify permission sets', () async {
      final manager = UserModel(
        id: 3,
        username: 'test_manager',
        fullName: 'Test Manager',
        role: 'manager',
        passwordHash: 'dummy',
      );

      await service.setCurrentUser(manager);
      
      final allPerms = {AppPermission.canCreateSale, AppPermission.canEditStock};
      expect(service.hasAllPermissions(allPerms), isTrue);

      final mixedPerms = {AppPermission.canCreateSale, AppPermission.canManageUsers};
      expect(service.hasAllPermissions(mixedPerms), isFalse);
      expect(service.hasAnyPermission(mixedPerms), isTrue);
    });

    test('canPerformAction maps action names correctly', () async {
      final cashier = UserModel(
        id: 2,
        username: 'test_cashier',
        fullName: 'Test Cashier',
        role: 'cashier',
        passwordHash: 'dummy',
      );

      await service.setCurrentUser(cashier);
      expect(service.canPerformAction('create_sale'), isTrue);
      expect(service.canPerformAction('manage_users'), isFalse);
      expect(service.canPerformAction('non_existent_action'), isTrue); // default fallback
    });

    test('updateUserRole updates role in db and reloads for current user', () async {
      final user = UserModel(
        id: 1,
        username: 'test_admin',
        fullName: 'Test Admin',
        role: 'admin',
        passwordHash: 'dummy',
      );

      await service.setCurrentUser(user);
      expect(service.currentRole, equals(AppRoles.admin));

      await service.updateUserRole(1, 'cashier');
      expect(service.currentUser?.role, equals('cashier'));
      expect(service.currentRole, equals(AppRoles.cashier));

      // Verify db state
      final maps = await db.query('users', where: 'id = ?', whereArgs: [1]);
      expect(maps.first['role'], equals('cashier'));
    });
  });
}
