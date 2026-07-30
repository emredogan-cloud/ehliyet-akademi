import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/coach/notification_service.dart';
import '../../data/practice/progress_repository.dart';
import '../notifications/notification_kind.dart';
import '../notifications/notification_plan.dart';

/// Bildirim tercihleri (persist: `ea:notifications:v1`).
///
/// Beta Faz 6 — tek anahtar yerine **tür başına** tercih. Gerekçe: tek anahtar kullanıcıya
/// "hepsi ya da hiçbiri" dayatır; haftalık özetten rahatsız olan kişi çalışma hatırlatmasını da
/// kaybeder ve pratikte bildirimlerin tamamını kapatır. Kapatılan bildirim bir daha açılmaz.
class NotificationPrefs {
  const NotificationPrefs({
    this.enabled = false,
    this.hour = 19,
    this.minute = 0,
    this.kinds = const {},
  });

  /// ANA anahtar — kapalıysa hiçbir bildirim planlanmaz (tür tercihleri korunur).
  final bool enabled;
  final int hour;
  final int minute;

  /// Açık olan türler. Boşsa katalogdaki varsayılanlar geçerlidir.
  final Set<NotificationKind> kinds;

  /// Bir tür şu an etkin mi (ana anahtar + tür tercihi).
  bool isOn(NotificationKind kind) => enabled && effectiveKinds.contains(kind);

  /// Tercih hiç kaydedilmemişse katalogdaki varsayılanlar.
  ///
  /// NEDEN boş küme "hiçbiri" DEĞİL: yeni bir bildirim türü eklendiğinde, daha önce tercih
  /// kaydetmiş kullanıcıların o türü otomatik alması istenir mi? Hayır — sessizce yeni bildirim
  /// göndermek kullanıcının verdiği izni genişletmek olurdu. Bu yüzden boş küme yalnız HİÇ
  /// tercih kaydedilmemişken varsayılana düşer; kaydedilmiş bir küme olduğu gibi kullanılır.
  Set<NotificationKind> get effectiveKinds => kinds.isEmpty
      ? {for (final k in NotificationKind.values) if (k.defaultEnabled) k}
      : kinds;

  NotificationPrefs copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    Set<NotificationKind>? kinds,
  }) => NotificationPrefs(
    enabled: enabled ?? this.enabled,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    kinds: kinds ?? this.kinds,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'hour': hour,
    'minute': minute,
    'kinds': [for (final k in kinds) k.prefKey],
  };

  factory NotificationPrefs.fromJson(Map<String, dynamic> j) {
    final rawKinds = (j['kinds'] as List?)?.map((e) => e.toString()).toSet() ?? const <String>{};
    return NotificationPrefs(
      enabled: j['enabled'] as bool? ?? false,
      hour: (j['hour'] as num?)?.toInt() ?? 19,
      minute: (j['minute'] as num?)?.toInt() ?? 0,
      kinds: {
        for (final k in NotificationKind.values)
          // Tanınmayan anahtar SESSİZCE atılır: eski bir sürümde var olup kaldırılmış bir tür,
          // güncellemeden sonra çökmeye yol açmamalı.
          if (rawKinds.contains(k.prefKey)) k,
      },
    );
  }

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

const _kNotif = 'ea:notifications:v1';

/// Bildirim tercihleri + planlama denetleyicisi.
///
/// Denetleyicinin tek işi: tercihler ya da ilerleme değiştiğinde **yeniden uzlaştırmak**. Neyin ne
/// zaman planlanacağı kararı burada DEĞİL, saf [planNotifications] içinde.
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
    // Açılışta da uzlaştır: tek seferlik bildirimler (kaçırılan gün, seri) her açılışta
    // yeniden hesaplanmalı — dünkü plan bugün yanlış olabilir.
    await reconcile();
  }

  Future<void> _persist(NotificationPrefs p) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kNotif, jsonEncode(p.toJson()));
    } catch (_) {}
  }

  /// Uygulamanın şu anki durumundan planı üret ve uygula.
  ///
  /// Hata YUTULUR: bildirim planlayamamak (izin yok, platform kanalı yok) ürünün çalışmasını
  /// engellemez.
  Future<void> reconcile({DateTime? now}) async {
    try {
      if (!state.enabled) {
        await _service.cancelAll();
        return;
      }
      await _service.apply(planNotifications(await _buildContext(now ?? DateTime.now())));
    } catch (_) {}
  }

  /// Planlayıcının göreceği gerçekler. İlerleme deposu henüz hazır değilse boş bağlamla devam
  /// edilir — bildirim uğruna açılışı beklemek doğru olmaz.
  Future<NotificationContext> _buildContext(DateTime now) async {
    final progress = ref.read(progressRepositoryProvider).value;
    final answers = progress?.loadAnswers() ?? const [];
    final streak = progress?.loadStreak();
    final weekAgo = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;

    return NotificationContext(
      now: now,
      reminderHour: state.hour,
      reminderMinute: state.minute,
      lastStudyDay: (streak?.lastDay.isEmpty ?? true) ? null : streak!.lastDay,
      currentStreak: streak?.current ?? 0,
      answeredThisWeek: answers.where((a) => a.at >= weekAgo).length,
      enabledKinds: state.effectiveKinds,
    );
  }

  /// Ana anahtar. Açarken izin ister; izin verilmezse durum DEĞİŞMEZ (yalan söylenmez).
  Future<bool> setEnabled(bool enabled) async {
    if (enabled) {
      final granted = await _service.requestPermission();
      if (!granted) return false;
    }
    state = state.copyWith(enabled: enabled);
    await _persist(state);
    await reconcile();
    return true;
  }

  /// Tek bir türü aç/kapat.
  Future<void> setKind(NotificationKind kind, bool on) async {
    final next = {...state.effectiveKinds};
    if (on) {
      next.add(kind);
    } else {
      next.remove(kind);
    }
    // Boş küme "varsayılana dön" anlamına geldiği için, kullanıcı HEPSİNİ kapattığında küme boş
    // kalmamalı — yoksa tercih sessizce geri gelirdi. Ana anahtar bu durumu temsil eder.
    if (next.isEmpty) {
      state = state.copyWith(enabled: false, kinds: {});
    } else {
      state = state.copyWith(kinds: next);
    }
    await _persist(state);
    await reconcile();
  }

  Future<void> setTime(int hour, int minute) async {
    state = state.copyWith(hour: hour, minute: minute);
    await _persist(state);
    await reconcile();
  }

  Future<void> sendTest() =>
      _service.showNow('Ehliyet Akademi', 'Bildirimler çalışıyor 🎉 Çalışma hatırlatmaların hazır.');
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsController, NotificationPrefs>(
      NotificationSettingsController.new,
    );
