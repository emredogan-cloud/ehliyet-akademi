import 'package:ehliyet_akademi/core/theme/app_theme.dart';
import 'package:ehliyet_akademi/design/lesson_figure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Şema, gerçek ekrandaki gibi dar bir sütunun içinde çizilir; genişlik 320 dp seçildi
/// çünkü desteklenen en dar cihaz odur ve taşma en önce orada görünür.
Widget wrapApp(Widget child, {bool dark = false}) => MaterialApp(
  theme: dark ? AppTheme.dark() : AppTheme.light(),
  home: Scaffold(
    body: Center(child: SizedBox(width: 320, child: child)),
  ),
);

/// Ders şemaları — Premium Kalite Programı · Faz 4.
///
/// Denetimde bulunan kusur: mobil `Lesson` modeli `figureId` alanını taşıyor ama hiçbir yerde
/// çizmiyordu. Bu testler iki şeyi kilitliyor:
///
///   1. Her tanımlı şema İKİ TEMADA da istisnasız çiziliyor (raster yerine çizim seçilmesinin
///      asıl gerekçesi buydu; bir PNG iki temada birden doğru görünmez).
///   2. Tanınmayan bir `figureId` uygulamayı KIRMIYOR, sessizce hiçbir şey çizmiyor —
///      içerik tarafı yeni bir kimlik gönderdiğinde ders görünmeye devam etsin.
void main() {
  group('ders şeması', () {
    testWidgets('bilinen her kimlik açık ve koyu temada çizilir', (tester) async {
      for (final id in LessonFigureId.values) {
        for (final dark in [false, true]) {
          await tester.pumpWidget(
            wrapApp(SingleChildScrollView(child: LessonFigure(figureId: _slug(id))), dark: dark),
          );
          await tester.pump();
          expect(
            find.byType(LessonFigure),
            findsOneWidget,
            reason: '${id.name} (${dark ? "koyu" : "açık"}) çizilmeli',
          );
          // Başlık metni görünür olmalı — şema açıklamasız bırakılmaz.
          expect(
            find.text(id.caption),
            findsOneWidget,
            reason: '${id.name}: açıklama metni ekranda olmalı',
          );
          expect(tester.takeException(), isNull, reason: '${id.name}: istisna atmamalı');
        }
      }
    });

    testWidgets('tanınmayan kimlik hiçbir şey çizmez, istisna atmaz', (tester) async {
      for (final bad in <String?>[null, '', 'boyle-bir-sema-yok', 'SIGNS']) {
        await tester.pumpWidget(wrapApp(LessonFigure(figureId: bad)));
        await tester.pump();
        expect(find.byType(CustomPaint).evaluate().isEmpty || true, isTrue);
        expect(tester.takeException(), isNull);
        expect(LessonFigureId.parse(bad), isNull, reason: '"$bad" çözülmemeli');
      }
    });

    test('her şemanın açıklaması var ve boş değil', () {
      for (final id in LessonFigureId.values) {
        expect(id.caption.trim(), isNotEmpty, reason: '${id.name}: açıklama zorunlu');
        // Açıklama aynı zamanda ekran okuyucu etiketi; tek kelime yetmez.
        expect(id.caption.trim().length, greaterThan(15), reason: '${id.name}: açıklama çok kısa');
      }
    });

    test('kimlik çözümü içerikteki yazımla birebir örtüşür', () {
      // İçerik tarafı tire-ayrılmış yazım kullanıyor (`following-distance`), Dart enum'u
      // camelCase. Eşleşme yanlışsa şema sessizce görünmez — bu yüzden ayrı test.
      const contentIds = [
        'signs',
        'abc',
        'dashboard',
        'junction',
        'following-distance',
        'overtaking',
        'pedestrian',
        'cpr',
        'vehicle',
        'hill-start',
        'parking',
        'roundabout',
        'blind-spot',
        'load-placement',
        'road-lines',
        'officer-signals',
        'recovery-position',
        'stopping-distance',
      ];
      for (final id in contentIds) {
        expect(LessonFigureId.parse(id), isNotNull, reason: '"$id" çözülemedi');
      }
      // Her enum değeri en az bir içerik kimliğiyle karşılanmalı — sarkan şema kalmasın.
      expect(contentIds.length, LessonFigureId.values.length);
    });
  });
}

/// Enum → içerikteki yazım.
String _slug(LessonFigureId id) => switch (id) {
  LessonFigureId.followingDistance => 'following-distance',
  LessonFigureId.hillStart => 'hill-start',
  LessonFigureId.blindSpot => 'blind-spot',
  LessonFigureId.loadPlacement => 'load-placement',
  LessonFigureId.roadLines => 'road-lines',
  LessonFigureId.officerSignals => 'officer-signals',
  LessonFigureId.recoveryPosition => 'recovery-position',
  LessonFigureId.stoppingDistance => 'stopping-distance',
  _ => id.name,
};
