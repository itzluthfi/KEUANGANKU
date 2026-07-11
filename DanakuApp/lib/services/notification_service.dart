import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../data/database_helper.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (kIsWeb) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    if (_isInitialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    
    try {
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint("Notification tapped: ${details.payload}");
        },
      );
      _isInitialized = true;
      debugPrint("NotificationService initialized successfully.");
    } catch (e) {
      debugPrint("Error initializing NotificationService: $e");
    }
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    if (!_isInitialized) await init();

    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        // Request notifications permission (Android 13+)
        await androidPlugin.requestNotificationsPermission();
        // Request exact alarms permission for precise daily schedule
        await androidPlugin.requestExactAlarmsPermission();
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _localNotifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    }
  }

  Future<void> showInstantNotification() async {
    if (kIsWeb) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    if (!_isInitialized) await init();

    try {
      await _localNotifications.show(
        99,
        'Uji Coba Notifikasi Danaku',
        'Notifikasi berfungsi dengan baik di handphone Anda!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notification',
            channelDescription: 'Channel untuk testing notifikasi',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint("Instant notification shown.");
    } catch (e) {
      debugPrint("Error showing instant notification: $e");
    }
  }

  Future<void> showCustomNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    if (!_isInitialized) await init();

    try {
      await _localNotifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'budget_channel',
            'Budget Notification',
            channelDescription: 'Channel untuk peringatan anggaran bulanan',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint("Custom notification shown: id=$id");
    } catch (e) {
      debugPrint("Error showing custom notification: $e");
    }
  }

  Future<void> cancelDailyNotification() async {
    if (kIsWeb) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    if (!_isInitialized) await init();
    try {
      await _localNotifications.cancel(100);
      debugPrint("Daily notification successfully cancelled.");
    } catch (e) {
      debugPrint("Error cancelling daily notification: $e");
    }
  }

  Future<void> scheduleDailyNotification(int hour, int minute) async {
    if (kIsWeb) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    if (!_isInitialized) await init();

    try {
      // Cancel previous notification with the same ID to avoid duplicates
      await _localNotifications.cancel(100);

      // Schedule the new daily notification (Exact)
      await _localNotifications.zonedSchedule(
        100,
        'Pengingat Danaku',
        'Jangan lupa mencatat pengeluaran Anda hari ini agar keuangan tetap terpantau!',
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel',
            'Daily Reminder',
            channelDescription: 'Channel untuk pengingat harian mencatat transaksi',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint("Daily notification successfully scheduled (Exact) at $hour:$minute");
    } catch (e) {
      debugPrint("Error scheduling exact daily notification, trying inexact fallback: $e");
      try {
        await _localNotifications.zonedSchedule(
          100,
          'Pengingat Danaku',
          'Jangan lupa mencatat pengeluaran Anda hari ini agar keuangan tetap terpantau!',
          _nextInstanceOfTime(hour, minute),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_reminder_channel_inexact',
              'Daily Reminder (Inexact)',
              channelDescription: 'Channel untuk pengingat harian',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint("Daily notification successfully scheduled (Inexact fallback) at $hour:$minute");
      } catch (e2) {
        debugPrint("Error scheduling inexact daily notification: $e2");
      }
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final nowLocal = DateTime.now();
    var targetLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day, hour, minute);
    if (targetLocal.isBefore(nowLocal)) {
      targetLocal = targetLocal.add(const Duration(days: 1));
    }
    final targetUtc = targetLocal.toUtc();
    return tz.TZDateTime(
      tz.UTC,
      targetUtc.year,
      targetUtc.month,
      targetUtc.day,
      targetUtc.hour,
      targetUtc.minute,
      targetUtc.second,
    );
  }

  void setupFcmListeners() {
    if (kIsWeb) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("FCM Message received in foreground: ${message.notification?.title}");
      final notification = message.notification;
      if (notification != null) {
        showCustomLocalNotification(
          notification.hashCode,
          notification.title ?? '',
          notification.body ?? '',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("FCM Message opened app: ${message.data}");
    });
  }

  Future<void> showCustomLocalNotification(int id, String title, String body) async {
    try {
      await _localNotifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fcm_push_channel',
            'Push Notifications',
            channelDescription: 'Channel untuk notifikasi dari server',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error showing custom local notification: $e");
    }
  }

  Future<void> rescheduleDailyReminderIfNeeded() async {
    if (kIsWeb) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    try {
      final reminderEnabled = await DatabaseHelper.instance.getSetting('reminder_enabled');
      if (reminderEnabled != 'false') { // Default to true if not set
        final reminderTime = await DatabaseHelper.instance.getSetting('reminder_time') ?? "20:00";
        final timeParts = reminderTime.split(":");
        final hour = int.tryParse(timeParts[0]) ?? 20;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        await scheduleDailyNotification(hour, minute);
      }
    } catch (e) {
      debugPrint("Error rescheduleDailyReminderIfNeeded: $e");
    }
  }

  Future<void> scheduleDebtReminder(int debtId, String kontak, String tipe, DateTime jatuhTempo) async {
    if (kIsWeb) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    try {
      final id = 10000 + debtId; // Offset to avoid ID collision
      final scheduledDate = tz.TZDateTime.from(
        jatuhTempo.subtract(const Duration(days: 1)), // Notify 1 day before due date
        tz.local,
      );

      // If scheduled date is in the past, return (don't schedule)
      if (scheduledDate.isBefore(DateTime.now())) return;

      final typeLabel = tipe.toLowerCase() == 'utang' ? 'utang Anda kepada' : 'piutang Anda dari';
      await _localNotifications.zonedSchedule(
        id,
        '🚨 Pengingat Jatuh Tempo!',
        'Besok adalah tanggal jatuh tempo $typeLabel $kontak.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'debt_reminders',
            'Pengingat Utang Piutang',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint("Scheduled debt reminder for ID $debtId on $scheduledDate");
    } catch (e) {
      debugPrint("Error scheduling debt reminder: $e");
    }
  }

  Future<void> cancelDebtReminder(int debtId) async {
    if (kIsWeb) return;
    try {
      await _localNotifications.cancel(10000 + debtId);
      debugPrint("Cancelled debt reminder for ID $debtId");
    } catch (e) {
      debugPrint("Error cancelling debt reminder: $e");
    }
  }
}
