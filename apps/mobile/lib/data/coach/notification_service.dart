import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/notifications/notification_kind.dart';
import '../../domain/notifications/notification_plan.dart';

/// Yerel bildirim servisi (flutter_local_notifications). Çevrimdışı; zamanı-tabanlı hatırlatmalar
/// cihazda planlanır. FCM push AYRI bir iş (bu ortamda Firebase yapılandırması yok → belgelenmiş
/// takip). Saat dilimi: Türkiye uygulaması → Europe/Istanbul.
///
/// Beta Faz 6 — servis artık TEK bir günlük hatırlatma değil, **katalogdaki her türü** planlar ve
/// istenen kümeyle cihazdaki kümeyi UZLAŞTIRIR ([apply]).
abstract class NotificationService {
  Future<void> init();
  Future<bool> requestPermission();

  /// İstenen bildirim kümesini uygula: eksikleri planla, artık istenmeyenleri İPTAL ET.
  Future<void> apply(List<PlannedNotification> planned);

  /// Tek bir bildirimi hemen göster (ayarlar ekranındaki "test et").
  Future<void> showNow(String title, String body);

  /// Tüm planlı bildirimleri iptal et (ana anahtar kapatıldığında).
  Future<void> cancelAll();
}

class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  /// "Test et" bildirimi — katalogdaki hiçbir kimlikle çakışmayan ayrı bir kimlik.
  static const _testId = 999;

  @override
  Future<void> init() async {
    if (_inited) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    } catch (_) {}
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(settings: const InitializationSettings(android: android));

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    // Her kanal AYRI kurulur: Android'de kullanıcı kanalları tek tek susturabilir. Tek kanal
    // olsaydı, haftalık özetten rahatsız olan kullanıcı çalışma hatırlatmasını da kapatmak
    // zorunda kalırdı (bkz. `NotificationChannelKind`).
    for (final channel in NotificationChannelKind.values) {
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          channel.id,
          channel.name,
          description: channel.description,
          importance: Importance.high,
        ),
      );
    }
    _inited = true;
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  NotificationDetails _detailsFor(NotificationChannelKind channel) => NotificationDetails(
    android: AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  @override
  Future<void> showNow(String title, String body) async {
    await init();
    await _plugin.show(
      id: _testId,
      title: title,
      body: body,
      notificationDetails: _detailsFor(NotificationChannelKind.study),
    );
  }

  /// İstenen kümeyi uygula.
  ///
  /// UZLAŞTIRMA, "ekleme" değil: katalogdaki ama istenen kümede OLMAYAN her tür iptal edilir.
  /// Aksi hâlde kullanıcı bir türü kapattığında, zaten planlanmış bildirim cihazda kalır ve
  /// kapatma isteği görmezden gelinmiş olurdu — kullanıcının bildirim ayarlarına bir daha
  /// güvenmemesi için yeterli bir sebep.
  @override
  Future<void> apply(List<PlannedNotification> planned) async {
    await init();
    final wanted = {for (final p in planned) p.kind: p};

    for (final kind in NotificationKind.values) {
      final want = wanted[kind];
      if (want == null) {
        await _plugin.cancel(id: kind.id);
        continue;
      }
      await _plugin.cancel(id: kind.id);
      await _plugin.zonedSchedule(
        id: kind.id,
        title: want.title,
        body: want.body,
        scheduledDate: tz.TZDateTime.from(want.at, tz.local),
        notificationDetails: _detailsFor(kind.channel),
        // `inexactAllowWhileIdle`: tam saat gerektirmeyen hatırlatmalar için Android'in
        // önerdiği kip. `exact` izni Android 12+'ta ayrı bir kullanıcı onayı ister ve bir
        // çalışma hatırlatması o onayı istemeyi hak etmez.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // Günlük hatırlatma HER GÜN tekrarlar; diğerleri tek seferliktir ve bir sonraki
        // uzlaştırmada yeniden hesaplanır.
        matchDateTimeComponents:
            kind == NotificationKind.studyReminder ? DateTimeComponents.time : null,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    await init();
    for (final kind in NotificationKind.values) {
      await _plugin.cancel(id: kind.id);
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => LocalNotificationService(),
);
