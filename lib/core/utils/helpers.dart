import 'package:intl/intl.dart';

class Helpers {
  static String formatCurrency(double amount) {
    final format = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd-MM-yyyy HH:mm').format(date);
  }

  static String generateBillNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(5);
    return 'BILL-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$timestamp';
  }

  static String generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(5);
    return 'PO-${now.year}${now.month.toString().padLeft(2, '0')}$timestamp';
  }
}
