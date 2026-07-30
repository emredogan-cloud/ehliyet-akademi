import 'package:flutter/foundation.dart';

import 'notification_kind.dart';

/// Planlanacak tek bir bildirim.
@immutable
class PlannedNotification {
  const PlannedNotification({
    required this.kind,
    required this.at,
    required this.title,
    required this.body,
  });

  final NotificationKind kind;
  final DateTime at;
  final String title;
  final String body;

  @override
  bool operator ==(Object other) =>
      other is PlannedNotification &&
      other.kind == kind &&
      other.at == at &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(kind, at, title, body);

  @override
  String toString() => '${kind.name}@${at.toIso8601String()}';
}

/// Planlayıcının gördüğü uygulama durumu.
///
/// **Yalnız gerçekler; karar yok.** Bu ayrım bilinçli: kararlar [planNotifications] içinde, tek
/// yerde ve saf olarak verilir. Ekranların "acaba şimdi bildirim planlamalı mıyım" diye düşünmesi
/// gerekseydi, kural her ekranda biraz farklı uygulanırdı.
@immutable
class NotificationContext {
  const NotificationContext({
    required this.now,
    required this.reminderHour,
    required this.reminderMinute,
    this.lastStudyDay,
    this.currentStreak = 0,
    this.answeredThisWeek = 0,
    this.readiness,
    this.premiumExpiresAt,
    this.enabledKinds = const {},
  });

  final DateTime now;
  final int reminderHour;
  final int reminderMinute;

  /// Son çalışılan gün (`YYYY-MM-DD`). Hiç çalışılmadıysa null.
  final String? lastStudyDay;
  final int currentStreak;
  final int answeredThisWeek;

  /// 0–100 hazırlık oranı (bilinmiyorsa null).
  final int? readiness;

  /// SÜRELİ premium erişiminin bitişi (ömür boyu satın almada null).
  final DateTime? premiumExpiresAt;

  /// Kullanıcının açık bıraktığı türler.
  final Set<NotificationKind> enabledKinds;
}

/// `YYYY-MM-DD`.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Gece saatleri — bu aralıkta bildirim GÖNDERİLMEZ.
///
/// Sınava hazırlanan kitlenin büyük kısmı genç ve telefonu yatakta. Gece 23:00–08:00 arasında
/// gelen bir "çalışma hatırlatması" ürünü sevdirmez, bildirimleri kapattırır — ve kapatılan bir
/// bildirim bir daha geri açılmaz. Sessiz saat, kısıtlama değil koruma.
const int kQuietStartHour = 23;
const int kQuietEndHour = 8;

bool isQuietHour(int hour) => hour >= kQuietStartHour || hour < kQuietEndHour;

/// Verilen anı sessiz saatlerin DIŞINA taşı (gerekiyorsa).
///
/// Öne değil ARKAYA alınır: bir hatırlatmayı erkene çekmek onu kullanıcının hiç beklemediği bir
/// ana koyar; ertelemek yalnız geciktirir.
DateTime avoidQuietHours(DateTime at) {
  if (!isQuietHour(at.hour)) return at;
  final nextMorning = at.hour >= kQuietStartHour
      ? DateTime(at.year, at.month, at.day, kQuietEndHour).add(const Duration(days: 1))
      : DateTime(at.year, at.month, at.day, kQuietEndHour);
  return nextMorning;
}

