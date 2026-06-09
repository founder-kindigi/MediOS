import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../../lib/core/database/database_helper.dart';
import '../../lib/core/di/service_locator.dart';
import '../../lib/features/auth/services/auth_service.dart';

class MockAuthService extends AuthService {
  bool _loginResult = true;
  bool _mockLoading = false;
  String _loginUsername = '';
  String _loginPassword = '';

  MockAuthService() : super();

  void setLoginResult(bool result) {
    _loginResult = result;
  }

  @override
  Future<bool> login(String username, String password) async {
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
    return false;
  }

  @override
  bool get isLoading => _mockLoading;

  String get lastLoginUsername => _loginUsername;
  String get lastLoginPassword => _loginPassword;
}

void setupWidgetTestLocator() {
  if (!GetIt.I.isRegistered<DatabaseHelper>()) {
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
