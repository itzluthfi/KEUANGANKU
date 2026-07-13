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
      for (int i = 0; i < 7; i++) {
        await _localNotifications.cancel(100 + i);
      }
      debugPrint("Daily notifications successfully cancelled.");
    } catch (e) {
      debugPrint("Error cancelling daily notifications: $e");
    }
  }

  Future<void> scheduleDailyNotification(int hour, int minute) async {
    if (kIsWeb) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    if (!_isInitialized) await init();

    try {
      // Bersihkan notifikasi harian lama terlebih dahulu untuk mencegah duplikasi
      await cancelDailyNotification();

      // Daftar pesan unik motivasi finansial untuk setiap hari dalam seminggu
      final smartMessages = {
        DateTime.monday: "Mulai minggu baru dengan keuangan yang rapi. Catat transaksi pertamamu hari ini!",
        DateTime.tuesday: "Keuangan terkendali, hidup lebih tenang. Sudahkah kamu mencatat pengeluaran hari ini?",
        DateTime.wednesday: "Sudah setengah minggu berjalan! Yuk tinjau sisa anggaran belanjamu di Danaku.",
        DateTime.thursday: "Uang yang tidak dicatat cenderung menguap begitu saja. Catat jajanmu hari ini, yuk!",
        DateTime.friday: "Jelang akhir pekan, pastikan budget nongkrongmu aman. Yuk catat dulu keuanganmu!",
        DateTime.saturday: "Hari Sabtu saatnya bersantai, tapi jangan lupa catat belanjaan akhir pekanmu di Danaku!",
        DateTime.sunday: "Evaluasi mingguan yuk! Catat semua pengeluaran minggu ini agar siap hadapi senin besok.",
      };

      // Jadwalkan masing-masing hari secara terpisah
      for (int dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
        final message = smartMessages[dayOfWeek] ?? 'Jangan lupa mencatat pengeluaran Anda hari ini agar keuangan tetap terpantau!';
        final notificationId = 100 + dayOfWeek - 1; // 100 s.d 106

        await _localNotifications.zonedSchedule(
          notificationId,
          'Pengingat Danaku',
          message,
          _nextInstanceOfWeekdayTime(dayOfWeek, hour, minute),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_reminder_channel_v2',
              'Daily Reminder Smart',
              channelDescription: 'Channel pengingat harian dengan pesan motivasi cerdas yang bervariasi',
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
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
      debugPrint("7 weekly scheduled daily notifications successfully set at $hour:$minute");
    } catch (e) {
      debugPrint("Error scheduling exact daily notifications, trying inexact fallback: $e");
      try {
        final smartMessages = {
          1: "Mulai minggu baru dengan keuangan yang rapi. Catat transaksi pertamamu hari ini!",
          2: "Keuangan terkendali, hidup lebih tenang. Sudahkah kamu mencatat pengeluaran hari ini?",
          3: "Sudah setengah minggu berjalan! Yuk tinjau sisa anggaran belanjamu di Danaku.",
          4: "Uang yang tidak dicatat cenderung menguap begitu saja. Catat jajanmu hari ini, yuk!",
          5: "Jelang akhir pekan, pastikan budget nongkrongmu aman. Yuk catat dulu keuanganmu!",
          6: "Hari Sabtu saatnya bersantai, tapi jangan lupa catat belanjaan akhir pekanmu di Danaku!",
          7: "Evaluasi mingguan yuk! Catat semua pengeluaran minggu ini agar siap hadapi senin besok.",
        };
        for (int dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
          final message = smartMessages[dayOfWeek] ?? 'Jangan lupa mencatat pengeluaran Anda hari ini!';
          final notificationId = 100 + dayOfWeek - 1;
          await _localNotifications.zonedSchedule(
            notificationId,
            'Pengingat Danaku',
            message,
            _nextInstanceOfWeekdayTime(dayOfWeek, hour, minute),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'daily_reminder_channel_inexact',
                'Daily Reminder (Inexact)',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      } catch (e2) {
        debugPrint("Error scheduling fallback notifications: $e2");
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

  tz.TZDateTime _nextInstanceOfWeekdayTime(int dayOfWeek, int hour, int minute) {
    var tzDateTime = _nextInstanceOfTime(hour, minute);
    while (tzDateTime.weekday != dayOfWeek) {
      tzDateTime = tzDateTime.add(const Duration(days: 1));
    }
    return tzDateTime;
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
