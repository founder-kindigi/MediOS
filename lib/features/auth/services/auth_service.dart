import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?.role == 'admin';

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final users = await _db.query('users',
          where: 'username = ?', whereArgs: [username]);
      if (users.isNotEmpty) {
        final user = UserModel.fromMap(users.first);
        if (user.passwordHash == password) {
          _currentUser = user;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> loginByUsername(String username) async {
    try {
      final users = await _db.query('users',
          where: 'username = ?', whereArgs: [username]);
      if (users.isNotEmpty) {
        _currentUser = UserModel.fromMap(users.first);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<int> createUser(UserModel user) async {
    return await _db.insert('users', user.toMap());
  }

  Future<List<UserModel>> getAllUsers() async {
    final maps = await _db.query('users', orderBy: 'full_name ASC');
    return maps.map((m) => UserModel.fromMap(m)).toList();
  }
}
