import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/coach/notification_service.dart';

/// Bildirim tercihleri (persist: `ea:notifications:v1`).
class NotificationPrefs {
  const NotificationPrefs({this.enabled = false, this.hour = 19, this.minute = 0});
  final bool enabled;
  final int hour;
  final int minute;

  NotificationPrefs copyWith({bool? enabled, int? hour, int? minute}) => NotificationPrefs(
    enabled: enabled ?? this.enabled,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
  );

  Map<String, dynamic> toJson() => {'enabled': enabled, 'hour': hour, 'minute': minute};
  factory NotificationPrefs.fromJson(Map<String, dynamic> j) => NotificationPrefs(
    enabled: j['enabled'] as bool? ?? false,
    hour: (j['hour'] as num?)?.toInt() ?? 19,
    minute: (j['minute'] as num?)?.toInt() ?? 0,
  );

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

const _kNotif = 'ea:notifications:v1';

/// Bildirim tercihleri + planlama denetleyicisi. Yerelde saklar; açıkken günlük hatırlatma planlar.
class NotificationSettingsController extends Notifier<NotificationPrefs> {
  @override
  NotificationPrefs build() {
    Future.microtask(_load);
    return const NotificationPrefs();
  }

  NotificationService get _service => ref.read(notificationServiceProvider);

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kNotif);
      if (raw != null) {
        state = NotificationPrefs.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  Future<void> _persist(NotificationPrefs p) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kNotif, jsonEncode(p.toJson()));
    } catch (_) {}
  }

  /// Bildirimleri aç/kapat. Açarken izin ister + günlük hatırlatma planlar; kapatırken iptal eder.
  Future<bool> setEnabled(bool enabled) async {
    if (enabled) {
      final granted = await _service.requestPermission();
      if (!granted) return false;
      await _service.scheduleDaily(state.hour, state.minute);
    } else {
      await _service.cancelDaily();
    }
    state = state.copyWith(enabled: enabled);
    await _persist(state);
    return true;
  }

  Future<void> setTime(int hour, int minute) async {
    state = state.copyWith(hour: hour, minute: minute);
    await _persist(state);
    if (state.enabled) await _service.scheduleDaily(hour, minute);
  }

  Future<void> sendTest() =>
      _service.showNow('Ehliyet Akademi', 'Bildirimler çalışıyor 🎉 Çalışma hatırlatmaların hazır.');
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsController, NotificationPrefs>(
      NotificationSettingsController.new,
    );
