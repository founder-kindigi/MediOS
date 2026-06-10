import 'package:intl/intl.dart';

/// Comprehensive input validation service.
///
/// Provides validation for various input types to ensure data integrity.
/// Note: SQL injection prevention is handled by parameterized queries
/// in the database layer — never concatenate user input into SQL strings.
class InputValidator {
  /// Validate email address format.
  static bool isValidEmail(String email) {
    final pattern = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
    );
    return pattern.hasMatch(email) && email.length <= 254;
  }

  /// Validate phone number format (supports international numbers).
  static bool isValidPhone(String phone) {
    // Remove all non-digit characters except + at start
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check if it starts with + (international) or is local
    if (cleaned.startsWith('+')) {
      // International number: + followed by 1-15 digits
      return RegExp(r'^\+\d{1,15}$').hasMatch(cleaned);
    } else {
      // Local number: 7-15 digits
      return RegExp(r'^\d{7,15}$').hasMatch(cleaned);
    }
  }

  /// Validate medicine name (alphanumeric with spaces and hyphens).
  static bool isValidMedicineName(String name) {
    if (name.isEmpty || name.length > 100) return false;
    
    // Allow letters, numbers, spaces, hyphens, parentheses, and periods
    final pattern = RegExp(r'^[a-zA-Z0-9\s\-().,]+$');
    return pattern.hasMatch(name);
  }

  /// Validate price (positive number with up to 2 decimal places).
  static bool isValidPrice(String price) {
    try {
      final value = double.tryParse(price);
      if (value == null || value < 0) return false;
      
      // Check decimal places
      final parts = price.split('.');
      if (parts.length > 1 && parts[1].length > 2) return false;
      
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Validate quantity (positive integer).
  static bool isValidQuantity(String quantity) {
    try {
      final value = int.tryParse(quantity);
      return value != null && value > 0 && value <= 1000000;
    } catch (_) {
      return false;
    }
  }

  /// Validate barcode format (EAN-13, UPC, or custom).
  static bool isValidBarcode(String barcode) {
    if (barcode.isEmpty) return true; // Barcode is optional
    
    // Remove spaces and dashes
    final cleaned = barcode.replaceAll(RegExp(r'[\s-]'), '');
    
    // Check length
    if (cleaned.length < 8 || cleaned.length > 13) return false;
    
    // Check if all characters are digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return false;
    
    return true;
  }

  /// Validate date string (YYYY-MM-DD format).
  static bool isValidDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      final formatted = DateFormat('yyyy-MM-dd').format(parsed);
      return formatted == date;
    } catch (_) {
      return false;
    }
  }

  /// Validate username (alphanumeric with underscores, 3-30 chars).
  static bool isValidUsername(String username) {
    if (username.length < 3 || username.length > 30) return false;
    
    final pattern = RegExp(r'^[a-zA-Z0-9_]+$');
    return pattern.hasMatch(username);
  }

  /// Validate full name (letters, spaces, and hyphens, 2-50 chars).
  static bool isValidFullName(String name) {
    if (name.length < 2 || name.length > 50) return false;
    
    final pattern = RegExp(r'^[a-zA-Z\s\-]+$');
    return pattern.hasMatch(name);
  }

  /// Get validation error message for a field.
  static String? getErrorMessage({
    required String fieldName,
    required String value,
    required bool isValid,
    String? customMessage,
  }) {
    if (isValid) return null;
    
    if (customMessage != null) return customMessage;
    
    // Default error messages based on field type
    switch (fieldName.toLowerCase()) {
      case 'email':
        return 'Please enter a valid email address';
      case 'phone':
        return 'Please enter a valid phone number';
      case 'username':
        return 'Username must be 3-30 characters (letters, numbers, underscores)';
      case 'password':
        return 'Password does not meet requirements';
      case 'name':
        return 'Please enter a valid name';
      case 'price':
        return 'Please enter a valid price (positive number with up to 2 decimal places)';
      case 'quantity':
        return 'Please enter a valid quantity (positive number up to 1,000,000)';
      case 'barcode':
        return 'Barcode must be 8-13 digits';
      case 'date':
        return 'Please enter a valid date (YYYY-MM-DD)';
      default:
        return 'Please enter a valid value';
    }
  }

  /// Validate all fields in a map and return error messages.
  static Map<String, String> validateForm(Map<String, dynamic> formData) {
    final errors = <String, String>{};

    for (final entry in formData.entries) {
      final field = entry.key;
      final value = entry.value?.toString() ?? '';

      bool isValid = true;
      String? errorMessage;

      switch (field) {
        case 'email':
          isValid = isValidEmail(value);
          break;
        case 'phone':
          isValid = isValidPhone(value);
          break;
        case 'username':
          isValid = isValidUsername(value);
          break;
        case 'medicine_name':
          isValid = isValidMedicineName(value);
          break;
        case 'price':
        case 'selling_price':
        case 'purchase_price':
        case 'wholesale_price':
          isValid = isValidPrice(value);
          break;
        case 'quantity':
        case 'stock_quantity':
        case 'reorder_level':
          isValid = isValidQuantity(value);
          break;
        case 'barcode':
          isValid = isValidBarcode(value);
          break;
        case 'expiry_date':
          isValid = isValidDate(value);
          break;
        case 'full_name':
          isValid = isValidFullName(value);
          break;
      }

      if (!isValid) {
        errorMessage = getErrorMessage(
          fieldName: field,
          value: value,
          isValid: false,
        );
        errors[field] = errorMessage!;
      }
    }

    return errors;
  }

  /// Truncate string to prevent overflow attacks.
  static String truncate(String input, int maxLength) {
    if (input.length <= maxLength) return input;
    return '${input.substring(0, maxLength)}...';
  }

  /// Normalize string for consistent comparison (lowercase, trim).
  static String normalize(String input) {
    return input.toLowerCase().trim();
  }
}