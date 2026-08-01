import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/practice/exam.dart' show seededRng, theorySubjects;
import 'package:ehliyet_akademi/domain/practice/exam_v2.dart';
import 'package:ehliyet_akademi/domain/practice/question.dart';
import 'package:flutter_test/flutter_test.dart';

/// QIP v3 · Faz 5 — Sınav Üreteci V2 kapısı.
///
/// Üretecin iddiaları ÖLÇÜLEBİLİR olmalı: "zorluk dengeliyorum", "aynı görseli tekrarlamıyorum",
/// "zayıf konuya ağırlık veriyorum" — üçü de sayılabildiği için test edilebiliyor. `ExamPlan`
/// tam bunun için var.

Question _q(
  String id, {
  Subject subject = Subject.trafik,
  Difficulty difficulty = Difficulty.orta,
  String topic = 'Konu',
  String? asset,
}) => Question(
  id: id,
  subject: subject,
  topic: topic,
  difficulty: difficulty,
  stem: 'Soru gövdesi $id',
  options: const ['A secenegi', 'B secenegi', 'C secenegi', 'D secenegi'],
  answerIndex: 1,
  explanation: 'Açıklama $id',
  kind: asset == null ? QuestionKind.text : QuestionKind.sign,
  media: asset == null
      ? null
      : QuestionMedia(images: [QuestionImage(assetId: asset, alt: 'alt $asset')]),
);

List<Question> _pool({int perSubject = 30}) => [
  for (final s in theorySubjects)
    for (var i = 0; i < perSubject; i++)
      _q(
        '${s.name}-$i',
        subject: s,
        difficulty: Difficulty.values[i % 3],
        topic: 'Konu-${i % 5}',
      ),
];

