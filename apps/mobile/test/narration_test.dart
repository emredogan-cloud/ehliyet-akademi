import 'package:ehliyet_akademi/data/content/narration_source.dart';
import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/content/lesson.dart';
import 'package:ehliyet_akademi/domain/content/narration.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sesli anlatım altyapısı — Premium Kalite Programı · Faz 5.
///
/// Ses SENTEZİ bu oturumda bağlanmadı. Bağlanmayan bir şeyin testi de olmaz; test edilen,
/// bugün gerçekten çalışan kısım: metnin dersten TÜRETİLMESİ, sağlayıcı seçiminin davranışı
/// ve ses yokken sistemin sessizce doğru davranması.
Lesson _lesson({
  String summary = 'Bu ders **takip mesafesini** anlatır.',
  List<String> objectives = const ['İki saniye kuralını uygulamak'],
  List<LessonSection> sections = const [],
  List<String> takeaways = const [],
}) => Lesson(
  id: 'hiz-takip',
  slug: 'hiz-takip',
  no: 1,
  subject: Subject.trafik,
  title: 'Hız ve Takip Mesafesi',
  summary: summary,
  minutes: 8,
  objectives: objectives,
  sections: sections,
  keyTakeaways: takeaways,
);

void main() {
  group('anlatım metni dersten türetilir', () {
    test('özet, hedefler, bölümler ve kapanış sırayla parçalanır', () {
      final n = buildLessonNarration(
        _lesson(
          sections: const [
            LessonSection(heading: 'İki saniye kuralı', body: 'Sabit bir nokta seç ve say.'),
            LessonSection(heading: 'Islak zemin', body: 'Mesafeyi artır.'),
          ],
          takeaways: const ['Kuru zeminde iki saniye'],
        ),
      );
      expect(n.segments.map((s) => s.id).toList(), [
        'ozet',
        'hedefler',
        'bolum-0',
        'bolum-1',
        'ozet-kapanis',
      ]);
      expect(n.lessonId, 'hiz-takip');
    });

    test('markdown süsleri seslendirme metninden temizlenir', () {
      final n = buildLessonNarration(_lesson());
      final ozet = n.segments.firstWhere((s) => s.id == 'ozet');
      // Yıldızlar okunmamalı; "yıldız yıldız takip mesafesini yıldız yıldız" olmamalı.
      expect(ozet.text, isNot(contains('*')));
      expect(ozet.text, contains('takip mesafesini'));
      // Başlık metnin başında olmalı — ekrana bakmayan dinleyici nerede olduğunu bilsin.
      expect(ozet.text, startsWith('Hız ve Takip Mesafesi.'));
    });

    test('boş gövdeli bölüm parça üretmez', () {
      final n = buildLessonNarration(
        _lesson(sections: const [LessonSection(heading: 'Boş', body: '   ')]),
      );
      expect(n.segments.any((s) => s.id.startsWith('bolum-')), isFalse);
    });

    test('süre tahmini sözcük sayısıyla artar ve makul aralıkta kalır', () {
      final kisa = buildLessonNarration(_lesson(summary: 'Kısa.'));
      final uzun = buildLessonNarration(
        _lesson(summary: List.filled(300, 'sözcük').join(' ')),
      );
      expect(uzun.estimatedSeconds, greaterThan(kisa.estimatedSeconds));
      // 300 sözcük ≈ 2 dakika (dakikada 150 sözcük varsayımı).
      expect(uzun.estimatedSeconds, inInclusiveRange(100, 160));
    });

    test('markdown temizleyici bağlantı METNİNİ korur, hedefini atar', () {
      expect(stripMarkdownForSpeech('[takip mesafesi](https://x.dev)'), 'takip mesafesi');
      expect(stripMarkdownForSpeech('## Başlık'), 'Başlık');
      expect(stripMarkdownForSpeech('- madde'), 'madde');
    });
  });

  group('kaynak soyutlaması', () {
    final seg = const NarrationSegment(id: 'ozet', title: 'Özet', text: 'metin');

    test('BUGÜNKÜ varsayılan sessizdir — ses yok, istisna da yok', () async {
      const src = SilentNarrationSource();
      expect(await src.resolve('ders', seg), isNull);
      expect(src.name, 'silent');
    });

    test('varlık kaynağı yalnız dosya GERÇEKTEN paketteyse yol döner', () async {
      final yok = AssetNarrationSource(exists: (_) => false);
      expect(await yok.resolve('hiz-takip', seg), isNull);

      final var_ = AssetNarrationSource(exists: (_) => true);
      expect(await var_.resolve('hiz-takip', seg), 'assets/audio/hiz-takip/ozet.m4a');
    });

    test('dosya adı sözleşmesi sabit — ses üreten buna göre isimlendirir', () {
      expect(AssetNarrationSource.pathFor('kavsak-oncelik', 'bolum-2'),
          'assets/audio/kavsak-oncelik/bolum-2.m4a');
    });

    test('geri düşüş sırayla dener, ilk ses vereni kullanır', () async {
      final src = FallbackNarrationSource([
        const SilentNarrationSource(),
        AssetNarrationSource(exists: (_) => true),
      ]);
      expect(await src.resolve('ders', seg), 'assets/audio/ders/ozet.m4a');
      expect(src.name, contains('silent>asset'));
    });

    test('uzak kaynak önbellekte hazır olanı verir, indirmeyi TETİKLEMEZ', () async {
      var calls = 0;
      final src = RemoteNarrationSource(
        cachedPath: (lesson, segment) async {
          calls++;
          return segment == 'ozet' ? '/tmp/ses/$lesson-$segment.m4a' : null;
        },
      );
      expect(await src.resolve('d', seg), '/tmp/ses/d-ozet.m4a');
      expect(
        await src.resolve('d', const NarrationSegment(id: 'bolum-9', title: 'x', text: 'y')),
        isNull,
      );
      expect(calls, 2, reason: 'her parça için tam bir kez sorulmalı');
    });
  });

  group('oynatma hızı', () {
    test('döngü 0,75 → 1 → 1,25 → 1,5 → 0,75', () {
      var s = NarrationSpeed.slow;
      final seen = <double>[];
      for (var i = 0; i < 5; i++) {
        seen.add(s.rate);
        s = s.next;
      }
      expect(seen, [0.75, 1.0, 1.25, 1.5, 0.75]);
    });

    test('2× BİLİNÇLİ olarak yok — eğitim içeriğinde anlamayı bozar', () {
      expect(NarrationSpeed.values.map((s) => s.rate), isNot(contains(2.0)));
      expect(NarrationSpeed.values.map((s) => s.rate).reduce((a, b) => a > b ? a : b), 1.5);
    });
  });
}
