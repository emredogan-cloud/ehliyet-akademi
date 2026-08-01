import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/content/dash_lights.dart';
import 'package:ehliyet_akademi/domain/content/traffic_sign.dart';
import 'package:ehliyet_akademi/domain/content/vehicle_part.dart';
import 'package:ehliyet_akademi/domain/practice/exam.dart' show seededRng;
import 'package:ehliyet_akademi/domain/practice/question.dart';
import 'package:ehliyet_akademi/domain/practice/visual_questions.dart';
import 'package:flutter_test/flutter_test.dart';

/// QIP v3 · Faz 2/4/7 — görsel soru üretiminin kalite kapısı.
///
/// Bu dosya bir özelliğin çalıştığını değil, **üretilen her sorunun bankaya girebilecek kalitede
/// olduğunu** doğrular. Üreteç, insan yazımından farklı olarak yorulmaz ve dikkatsizleşmez; ama
/// bozuk bir kuralı da hiç şaşmadan 500 kez uygular. Kapı bunun içindir.

TrafficSign _sign(String id, SignCategory cat, String meaning) => TrafficSign(
  id: id,
  category: cat,
  name: 'Levha $id',
  shape: SignShape.triangle,
  meaning: meaning,
  memoryTip: 'İpucu $id.',
  examImportance: ExamImportance.orta,
);

VehiclePart _part(String id, VehicleSystem sys, String name, String desc) =>
    VehiclePart(id: id, name: name, system: sys, desc: desc, tip: 'İpucu $id.');