void main() {
  group('kip varsayılanları', () {
    test('her kip kendi adedini kurar', () {
      expect(ExamConfig.forMode(ExamMode.exam).effectiveCount, 50);
      expect(ExamConfig.forMode(ExamMode.quick).effectiveCount, 10);
      expect(ExamConfig.forMode(ExamMode.practice).effectiveCount, 20);
      expect(ExamConfig.forMode(ExamMode.random).effectiveCount, 20);
      expect(ExamConfig.forMode(ExamMode.adaptive).effectiveCount, 20);
    });

    test('rastgele kip ders dağılımını GÖZETMEZ', () {
      expect(ExamConfig.forMode(ExamMode.random).subjects, isEmpty);
    });

    /// Zayıf konu çalışılırken "aynı konu arka arkaya gelmesin" kuralı amaca ters düşer.
    test('uyarlanabilir kipte ardışık konu kırma KAPALI', () {
      expect(ExamConfig.forMode(ExamMode.adaptive).avoidSameTopicRun, isFalse);
    });
  });

  group('konu/ders dengesi', () {
    test('sınav kipi MEB dağılımını kurar', () {
      final plan = buildExamV2(_pool(), ExamConfig.forMode(ExamMode.exam, seed: 1));
      expect(plan.exam.questions, hasLength(50));
      // 23/12/9/6 — havuz yeterli olduğu için tam kurulmalı.
      expect(plan.bySubject[Subject.trafik], 23);
      expect(plan.bySubject[Subject.ilkyardim], 12);
      expect(plan.bySubject[Subject.motor], 9);
      expect(plan.bySubject[Subject.adab], 6);
      expect(plan.exam.fullBlueprint, isTrue);
    });

    test('havuz yetersizse eksik olduğu DÜRÜSTÇE bildirilir', () {
      final plan = buildExamV2(_pool(perSubject: 2), ExamConfig.forMode(ExamMode.exam, seed: 1));
      expect(plan.exam.fullBlueprint, isFalse);
      expect(plan.exam.questions.length, lessThan(50));
      // Geçme sınırı da ölçeklenmeli — 8 soruluk sınavda 35 doğru istenemez.
      expect(plan.exam.passCorrect, lessThanOrEqualTo(plan.exam.questions.length));
    });
  });

  group('zorluk dengesi', () {
    /// Havuzda `orta` baskınken dengeleme olmadan sınav ortaya yığılıyordu. Dengeli seçim üç
    /// zorluğu da temsil etmeli.
    test('üç zorluk da temsil edilir', () {
      final skewed = [
        for (var i = 0; i < 60; i++) _q('orta-$i', difficulty: Difficulty.orta),
        for (var i = 0; i < 10; i++) _q('kolay-$i', difficulty: Difficulty.kolay),
        for (var i = 0; i < 10; i++) _q('zor-$i', difficulty: Difficulty.zor),
      ];
      final plan = buildExamV2(
        skewed,
        const ExamConfig(mode: ExamMode.practice, count: 12, subjects: {}, seed: 7),
      );
      expect(plan.byDifficulty[Difficulty.kolay] ?? 0, greaterThan(0));
      expect(plan.byDifficulty[Difficulty.zor] ?? 0, greaterThan(0));
    });

    test('dengeleme kapalıyken müdahale edilmez', () {
      final plan = buildExamV2(
        _pool(),
        const ExamConfig(count: 20, subjects: {}, difficultyBalance: false, seed: 3),
      );
      expect(plan.exam.questions, hasLength(20));
    });
  });

  group('görsel kuralları', () {
    test('aynı görsel iki kez KULLANILMAZ', () {
      final pool = [
        for (var i = 0; i < 40; i++) _q('v$i', asset: 'sign-${i % 4}'),
      ];
      final plan = buildExamV2(
        pool,
        const ExamConfig(count: 10, subjects: {}, seed: 5),
      );
      expect(plan.repeatedImages, 0);
      // Yalnız 4 benzersiz görsel var → en fazla 4 soru kurulabilir.
      expect(plan.exam.questions.length, lessThanOrEqualTo(4));
    });

    test('tekrar engeli kapalıyken aynı görsel gelebilir', () {
      final pool = [
        for (var i = 0; i < 40; i++) _q('v$i', asset: 'sign-${i % 2}'),
      ];
      final plan = buildExamV2(
        pool,
        const ExamConfig(count: 10, subjects: {}, noRepeatImage: false, seed: 5),
      );
      expect(plan.exam.questions, hasLength(10));
    });

    /// Görsel enjeksiyonu — metin ağırlıklı havuzda hedef orana yaklaşmalı.
    test('görsel oranı hedefi karışıma yansır', () {
      final pool = [
        for (var i = 0; i < 40; i++) _q('t$i'),
        for (var i = 0; i < 20; i++) _q('v$i', asset: 'a$i'),
      ];
      final none = buildExamV2(pool, const ExamConfig(count: 10, subjects: {}, seed: 11));
      final injected = buildExamV2(
        pool,
        const ExamConfig(count: 10, subjects: {}, visualRatio: 0.5, seed: 11),
      );
      expect(injected.visualCount, greaterThanOrEqualTo(none.visualCount));
      expect(injected.visualCount, greaterThan(0));
    });
  });

  group('şık karıştırma', () {
    /// En sinsi kusur: şıklar karışır ama `answerIndex` eski yerinde kalır → üreteç sessizce
    /// YANLIŞ cevap öğretir.
    test('karıştırmadan sonra doğru cevap hâlâ doğru', () {
      final pool = _pool(perSubject: 20);
      final byId = {for (final q in pool) q.id: q};
      final plan = buildExamV2(pool, ExamConfig.forMode(ExamMode.exam, seed: 9));
      for (final q in plan.exam.questions) {
        final original = byId[q.id]!;
        expect(
          q.options[q.answerIndex],
          original.options[original.answerIndex],
          reason: '${q.id}: doğru şık metni değişmemeli',
        );
        expect(q.options.toSet(), original.options.toSet());
      }
    });

    test('karıştırma kapalıyken sıra korunur', () {
      final plan = buildExamV2(
        _pool(perSubject: 20),
        const ExamConfig(count: 10, subjects: {}, randomizeChoices: false, seed: 4),
      );
      for (final q in plan.exam.questions) {
        expect(q.options.first, 'A secenegi');
      }
    });
  });

  group('uyarlanabilir kip', () {
    test('zayıf konular öne alınır', () {
      final pool = [
        for (var i = 0; i < 40; i++) _q('zayif-$i', topic: 'Zayıf Konu'),
        for (var i = 0; i < 40; i++) _q('iyi-$i', topic: 'İyi Konu'),
      ];
      final adaptive = buildExamV2(
        pool,
        const ExamConfig(
          mode: ExamMode.adaptive,
          count: 10,
          subjects: {},
          weakTopics: ['Zayıf Konu'],
          avoidSameTopicRun: false,
          seed: 2,
        ),
      );
      expect(adaptive.weakTopicCount, greaterThan(5), reason: 'zayıf konu ağır basmalı');
    });

    test('zayıf konu verilmezse normal seçim yapılır', () {
      final plan = buildExamV2(_pool(), ExamConfig.forMode(ExamMode.adaptive, seed: 2));
      expect(plan.weakTopicCount, 0);
      expect(plan.exam.questions, hasLength(20));
    });
  });

  group('ardışık konu tekrarı', () {
    test('aynı konu arka arkaya gelmez', () {
      final pool = [
        for (var i = 0; i < 30; i++) _q('a$i', topic: 'K${i % 3}'),
      ];
      final plan = buildExamV2(pool, const ExamConfig(count: 12, subjects: {}, seed: 6));
      var runs = 0;
      for (var i = 1; i < plan.exam.questions.length; i++) {
        if (plan.exam.questions[i].topic == plan.exam.questions[i - 1].topic) runs++;
      }
      expect(runs, 0, reason: 'ardışık aynı konu kalmamalı');
    });
  });

  group('belirlenimcilik', () {
    test('aynı tohum aynı sınavı kurar', () {
      final a = buildExamV2(_pool(), ExamConfig.forMode(ExamMode.exam, seed: 123));
      final b = buildExamV2(_pool(), ExamConfig.forMode(ExamMode.exam, seed: 123));
      expect(
        a.exam.questions.map((q) => q.id).toList(),
        b.exam.questions.map((q) => q.id).toList(),
      );
    });

    test('dışarıdan verilen rng de çalışır', () {
      final plan = buildExamV2(
        _pool(),
        const ExamConfig(count: 10, subjects: {}),
        rng: seededRng(77),
      );
      expect(plan.exam.questions, hasLength(10));
    });
  });

  group('biçimi bozuk soru sınava GİRMEZ', () {
    test('üç şıklı soru elenir', () {
      final broken = Question(
        id: 'bozuk',
        subject: Subject.trafik,
        topic: 'K',
        stem: 'Üç şıklı bozuk soru',
        options: const ['a', 'b', 'c'],
        answerIndex: 0,
        explanation: 'x',
      );
      final plan = buildExamV2(
        [broken, ..._pool(perSubject: 10)],
        const ExamConfig(count: 10, subjects: {}, seed: 1),
      );
      expect(plan.exam.questions.any((q) => q.id == 'bozuk'), isFalse);
    });
  });
}
