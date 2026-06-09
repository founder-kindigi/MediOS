import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import '../../lib/features/auth/services/auth_service.dart';
import '../../lib/models/user_model.dart';

void main() {
  late Database db;
  late AuthService auth;

  setUp(() async {
    db = await createAndSetTestDb();
    auth = AuthService();
  });

  tearDown(() async {
    await db.close();
    resetTestDb();
  });

  test('login with valid credentials returns true', () async {
    final result = await auth.login('admin', 'admin123');
    expect(result, true);
    expect(auth.isLoggedIn, true);
    expect(auth.currentUser?.username, 'admin');
  });

  test('login with invalid password returns false', () async {
    final result = await auth.login('admin', 'wrong');
    expect(result, false);
    expect(auth.isLoggedIn, false);
  });

  test('login with nonexistent user returns false', () async {
    final result = await auth.login('nobody', 'pass');
    expect(result, false);
  });

  test('isAdmin returns true for admin role', () async {
    await auth.login('admin', 'admin123');
    expect(auth.isAdmin, true);
  });

  test('logout clears current user', () async {
    await auth.login('admin', 'admin123');
    expect(auth.isLoggedIn, true);
    await auth.logout();
    expect(auth.isLoggedIn, false);
    expect(auth.currentUser, null);
  });

  test('createUser inserts and returns id', () async {
    final id = await auth.createUser(UserModel(
      username: 'pharmacist1', passwordHash: 'pass123',
      fullName: 'Pharmacist One', role: 'pharmacist',
    ));
    expect(id, greaterThan(0));
    final users = await auth.getAllUsers();
    expect(users.length, 2);
  });

  test('loginByUsername sets currentUser', () async {
    final ok = await auth.loginByUsername('admin');
    expect(ok, true);
    expect(auth.currentUser?.username, 'admin');
  });

  test('loginByUsername returns false for unknown user', () async {
    final ok = await auth.loginByUsername('ghost');
    expect(ok, false);
  });
}
