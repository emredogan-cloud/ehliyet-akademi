import 'package:ehliyet_akademi/domain/notifications/notification_kind.dart';
import 'package:ehliyet_akademi/domain/notifications/notification_plan.dart';
import 'package:flutter_test/flutter_test.dart';

/// Beta Faz 6 — bildirim planlama kuralları.
///
/// ## Neden bu kadar test
///
/// Bildirim hataları en pahalı hata sınıfıdır çünkü **gecikmeli** görünürler: yanlış kural bugün
/// yazılır, kullanıcı üç gün sonra gece yarısı uyanır ve uygulamayı siler. Cihazda deneyerek
/// doğrulamak günler alır — "üç gün sonra ne olacak" sorusunu cihaz üç günde cevaplar, saf bir
/// fonksiyon bir milisaniyede.
void main() {
  /// Salı, 14:00.
  final tuesday2pm = DateTime(2026, 7, 28, 14);

  NotificationContext ctx({
    DateTime? now,
    int hour = 19,
    int minute = 0,
    String? lastStudyDay,
    int streak = 0,
    int answeredThisWeek = 0,
    DateTime? premiumExpiresAt,
    Set<NotificationKind>? kinds,
  }) => NotificationContext(
    now: now ?? tuesday2pm,
    reminderHour: hour,
    reminderMinute: minute,
    lastStudyDay: lastStudyDay,
    currentStreak: streak,
    answeredThisWeek: answeredThisWeek,
    premiumExpiresAt: premiumExpiresAt,
    enabledKinds: kinds ?? NotificationKind.values.toSet(),
  );

  PlannedNotification? pick(List<PlannedNotification> list, NotificationKind kind) {
    for (final p in list) {
      if (p.kind == kind) return p;
    }
    return null;
  }

  group('katalog bütünlüğü', () {
    /// Kimlik çakışması SESSİZ bir hatadır: ikinci bildirim birincisini ezer ve kullanıcı bir
    /// hatırlatmayı hiç görmez. Hiçbir yere log düşmez.
    test('her türün kimliği TEKİL', () {
      final ids = NotificationKind.values.map((k) => k.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('kimlikler "test" bildirimiyle de çakışmaz', () {
      // `LocalNotificationService._testId` = 999.
      expect(NotificationKind.values.map((k) => k.id), isNot(contains(999)));
    });

    test('her türün kullanıcıya gösterilecek adı ve açıklaması var', () {
      for (final k in NotificationKind.values) {
        expect(k.label, isNotEmpty);
        expect(k.description, isNotEmpty, reason: '${k.name}: kullanıcı NEYE izin verdiğini bilmeli');
      }
    });
  });

  group('sessiz saatler', () {
    /// Gece gelen bir "çalışma hatırlatması" bildirimleri kapattırır — ve kapatılan bildirim bir
    /// daha açılmaz.
    test('gece 23:00–08:00 sessizdir', () {
      expect(isQuietHour(23), isTrue);
      expect(isQuietHour(2), isTrue);
      expect(isQuietHour(7), isTrue);
      expect(isQuietHour(8), isFalse);
      expect(isQuietHour(22), isFalse);
    });

    test('gece yarısına düşen an SABAHA ötelenir, öne ÇEKİLMEZ', () {
      // Öne çekmek, hatırlatmayı kullanıcının hiç beklemediği bir ana koyardı.
      final lateNight = DateTime(2026, 7, 28, 23, 30);
      final moved = avoidQuietHours(lateNight);
      expect(moved.isAfter(lateNight), isTrue);
      expect(moved.hour, kQuietEndHour);
      expect(moved.day, 29);
    });

    test('sabaha karşı olan an AYNI günün sabahına ötelenir', () {
      final earlyMorning = DateTime(2026, 7, 28, 3);
      final moved = avoidQuietHours(earlyMorning);
      expect(moved, DateTime(2026, 7, 28, kQuietEndHour));
    });

    test('gündüz olan an DEĞİŞMEZ', () {
      expect(avoidQuietHours(tuesday2pm), tuesday2pm);
    });
  });

  group('günlük çalışma hatırlatması', () {
    test('saat henüz gelmediyse BUGÜN planlanır', () {
      final plan = planNotifications(ctx(hour: 19));
      expect(pick(plan, NotificationKind.studyReminder)!.at, DateTime(2026, 7, 28, 19));
    });

    test('saat GEÇTİYSE yarına planlanır', () {
      final plan = planNotifications(ctx(hour: 9));
      expect(pick(plan, NotificationKind.studyReminder)!.at, DateTime(2026, 7, 29, 9));
    });

    test('serisi olan kullanıcıya seri hatırlatılır', () {
      final plan = planNotifications(ctx(streak: 5));
      expect(pick(plan, NotificationKind.studyReminder)!.body, contains('5 günlük'));
    });

    test('serisi olmayana seriden BAHSEDİLMEZ', () {
      final plan = planNotifications(ctx());
      expect(pick(plan, NotificationKind.studyReminder)!.body, isNot(contains('seri')));
    });
  });

  group('kaçırılan gün', () {
    /// Hiç çalışmamış kullanıcıya "ara verdin" demek yanlış: ara verecek bir şey yok ve mesaj
    /// suçlayıcı okunur.
    test('HİÇ çalışmamış kullanıcıya gönderilmez', () {
      expect(pick(planNotifications(ctx(lastStudyDay: null)), NotificationKind.missedStudyDay), isNull);
    });

    test('bugün çalışmışsa gönderilmez', () {
      final plan = planNotifications(ctx(lastStudyDay: '2026-07-28'));
      expect(pick(plan, NotificationKind.missedStudyDay), isNull);
    });

    test('dün çalışmış, bugün çalışmamışsa gönderilir', () {
      final plan = planNotifications(ctx(lastStudyDay: '2026-07-27'));
      expect(pick(plan, NotificationKind.missedStudyDay), isNotNull);
    });

    /// Metin SUÇLAMAZ. "İki gündür çalışmadın" cümlesi kullanıcıyı savunmaya geçirir; amaç
    /// utandırmak değil geri getirmek.
    test('metin suçlayıcı değil', () {
      final body = pick(
        planNotifications(ctx(lastStudyDay: '2026-07-20')),
        NotificationKind.missedStudyDay,
      )!.body;
      for (final blame in ['çalışmadın', 'ihmal', 'unuttun']) {
        expect(body.toLowerCase(), isNot(contains(blame)));
      }
    });
  });

  group('seri koruması', () {
    test('serisi 2+ ve bugün çalışmamışsa akşam hatırlatılır', () {
      final plan = planNotifications(ctx(streak: 4, lastStudyDay: '2026-07-27'));
      final streak = pick(plan, NotificationKind.streak);
      expect(streak, isNotNull);
      expect(streak!.at.hour, 21);
      expect(streak.title, contains('4 günlük'));
    });

    /// Serisi olmayan kullanıcıya "serin tehlikede" demek anlamsızdır — tehlikede olan bir şey yok.
    test('serisi yoksa gönderilmez', () {
      expect(pick(planNotifications(ctx(streak: 0)), NotificationKind.streak), isNull);
      expect(pick(planNotifications(ctx(streak: 1)), NotificationKind.streak), isNull);
    });

    test('bugün zaten çalışmışsa gönderilmez', () {
      final plan = planNotifications(ctx(streak: 4, lastStudyDay: '2026-07-28'));
      expect(pick(plan, NotificationKind.streak), isNull);
    });

    /// Saat 21'i geçtiyse "akşam 21'de hatırlat" GEÇMİŞE planlama olurdu.
    test('akşam 21 geçtiyse gönderilmez', () {
      final plan = planNotifications(
        ctx(now: DateTime(2026, 7, 28, 22), streak: 4, lastStudyDay: '2026-07-27'),
      );
      expect(pick(plan, NotificationKind.streak), isNull);
    });
  });

  group('haftalık özet', () {
    test('pazar akşamı 19:00 planlanır', () {
      final weekly = pick(planNotifications(ctx()), NotificationKind.weeklySummary)!;
      expect(weekly.at.weekday, DateTime.sunday);
      expect(weekly.at.hour, 19);
    });

    test('bugün pazar ve saat geçtiyse HAFTAYA planlanır', () {
      // 2026-08-02 pazar.
      final sundayLate = DateTime(2026, 8, 2, 20);
      final weekly = pick(planNotifications(ctx(now: sundayLate)), NotificationKind.weeklySummary)!;
      expect(weekly.at, DateTime(2026, 8, 9, 19));
    });

    /// Sayı GERÇEK. "Harika bir hafta geçirdin" demek, hiç çalışmamış kullanıcıya yalan
    /// söylemektir ve güveni tek seferde bitirir.
    test('sıfır soruyu SIFIR olarak söyler, övmez', () {
      final body = pick(planNotifications(ctx(answeredThisWeek: 0)), NotificationKind.weeklySummary)!.body;
      expect(body, contains('hiç soru çözmedin'));
      expect(body.toLowerCase(), isNot(contains('harika')));
    });

    test('gerçek sayıyı yazar', () {
      final body = pick(planNotifications(ctx(answeredThisWeek: 42)), NotificationKind.weeklySummary)!.body;
      expect(body, contains('42'));
    });
  });

  group('premium süresi', () {
    /// Ömür boyu satın almada bitiş YOKTUR. "Premium'un bitiyor" demek, satın aldığı şeyi
    /// kaybedeceğini sanan bir kullanıcı yaratırdı.
    test('süresiz erişimde gönderilmez', () {
      expect(pick(planNotifications(ctx(premiumExpiresAt: null)), NotificationKind.premiumExpiring), isNull);
    });

    test('süreli erişimde 3 gün önce hatırlatılır', () {
      final expiry = DateTime(2026, 8, 10, 12);
      final plan = planNotifications(ctx(premiumExpiresAt: expiry));
      expect(pick(plan, NotificationKind.premiumExpiring)!.at, DateTime(2026, 8, 7, 12));
    });

    /// Uyarı anı GEÇMİŞTE kalıyorsa planlanmaz — geçmişe bildirim kurulamaz.
    test('bitişe 3 günden az kaldıysa gönderilmez', () {
      final plan = planNotifications(ctx(premiumExpiresAt: DateTime(2026, 7, 29)));
      expect(pick(plan, NotificationKind.premiumExpiring), isNull);
    });
  });

  group('kullanıcı tercihi', () {
    test('kapalı tür HİÇ planlanmaz', () {
      final plan = planNotifications(ctx(kinds: {NotificationKind.studyReminder}));
      expect(plan.map((p) => p.kind), [NotificationKind.studyReminder]);
    });

    test('hiçbir tür açık değilse plan BOŞTUR', () {
      expect(planNotifications(ctx(kinds: {})), isEmpty);
    });
  });

  group('planlanan hiçbir bildirim sessiz saate düşmez', () {
    /// Bütün kuralların ortak kapısı. Tek tek doğru olan kurallar, birlikte yanlış bir sonuç
    /// verebilir; bu test onu yakalar.
    test('gün boyunca hangi saatte hesaplanırsa hesaplansın', () {
      for (var hour = 0; hour < 24; hour++) {
        final plan = planNotifications(
          ctx(
            now: DateTime(2026, 7, 28, hour),
            hour: 19,
            lastStudyDay: '2026-07-26',
            streak: 3,
            premiumExpiresAt: DateTime(2026, 9, 1),
          ),
        );
        for (final p in plan) {
          expect(
            isQuietHour(p.at.hour),
            isFalse,
            reason: 'saat $hour için ${p.kind.name} sessiz saate düştü (${p.at})',
          );
        }
      }
    });
  });
}
