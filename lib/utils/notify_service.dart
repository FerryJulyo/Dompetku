// utils/notify_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'dart:io';
import '../models/recurring.dart';

class NotifyService {
  static final NotifyService _instance = NotifyService._internal();
  factory NotifyService() => _instance;
  NotifyService._internal();

  final FlutterLocalNotificationsPlugin _plug = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    final String localZone = await FlutterNativeTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(localZone));
    } catch (e) {
      // fallback to UTC
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plug.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));
    _initialized = true;
  }

  Future<void> scheduleRecurringNotification(RecurringModel r) async {
    if (!_initialized) await init();
    final id = r.id ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    final scheduled = tz.TZDateTime.from(r.nextRun, tz.local);
    final androidDetails = AndroidNotificationDetails('recurring_channel', 'Recurring Transactions', channelDescription: 'Pengingat recurring transaction', importance: Importance.max, priority: Priority.high);
    final iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Cancel previous scheduled with same id first
    await _plug.cancel(id);

    // Schedule exact zoned notification once; when nextRun advances, we reschedule
    await _plug.zonedSchedule(id, 'Transaksi Berulang', 'Transaksi ${r.category}: ${r.amount}', scheduled, details, androidAllowWhileIdle: true, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
  }

  Future<void> cancelNotification(int id) async {
    await _plug.cancel(id);
  }

  Future<void> showImmediate(String title, String body) async {
    if (!_initialized) await init();
    const details = NotificationDetails(android: AndroidNotificationDetails('default', 'Default', channelDescription: 'Default channel'));
    await _plug.show(0, title, body, details);
  }
}