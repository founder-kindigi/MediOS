import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../security/password_policy.dart';
import '../security/input_validator.dart';
import '../../features/auth/services/auth_service.dart';
import '../../models/user_model.dart';

/// Service for handling first-time application setup.
///
/// This service manages the initial setup workflow when the app is run
/// for the first time, including creating the first administrator account.
class FirstTimeSetupService extends ChangeNotifier {
  final DatabaseHelper _db;
  final SharedPreferences _prefs;
  final AuthService _authService;
  
  static const String _setupCompletedKey = 'first_time_setup_completed';
  static const String _firstAdminCreatedKey = 'first_admin_created';
  
  bool _isChecking = false;
  bool _isSettingUp = false;
  bool _setupCompleted = false;
  bool _firstAdminCreated = false;
  String? _error;

  FirstTimeSetupService({
    required DatabaseHelper db,
    required SharedPreferences prefs,
    required AuthService authService,
  }) : _db = db, _prefs = prefs, _authService = authService {
    _loadSetupStatus();
  @override
  void dispose() {
    // Clear data to prevent memory leaks
    _setupCompleted = false;
    super.dispose();
  }

  }

  bool get isChecking => _isChecking;
  bool get isSettingUp => _isSettingUp;
  bool get setupCompleted => _setupCompleted;
  bool get firstAdminCreated => _firstAdminCreated;
  String? get error => _error;

  /// Check if first-time setup is required.
  Future<bool> checkIfSetupRequired() async {
    _isChecking = true;
    notifyListeners();
    
    try {
      // Check if setup was already completed
      _setupCompleted = _prefs.getBool(_setupCompletedKey) ?? false;
      _firstAdminCreated = _prefs.getBool(_firstAdminCreatedKey) ?? false;
      
      // If setup was marked as completed, verify it's still valid
      if (_setupCompleted) {
        // Check if at least one admin user exists
        final adminCount = await _getAdminCount();
        if (adminCount == 0) {
          // Setup was marked complete but no admin exists - reset
          _setupCompleted = false;
          _firstAdminCreated = false;
          await _saveSetupStatus();
        }
      }
      
      _isChecking = false;
      notifyListeners();
      return !_setupCompleted;
    } catch (e) {
      _error = 'Failed to check setup status: $e';
      _isChecking = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Create the first administrator account.
  Future<FirstTimeSetupResult> createFirstAdmin({
    required String username,
    required String password,
    required String fullName,
  }) async {
    _isSettingUp = true;
    _error = null;
    notifyListeners();

    try {
      // Validate inputs
      if (!InputValidator.isValidUsername(username)) {
        return FirstTimeSetupResult.failure(
          'Username must be 3-30 characters (letters, numbers, underscores)'
        );
      }

      if (!InputValidator.isValidFullName(fullName)) {
        return FirstTimeSetupResult.failure(
          'Please enter a valid full name (letters, spaces, and hyphens only)'
        );
      }

      // Validate password against policy
      final passwordErrors = PasswordPolicy.validate(password);
      if (passwordErrors.isNotEmpty) {
        return FirstTimeSetupResult.failure(passwordErrors.first);
      }

      // Check if any user already exists
      final userCount = await _getUserCount();
      if (userCount > 0) {
        return FirstTimeSetupResult.failure(
          'Users already exist. First-time setup cannot proceed.'
        );
      }

      // Create the admin user
      final user = UserModel(
        username: username,
        passwordHash: password,
        fullName: fullName,
        role: 'admin',
      );

      final creationResult = await _authService.createUser(user);
      if (!creationResult.isSuccess) {
        return FirstTimeSetupResult.failure(
          creationResult.errorMessage ?? 'Failed to create admin user'
        );
      }

      // Mark setup as completed
      _firstAdminCreated = true;
      _setupCompleted = true;
      await _saveSetupStatus();

      // Auto-login the newly created admin
      final loginResult = await _authService.login(username, password);
      if (!loginResult.isSuccess) {
        // User created but login failed - still mark setup as complete
        return FirstTimeSetupResult.success(
          userId: creationResult.userIdOrNull!,
          autoLoginFailed: true,
        );
      }

      _isSettingUp = false;
      notifyListeners();
      
      return FirstTimeSetupResult.success(
        userId: creationResult.userIdOrNull!,
        autoLoginFailed: false,
      );
    } catch (e) {
      _error = 'Setup failed: $e';
      _isSettingUp = false;
      notifyListeners();
      return FirstTimeSetupResult.failure('Setup failed: $e');
    }
  }

  /// Reset first-time setup (for testing purposes).
  Future<void> resetSetup() async {
    await _prefs.remove(_setupCompletedKey);
    await _prefs.remove(_firstAdminCreatedKey);
    _setupCompleted = false;
    _firstAdminCreated = false;
    notifyListeners();
  }

  /// Get a password suggestion that meets policy requirements.
  String getPasswordSuggestion() {
    return PasswordPolicy.generateSuggestion();
  }

  /// Calculate password strength (0-100).
  int getPasswordStrength(String password) {
    return PasswordPolicy.calculateStrength(password);
  }

  // Private methods

  Future<void> _loadSetupStatus() async {
    _setupCompleted = _prefs.getBool(_setupCompletedKey) ?? false;
    _firstAdminCreated = _prefs.getBool(_firstAdminCreatedKey) ?? false;
  }

  Future<void> _saveSetupStatus() async {
    await _prefs.setBool(_setupCompletedKey, _setupCompleted);
    await _prefs.setBool(_firstAdminCreatedKey, _firstAdminCreated);
  }

  Future<int> _getUserCount() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return result.first['count'] as int;
  }

  Future<int> _getAdminCount() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM users WHERE role = 'admin'"
    );
    return result.first['count'] as int;
  }
}

/// Result of a first-time setup attempt.
sealed class FirstTimeSetupResult {
  const FirstTimeSetupResult();
  
  factory FirstTimeSetupResult.success({
    required int userId,
    bool autoLoginFailed,
  }) = FirstTimeSetupSuccess;
  
  factory FirstTimeSetupResult.failure(String message) = FirstTimeSetupFailure;
  
  bool get isSuccess => this is FirstTimeSetupSuccess;
  bool get isFailure => this is FirstTimeSetupFailure;
  
  int? get userIdOrNull => switch (this) {
    FirstTimeSetupSuccess(:final userId) => userId,
    _ => null,
  };
  
  String? get errorMessage => switch (this) {
    FirstTimeSetupFailure(:final message) => message,
    _ => null,
  };
}

class FirstTimeSetupSuccess extends FirstTimeSetupResult {
  final int userId;
  final bool autoLoginFailed;
  
  const FirstTimeSetupSuccess({
    required this.userId,
    this.autoLoginFailed = false,
  });
}

class FirstTimeSetupFailure extends FirstTimeSetupResult {
  final String message;
  const FirstTimeSetupFailure(this.message);
}