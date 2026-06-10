import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:get_it/get_it.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../core/errors/app_error.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorageService _secureStorage;
  
  BiometricAuthService({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? GetIt.instance<SecureStorageService>();

  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({String? reason}) async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: reason ?? 'Authenticate to access MediOS',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    try {
      await _secureStorage.initialize();
      final enabled = await _secureStorage.retrieve(SecureStorageKeys.autoLoginEnabled);
      return enabled == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<String?> getStoredUsername() async {
    try {
      await _secureStorage.initialize();
      return await _secureStorage.retrieve(SecureStorageKeys.biometricUsername);
    } catch (_) {
      return null;
    }
  }

  Future<void> enable(String username) async {
    try {
      await _secureStorage.initialize();
      await _secureStorage.store(SecureStorageKeys.autoLoginEnabled, 'true');
      await _secureStorage.store(SecureStorageKeys.biometricUsername, username);
    } catch (e) {
      throw AppError(
        message: 'Failed to enable biometric login: $e',
        type: ErrorType.authentication,
        originalError: e,
      );
    }
  }

  Future<void> disable() async {
    try {
      await _secureStorage.initialize();
      await _secureStorage.delete(SecureStorageKeys.autoLoginEnabled);
      await _secureStorage.delete(SecureStorageKeys.biometricUsername);
    } catch (e) {
      throw AppError(
        message: 'Failed to disable biometric login: $e',
        type: ErrorType.authentication,
        originalError: e,
      );
    }
  }
  
  /// Check if biometric authentication is supported and properly configured.
  Future<BiometricStatus> checkStatus() async {
    try {
      final available = await isAvailable();
      if (!available) {
        return BiometricStatus.notAvailable;
      }
      
      final enabled = await isEnabled();
      if (!enabled) {
        return BiometricStatus.notEnabled;
      }
      
      final hasStoredUsername = await getStoredUsername() != null;
      if (!hasStoredUsername) {
        return BiometricStatus.notConfigured;
      }
      
      return BiometricStatus.ready;
    } catch (_) {
      return BiometricStatus.error;
    }
  }
  
  /// Migrate from old shared preferences storage to secure storage.
  Future<void> migrateFromSharedPreferences() async {
    try {
      // This would check for old shared preferences data and migrate it
      // For now, we just initialize secure storage
      await _secureStorage.initialize();
    } catch (_) {
      // Migration failed, but we can continue
    }
  }
}

/// Status of biometric authentication.
enum BiometricStatus {
  /// Biometric authentication is ready to use.
  ready,
  
  /// Biometric hardware is not available on this device.
  notAvailable,
  
  /// Biometric authentication is not enabled in app settings.
  notEnabled,
  
  /// Biometric authentication is not configured (no username stored).
  notConfigured,
  
  /// An error occurred while checking biometric status.
  error,
}

extension BiometricStatusExtension on BiometricStatus {
  String get description {
    switch (this) {
      case BiometricStatus.ready:
        return 'Biometric authentication is ready';
      case BiometricStatus.notAvailable:
        return 'Biometric authentication is not available on this device';
      case BiometricStatus.notEnabled:
        return 'Biometric authentication is not enabled';
      case BiometricStatus.notConfigured:
        return 'Biometric authentication is not configured';
      case BiometricStatus.error:
        return 'An error occurred while checking biometric status';
    }
  }
  
  bool get isReady => this == BiometricStatus.ready;
  bool get canUseBiometrics => this == BiometricStatus.ready;
}
