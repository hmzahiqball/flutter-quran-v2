import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Inisialisasi Timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    // Inisialisasi Notifikasi
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings);

    // Minta izin notifikasi
    requestNotificationPermission();

    // Ambil jadwal dari API dan atur notifikasi
    await schedulePrayerNotifications();
  }

  static Future<void> requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        print("Izin notifikasi ditolak");
      }
    }
  }

  /// Ambil jadwal sholat dari API
  static Future<List<Map<String, dynamic>>> fetchPrayerTimes() async {
    try {
      final response = await http.get(
        Uri.parse("https://api.aladhan.com/v1/timingsByCity?city=Jakarta&country=Indonesia&method=2"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timings = data['data']['timings'];

        final prayerTimes = [
          {"name": "Subuh", "time": timings["Fajr"]},
          {"name": "Dzuhur", "time": timings["Dhuhr"]},
          {"name": "Ashar", "time": timings["Asr"]},
          {"name": "Maghrib", "time": timings["Maghrib"]},
          {"name": "Isya", "time": timings["Isha"]},
        ];
        print(prayerTimes);
        return prayerTimes;
      } else {
        print("Gagal mengambil jadwal sholat: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error mengambil jadwal sholat: $e");
      return [];
    }
  }

  /// Jadwalkan notifikasi sholat berdasarkan jadwal dari API
  static Future<void> schedulePrayerNotifications() async {
    List<Map<String, dynamic>> prayerTimes = await fetchPrayerTimes();

    for (var prayer in prayerTimes) {
      await _scheduleNotification(prayer["name"], prayer["time"]);
    }
  }

  /// Atur notifikasi dengan waktu yang sesuai
  static Future<void> _scheduleNotification(String prayerName, String time) async {
    final DateTime now = DateTime.now();
    final List<String> timeParts = time.split(":");
    final DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    if (scheduledTime.isAfter(now)) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'prayer_channel',
        'Prayer Notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      await _notificationsPlugin.zonedSchedule(
        prayerName.hashCode, // Gunakan hash agar ID unik
        'Waktu Sholat',
        'Saatnya sholat $prayerName',
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Ulang setiap hari
      );
    }
  }
}
