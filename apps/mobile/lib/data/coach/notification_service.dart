import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Yerel bildirim servisi (flutter_local_notifications). Çevrimdışı; zamanı-tabanlı hatırlatmalar
/// cihazda planlanır. FCM push AYRI bir iş (bu ortamda Firebase yapılandırması yok → belgelenmiş
/// takip). Saat dilimi: Türkiye uygulaması → Europe/Istanbul.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  static const _channelId = 'ea_study';
  static const _channelName = 'Çalışma hatırlatmaları';
  static const _dailyId = 1001;
  static const _testId = 999;

  Future<void> init() async {
    if (_inited) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    } catch (_) {}
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(settings: const InitializationSettings(android: android));
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Günlük çalışma ve seri hatırlatmaları',
            importance: Importance.high,
          ),
        );
    _inited = true;
  }

  Future<bool> requestPermission() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Günlük çalışma ve seri hatırlatmaları',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> showNow(String title, String body) async {
    await init();
    await _plugin.show(id: _testId, title: title, body: body, notificationDetails: _details);
  }

  /// Her gün [hour]:[minute]'da çalışma hatırlatması planla (quiet-hours: gündüz saatleri önerilir).
  Future<void> scheduleDaily(int hour, int minute) async {
    await init();
    await _plugin.cancel(id: _dailyId);
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: _dailyId,
      title: 'Çalışma zamanı 📚',
      body: 'Bugünkü kısa oturumla serini sürdür — birkaç dakika yeter.',
      scheduledDate: next,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDaily() async {
    await init();
    await _plugin.cancel(id: _dailyId);
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());
