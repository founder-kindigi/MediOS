import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../database/database_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> checkAndNotify() async {
    if (kIsWeb) return;
    await init();
    final db = DatabaseHelper();
    final now = DateTime.now();
    final in30Days = now.add(const Duration(days: 30));

    final lowStock = await db.query('medicines',
      where: 'stock_quantity <= reorder_level AND reorder_level > 0',
      orderBy: 'name ASC',
    );

    final expiring = await db.query('medicines',
      where: "expiry_date IS NOT NULL AND expiry_date != '' "
             "AND expiry_date <= ? AND expiry_date > ?",
      whereArgs: [in30Days.toIso8601String(), now.toIso8601String()],
      orderBy: 'expiry_date ASC',
    );

    if (lowStock.isNotEmpty) {
      await _showNotification(
        1,
        'Low Stock Alert',
        '${lowStock.length} item${lowStock.length > 1 ? 's' : ''} below reorder level',
      );
    }

    if (expiring.isNotEmpty) {
      await _showNotification(
        2,
        'Expiry Alert',
        '${expiring.length} item${expiring.length > 1 ? 's' : ''} expiring within 30 days',
      );
    }
  }

  Future<void> _showNotification(int id, String title, String body) async {
    const android = AndroidNotificationDetails(
      'medios_alerts',
      'MediOS Alerts',
      channelDescription: 'Low stock and expiry notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);
    await _plugin.show(id, title, body, details);
  }
}