/// Beta Faz 6 — HANGİ bildirimin NE ZAMAN planlanacağına karar veren SAF fonksiyon.
///
/// ## Neden saf
///
/// Bildirim hataları en pahalı hata sınıfıdır çünkü **gecikmeli** görünürler: yanlış kural bugün
/// yazılır, kullanıcı üç gün sonra gece yarısı uyanır ve uygulamayı siler. Cihazda deneyerek
/// doğrulamak günler alır. Kural saf bir fonksiyon olduğunda, üç gün sonrası bir testte bir
/// milisaniyede denenir.
///
/// ## Dönüş
///
/// **İSTENEN küme.** Planlayıcı bunu cihazdaki mevcut kümeyle karşılaştırır; fazlalıkları iptal
/// eder, eksikleri planlar. "Ekle" değil "uzlaştır" olması önemli: kullanıcı bir türü kapattığında
/// zaten planlanmış bildirimin de gitmesi gerekir.
List<PlannedNotification> planNotifications(NotificationContext ctx) {
  final out = <PlannedNotification>[];
  bool on(NotificationKind k) => ctx.enabledKinds.contains(k);

  // ── Günlük çalışma hatırlatması ──────────────────────────────────────────────────────────────
  if (on(NotificationKind.studyReminder)) {
    out.add(
      PlannedNotification(
        kind: NotificationKind.studyReminder,
        at: _nextDailyAt(ctx.now, ctx.reminderHour, ctx.reminderMinute),
        title: 'Bugünün çalışması seni bekliyor',
        body: ctx.currentStreak > 0
            ? '${ctx.currentStreak} günlük serini sürdür — 10 dakika yeter.'
            : 'Kısa bir oturum bile ilerlemeni değiştirir.',
      ),
    );
  }

  // ── Kaçırılan gün ────────────────────────────────────────────────────────────────────────────
  //
  // YALNIZ daha önce çalışmış kullanıcıya. Hiç çalışmamış birine "ara verdin" demek yanlış olurdu:
  // ara verecek bir şey yok ve mesaj suçlayıcı okunur.
  if (on(NotificationKind.missedStudyDay) && ctx.lastStudyDay != null) {
    final missedFor = _daysSince(ctx.lastStudyDay!, ctx.now);
    if (missedFor >= 1) {
      out.add(
        PlannedNotification(
          kind: NotificationKind.missedStudyDay,
          at: avoidQuietHours(ctx.now.add(const Duration(hours: 2))),
          title: 'Kaldığın yerden devam',
          // Suçlama YOK. "İki gündür çalışmadın" cümlesi kullanıcıyı savunmaya geçirir;
          // amaç utandırmak değil geri getirmek.
          body: 'Sınav yaklaşıyor — bugün 10 soruyla ısınmaya ne dersin?',
        ),
      );
    }
  }

  // ── Seri koruması ────────────────────────────────────────────────────────────────────────────
  //
  // Seri VARSA ve BUGÜN çalışılmadıysa: gün bitmeden hatırlat. Serisi olmayan kullanıcı için
  // "serin kırılıyor" demek anlamsızdır.
  if (on(NotificationKind.streak) && ctx.currentStreak >= 2) {
    final studiedToday = ctx.lastStudyDay == dayKey(ctx.now);
    if (!studiedToday) {
      final atNine = DateTime(ctx.now.year, ctx.now.month, ctx.now.day, 21);
      if (atNine.isAfter(ctx.now)) {
        out.add(
          PlannedNotification(
            kind: NotificationKind.streak,
            at: atNine,
            title: '${ctx.currentStreak} günlük serin tehlikede',
            body: 'Bugün birkaç soru çöz, seri devam etsin.',
          ),
        );
      }
    }
  }

  // ── Haftalık özet — pazar akşamı ─────────────────────────────────────────────────────────────
  if (on(NotificationKind.weeklySummary)) {
    out.add(
      PlannedNotification(
        kind: NotificationKind.weeklySummary,
        at: _nextSundayEvening(ctx.now),
        title: 'Haftanın özeti hazır',
        // Sayı GERÇEK: sıfırsa sıfır yazılır. "Harika bir hafta geçirdin" demek, hiç çalışmamış
        // kullanıcıya yalan söylemektir ve güveni tek seferde bitirir.
        body: ctx.answeredThisWeek > 0
            ? 'Bu hafta ${ctx.answeredThisWeek} soru çözdün. İlerlemene göz at.'
            : 'Bu hafta hiç soru çözmedin. Yeni hafta iyi bir başlangıç için fırsat.',
      ),
    );
  }

  // ── Premium süresi bitiyor ───────────────────────────────────────────────────────────────────
  //
  // YALNIZ SÜRELİ erişimde (davet ödülü). Ömür boyu satın almada bitiş yoktur → bildirim de yok.
  final expiry = ctx.premiumExpiresAt;
  if (on(NotificationKind.premiumExpiring) && expiry != null) {
    final warnAt = expiry.subtract(const Duration(days: 3));
    if (warnAt.isAfter(ctx.now)) {
      out.add(
        PlannedNotification(
          kind: NotificationKind.premiumExpiring,
          at: avoidQuietHours(warnAt),
          title: 'Premium erişimin 3 gün sonra bitiyor',
          body: 'Erişimini sürdürmek için paketi inceleyebilir ya da arkadaş davet edebilirsin.',
        ),
      );
    }
  }

  return out;
}

/// Bir sonraki [hour]:[minute] anı (bugün geçtiyse yarın).
DateTime _nextDailyAt(DateTime now, int hour, int minute) {
  var next = DateTime(now.year, now.month, now.day, hour, minute);
  if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
  return next;
}

/// Bir sonraki pazar 19:00. Bugün pazar ve saat geçtiyse HAFTAYA.
DateTime _nextSundayEvening(DateTime now) {
  // `DateTime.sunday` == 7.
  final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
  var next = DateTime(now.year, now.month, now.day, 19).add(Duration(days: daysUntilSunday));
  if (!next.isAfter(now)) next = next.add(const Duration(days: 7));
  return next;
}

/// [day] (`YYYY-MM-DD`) ile bugün arasındaki tam gün farkı. Ayrıştırılamazsa 0.
int _daysSince(String day, DateTime now) {
  final parsed = DateTime.tryParse(day);
  if (parsed == null) return 0;
  final a = DateTime(parsed.year, parsed.month, parsed.day);
  final b = DateTime(now.year, now.month, now.day);
  return b.difference(a).inDays;
}
