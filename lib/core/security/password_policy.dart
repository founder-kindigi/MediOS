import 'dart:math';

/// NIST 800-63B compliant password policy for MediOS.
///
/// This policy enforces strong password requirements to ensure
/// security compliance and protect against brute force attacks.
class PasswordPolicy {
  /// Minimum password length (NIST recommends at least 8, we use 12)
  static const int minLength = 12;

  /// Maximum password length to prevent DoS attacks
  static const int maxLength = 128;

  /// Require at least one uppercase letter
  static const bool requireUppercase = true;

  /// Require at least one lowercase letter
  static const bool requireLowercase = true;

  /// Require at least one digit
  static const bool requireNumbers = true;

  /// Require at least one special character
  static const bool requireSpecial = true;

  /// Maximum password age in days (90 days per NIST)
  static const int maxAgeDays = 90;

  /// Minimum password age in days (prevent rapid changes)
  static const int minAgeDays = 1;

  /// Password history size (prevent reuse of last 5 passwords)
  static const int historySize = 5;

  /// Special characters allowed in passwords
  static const String specialCharacters = r'!@#$%^&*()_+-=[]{}|;:,.<>?';

  /// Check if a password meets all policy requirements.
  ///
  /// Returns a list of error messages if password is invalid,
  /// or an empty list if password is valid.
  static List<String> validate(String password) {
    final errors = <String>[];

    if (password.length < minLength) {
      errors.add('Password must be at least $minLength characters long');
    }

    if (password.length > maxLength) {
      errors.add('Password must not exceed $maxLength characters');
    }

    if (requireUppercase && !password.contains(RegExp(r'[A-Z]'))) {
      errors.add('Password must contain at least one uppercase letter');
    }

    if (requireLowercase && !password.contains(RegExp(r'[a-z]'))) {
      errors.add('Password must contain at least one lowercase letter');
    }

    if (requireNumbers && !password.contains(RegExp(r'[0-9]'))) {
      errors.add('Password must contain at least one number');
    }

    if (requireSpecial && !password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'))) {
      errors.add('Password must contain at least one special character ($specialCharacters)');
    }

    // Check for common weak patterns
    if (_isCommonWeakPassword(password)) {
      errors.add('Password is too common or easily guessable');
    }

    return errors;
  }

  /// Generate a cryptographically secure password suggestion.
  static String generateSuggestion() {
    // In a real implementation, use a proper password generator
    // This is a simple example for demonstration
    final random = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    
    return String.fromCharCodes(
      List.generate(16, (index) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  /// Check if password is in common weak password list.
  static bool _isCommonWeakPassword(String password) {
    const weakPasswords = {
      'password',
      '123456',
      'admin123',
      'admin',
      'password123',
      'qwerty',
      'letmein',
      'welcome',
      'monkey',
      'dragon',
    };

    return weakPasswords.contains(password.toLowerCase());
  }

  /// Calculate password strength score (0-100).
  static int calculateStrength(String password) {
    int score = 0;

    // Length score (up to 40 points)
    score += (password.length * 2).clamp(0, 40);

    // Character variety score (up to 40 points)
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[^A-Za-z0-9]'));

    final varietyCount = [hasUpper, hasLower, hasNumber, hasSpecial].where((e) => e).length;
    score += varietyCount * 10; // 10 points per character type

    // Penalize common patterns (up to -20 points)
    if (_isCommonWeakPassword(password)) {
      score -= 20;
    }

    // Penalize sequential characters (e.g., abc, 123)
    if (_hasSequentialCharacters(password)) {
      score -= 10;
    }

    return score.clamp(0, 100);
  }

  /// Check for sequential characters in password.
  static bool _hasSequentialCharacters(String password) {
    if (password.length < 3) return false;

    for (int i = 0; i < password.length - 2; i++) {
      final a = password.codeUnitAt(i);
      final b = password.codeUnitAt(i + 1);
      final c = password.codeUnitAt(i + 2);

      // Check for sequential letters (abc, bcd, etc.)
      if (b == a + 1 && c == b + 1) {
        return true;
      }

      // Check for sequential numbers (123, 234, etc.)
      if (b == a + 1 && c == b + 1 && 
          a >= '0'.codeUnitAt(0) && a <= '9'.codeUnitAt(0)) {
        return true;
      }
    }

    return false;
  }
}