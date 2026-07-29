import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../domain/premium/paywall_offer.dart';

/// Faz 9 — ödeme ekranının referanstan gelen üç bölümü.
///
/// Bunlar `apps/assets/interface-assets/026`, `027` ve `028`'in WIDGET karşılıklarıdır. Neden
/// raster sevk edilmediği `tool/extract_paywall_hero.py` başlığında yazılı: mockup widget'tır,
/// sanat rasterdır. Buradaki üç bölüm mockuptur — hepsi metin, sayı ve durum taşır; raster
/// olsalardı fiyat ülkeye göre değişemez, sayaç işlemez, tema değişemez ve ekran okuyucu
/// hiçbirini okuyamazdı.

/// Referans `026` — dört sütunluk özellik şeridi (neon simge + başlık + alt metin).
class PaywallFeatureStrip extends StatelessWidget {
  const PaywallFeatureStrip({super.key});

  static const items = <(IconData, String, String)>[
    (Icons.all_inclusive_rounded, 'SINIRSIZ ERİŞİM', 'Tüm konulara sınırsız erişim.'),
    (Icons.assignment_turned_in_outlined, 'SINIRSIZ DENEME', 'Gerçek sınav deneyimi, sınırsız pratik.'),
    (Icons.smart_toy_outlined, 'AI KOÇ DESTEĞİ', 'Yapay zekâ ile akıllı öğrenme desteği.'),
    (Icons.play_circle_outline_rounded, 'VİDEO DERSLER', 'Tüm video derslere sınırsız erişim.'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s5, horizontal: AppSpacing.s2),
      decoration: BoxDecoration(
        color: p.surface2.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: p.primary.withValues(alpha: 0.35)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Icon(items[i].$1, color: p.primaryBright, size: 30),
                      const SizedBox(height: AppSpacing.s2),
                      // Referanstaki büyük-harfli başlık dar sütunda taşabilir → küçültülür,
                      // kırpılmaz: bir özelliğin adı yarım okunmamalı.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          items[i].$2,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            color: p.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].$3,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.text3, fontSize: 10.5, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ),
              if (i != items.length - 1) VerticalDivider(width: 1, color: p.border),
            ],
          ],
        ),
      ),
    );
  }
}

/// Referans `027` — onay listesi + "DAHA YÜKSEK BAŞARI" altın rozeti.
///
/// Referanstaki telefon render'ı BİLİNÇLİ olarak yok: uygulamanın belirli bir anını donduruyor ve
/// ilk arayüz değişikliğinde yalan olurdu. Yerine rozet, listenin yanında dikey olarak durur.
class PaywallChecklist extends StatelessWidget {
  const PaywallChecklist({super.key, required this.features});

  /// Ürün kataloğundan gelen özellikler — burada TEKRAR YAZILMAZ, tek kaynak katalogdur.
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: p.surface2.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: p.primary.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < features.length; i++) ...[
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.primary.withValues(alpha: 0.16),
                          border: Border.all(color: p.primary.withValues(alpha: 0.55)),
                        ),
                        child: Icon(Icons.check_rounded, size: 15, color: p.primary),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: Text(
                          features[i],
                          style: TextStyle(
                            color: p.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (i != features.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                      child: Divider(height: 1, color: p.border),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          const _HigherSuccessBadge(),
        ],
      ),
    );
  }
}

/// Referanstaki altın çerçeveli "DAHA YÜKSEK BAŞARI" rozeti.
class _HigherSuccessBadge extends StatelessWidget {
  const _HigherSuccessBadge();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4, horizontal: AppSpacing.s2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.base),
        border: Border.all(color: p.accent, width: 1.6),
        boxShadow: [
          BoxShadow(color: p.accent.withValues(alpha: 0.26), blurRadius: 22, spreadRadius: -6),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.trending_up_rounded, color: p.accent, size: 30),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'DAHA\nYÜKSEK\nBAŞARI',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.accent,
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

/// Referans `028` — fiyat bloğu, (varsa) geri sayım ve altın satın alma düğmesi.
///
/// FİYAT MAĞAZADAN GELİR. Üstü çizili eski fiyat ve "SINIRLI SÜRE" sayacı yalnız GERÇEK bir
/// kampanya yapılandırıldıysa çizilir — gerekçesi [PaywallOffer] sınıf notunda.
class PaywallPriceBlock extends StatefulWidget {
  const PaywallPriceBlock({
    super.key,
    required this.priceLabel,
    required this.offer,
    required this.onBuy,
    required this.busy,
  });

