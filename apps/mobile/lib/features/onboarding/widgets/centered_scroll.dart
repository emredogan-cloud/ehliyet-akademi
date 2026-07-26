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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight - padding.vertical),
        child: Column(
          mainAxisAlignment: distribute ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
