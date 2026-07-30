import 'package:ehliyet_akademi/features/onboarding/widgets/centered_scroll.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Beta Faz 5 — `CenteredScroll` en küçük yükseklik hesabı.
///
/// ## Bu testin var olma sebebi (gerçek cihazda yakalandı)
///
/// Bileşen `minHeight - padding.vertical` hesabını çıplak kullanıyordu. Dolgu, o anki kullanılabilir
/// yükseklikten büyük olduğunda sonuç NEGATİF çıkıyor ve Flutter
/// **"BoxConstraints has a negative minimum height"** diye fırlatıyordu.
///
/// Redmi Note 11R'de (Android 13) HER AÇILIŞTA oluyordu; Redmi 8A'da (Android 11) hiç olmadı —
/// sistem çubuğu/hareket alanı yerleşirken ilk düzen geçişinde gelen kısa yükseklik cihaza ve
/// Android sürümüne göre değişiyor. Tek cihazda doğrulamanın neden yetmediğinin somut örneği.
void main() {
  Future<void> pump(WidgetTester tester, {required double minHeight, required EdgeInsets pad}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CenteredScroll(
            minHeight: minHeight,
            padding: pad,
            children: const [Text('içerik')],
          ),
        ),
      ),
    );
  }

  testWidgets('dolgu kullanılabilir yükseklikten BÜYÜKKEN fırlatmaz', (tester) async {
    // Cihazda ölçülen durum: 24 birim yer, 40 birim dolgu → çıplak hesap -16 verir.
    await pump(tester, minHeight: 24, pad: const EdgeInsets.symmetric(vertical: 20));
    expect(tester.takeException(), isNull);
    expect(find.text('içerik'), findsOneWidget);
  });

  testWidgets('yükseklik SIFIR olsa bile fırlatmaz', (tester) async {
    await pump(tester, minHeight: 0, pad: const EdgeInsets.all(16));
    expect(tester.takeException(), isNull);
  });

  testWidgets('normal durumda içerik yine dikeyde yer kaplar', (tester) async {
    // Sıkıştırma yalnız negatif durumu düzeltmeli; olağan yerleşimi DEĞİŞTİRMEMELİ.
    await pump(tester, minHeight: 600, pad: const EdgeInsets.symmetric(vertical: 20));
    expect(tester.takeException(), isNull);
    final box = tester.renderObject<RenderBox>(
      find.descendant(of: find.byType(CenteredScroll), matching: find.byType(ConstrainedBox)).first,
    );
    expect(box.size.height, greaterThanOrEqualTo(560));
  });
}
