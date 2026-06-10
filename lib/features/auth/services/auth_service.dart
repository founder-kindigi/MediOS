import 'package:flutter/foundation.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:get_it/get_it.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/security/password_policy.dart';
import '../../../core/security/input_validator.dart';
import '../../../core/security/rate_limiter.dart';
import '../../../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final DatabaseHelper _db;
  final RateLimiter _rateLimiter;
  
  // Pre-computed static dummy BCrypt hash string for timing attack protection
  static const String _dummyHash = r'$2a$10$Lg59Jm36Zc2G.3P7gV5qeeWfG4V6N5b1S8/PjF9lZq7YhR4y5O8W.';

  AuthService({DatabaseHelper? databaseHelper, RateLimiter? rateLimiter})
      : _db = databaseHelper ?? GetIt.instance<DatabaseHelper>(),
        _rateLimiter = rateLimiter ?? GetIt.instance<RateLimiter>();
        
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?.role == 'admin';

  Future<LoginResult> login(String username, String password) async {
    // Input validation
    if (!InputValidator.isValidUsername(username)) {
      return LoginResult.failure('Invalid username format');
    }

    if (password.isEmpty) {
      return LoginResult.failure('Password is required');
    }

    // Rate limiting check
    if (_rateLimiter.isLockedOut(username, 'login')) {
      final remainingTime = _rateLimiter.getTimeUntilReset(username, 'login');
      return LoginResult.rateLimited(remainingTime);
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Use constant-time comparison to prevent timing attacks
      final result = await _performSecureLogin(username, password);
      
      if (result.isSuccess) {
        _rateLimiter.reset(username, 'login');
      } else {
        final isLimitedNow = _rateLimiter.isRateLimited(username, 'login');
        if (isLimitedNow) {
          _isLoading = false;
          notifyListeners();
          final remainingTime = _rateLimiter.getTimeUntilReset(username, 'login');
          return LoginResult.rateLimited(remainingTime);
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return result;
    } on AppError {
      _isLoading = false;
      notifyListeners();
      return LoginResult.failure('Authentication error');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return LoginResult.failure('Unexpected error occurred');
    }
  }

  Future<LoginResult> _performSecureLogin(String username, String password) async {
    // Always perform the same operations regardless of user existence
    // to prevent timing attacks
    
    // 1. Query database (same query regardless of user existence)
    final users = await _db.query('users', where: 'username = ?', whereArgs: [username]);
    
    // 2. Always use the same BCrypt verification operation to ensure constant time
    final userHash = users.isNotEmpty 
        ? UserModel.fromMap(users.first).passwordHash
        : _dummyHash;
    
    // 3. Use constant-time password comparison
    final passwordMatches = _constantTimeCompare(password, userHash);
    
    if (users.isNotEmpty && passwordMatches) {
      final user = UserModel.fromMap(users.first);
      _currentUser = user;
      return LoginResult.success(user);
    }
    
    // Always wait a minimum time to prevent timing attacks
    await Future.delayed(const Duration(milliseconds: 100));
    
    return LoginResult.failure('Invalid username or password');
  }

  /// Constant-time string comparison to prevent timing attacks.
  bool _constantTimeCompare(String input, String storedHash) {
    // Use BCrypt's built-in constant-time comparison
    return BCrypt.checkpw(input, storedHash);
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

  Future<UserCreationResult> createUser(UserModel user) async {
    // Validate username
    if (!InputValidator.isValidUsername(user.username)) {
      return UserCreationResult.failure('Invalid username format');
    }
    
    // Validate full name
    if (!InputValidator.isValidFullName(user.fullName)) {
      return UserCreationResult.failure('Invalid full name format');
    }
    
    // Validate password against policy
    final passwordErrors = PasswordPolicy.validate(user.passwordHash);
    if (passwordErrors.isNotEmpty) {
      return UserCreationResult.failure(passwordErrors.first);
    }
    
    // Check if username already exists
    final existingUsers = await _db.query('users',
        where: 'username = ?', whereArgs: [user.username]);
    if (existingUsers.isNotEmpty) {
      return UserCreationResult.failure('Username already exists');
    }
    
    try {
      final hashedUser = UserModel(
        username: user.username,
        passwordHash: BCrypt.hashpw(user.passwordHash, BCrypt.gensalt()),
        fullName: user.fullName,
        role: user.role,
      );
      final id = await _db.insert('users', hashedUser.toMap());
      return UserCreationResult.success(id);
    } catch (e) {
      return UserCreationResult.failure('Failed to create user: $e');
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    final maps = await _db.query('users', orderBy: 'full_name ASC');
    return maps.map((m) => UserModel.fromMap(m)).toList();
  }

  @override
  void dispose() {
    // Clear data to prevent memory leaks
    _currentUser = null;
    super.dispose();
  }
}

/// Result of a login attempt.
sealed class LoginResult {
  const LoginResult();
  
  factory LoginResult.success(UserModel user) = LoginSuccess;
  factory LoginResult.failure(String message) = LoginFailure;
  factory LoginResult.rateLimited(int seconds) = LoginRateLimited;
  
  bool get isSuccess => this is LoginSuccess;
  bool get isFailure => this is LoginFailure;
  bool get isRateLimited => this is LoginRateLimited;
  
  UserModel? get userOrNull => switch (this) {
    LoginSuccess(:final user) => user,
    _ => null,
  };
  
  String? get errorMessage => switch (this) {
    LoginFailure(:final message) => message,
    LoginRateLimited(:final seconds) => 'Too many attempts. Try again in ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
    _ => null,
  };
}

class LoginSuccess extends LoginResult {
  final UserModel user;
  const LoginSuccess(this.user);
}

class LoginFailure extends LoginResult {
  final String message;
  const LoginFailure(this.message);
}

class LoginRateLimited extends LoginResult {
  final int seconds;
  const LoginRateLimited(this.seconds);
}

/// Result of a user creation attempt.
sealed class UserCreationResult {
  const UserCreationResult();
  
  factory UserCreationResult.success(int userId) = UserCreationSuccess;
  factory UserCreationResult.failure(String message) = UserCreationFailure;
  
  bool get isSuccess => this is UserCreationSuccess;
  bool get isFailure => this is UserCreationFailure;
  
  int? get userIdOrNull => switch (this) {
    UserCreationSuccess(:final userId) => userId,
    _ => null,
  };
  
  String? get errorMessage => switch (this) {
    UserCreationFailure(:final message) => message,
    _ => null,
  };
}

class UserCreationSuccess extends UserCreationResult {
  final int userId;
  const UserCreationSuccess(this.userId);
}

class UserCreationFailure extends UserCreationResult {
  final String message;
  const UserCreationFailure(this.message);
}
