import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Inisialisasi timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Notification tapped: ${response.payload}');
      },
    );

    // Minta izin notifikasi (Android 13+)
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    _isInitialized = true;
    debugPrint('✅ NotificationHelper initialized');
  }

  // 🔶 Notifikasi tunggal untuk peringatan alergen
  Future<void> showAllergenWarning({
    required String productName,
    required String allergens,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'allergen_channel',
          'Allergen Warnings',
          channelDescription: 'Notifications for allergen warnings in products',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFFF6B9D),
          icon: '@mipmap/ic_launcher',
          enableLights: false,
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      '⚠️ Peringatan Alergen!',
      '$productName mengandung: $allergens. Harap berhati-hati!',
      notificationDetails,
    );
  }

  // 🔶 Notifikasi untuk banyak alergen
  Future<void> showMultipleAllergensWarning({
    required String productName,
    required List<String> allergensList,
  }) async {
    final String allergensText = allergensList.join(', ');

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'allergen_channel',
          'Allergen Warnings',
          channelDescription: 'Notifications for allergen warnings in products',
          importance: Importance.max,
          priority: Priority.max,
          color: const Color(0xFFFF6B9D),
          icon: '@mipmap/ic_launcher',
          styleInformation: const BigTextStyleInformation(''),
          enableLights: false,
          enableVibration: true,
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      '⚠️ Perhatian! Produk Mengandung ${allergensList.length} Alergen',
      'Produk "$productName" mengandung: $allergensText. Mohon teliti sebelum dikonsumsi!',
      notificationDetails,
    );
  }

  // 🔶 Jadwal notifikasi "Enjoy Snack"
  Future<void> scheduleEnjoySnackNotification() async {
    try {
      await cancelEnjoySnackNotification();

      final scheduledDate = tz.TZDateTime.now(
        tz.local,
      ).add(const Duration(seconds: 5));

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'enjoy_snack_channel',
            'Enjoy Snack Reminders',
            channelDescription: 'Friendly reminders to enjoy your snacks',
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFFFF6B9D),
            icon: '@mipmap/ic_launcher',
            styleInformation: const BigTextStyleInformation(
              'Jangan lupa untuk menikmati camilan favorit Anda! 😊',
            ),
            enableLights: false,
          );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        1,
        '🍪 Selamat Menikmati Camilan Anda!',
        'Jangan lupa untuk menikmati camilan favorit Anda! 😊',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'enjoy_snack',
      );

      debugPrint('✅ Notifikasi dijadwalkan untuk: $scheduledDate');
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
    }
  }

  // 🔶 Jadwal notifikasi acak "Enjoy Snack"
  Future<void> scheduleRandomEnjoySnackNotification() async {
    try {
      await cancelEnjoySnackNotification();

      final List<Map<String, String>> messages = [
        {
          'title': '🍪 Selamat Menikmati Camilan Anda!',
          'body': 'Jangan lupa untuk menikmati camilan favorit Anda! 😊',
        },
        {
          'title': '🎉 Waktunya Snack Time!',
          'body': 'Camilan lezat menanti Anda. Selamat menikmati! 🍫',
        },
        {
          'title': '😋 Nikmati Camilan Anda!',
          'body': 'Sudah waktunya untuk menikmati camilan yang lezat! 🍭',
        },
        {
          'title': '🌟 Snack Break Time!',
          'body': 'Jangan lupa untuk menikmati camilan Anda hari ini! 🥨',
        },
        {
          'title': '🎊 Waktu Makan Camilan!',
          'body': 'Camilan spesial Anda sudah menunggu. Selamat menikmati! 🍩',
        },
      ];

      final randomIndex = DateTime.now().second % messages.length;
      final selectedMessage = messages[randomIndex];

      final scheduledDate = tz.TZDateTime.now(
        tz.local,
      ).add(const Duration(seconds: 5));

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'enjoy_snack_channel',
            'Enjoy Snack Reminders',
            channelDescription: 'Friendly reminders to enjoy your snacks',
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFFFF6B9D),
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              selectedMessage['body'] ?? '',
            ),
            enableLights: false, // 🔧 FIX
            playSound: true,
          );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        1,
        selectedMessage['title']!,
        selectedMessage['body']!,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'enjoy_snack',
      );

      debugPrint(
        '✅ Notifikasi "${selectedMessage['title']}" dijadwalkan untuk: $scheduledDate',
      );
    } catch (e) {
      debugPrint('❌ Error scheduling random notification: $e');
    }
  }

  // 🔶 Batalkan notifikasi "Enjoy Snack"
  Future<void> cancelEnjoySnackNotification() async {
    try {
      await flutterLocalNotificationsPlugin.cancel(1);
      debugPrint('❌ Notifikasi enjoy snack dibatalkan');
    } catch (e) {
      debugPrint('❌ Error canceling notification: $e');
    }
  }

  // 🔶 Batalkan semua notifikasi
  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('❌ Semua notifikasi dibatalkan');
    } catch (e) {
      debugPrint('❌ Error canceling all notifications: $e');
    }
  }

  // 🔶 Cek notifikasi yang terjadwal
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
      return [];
    }
  }
}