void main() {
  final rng = () => seededRng(20260801);

  group('üretilen her soru BİÇİM kapısından geçer', () {
    final signs = [
      for (var i = 0; i < 8; i++)
        _sign('s$i', i.isEven ? SignCategory.tehlike : SignCategory.yasak, 'Anlam $i'),
    ];
    // Gerçek varlık kimlikleri — üreteç varlığı olmayan parça için soru üretmez, bu yüzden
    // uydurma kimlik kullanılamaz.
    const partIds = [
      'ac-button',
      'air-filter-box',
      'battery-12v',
      'blank-panel',
      'boot-release-button',
      'brake-fluid-reservoir',
    ];
    final parts = [
      for (var i = 0; i < partIds.length; i++)
        _part(partIds[i], VehicleSystem.motorBolmesi, 'Parça $i', 'Görev $i'),
    ];

    test('tam dört şık, geçerli cevap indeksi, benzersiz şıklar', () {
      final qs = buildVisualQuestions(signs: signs, parts: parts, rng: rng());
      expect(qs, isNotEmpty);
      for (final q in qs) {
        expect(q.options, hasLength(kOptionCount), reason: '${q.id}: dört şık olmalı');
        expect(q.answerIndex, inInclusiveRange(0, kOptionCount - 1));
        expect(
          q.options.toSet(),
          hasLength(kOptionCount),
          reason: '${q.id}: şıklar birbirini tekrar edemez',
        );
        expect(q.explanation.trim(), isNotEmpty, reason: '${q.id}: açıklama zorunlu');
        expect(q.stem.trim(), isNotEmpty);
      }
    });

    /// Doğru cevap gerçekten doğru olmalı — `answerIndex` karıştırmadan SONRA yeniden eşlenmezse
    /// üreteç sessizce yanlış cevap öğretir. Bu, üretimin en sinsi kusurudur.
    test('answerIndex karıştırmadan sonra doğru şıkkı gösterir', () {
      final qs = buildSignQuestions(signs, rng());
      for (final q in qs) {
        final id = q.id.replaceFirst('vq-sign-', '');
        final sign = signs.firstWhere((s) => s.id == id);
        expect(
          q.options[q.answerIndex],
          sign.meaning,
          reason: '${q.id}: doğru şık işaretin anlamı olmalı',
        );
      }
    });

    test('her görsel sorunun media + BOŞ OLMAYAN alt metni var', () {
      final qs = buildVisualQuestions(signs: signs, parts: parts, rng: rng());
      for (final q in qs) {
        expect(q.kind.needsMedia, isTrue, reason: '${q.id}: görsel tür bekleniyor');
        expect(q.media, isNotNull, reason: '${q.id}: media zorunlu');
        expect(q.media!.images, isNotEmpty);
        for (final img in q.media!.images) {
          expect(img.assetId.trim(), isNotEmpty);
          expect(
            img.alt.trim().length,
            greaterThanOrEqualTo(3),
            reason: '${q.id}: görsel çizilemezse soru bu metinle cevaplanabilir olmalı',
          );
        }
      }
    });

    test('kimlikler benzersiz', () {
      final qs = buildVisualQuestions(signs: signs, parts: parts, rng: rng());
      expect(qs.map((q) => q.id).toSet(), hasLength(qs.length));
    });

    test('öğrenme kazanımı her soruda dolu', () {
      final qs = buildVisualQuestions(signs: signs, parts: parts, rng: rng());
      expect(qs.every((q) => (q.objective ?? '').trim().isNotEmpty), isTrue);
    });
  });

  group('belirlenimcilik', () {
    /// Aynı tohum → birebir aynı çıktı. Kullanıcı sınavı yarıda bırakıp döndüğünde aynı soruyu
    /// aynı şık sırasıyla görmeli; ilerleme kaydı soru kimliğine bağlı.
    test('aynı tohum aynı soruları aynı sırayla üretir', () {
      final a = buildVisualQuestions(rng: seededRng(42));
      final b = buildVisualQuestions(rng: seededRng(42));
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].id, b[i].id);
        expect(a[i].options, b[i].options);
        expect(a[i].answerIndex, b[i].answerIndex);
      }
    });

    test('farklı tohum şık sırasını değiştirir', () {
      final a = buildVisualQuestions(rng: seededRng(1));
      final b = buildVisualQuestions(rng: seededRng(2));
      expect(a.length, b.length);
      expect(
        List.generate(a.length, (i) => a[i].options.join()),
        isNot(List.generate(b.length, (i) => b[i].options.join())),
      );
    });
  });

  group('gömülü ikaz ışığı kataloğu', () {
    /// İkaz ışıkları pakete gömülü — içerik indirilmeden de görsel soru üretilebilmeli.
    test('içerik indirilmemişken bile ikaz soruları üretilir', () {
      final qs = buildVisualQuestions(rng: rng());
      expect(qs, isNotEmpty);
      expect(qs.every((q) => q.kind == QuestionKind.dashboard), isTrue);
      expect(qs.length, greaterThanOrEqualTo(kDashLights.length));
    });

    test('her ikaz için anlam ve eylem sorusu ayrı ayrı üretilir', () {
      final qs = buildDashQuestions(kDashLights, rng());
      final actionIds = qs.where((q) => q.id.endsWith('-eylem')).length;
      expect(actionIds, greaterThan(0));
      expect(qs.length, greaterThan(actionIds), reason: 'anlam soruları da olmalı');
    });
  });

  group('çeldirici yetersizse soru ÜRETİLMEZ', () {
    /// Üç benzersiz çeldirici bulunamıyorsa üç şıklı soru üretmektense hiç üretmemek doğrudur
    /// (Faz 11'de kapatılan "üç şıklı soru" kusuru geri gelmemeli).
    test('havuz küçükse üretim atlanır, bozuk soru çıkmaz', () {
      final tiny = [_sign('a', SignCategory.tehlike, 'Tek anlam')];
      expect(buildSignQuestions(tiny, rng()), isEmpty);
    });

    test('aynı anlamı taşıyan levhalar çeldirici sayısını düşürür', () {
      final dup = [
        for (var i = 0; i < 4; i++) _sign('d$i', SignCategory.tehlike, 'Aynı anlam'),
      ];
      expect(buildSignQuestions(dup, rng()), isEmpty);
    });
  });

  group('birleştirme — yazılmış soru her zaman kazanır', () {
    test('aynı kimlikteki üretim atılır', () {
      const authored = Question(
        id: 'vq-dash-fren-uyari',
        subject: Subject.motor,
        topic: 'Gösterge Paneli',
        stem: 'İnsan yazımı soru',
        options: ['a', 'b', 'c', 'd'],
        answerIndex: 0,
        explanation: 'insan açıklaması',
      );
      final merged = mergeVisualQuestions([authored], buildVisualQuestions(rng: rng()));
      final hit = merged.where((q) => q.id == 'vq-dash-fren-uyari').toList();
      expect(hit, hasLength(1));
      expect(hit.single.stem, 'İnsan yazımı soru', reason: 'üreteç insan yazımının üstüne yazamaz');
    });

    test('çakışmayan üretimler eklenir', () {
      final visual = buildVisualQuestions(rng: rng());
      final merged = mergeVisualQuestions(const [], visual);
      expect(merged, hasLength(visual.length));
    });
  });
}
