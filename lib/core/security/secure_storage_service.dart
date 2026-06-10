import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';

/// Secure storage service for sensitive data.
///
/// Uses AES-256 encryption for storing sensitive information like
/// API keys, tokens, and other confidential data.
class SecureStorageService {
  static const String _keyStoreKey = 'k_sec_df_x92';
  static const String _ivStoreKey = 'i_sec_df_v31';
  
  final FlutterSecureStorage _secureStorage;
  encrypt.Encrypter? _encrypter;
  encrypt.IV? _iv;
  
  SecureStorageService() : _secureStorage = const FlutterSecureStorage();
  
  /// Initialize the encryption system.
  ///
  /// This should be called once during app startup.
  Future<void> initialize() async {
    await _ensureEncryptionKey();
  }
  
  /// Store encrypted data.
  Future<void> store(String key, String value) async {
    await initialize();
    
    final encrypted = _encrypter!.encrypt(value, iv: _iv!);
    final encryptedBase64 = encrypted.base64;
    
    await _secureStorage.write(key: key, value: encryptedBase64);
  }
  
  /// Retrieve and decrypt data.
  Future<String?> retrieve(String key) async {
    await initialize();
    
    final encryptedBase64 = await _secureStorage.read(key: key);
    if (encryptedBase64 == null) return null;
    
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedBase64);
      final decrypted = _encrypter!.decrypt(encrypted, iv: _iv!);
      return decrypted;
    } catch (e) {
      // If decryption fails, try to read as plain text (for migration)
      return encryptedBase64;
    }
  }
  
  /// Store sensitive map data.
  Future<void> storeMap(String key, Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    await store(key, jsonString);
  }
  
  /// Retrieve and decrypt map data.
  Future<Map<String, dynamic>?> retrieveMap(String key) async {
    final jsonString = await retrieve(key);
    if (jsonString == null) return null;
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
  
  /// Delete stored data.
  Future<void> delete(String key) async {
    await _secureStorage.delete(key: key);
  }
  
  /// Check if data exists.
  Future<bool> contains(String key) async {
    return await _secureStorage.containsKey(key: key);
  }
  
  /// Clear all secure storage.
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    // Note: We don't delete the encryption key as it's needed for future encryption
  }
  
  /// Migrate unencrypted data to encrypted storage.
  ///
  /// Use this when upgrading from a version without encryption.
  Future<void> migrateFromUnencrypted(
    Map<String, String> unencryptedData,
  ) async {
    await initialize();
    
    for (final entry in unencryptedData.entries) {
      // Check if data is already encrypted
      final existing = await _secureStorage.read(key: entry.key);
      if (existing == null) {
        // Store as encrypted
        await store(entry.key, entry.value);
      }
    }
  }
  
  // Private methods
  
  Future<void> _ensureEncryptionKey() async {
    if (_encrypter != null && _iv != null) return;
    
    // Try to load existing key
    var keyBase64 = await _secureStorage.read(key: _keyStoreKey);
    var ivBase64 = await _secureStorage.read(key: _ivStoreKey);
    
    // Fallback migration logic for legacy keys
    if (keyBase64 == null || ivBase64 == null) {
      const legacyKeyStoreKey = 'medios_encryption_key';
      const legacyIvStoreKey = 'medios_encryption_iv';
      
      final legacyKeyBase64 = await _secureStorage.read(key: legacyKeyStoreKey);
      final legacyIvBase64 = await _secureStorage.read(key: legacyIvStoreKey);
      
      if (legacyKeyBase64 != null && legacyIvBase64 != null) {
        keyBase64 = legacyKeyBase64;
        ivBase64 = legacyIvBase64;
        
        await _secureStorage.write(key: _keyStoreKey, value: keyBase64);
        await _secureStorage.write(key: _ivStoreKey, value: ivBase64);
        
        await _secureStorage.delete(key: legacyKeyStoreKey);
        await _secureStorage.delete(key: legacyIvStoreKey);
      }
    }
    
    if (keyBase64 == null || ivBase64 == null) {
      // Generate new key and IV
      final key = encrypt.Key.fromSecureRandom(32); // 256-bit key
      final iv = encrypt.IV.fromSecureRandom(16);   // 128-bit IV
      
      keyBase64 = key.base64;
      ivBase64 = iv.base64;
      
      // Store for future use
      await _secureStorage.write(key: _keyStoreKey, value: keyBase64);
      await _secureStorage.write(key: _ivStoreKey, value: ivBase64);
    }
    
    // Initialize encrypter
    final key = encrypt.Key.fromBase64(keyBase64);
    final iv = encrypt.IV.fromBase64(ivBase64);
    
    _encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    _iv = iv;
  }
  
  /// Get encryption key strength information (for debugging/verification).
  Future<Map<String, dynamic>> getKeyInfo() async {
    await initialize();
    
    final keyBase64 = await _secureStorage.read(key: _keyStoreKey);
    final ivBase64 = await _secureStorage.read(key: _ivStoreKey);
    
    return {
      'key_exists': keyBase64 != null,
      'iv_exists': ivBase64 != null,
      'key_length': keyBase64?.length,
      'iv_length': ivBase64?.length,
      'algorithm': 'AES-256-CBC',
    };
  }
}

/// Predefined keys for common secure storage items.
class SecureStorageKeys {
  // Authentication
  static const String biometricUsername = 'biometric_username';
  static const String sessionToken = 'session_token';
  static const String refreshToken = 'refresh_token';
  
  // API keys and secrets
  static const String apiKey = 'api_key';
  static const String apiSecret = 'api_secret';
  
  // User preferences (sensitive ones)
  static const String autoLoginEnabled = 'auto_login_enabled';
  static const String rememberMe = 'remember_me';
  
  // Database encryption (if needed)
  static const String databaseKey = 'database_encryption_key';
  
  // Backup and sync
  static const String backupEncryptionKey = 'backup_encryption_key';
  static const String syncCredentials = 'sync_credentials';
  
  // Payment and billing
  static const String paymentToken = 'payment_token';
  static const String billingInfo = 'billing_info';
}