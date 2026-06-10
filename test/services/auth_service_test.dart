import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../test_helper.dart';
import 'package:medios/features/auth/services/auth_service.dart';
import 'package:medios/models/user_model.dart';

import 'package:medios/core/security/rate_limiter.dart';

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

  test('login with valid credentials returns success', () async {
    final result = await auth.login('test_admin', 'TestAdmin@Secure123');
    expect(result.isSuccess, true);
    expect(auth.isLoggedIn, true);
    expect(auth.currentUser?.username, 'test_admin');
    expect(auth.isAdmin, true);
  });

  test('login with invalid password returns failure', () async {
    final result = await auth.login('test_admin', 'wrongpassword');
    expect(result.isFailure, true);
    expect(auth.isLoggedIn, false);
    expect(result.errorMessage, contains('Invalid username or password'));
  });

  test('login with nonexistent user returns failure', () async {
    final result = await auth.login('nonexistent', 'somepassword');
    expect(result.isFailure, true);
    expect(auth.isLoggedIn, false);
  });

  test('logout clears current user', () async {
    final result = await auth.login('test_admin', 'TestAdmin@Secure123');
    expect(result.isSuccess, true);
    expect(auth.isLoggedIn, true);
    
    await auth.logout();
    expect(auth.isLoggedIn, false);
    expect(auth.currentUser, null);
  });

  test('createUser with valid data returns success', () async {
    final result = await auth.createUser(UserModel(
      username: 'new_pharmacist',
      passwordHash: 'NewPharmacist@Secure789',
      fullName: 'New Pharmacist',
      role: 'pharmacist',
    ));
    
    expect(result.isSuccess, true);
    expect(result.userIdOrNull, greaterThan(0));
    
    final users = await auth.getAllUsers();
    expect(users.length, 3); // 2 test users + 1 new user
  });

  test('createUser with weak password returns failure', () async {
    final result = await auth.createUser(UserModel(
      username: 'weak_user',
      passwordHash: 'weak',
      fullName: 'Weak User',
      role: 'pharmacist',
    ));
    
    expect(result.isFailure, true);
    expect(result.errorMessage, contains('Password must be at least'));
  });

  test('createUser with existing username returns failure', () async {
    final result = await auth.createUser(UserModel(
      username: 'test_admin', // Already exists
      passwordHash: 'AnotherPassword@123',
      fullName: 'Duplicate User',
      role: 'pharmacist',
    ));
    
    expect(result.isFailure, true);
    expect(result.errorMessage, contains('Username already exists'));
  });

  test('loginByUsername sets currentUser for existing user', () async {
    final ok = await auth.loginByUsername('test_admin');
    expect(ok, true);
    expect(auth.currentUser?.username, 'test_admin');
  });

  test('loginByUsername returns false for unknown user', () async {
    final ok = await auth.loginByUsername('ghost');
    expect(ok, false);
  });

  test('rate limiting prevents brute force attacks', () async {
    final rateLimiter = RateLimiter();
    rateLimiter.resetAll('test_admin');

    // First 4 attempts should fail with normal Invalid message
    for (int i = 0; i < 4; i++) {
      final result = await auth.login('test_admin', 'wrongpassword$i');
      expect(result.isFailure, true);
      expect(result.isRateLimited, false);
      expect(result.errorMessage, contains('Invalid username or password'));
    }
    
    // 5th attempt should fail and trigger lockout immediately
    final fifthResult = await auth.login('test_admin', 'wrongpassword4');
    expect(fifthResult.isRateLimited, true);
    expect((fifthResult as LoginRateLimited).seconds, greaterThan(0));

    // 6th attempt should be blocked immediately without checking credentials
    final sixthResult = await auth.login('test_admin', 'wrongpassword5');
    expect(sixthResult.isRateLimited, true);
  });
}
