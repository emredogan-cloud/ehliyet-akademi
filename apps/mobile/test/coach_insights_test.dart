import 'package:ehliyet_akademi/domain/coach/coach_insights.dart';
import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/practice/srs.dart';
import 'package:flutter_test/flutter_test.dart';

/// Beta Faz 7 — AI Koç analiz katmanı.
///
/// ## Bu testlerin çoğu "hesap doğru mu" DEĞİL, "yanlış bir şey İDDİA ETMİYOR mu" diye sorar
///
/// Bir koçun en pahalı hatası yanlış hesap değil, **temelsiz güvendir**. "Şu konuda zayıfsın"
/// cümlesi üç soruya dayanıyorsa kullanıcıyı gerçek zayıflığından uzaklaştırır; "sınavdan 38
/// alırsın" cümlesi yirmi soruya dayanıyorsa kullanıcı sınava hazır olmadan girer. Aşağıdaki
/// testlerin yarısı tam olarak bunları yasaklar.
void main() {
  const now = 1785500000000;

  AnswerLog ans(String topic, bool correct, {Subject subject = Subject.trafik, int? at}) =>
      AnswerLog(
        questionId: 'q-$topic-$correct-${at ?? now}',
        subject: subject,
        topic: topic,
        correct: correct,
        at: at ?? now,
      );

  List<AnswerLog> series(String topic, {required int total, required int correct, int? at}) => [
    for (var i = 0; i < total; i++) ans(topic, i < correct, at: (at ?? now) - i),
  ];

  group('zayıf konu tespiti', () {
    test('AZ VERİYLE zayıflık iddia edilmez', () {
      // Üç soruda iki yanlış "%33" diye gösterilebilir ama bu istatistik değil, gürültüdür.
      final weak = weakTopics(series('kavsak', total: 3, correct: 1));
      expect(weak, isEmpty);
    });

    test('eşiğe ulaşınca ve doğruluk düşükse tespit edilir', () {
      final weak = weakTopics(series('kavsak', total: 20, correct: 8));
      expect(weak.single.topic, 'kavsak');
      expect(weak.single.accuracyPercent, 40);
      expect(weak.single.wrong, 12);
    });

    test('İYİ olduğu konu zayıf sayılmaz', () {
      expect(weakTopics(series('isaretler', total: 20, correct: 18)), isEmpty);
    });

    test('en zayıf ÖNCE sıralanır', () {
      final weak = weakTopics([
        ...series('orta', total: 20, correct: 12),
        ...series('kotu', total: 20, correct: 5),
      ]);
      expect(weak.map((w) => w.topic), ['kotu', 'orta']);
    });

    /// Aynı doğruluktaki iki konudan çok soru görüleni daha güvenilirdir ve sınavda daha çok yer
    /// kaplar.
    test('eşit doğrulukta ÇOK YANLIŞ olan öne alınır', () {
      final weak = weakTopics([
        ...series('az', total: 10, correct: 5),
        ...series('cok', total: 40, correct: 20),
      ]);
      expect(weak.first.topic, 'cok');
    });

    test('sınır sayısı kadar döner', () {
      final answers = [
        for (var i = 0; i < 9; i++) ...series('konu$i', total: 10, correct: 3),
      ];
      expect(weakTopics(answers, limit: 3), hasLength(3));
    });
  });

  group('ilerleme eğilimi', () {
    test('iki dönemin de anlamlı olması ŞART', () {
      // Son hafta 40 soru, ondan önce 2 soru → "gelişiyorsun" demek 2 soruluk gürültüyü referans
      // almak olurdu.
      final trend = progressTrend([
        ...series('a', total: 40, correct: 30),
        ...series('b', total: 2, correct: 0, at: now - 9 * dayMs),
      ], nowMs: now);
      expect(trend.isMeaningful, isFalse);
      expect(trend.isImproving, isFalse);
    });

    test('gerçek gelişme tespit edilir', () {
      final trend = progressTrend([
        ...series('a', total: 20, correct: 18),
        ...series('b', total: 20, correct: 10, at: now - 9 * dayMs),
      ], nowMs: now);
      expect(trend.isImproving, isTrue);
      expect(trend.isDeclining, isFalse);
    });

    test('gerçek düşüş tespit edilir — SAKLANMAZ', () {
      // Düşüşü saklamak, sınavdan kalan kullanıcıya "gelişiyorsun" demiş olmak demektir.
      final trend = progressTrend([
        ...series('a', total: 20, correct: 8),
        ...series('b', total: 20, correct: 18, at: now - 9 * dayMs),
      ], nowMs: now);
      expect(trend.isDeclining, isTrue);
    });

    test('küçük dalgalanma "değişim" sayılmaz', () {
      final trend = progressTrend([
        ...series('a', total: 20, correct: 14),
        ...series('b', total: 20, correct: 13, at: now - 9 * dayMs),
      ], nowMs: now);
      expect(trend.isMeaningful, isTrue);
      expect(trend.isImproving, isFalse);
      expect(trend.isDeclining, isFalse);
    });
  });

  group('7 günlük plan', () {
    test('her zaman yedi gün üretir', () {
      expect(sevenDayPlan(weak: const [], dueCardCount: 0), hasLength(7));
    });

    test('3. ve 7. gün TEKRAR günüdür', () {
      final plan = sevenDayPlan(weak: const [], dueCardCount: 0);
      expect(plan.where((d) => d.isReviewDay).map((d) => d.dayIndex), [2, 6]);
    });

    test('zayıf konular plana İNSAN OKUNUR adıyla girer', () {
      // Plan kartı odağı olduğu gibi çizer; slug orada görünmemeli.
      final weak = weakTopics(series('kavsak-onceligi', total: 20, correct: 6));
      final plan = sevenDayPlan(weak: weak, dueCardCount: 0);
      expect(
        plan.where((d) => !d.isReviewDay).map((d) => d.focus),
        everyElement('Kavsak onceligi'),
      );
    });

    /// Zayıf konu yoksa UYDURMA konu üretilmez.
    test('zayıf konu yoksa dürüstçe genel çalışma', () {
      final plan = sevenDayPlan(weak: const [], dueCardCount: 0);
      expect(plan.where((d) => !d.isReviewDay).map((d) => d.focus), everyElement('Karışık çalışma'));
    });

    test('vadesi gelen kart varsa tekrar günü onu gösterir', () {
      final plan = sevenDayPlan(weak: const [], dueCardCount: 12);
      expect(plan[2].focus, contains('12'));
      expect(plan[2].questionCount, 12);
    });

    test('çok fazla vadesi gelen kart varsa hedef makul kalır', () {
      // 200 kartlık bir gün, planı ilk günden terk ettirir.
      final plan = sevenDayPlan(weak: const [], dueCardCount: 200);
      expect(plan[2].questionCount, lessThanOrEqualTo(30));
    });
  });

  _humanizeGuard();

  group('sınav tahmini', () {
    Readiness readinessOf(int overall) => Readiness(
      overall: overall,
      predictedPassProbability: overall / 100,
      light: TrafficLight.sari,
      perSubject: const [],
      message: '',
    );

    /// Yirmi sorunun altında SAYI GÖSTERİLMEZ. "Sınavdan 38 alırsın" demek, örneklem küçükken
    /// yanlıştır ve kullanıcı sınava hazır olmadan girer.
    test('yetersiz veride tahmin YAPILMAZ', () {
      final f = examForecast(readiness: readinessOf(80), answeredCount: 10);
      expect(f.confidence, PredictionConfidence.none);
      expect(f.predictedCorrect, 0);
    });

    test('hiç veri yoksa tahmin yapılmaz', () {
      expect(examForecast(readiness: null, answeredCount: 0).confidence, PredictionConfidence.none);
    });

    test('veri arttıkça güven yükselir', () {
      expect(examForecast(readiness: readinessOf(70), answeredCount: 25).confidence,
          PredictionConfidence.low);
      expect(examForecast(readiness: readinessOf(70), answeredCount: 100).confidence,
          PredictionConfidence.medium);
      expect(examForecast(readiness: readinessOf(70), answeredCount: 500).confidence,
          PredictionConfidence.high);
    });

    test('tahmin 50 soruluk sınava ölçeklenir', () {
      expect(examForecast(readiness: readinessOf(76), answeredCount: 100).predictedCorrect, 38);
    });

    test('baraj kararı doğru', () {
      expect(examForecast(readiness: readinessOf(76), answeredCount: 100).predictsPass, isTrue);
      expect(examForecast(readiness: readinessOf(60), answeredCount: 100).predictsPass, isFalse);
    });

    /// Güvenilirlik cümlesi sayının yanından AYRILMAZ; yalnız sayı gösterilirse kullanıcı onu bir
    /// SÖZ sanar.
    test('güven etiketi dayanağı SÖYLER', () {
      final low = examForecast(readiness: readinessOf(70), answeredCount: 25);
      expect(confidenceLabel(low), contains('25'));
      expect(confidenceLabel(low), contains('kesin sonuç değildir'));

      final none = examForecast(readiness: null, answeredCount: 0);
      expect(confidenceLabel(none), contains('yeterli veri yok'));
    });
  });
}

