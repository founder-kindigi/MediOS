import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:medios/core/database/database_helper.dart';
import 'package:medios/core/di/service_locator.dart';
import 'package:medios/features/auth/services/auth_service.dart';
import 'package:medios/models/user_model.dart';

import 'package:shared_preferences/shared_preferences.dart';

class MockAuthService extends AuthService {
  LoginResult _loginResult = LoginSuccess(UserModel(
    username: 'test_user',
    passwordHash: 'hashed',
    fullName: 'Test User',
    role: 'admin',
  ));
  bool _mockLoading = false;
  String _loginUsername = '';
  String _loginPassword = '';

  MockAuthService() : super();

  void setLoginResult(bool success) {
    _loginResult = success 
        ? LoginSuccess(UserModel(
            username: 'test_user',
            passwordHash: 'hashed',
            fullName: 'Test User',
            role: 'admin',
          ))
        : const LoginFailure('Invalid username or password');
  }

  @override
  Future<LoginResult> login(String username, String password) async {
    _loginUsername = username;
    _loginPassword = password;
    _mockLoading = true;
    notifyListeners();
    await Future.delayed(Duration.zero);
    _mockLoading = false;
    notifyListeners();
    return _loginResult;
  }

  @override
  Future<bool> loginByUsername(String username) async {
    return username == 'test_user';
  }

  @override
  bool get isLoading => _mockLoading;

  String get lastLoginUsername => _loginUsername;
  String get lastLoginPassword => _loginPassword;
}

void setupWidgetTestLocator() {
  if (!GetIt.I.isRegistered<DatabaseHelper>()) {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    setupServiceLocator();
  }
}

Widget wrapWithProviders(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthService>(create: (_) => MockAuthService()),
    ],
    child: MaterialApp(home: child),
  );
}
