import 'package:flutter/material.dart';

/// Sığdığında DİKEY ORTALAYAN, sığmadığında kaydıran gövde.
///
/// Faz E6 şartı "kaydırmasız ve taşmasız"dır. Bu bileşen taşmayı yapısal olarak imkânsız kılar
/// (kaydırılabilir), ölçütü ise ölçülebilir hâle getirir: içerik sığıyorsa `maxScrollExtent == 0`
/// olur ve testler tam olarak bunu doğrular. Desteklenen ölçülerin ALTINDA (ör. çok küçük ekran +
/// çok büyük yazı tipi) düzen kırpmak yerine kaydırmaya geçer — dürüst bozulma.
class CenteredScroll extends StatelessWidget {
  const CenteredScroll({
    super.key,
    required this.minHeight,
    required this.children,
    required this.padding,
    this.distribute = false,
  });
  final double minHeight;
  final List<Widget> children;
  final EdgeInsets padding;

  /// Beta R2 — artan dikey boşluğu çocukların ARASINA dağıt (`spaceBetween`).
  ///
  /// NEDEN: varsayılan ortalama, içerik kısa olduğunda üstte ve altta büyük boşluk bırakıyor;
  /// yol haritası ise her onboarding sayfasının güvenli alanın **%85–95'ini** kaplamasını
  /// istiyor. Dağıtım, içeriği ESNETMEDEN (kartlar/tipografi büyümez) sayfayı doldurur.
  ///
  /// İçerik sığmadığında `spaceBetween` zaten `start` gibi davranır → kaydırma davranışı
  /// değişmez ve `maxScrollExtent == 0` kapısı korunur.
  final bool distribute;

  /// Kullanılabilir yükseklikten dolguyu düşür — ama **asla eksiye inme**.
  ///
  /// ## Gerçek cihazda yakalanan hata (Beta Faz 5, Redmi Note 11R / Android 13)
  ///
  /// `minHeight - padding.vertical` çıplak hâlde kullanılıyordu. Dolgu, o anki kullanılabilir
  /// yükseklikten büyük olduğunda sonuç NEGATİF çıkıyor ve Flutter
  /// **"BoxConstraints has a negative minimum height"** diye fırlatıyordu
  /// (ölçülen değer: `-16.0<=h<=Infinity; NOT NORMALIZED`).
  ///
  /// Ne zaman olur: sistem çubukları/hareket alanı yerleşirken ilk düzen geçişinde `c.maxHeight`
  /// kısa bir an çok küçük gelir. Bu, cihaza ve Android sürümüne göre değişir — Redmi 8A'da
  /// (Android 11) hiç görülmedi, Redmi Note 11R'de (Android 13) her açılışta görüldü. Bu yüzden
  /// tek bir cihazda doğrulama yeterli değildir.
  ///
  /// Neden bu düzeltme doğru: en küçük yükseklik matematiksel olarak negatif OLAMAZ. Sıfıra
  /// sıkıştırmak bir tasarım kararı değil, aritmetiğin kendisidir — ve davranışı hiç bozmaz:
  /// yer yoksa `SingleChildScrollView` zaten kaydırmaya geçer.
  double get _minContentHeight {
    final available = minHeight - padding.vertical;
    return available > 0 ? available : 0;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: _minContentHeight),
        child: Column(
          mainAxisAlignment: distribute ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