/// Konu adlarının insan okunur hâle gelmesi.
///
/// Cihazda görüldü: soru bankasındaki `topic` bir SLUG (`kavsaklarda-gecis-onceligi`,
/// `abc-degerlendirme`, `112-arama`) ve kartlar bunları HAM gösteriyordu. Kullanıcı
/// "abc-degerlendirme" diye bir şey okumaz; ekran teknik bir döküman gibi görünür.
void _humanizeGuard() {
  group('konu adı insanileştirme', () {
    test('tire boşluğa döner, ilk harf büyür', () {
      expect(humanizeTopic('kavsaklarda-gecis-onceligi'), 'Kavsaklarda gecis onceligi');
    });

    /// TÜRKÇE: Dart'ın `toUpperCase()` metodu `i` harfini `I` yapar; doğrusu `İ`'dir.
    /// "Ilk yardım" yazan bir ürün Türkçe bilmiyor görünür.
    test('Türkçe büyük harf kuralı — i → İ, ı → I', () {
      expect(humanizeTopic('ilk-yardim'), startsWith('İ'));
      expect(humanizeTopic('ilk-yardim'), isNot(startsWith('I')));
      expect(humanizeTopic('ısınma-turu'), startsWith('I'));
    });

    test('bilinen kısaltmalar BÜYÜK kalır', () {
      expect(humanizeTopic('abs'), 'ABS');
      expect(humanizeTopic('abc-degerlendirme'), 'ABC degerlendirme');
    });

    test('sayıyla başlayan parça olduğu gibi kalır', () {
      expect(humanizeTopic('112-arama'), '112 arama');
    });

    test('yalnız İLK kelime büyür — başlık gibi durmasın', () {
      expect(humanizeTopic('agir-tasit-serit'), 'Agir tasit serit');
    });

    test('boş ve tek kelimelik girdide çökmez', () {
      expect(humanizeTopic(''), '');
      expect(humanizeTopic('genel'), 'Genel');
      expect(humanizeTopic('---'), '---');
    });
  });
}
