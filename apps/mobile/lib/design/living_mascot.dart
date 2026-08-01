import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brand.dart';

/// Ürün Evrimi v1.1 · Faz 6 — YAŞAYAN KOÇ.
///
/// ## Kütüphane araştırması ve neden hiçbiri kullanılmadı
///
/// Flutter'da karakter animasyonu için iki olgun seçenek var:
///
/// · **Rive** — durum makineli, etkileşimli, en güçlüsü. `.riv` dosyası ister.
/// · **Lottie** — After Effects çıktısı, yaygın. `.json` dosyası ister.
///
/// İkisi de **yazılmış bir animasyon dosyası** gerektiriyor. Elimizde yedi DURAĞAN `.webp`
/// var; onlardan `.riv`/`.json` üretilemez. Bağımlılık eklemek, dosya gelene kadar hiçbir şey
/// çalıştırmazdı — yani bugün için sıfır kazanç, kalıcı bakım yükü.
///
/// Bu yüzden hareket **yerel Flutter dönüşümleriyle** üretiliyor: bağımlılık yok, dış varlık yok,
/// bugün çalışıyor. Rive/Lottie'ye geçilmek istenirse [LivingMascot] tek değiştirme noktası.
///
/// ## Neden göz kırpma ve bakış takibi YOK
///
/// İkisi de gözün NEREDE olduğunu bilmeyi gerektirir. Elimizdeki görsel tek parça bir raster;
/// gözün üstüne kapak çizmek ya da göz bebeğini kaydırmak için maskotun **katmanlı** sürümü
/// lazım (gövde / baş / göz akı / göz bebeği / göz kapağı). Konumu tahmin edip çizmek, gözün
/// yanına siyah bir çubuk koymak demek olurdu.
///
/// Gerekli katmanlar `ASSET_GENERATION_LIBRARY.md` §8'e yazıldı. Katmanlar geldiğinde göz
/// kırpma ve bakış takibi buraya eklenir; o zamana kadar **olmayan bir şey taklit edilmiyor.**
///
/// ## Bugün gerçekten yapılanlar
///
/// · **Nefes** — dikeyde çok hafif ölçek (%1,5). Canlılığın en güçlü ve en ucuz işareti.
/// · **Süzülme** — dikey kayma.
/// · **Mikro eğim** — omuz ekseninde çok küçük dönme.
/// · **Dikkat** — koç konuşurken öne doğru hafif yaklaşma.
///
/// Üç döngünün PERİYODU birbirine bölünmez (2600 / 4100 / 5900 ms). Aynı olsalardı hareket her
/// birkaç saniyede aynı kareye dönerdi ve göz bunu "döngü" olarak yakalardı — mekanik görünürdü.
/// Asal olmayan ama ortak katı büyük olmayan periyotlar, birleşik hareketi ~10 dakika boyunca
/// tekrarsız kılıyor.
class LivingMascot extends StatefulWidget {
  const LivingMascot(
    this.asset, {
    super.key,
    required this.height,
    this.width,
    this.semanticLabel,
    this.attentive = false,
  });

  final String asset;
  final double height;
  final double? width;
  final String? semanticLabel;

  /// Koç şu an "konuşuyor" mu — öne doğru hafif yaklaşır.
  final bool attentive;

  /// Nefes döngüsü.
  static const breathPeriod = Duration(milliseconds: 2600);

  /// Süzülme döngüsü.
  static const floatPeriod = Duration(milliseconds: 4100);

  /// Eğim döngüsü.
  static const tiltPeriod = Duration(milliseconds: 5900);

  /// Nefeste dikey ölçek genliği. %1,5 — bundan fazlası "şişip inen balon" gibi görünüyor.
  static const breathScale = 0.015;

  /// Süzülme genliği (px).
  static const floatAmplitude = 3.0;

  /// Eğim genliği (radyan) — ~1,1 derece.
  static const tiltAmplitude = 0.019;

  @override
  State<LivingMascot> createState() => _LivingMascotState();
}

class _LivingMascotState extends State<LivingMascot> with TickerProviderStateMixin {
  // DİKKAT: tembel `late final ... =` OLMAZ. Hareket azaltma açıkken denetleyicilere hiç
  // dokunulmazsa ilk erişim `dispose()` içinde olur ve orada ata aramak yasaktır. Aynı kusur
  // `IdleMascot`'ta bir kez yaşandı; kalıp burada da korunuyor.
  late final AnimationController _breath;
  late final AnimationController _float;
  late final AnimationController _tilt;
  bool _motion = false;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(vsync: this, duration: LivingMascot.breathPeriod);
    _float = AnimationController(vsync: this, duration: LivingMascot.floatPeriod);
    _tilt = AnimationController(vsync: this, duration: LivingMascot.tiltPeriod);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = !MediaQuery.disableAnimationsOf(context);
    if (motion == _motion) return;
    _motion = motion;
    for (final c in [_breath, _float, _tilt]) {
      if (motion) {
        c.repeat(reverse: true);
      } else {
        c.stop();
        c.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _float.dispose();
    _tilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = MascotImage(
      widget.asset,
      height: widget.height,
      width: widget.width,
      fit: BoxFit.contain,
      semanticLabel: widget.semanticLabel,
    );

    // Hareket azaltıldığında hiçbir dönüşüm uygulanmaz — sarmalayıcı bile eklenmez.
    if (!_motion) return image;

    return AnimatedBuilder(
      animation: Listenable.merge([_breath, _float, _tilt]),
      builder: (context, child) {
        // Sinüs, testere dişi yerine yumuşak uçlar verir: hareket dönüş noktalarında durup
        // yön değiştirmiş gibi değil, yavaşlayıp hızlanmış gibi görünür.
        final breath = math.sin(_breath.value * math.pi);
        final float = math.sin(_float.value * math.pi);
        final tilt = math.sin(_tilt.value * math.pi * 2 - math.pi / 2);

        return Transform.translate(
          offset: Offset(0, -LivingMascot.floatAmplitude * float),
          child: Transform.rotate(
            angle: LivingMascot.tiltAmplitude * tilt,
            // Dönme merkezi ALT ORTA: baş sallanıyormuş gibi görünsün diye. Merkez ortada
            // olsaydı bütün gövde bir sarkaç gibi salınırdı.
            alignment: Alignment.bottomCenter,
            child: Transform.scale(
              scaleY: 1 + LivingMascot.breathScale * breath,
              // Nefeste yalnız dikey ölçek değişir; yatayı da büyütmek "yaklaşıyor" hissi
              // verir ve nefesle karışır.
              scaleX: 1,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
      // Dikkat durumu dış katmanda: konuşurken maskot hafifçe büyür ve öne gelir.
      child: AnimatedScale(
        scale: widget.attentive ? 1.04 : 1,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: Alignment.bottomCenter,
        child: image,
      ),
    );
  }
}