  final String priceLabel;
  final PaywallOffer offer;
  final VoidCallback? onBuy;
  final bool busy;

  @override
  State<PaywallPriceBlock> createState() => _PaywallPriceBlockState();
}

class _PaywallPriceBlockState extends State<PaywallPriceBlock> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Sayaç YOKSA zamanlayıcı da kurulmaz — boşuna saniyede bir kare çizilmez.
    if (widget.offer.isCountdownVisible(_now)) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _now = DateTime.now());
        // Süre dolduğunda sayaç kaybolur ve zamanlayıcı KENDİNİ durdurur.
        if (!widget.offer.isCountdownVisible(_now)) {
          _ticker?.cancel();
          _ticker = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final showCountdown = widget.offer.isCountdownVisible(_now);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: p.surface2.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _price(p)),
              if (showCountdown) ...[
                const SizedBox(width: AppSpacing.s3),
                _Countdown(remaining: widget.offer.remaining(_now)),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          _BuyButton(onPressed: widget.onBuy, loading: widget.busy),
          const SizedBox(height: AppSpacing.s3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, size: 14, color: p.text3),
              const SizedBox(width: 6),
              Text(
                'Ödeme Google Play üzerinden alınır.',
                style: TextStyle(color: p.text3, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _price(AppPalette p) {
    final offer = widget.offer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Üstü çizili eski fiyat — YALNIZ gerçek bir liste fiyatı yapılandırıldıysa.
        if (offer.hasListPrice)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: offer.listPriceLabel,
                  style: TextStyle(
                    color: p.text3,
                    fontSize: 15,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: p.text3,
                  ),
                ),
                TextSpan(text: '  yerine sadece', style: TextStyle(color: p.text3, fontSize: 13)),
              ],
            ),
          ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.priceLabel,
                style: TextStyle(
                  color: p.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 36,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 6),
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: p.primary.withValues(alpha: 0.45)),
                ),
                child: Text(
                  'tek seferlik ödeme',
                  style: TextStyle(color: p.primary, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "SINIRLI SÜRE" kutusu — saat : dakika : saniye.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.remaining});
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = countdownParts(remaining);

    Widget unit(String value, String label) => Column(
      children: [
        Text(
          value,
          style: TextStyle(color: p.text, fontWeight: FontWeight.w900, fontSize: 19, height: 1.1),
        ),
        Text(label, style: TextStyle(color: p.text3, fontSize: 8.5, letterSpacing: 0.4)),
      ],
    );
    Widget colon() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(':', style: TextStyle(color: p.accent, fontWeight: FontWeight.w900, fontSize: 17)),
    );

    return Semantics(
      label: 'Kampanya bitişine kalan süre '
          '${t.hours} saat ${t.minutes} dakika ${t.seconds} saniye',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.base),
          border: Border.all(color: p.accent.withValues(alpha: 0.75)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.alarm_rounded, color: p.accent, size: 14),
                const SizedBox(width: 4),
                Text(
                  'SINIRLI SÜRE',
                  style: TextStyle(
                    color: p.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                unit(t.hours, 'SAAT'),
                colon(),
                unit(t.minutes, 'DAKİKA'),
                colon(),
                unit(t.seconds, 'SANİYE'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Referanstaki altın satın alma düğmesi — kalkan-taç + metin + ok.
class _BuyButton extends StatelessWidget {
  const _BuyButton({required this.onPressed, required this.loading});
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !loading;
    // Altın üstündeki metin rengi TEMADAN gelir (E13 kuralı: sabit renk yok). `onSecondary`
    // tam olarak "ikincil renk (altın) üstünde okunan renk" demektir — koyu temada koyu kahve,
    // açık temada beyaz.
    final onGold = Theme.of(context).colorScheme.onSecondary;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Paketi Satın Al',
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: Ink(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [p.accent, p.yellow]),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                boxShadow: [
                  BoxShadow(
                    color: p.accent.withValues(alpha: 0.45),
                    blurRadius: 28,
                    spreadRadius: -6,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: loading
                  ? Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: onGold),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                      child: Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: onGold, size: 26),
                          const SizedBox(width: AppSpacing.s2),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Text(
                                'PAKETİ SATIN AL',
                                maxLines: 1,
                                style: TextStyle(
                                  color: onGold,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: onGold, size: 24),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
