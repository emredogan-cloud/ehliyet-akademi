import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/duel/duel.dart';
import 'package:ehliyet_akademi/domain/duel/duel_energy.dart';
import 'package:ehliyet_akademi/domain/practice/question.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ürün Evrimi v1.1 · Faz 4 — Düello motoru kapısı.

Question _q(String id) => Question(
  id: id,
  subject: Subject.trafik,
  topic: 'Konu-${id.hashCode % 5}',
  difficulty: Difficulty.orta,
  stem: 'Soru gövdesi $id',
  options: const ['Birinci seçenek', 'İkinci seçenek', 'Üçüncü seçenek', 'Dördüncü seçenek'],
  answerIndex: 1,
  explanation: 'Açıklama $id',
);

List<Question> _bank() => [for (var i = 0; i < 80; i++) _q('q$i')];

const _config = DuelConfig(seed: 42);

void main() {
  group('yapay zekâ rakip', () {
    test('doğruluk seviyeyle artar ama %85\'i AŞMAZ', () {
      expect(AiOpponent.accuracyForLevel(1), closeTo(0.55, 0.001));
      expect(AiOpponent.accuracyForLevel(20), closeTo(0.85, 0.001));
      // Kusursuz rakip, oyuncunun kusursuz oynamadıkça kazanamayacağı demektir.
      expect(AiOpponent.accuracyForLevel(999), closeTo(0.85, 1e-9));
      expect(AiOpponent.accuracyForLevel(-5), greaterThanOrEqualTo(0.55));
    });

    test('BELİRLENİMCİ — aynı tohum aynı davranış', () async {
      final qs = _bank().take(20).toList();
      Future<List<int?>> run() async {
        final o = AiOpponent(level: 5, seed: 7);
        return [
          for (var i = 0; i < qs.length; i++) (await o.answerFor(qs[i], i)).choice,
        ];
      }

      expect(await run(), await run());
    });

    test('yanlış cevap DOĞRU şıkkın dışından seçilir', () async {
      // Doğruluğu sıfırlanmış rakip hiçbir zaman doğruyu tutturmamalı; tutturursa
      // "doğruluk oranı" ölçüsü anlamını yitirir.
      final o = AiOpponent(level: 1, seed: 3, accuracy: 0);
      final qs = _bank().take(40).toList();
      for (var i = 0; i < qs.length; i++) {
        final a = await o.answerFor(qs[i], i);
        expect(a.isCorrectFor(qs[i]), isFalse);
        expect(a.choice, isNotNull);
      }
    });

    test('düşünme süresi SABİT değil — bot gibi görünmesin', () async {
      final o = AiOpponent(level: 10, seed: 11);
      final qs = _bank().take(15).toList();
      final times = <int>[];
      for (var i = 0; i < qs.length; i++) {
        times.add((await o.answerFor(qs[i], i)).elapsedMs);
      }
      expect(times.toSet().length, greaterThan(5));
      expect(times.every((t) => t >= AiOpponent.minThinkMs && t <= AiOpponent.maxThinkMs), isTrue);
    });
  });

  group('puanlama', () {
    final q = _q('x');

    test('yanlış cevap 0 puan — ceza YOK', () {
      expect(DuelScoring.pointsFor(const DuelAnswer(choice: 0, elapsedMs: 100), q, _config), 0);
      expect(DuelScoring.pointsFor(const DuelAnswer(choice: null, elapsedMs: 20000), q, _config), 0);
    });

    test('hızlı doğru, yavaş doğrudan çok puan getirir', () {
      final hizli = DuelScoring.pointsFor(const DuelAnswer(choice: 1, elapsedMs: 1000), q, _config);
      final yavas = DuelScoring.pointsFor(const DuelAnswer(choice: 1, elapsedMs: 19000), q, _config);
      expect(hizli, greaterThan(yavas));
    });

    /// Yalnız hıza puan verilseydi en iyi strateji "okuma, rastgele bas" olurdu.
    test('EN YAVAŞ doğru bile, EN HIZLI yanlıştan çok eder', () {
      final yavasDogru = DuelScoring.pointsFor(
        const DuelAnswer(choice: 1, elapsedMs: 20000),
        q,
        _config,
      );
      final hizliYanlis = DuelScoring.pointsFor(
        const DuelAnswer(choice: 0, elapsedMs: 1),
        q,
        _config,
      );
      expect(yavasDogru, greaterThan(hizliYanlis));
      expect(yavasDogru, DuelScoring.correctPoints);
    });
  });

  group('sonuç ve XP', () {
    List<DuelAnswer> answers(int correct, int total) => [
      for (var i = 0; i < total; i++)
        DuelAnswer(choice: i < correct ? 1 : 0, elapsedMs: 5000),
    ];

    test('kazanan/kaybeden/berabere', () {
      final qs = _bank().take(10).toList();
      final win = scoreDuel(
        questions: qs,
        player: answers(8, 10),
        opponent: answers(4, 10),
        config: _config,
      );
      expect(win.won, isTrue);
      expect(win.label, 'Kazandın');

      final draw = scoreDuel(
        questions: qs,
        player: answers(5, 10),
        opponent: answers(5, 10),
        config: _config,
      );
      expect(draw.drew, isTrue);
    });

    /// Sıfır XP veren bir sistem, oyuncuyu zayıf olduğu konudan kaçırır — tam olarak
    /// çalışması gereken konudan.
    test('KAYBEDEN DE XP alır', () {
      final qs = _bank().take(10).toList();
      final lose = scoreDuel(
        questions: qs,
        player: answers(3, 10),
        opponent: answers(9, 10),
        config: _config,
      );
      expect(lose.lost, isTrue);
      expect(lose.xp, greaterThan(0));
      expect(lose.xp, 3 * DuelResult.xpPerCorrect);
    });

    test('galibiyet bonusu eklenir', () {
      final qs = _bank().take(10).toList();
      final win = scoreDuel(
        questions: qs,
        player: answers(7, 10),
        opponent: answers(2, 10),
        config: _config,
      );
      expect(win.xp, 7 * DuelResult.xpPerCorrect + DuelResult.xpWinBonus);
    });
  });

  test('düello soruları üreteçten gelir ve istenen adette', () {
    final qs = buildDuelQuestions(_bank(), const DuelConfig(questionCount: 10, seed: 5));
    expect(qs, hasLength(10));
    expect(qs.map((q) => q.id).toSet(), hasLength(10), reason: 'aynı soru iki kez gelmemeli');
  });

  group('enerji ve günlük sınır', () {
    final now = DateTime(2026, 8, 1, 12);

    test('ücretsiz kullanıcı günde $kFreeDailyDuels düello', () {
      var e = DuelEnergy.empty;
      expect(remainingDuels(e, now, premium: false), kFreeDailyDuels);
      for (var i = 0; i < kFreeDailyDuels; i++) {
        expect(canStartDuel(e, now, premium: false), isTrue);
        e = spendForDuel(e, now);
      }
      expect(remainingDuels(e, now, premium: false), 0);
      expect(duelBlockReason(e, now, premium: false), DuelBlock.dailyLimit);
    });

    test('premium daha çok ama SINIRSIZ değil', () {
      expect(kPremiumDailyDuels, greaterThan(kFreeDailyDuels));
      expect(kPremiumDailyDuels, lessThan(1000));
      var e = DuelEnergy.empty;
      for (var i = 0; i < kPremiumDailyDuels; i++) {
        e = spendForDuel(e, now);
      }
      expect(duelBlockReason(e, now, premium: true), DuelBlock.dailyLimit);
    });

    test('gün değişince hak yenilenir', () {
      var e = DuelEnergy.empty;
      for (var i = 0; i < kFreeDailyDuels; i++) {
        e = spendForDuel(e, now);
      }
      expect(remainingDuels(e, now, premium: false), 0);
      expect(remainingDuels(e, now.add(const Duration(days: 1)), premium: false), kFreeDailyDuels);
    });

    test('enerji BAŞLANGIÇTA harcanır — yarıda bırakmak bedava düello vermez', () {
      final before = DuelEnergy.empty;
      final after = spendForDuel(before, now);
      expect(after.spent, 1);
      // Düello bitirilmese bile hak geri gelmiyor.
      expect(remainingDuels(after, now, premium: false), kFreeDailyDuels - 1);
    });
  });

  group('çiftçilik önleme', () {
    final now = DateTime(2026, 8, 1, 12);

    test('bitişten hemen sonra yeni düello başlatılamaz', () {
      final e = markFinished(DuelEnergy.empty, now);
      expect(duelBlockReason(e, now, premium: false), DuelBlock.cooldown);
      expect(cooldownLeft(e, now).inMilliseconds, kDuelCooldownMs);
    });

    test('bekleme dolunca serbest', () {
      final e = markFinished(DuelEnergy.empty, now);
      final sonra = now.add(const Duration(milliseconds: kDuelCooldownMs + 1));
      expect(duelBlockReason(e, sonra, premium: false), isNull);
      expect(cooldownLeft(e, sonra), Duration.zero);
    });

    test('hiç düello bitirilmemişse bekleme UYGULANMAZ', () {
      expect(duelBlockReason(DuelEnergy.empty, now, premium: false), isNull);
    });

    /// Bekleme, meşru kullanımı engellememeli: sonucu okuyup yeniden başlamak bundan uzun sürer.
    test('bekleme kısa tutulmuş', () {
      expect(kDuelCooldownMs, lessThanOrEqualTo(60 * 1000));
    });
  });

  group('sıralama basamağı', () {
    test('XP arttıkça yükselir', () {
      expect(rankForXp(0), DuelRank.cirak);
      expect(rankForXp(499), DuelRank.cirak);
      expect(rankForXp(500), DuelRank.kalfa);
      expect(rankForXp(99999), DuelRank.sampiyon);
    });

    test('sonraki basamağa kalan XP', () {
      expect(xpToNextRank(0), 500);
      expect(xpToNextRank(499), 1);
      expect(xpToNextRank(99999), isNull);
    });
  });

  group('kalıcılık', () {
    test('gidiş-dönüş bozulmaz', () {
      const e = DuelEnergy(spent: 3, dayKey: '2026-08-01', lastFinishedAtMs: 12345);
      final back = DuelEnergy.fromJson(e.toJson());
      expect(back.spent, 3);
      expect(back.dayKey, '2026-08-01');
      expect(back.lastFinishedAtMs, 12345);
    });

    test('bozuk kayıt çökmez', () {
      final back = DuelEnergy.fromJson(const {'spent': 'x', 'dayKey': 5});
      expect(back.spent, 0);
      expect(back.dayKey, '');
    });
  });

  /// Çevrimiçi eşleşme geldiğinde ekran kodu değişmemeli.
  test('rakip ARAYÜZLE soyutlanmış — çevrimiçi uygulama takılabilir', () {
    final o = AiOpponent(level: 3, seed: 1);
    expect(o, isA<DuelOpponent>());
    expect(o.name, isNotEmpty);
  });
}
