import 'package:ehliyet_akademi/core/assets.dart';
import 'package:ehliyet_akademi/features/onboarding/widgets/onboarding_density.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Beta Faz 6 — onboarding illüstrasyonu düzene HÂKİM mi?
///
/// Yol haritasının ölçütü "görsel güvenli alanın **%85–95**'ini kaplamalı"dır. Bu dosya o
/// ölçütü **ölçülebilir bir kapıya** çevirir; `onboarding_experience_test.dart` ise aynı
/// düzenin **kaydırmasız** kaldığını doğrular. İkisi birlikte Faz 6'nın DoD'sidir.
///
/// ÖLÇÜM TUZAĞI: `tester.getSize()` widget KUTUSUNU verir. `BoxFit.contain` ile görsel bu
/// kutunun içine en-boy oranını koruyarak yerleşir; kutu geniş ama alçaksa **çizilen** görsel
/// kutudan dar olur. Bu yüzden burada çizilen genişlik hesaplanır — kutu genişliği DEĞİL.
void main() {
  // `onb_welcome.webp` ÖLÇÜLDÜ: 820×721.
  const double aspect = 820 / 721;

  /// Karşılama adımındaki illüstrasyonun **çizilen** genişliği (dp).
  double paintedWidth(WidgetTester tester) {
    final finder = find.byWidgetPredicate((w) {
      if (w is! Image) return false;
      final provider = w.image;
      final asset = provider is ResizeImage ? provider.imageProvider : provider;
      return asset is AssetImage && asset.assetName == AppImages.onbWelcome;
    });
    expect(finder, findsWidgets, reason: 'karşılama illüstrasyonu çizilmeli');
    final box = tester.getSize(finder.first);
    final byHeight = box.height * aspect;
    return box.width < byHeight ? box.width : byHeight;
  }

  Future<double> widthFractionAt(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(tester, onboardingSeen: false);
    return paintedWidth(tester) / size.width;
  }

  group('illüstrasyon düzene hâkim', () {
    testWidgets('gerçek cihaz ölçüsünde (393×780) hedef bandında', (tester) async {
      final f = await widthFractionAt(tester, const Size(393, 780));
      expect(
        f,
        inInclusiveRange(0.85, 0.95),
        reason: 'çizilen genişlik ekranın %${(f * 100).toStringAsFixed(1)}\'i — hedef %85–95',
      );
    });

    testWidgets('tam ekranda (393×851) hedef bandında', (tester) async {
      final f = await widthFractionAt(tester, const Size(393, 851));
      expect(f, inInclusiveRange(0.85, 0.95));
    });

    testWidgets('E6 ÖNCESİNE göre belirgin biçimde büyüdü', (tester) async {
      // E6'da görsel yalnız yüksekliğe bağlıydı (0.20, 200 dp tavan) → 393 dp'de ~%37.
      final f = await widthFractionAt(tester, const Size(393, 780));
      expect(f, greaterThan(0.60), reason: 'eski davranış ~%37 idi');
    });
  });

  group('dar ekranda DÜRÜST bozulma', () {
    testWidgets('360×640: görsel küçülür ama ÇİZİLİR (kaybolmaz)', (tester) async {
      // Bu ölçüde dikey bütçe %85 bandına yetmiyor — ÖLÇÜLDÜ: dense oranı 0.36'ya
      // çıkarıldığında kaydırmasızlık kapısı kırılıyor. Görselin küçülmesi, kaydırma
      // oluşmasına yeğlenir (E6'nın dürüst bozulma ilkesi).
      final f = await widthFractionAt(tester, const Size(360, 640));
      expect(f, greaterThan(0.35), reason: 'görsel anlamlı biçimde görünür kalmalı');
      expect(f, lessThan(0.85), reason: 'bu ölçüde hedef banda ULAŞILAMAZ — dürüstçe kaydedildi');
    });

    testWidgets('büyük yazı tipinde de görsel kaybolmaz (360×640 · 1.3×)', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final f = await widthFractionAt(tester, const Size(360, 640));
      expect(f, greaterThan(0.35));
    });
  });

  group('kutu kuralı — saf', () {
    test('genişlik içerik genişliğinin TAMAMIDIR; yükseklik yalnız üst sınırdır', () {
      final box = onboardingHeroBox(
        OnboardingDensity.tight,
        availableWidth: 353,
        availableHeight: 629,
      );
      expect(box.width, 353);
      expect(box.height, closeTo(629 * 0.52, 0.01));
    });

    test('yoğunluk arttıkça dikey bütçe daralır', () {
      double h(OnboardingDensity d) =>
          onboardingHeroBox(d, availableWidth: 353, availableHeight: 629).height;
      expect(h(OnboardingDensity.dense), lessThan(h(OnboardingDensity.roomy)));
      expect(h(OnboardingDensity.dense), lessThan(h(OnboardingDensity.tight)));
    });

    test('çok kısa alanda taban, çok uzun alanda tavan uygulanır', () {
      expect(
        onboardingHeroBox(OnboardingDensity.dense, availableWidth: 300, availableHeight: 100).height,
        56.0,
      );
      expect(
        onboardingHeroBox(OnboardingDensity.roomy, availableWidth: 300, availableHeight: 4000).height,
        360.0,
      );
    });
  });
}
