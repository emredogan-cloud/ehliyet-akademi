import 'package:ehliyet_akademi/design/brand.dart';
import 'package:ehliyet_akademi/features/onboarding/widgets/coach_insight_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Beta R2 — onboarding ADIM sayfalarının **doluluk** kapısı.
///
/// Ürün sahibi geri bildirimi: "Faz 6 yalnız ilk sayfayı çözdü; kalan sayfalar ekranın yaklaşık
/// yarısını boş bırakıyor." Faz 6'da eksik olan şey ölçüt değil, **ölçüydü**: kaydırmasızlık
/// (`onboarding_experience_test.dart`) doğrulanıyordu ama DOLULUK hiçbir yerde ölçülmüyordu, bu
/// yüzden yarı boş bir sayfa da kapıdan geçebiliyordu.
///
/// Burada iki şey ölçülür:
/// 1. **Yayılım** — en üstteki içerikten (ilerleme çubuğu) CTA'nın altına kadar olan mesafe,
///    ekranın en az %85'i olmalı (yol haritası şartı: %85–95).
/// 2. **En büyük boşluk** — ardışık iki içerik bloğu arasındaki en büyük açıklık. Yayılım tek
///    başına yeterli DEĞİL: içerik yukarıda ve aşağıda toplanıp ortada kocaman bir delik
///    bırakabilir; "sırıtan boşluk olmasın" şartı ancak bu ölçüyle korunur.
void main() {
  const titles = <int, String>{
    1: 'Hangi ehliyeti alıyorsun?',
    2: 'Daha önce sınava girdin mi?',
    3: 'Hangi sınava hazırlanıyorsun?',
    4: 'Sınavına ne kadar süre kaldı?',
  };

  /// ÖLÇÜLEN en kötü değerler (bu dosyanın kapsadığı üç ölçü):
  /// yayılım %94,1–95,6 · en büyük boşluk %15,6 (393×851 · adım 3).
  /// Eşikler ölçümün hemen üstüne konur — gevşek bir eşik, gerilemeyi yakalamaz.
  const minSpan = 0.85;
  const maxGap = 0.17;

  Future<void> checkFlow(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(tester, onboardingSeen: false);
    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();

    // PageView komşu sayfaları ağaçta TUTAR → yalnız ekrandaki örnek ölçülür. Bu filtre olmadan
    // başka bir sayfanın kutusu ölçüye karışır ve sonuç sessizce yanlış çıkar (ilk denemede çıktı).
    List<Rect> onScreen(Finder f) => [
      for (final e in f.evaluate())
        if (e.renderObject case final RenderBox b when b.attached) b.localToGlobal(Offset.zero) & b.size,
    ].where((r) => r.center.dx >= 0 && r.center.dx <= size.width).toList();

    Rect one(Finder f, String name, int step) {
      final rs = onScreen(f);
      expect(rs.length, 1, reason: 'adım $step · $name → ${rs.length} eşleşme');
      return rs.first;
    }

    for (var step = 1; step <= 4; step++) {
      final title = one(find.text(titles[step]!), 'başlık', step);
      // Seçenekler tek blok sayılır: aralarındaki boşluk zaten sabit ve küçüktür.
      final options = onScreen(
        find.byType(GlowCard),
      ).where((r) => r.top > title.bottom).reduce((a, b) => a.expandToInclude(b));
      // Görsel yalnız yer varken çizilir → varsa bloklara katılır (başlığın ÜSTÜNDEKİ maskot).
      final hero = onScreen(find.byType(IdleMascot)).where((r) => r.bottom <= title.top);

      final blocks = <Rect>[
        one(find.byType(SegmentBar), 'ilerleme çubuğu', step),
        ...hero,
        title,
        options,
        one(find.byType(CoachInsightCard), 'koç kartı', step),
        one(find.widgetWithText(GradientPillButton, 'Devam Et'), 'CTA', step),
      ];

      final span = blocks.last.bottom - blocks.first.top;
      expect(
        span / size.height,
        greaterThanOrEqualTo(minSpan),
        reason:
            'adım $step · ${size.height.toInt()} px: içerik ekranın yalnız '
            '%${(span / size.height * 100).toStringAsFixed(1)}\'ini kaplıyor',
      );

      for (var i = 1; i < blocks.length; i++) {
        final gap = blocks[i].top - blocks[i - 1].bottom;
        expect(
          gap / size.height,
          lessThanOrEqualTo(maxGap),
          reason:
              'adım $step · ${size.height.toInt()} px: bloklar arasında '
              '${gap.toStringAsFixed(0)} px (%${(gap / size.height * 100).toStringAsFixed(1)}) boşluk',
        );
      }

      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('küçük telefon (360×640)', (t) => checkFlow(t, const Size(360, 640)));
  testWidgets('gerçek cihaz (393×780)', (t) => checkFlow(t, const Size(393, 780)));
  testWidgets('jest gezinme (393×851)', (t) => checkFlow(t, const Size(393, 851)));
}
