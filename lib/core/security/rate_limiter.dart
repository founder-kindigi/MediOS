import 'dart:async';
import 'package:flutter/foundation.dart';

/// Rate limiting service to prevent brute force attacks and abuse.
///
/// Implements sliding window rate limiting with configurable limits
/// for different types of operations.
class RateLimiter {
  static final RateLimiter _instance = RateLimiter._internal();
  factory RateLimiter() => _instance;
  RateLimiter._internal();

  /// Storage for rate limit attempts
  final Map<String, List<DateTime>> _attempts = {};
  final Map<String, DateTime> _lockedOut = {};

  /// Default rate limits for different operations
  static const Map<String, RateLimitConfig> _defaultConfigs = {
    'login': RateLimitConfig(maxAttempts: 5, windowMinutes: 15, lockoutMinutes: 30),
    'password_reset': RateLimitConfig(maxAttempts: 3, windowMinutes: 60, lockoutMinutes: 60),
    'api_call': RateLimitConfig(maxAttempts: 100, windowMinutes: 1, lockoutMinutes: 5),
    'file_upload': RateLimitConfig(maxAttempts: 10, windowMinutes: 5, lockoutMinutes: 15),
  };

  /// Check if an operation is currently locked out for a given identifier.
  bool isLockedOut(String identifier, String operation) {
    return _isLockedOut(identifier, operation);
  }

  /// Check if an operation is rate limited for a given identifier.
  ///
  /// [identifier]: Unique identifier (e.g., IP address, username, user ID)
  /// [operation]: Type of operation (e.g., 'login', 'password_reset')
  /// [customConfig]: Optional custom rate limit configuration
  ///
  /// Returns true if rate limited, false otherwise.
  bool isRateLimited(
    String identifier,
    String operation, {
    RateLimitConfig? customConfig,
  }) {
    // Clean up old attempts periodically
    _cleanupOldAttempts();

    // Check if identifier is currently locked out
    if (_isLockedOut(identifier, operation)) {
      return true;
    }

    final config = customConfig ?? _defaultConfigs[operation];
    if (config == null) {
      // No rate limiting for this operation
      return false;
    }

    final key = _getKey(identifier, operation);
    final now = DateTime.now();

    // Get attempts for this key
    final attempts = _attempts[key] ??= [];

    // Remove attempts outside the time window
    final cutoff = now.subtract(Duration(minutes: config.windowMinutes));
    attempts.removeWhere((attempt) => attempt.isBefore(cutoff));

    // Record this attempt first
    attempts.add(now);

    // Check if attempts exceed limit
    if (attempts.length >= config.maxAttempts) {
      // Lock out the identifier
      _lockOut(identifier, operation, config.lockoutMinutes);
      return true;
    }

    // Limit the stored attempts to prevent memory issues
    if (attempts.length > config.maxAttempts * 2) {
      attempts.removeRange(0, attempts.length - config.maxAttempts);
    }

    return false;
  }

  /// Get remaining attempts before rate limiting.
  ///
  /// Returns the number of attempts remaining before rate limiting kicks in.
  int getRemainingAttempts(String identifier, String operation) {
    final config = _defaultConfigs[operation];
    if (config == null) return 999; // No limit

    final key = _getKey(identifier, operation);
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(minutes: config.windowMinutes));

    final attempts = _attempts[key] ?? [];
    final validAttempts = attempts.where((a) => a.isAfter(cutoff)).length;

    return config.maxAttempts - validAttempts;
  }

  /// Get time until rate limit resets (in seconds).
  ///
  /// Returns 0 if not rate limited, or seconds until reset.
  int getTimeUntilReset(String identifier, String operation) {
    if (!_isLockedOut(identifier, operation)) {
      return 0;
    }

    final key = _getLockoutKey(identifier, operation);
    final lockoutTime = _lockedOut[key];
    if (lockoutTime == null) return 0;

    final now = DateTime.now();
    final resetTime = lockoutTime.add(const Duration(minutes: 30));
    
    if (now.isAfter(resetTime)) {
      _lockedOut.remove(key);
      return 0;
    }

    return resetTime.difference(now).inSeconds;
  }

  /// Reset rate limiting for an identifier and operation.
  void reset(String identifier, String operation) {
    final key = _getKey(identifier, operation);
    _attempts.remove(key);
    
    final lockoutKey = _getLockoutKey(identifier, operation);
    _lockedOut.remove(lockoutKey);
  }

  /// Reset all rate limiting for an identifier.
  void resetAll(String identifier) {
    final keysToRemove = _attempts.keys.where((k) => k.startsWith('$identifier:')).toList();
    for (final key in keysToRemove) {
      _attempts.remove(key);
    }

    final lockoutKeysToRemove = _lockedOut.keys.where((k) => k.startsWith('$identifier:')).toList();
    for (final key in lockoutKeysToRemove) {
      _lockedOut.remove(key);
    }
  }

  /// Clean up old rate limiting data.
  void cleanup() {
    _cleanupOldAttempts();
    
    // Remove expired lockouts
    final now = DateTime.now();
    _lockedOut.removeWhere((key, lockoutTime) {
      return now.isAfter(lockoutTime.add(const Duration(minutes: 30)));
    });
  }

  // Private methods

  bool _isLockedOut(String identifier, String operation) {
    final key = _getLockoutKey(identifier, operation);
    final lockoutTime = _lockedOut[key];
    
    if (lockoutTime == null) return false;
    
    final now = DateTime.now();
    if (now.isAfter(lockoutTime.add(const Duration(minutes: 30)))) {
      _lockedOut.remove(key);
      return false;
    }
    
    return true;
  }

  void _lockOut(String identifier, String operation, int lockoutMinutes) {
    final key = _getLockoutKey(identifier, operation);
    _lockedOut[key] = DateTime.now();
    
    // Schedule cleanup of this lockout
    Timer(Duration(minutes: lockoutMinutes), () {
      _lockedOut.remove(key);
    });
  }

  void _cleanupOldAttempts() {
    final now = DateTime.now();
    
    for (final entry in _attempts.entries) {
      final operation = entry.key.split(':').last;
      final config = _defaultConfigs[operation];
      if (config == null) continue;
      
      final cutoff = now.subtract(Duration(minutes: config.windowMinutes * 2));
      entry.value.removeWhere((attempt) => attempt.isBefore(cutoff));
      
      if (entry.value.isEmpty) {
        _attempts.remove(entry.key);
      }
    }
  }

  String _getKey(String identifier, String operation) {
    return '$identifier:$operation';
  }

  String _getLockoutKey(String identifier, String operation) {
    return 'lockout:$identifier:$operation';
  }
}

/// Rate limiting configuration.
class RateLimitConfig {
  final int maxAttempts;
  final int windowMinutes;
  final int lockoutMinutes;

  const RateLimitConfig({
    required this.maxAttempts,
    required this.windowMinutes,
    required this.lockoutMinutes,
  });
}

/// Extension methods for easier rate limiting in widgets.
extension RateLimiterExtensions on RateLimiter {
  /// Check rate limiting with IP address from context.
  bool isRateLimitedByIp(String operation, {RateLimitConfig? config}) {
    // In a real app, you would get the IP address from the request
    // For Flutter mobile apps, we use device ID as fallback
    final identifier = 'device'; // Placeholder - implement proper IP detection
    return isRateLimited(identifier, operation, customConfig: config);
  }

  /// Check rate limiting with user ID.
  bool isRateLimitedByUserId(String userId, String operation, {RateLimitConfig? config}) {
    return isRateLimited('user:$userId', operation, customConfig: config);
  }
}