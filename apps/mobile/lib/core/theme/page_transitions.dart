import 'package:flutter/material.dart';

/// Ortak zemin üzerinde ÇAKIŞMAYAN sayfa geçişi (Faz 2).
///
/// ## Kök neden — neden özel bir geçiş gerekti
///
/// Bu uygulamanın sayfaları **saydamdır**: `AppTheme` içinde
/// `scaffoldBackgroundColor: Colors.transparent` durur ve canlı zemin
/// ([AppBackground]) yönlendiricinin ÜSTÜNDE tek örnek olarak yaşar. Bu bilinçli bir
/// tasarım — zemin sayfa değişince yeniden kurulmaz, hareket kesintisiz akar.
///
/// Ama saydam bir sayfa, başka bir sayfanın ÜSTÜNE kaydırılamaz: alttaki sayfa üstteki
/// sayfanın içinden görünür. Eski yapılandırma tam bunu yapıyordu
/// (`CupertinoPageTransitionsBuilder` = yatay kaydırma, solma YOK), sonuç cihazda
/// videoya alındı:
///
/// > Öğren sekmesinden Dersler'e geçerken, gelen sayfanın içinden Öğren sayfasının
/// > baykuş görseli ve liste metni ~400 ms boyunca OKUNUYORDU.
///
/// Bu bir "cila" sorunu değil, bileşim (compositing) sorunudur: iki saydam katman üst
/// üste gelirse ikisi de görünür. Gecikmeyle ya da opaklıkla GİZLENEMEZ; geçişin
/// KENDİSİ değişmelidir.
///
/// ## Çözüm — Material "shared axis" (sıralı solma)
///
/// Materyal'in hiyerarşik gezinme için önerdiği geçiş budur ve buradaki asıl özelliği
/// **solmaların SIRALI olmasıdır**:
///
/// ```text
///   t:      0 ────────── 0,35 ────────────── 1
///   giden:  1 ─────────► 0        (0 kalır)
///   gelen:       (0 kalır)        0 ────────► 1
/// ```
///
/// Yani `t < 0,35` iken gelen sayfa TAMAMEN görünmez; `t > 0,35` iken giden sayfa
/// TAMAMEN görünmez. **Hiçbir anda ikisi birden çizilmez** → saydam olsalar bile
/// birbirlerinin içinden görünemezler. Çakışmayı ortadan kaldıran şey budur;
/// [enterOpacity] ve [exitOpacity] çarpımının her `t` için sıfır olması
/// `page_transition_test.dart` içinde kapı altına alınmıştır.
///
/// Yön duygusu, küçük bir yatay kaymayla verilir ([_shift] = 30 dp — Materyal'in
/// shared-axis ölçüsü): gelen sağdan gelir, giden sola gider. Kaydırma mesafesi
/// bilinçle küçüktür; sayfa boyu bir kaydırma, sıralı solmayla birlikte "sürükleniyor"
/// hissi verirdi.
///
/// ## Neden `FadeForwardsPageTransitionsBuilder` (Flutter'ın hazır olanı) DEĞİL
///
/// Flutter 3.41 onu sunuyor ve Android 16'nın geçişine benziyor, ama solma aralıkları
/// **örtüşüyor**: giden `Interval(0, 0.25)`, gelen `Interval(0, 0.75)`. `t = 0,12`
/// civarında giden ≈ 0,5 ve gelen ≈ 0,17 → ikisi birden çizilir. Opak sayfalarda bu
/// sorun değildir (üstteki alttakini kapatır); BİZDE sorun olur. Ayrıca kapatılmadığı
/// sürece geçiş boyunca `ColorScheme.surface` ile opak bir kutu çiziyor, bu da canlı
/// zemini 450 ms boyunca söndürürdü.
class SharedAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  const SharedAxisPageTransitionsBuilder();

  /// Yatay kayma miktarı (dp) — Materyal shared-axis ölçüsü.
  static const double _shift = 30;

  /// Solmanın devri teslim noktası. Bu değerin ALTINDA gelen sayfa, ÜSTÜNDE giden
  /// sayfa görünmezdir.
  static const double handover = 0.35;

  /// Geçiş süresi. Materyal shared-axis 300 ms önerir; 320 ms, sıralı solmanın iki
  /// yarısına da nefes bırakıyor ve cihazda ölçüldüğünde aceleci görünmüyor.
  static const Duration _duration = Duration(milliseconds: 320);

  @override
  Duration get transitionDuration => _duration;

  /// Gelen sayfanın opaklığı (`t` = ileri animasyon değeri).
  static double enterOpacity(double t) =>
      t <= handover ? 0 : Curves.easeOut.transform((t - handover) / (1 - handover));

  /// Giden sayfanın opaklığı (`t` = ikincil animasyon değeri).
  static double exitOpacity(double t) =>
      t >= handover ? 0 : 1 - Curves.easeIn.transform(t / handover);

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Sayfa başına TEK opaklık katmanı: gelme ve örtülme opaklıklarının ÇARPIMI.
    //
    // İki ayrı `FadeTransition` iç içe konsaydı ağaç iki kat opaklık katmanı taşırdı
    // (her biri ayrı bir kompozisyon katmanı) ve "bu sayfa şu an ne kadar görünür"
    // sorusu tek bir yerden okunamazdı.
    final opacity = _ProductAnimation(
      first: _CurveAnimation(animation, enterOpacity),
      next: _CurveAnimation(secondaryAnimation, exitOpacity),
    );

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(
        // Gelen: sağdan (+) sıfıra. Geri dönüşte Flutter aynı animasyonu ters çevirir,
        // yani sayfa sağa doğru çıkar — shared-axis'in beklediği davranış.
        position: Tween<Offset>(
          begin: const Offset(_shift / 400, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: SlideTransition(
          // Örtülen sayfa sola kayar; geri dönüşte soldan geri gelir.
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-_shift / 400, 0),
          ).animate(CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInCubic)),
          child: child,
        ),
      ),
    );
  }
}

/// Bir animasyon değerini saf bir fonksiyondan geçiren küçük yardımcı.
class _CurveAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  _CurveAnimation(this.parent, this._map);

  @override
  final Animation<double> parent;
  final double Function(double) _map;

  @override
  double get value => _map(parent.value);
}

/// İki animasyonun çarpımı — "her ikisi de görünürse görünür" değil, "ikisinin de izin
/// verdiği kadar görünür".
class _ProductAnimation extends CompoundAnimation<double> {
  _ProductAnimation({required super.first, required super.next});

  @override
  double get value => first.value * next.value;
}
