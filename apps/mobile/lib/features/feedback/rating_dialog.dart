import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/feedback/store_review_service.dart';
import '../../domain/feedback/rating_prompt.dart';

/// Faz 7 — uygulama puanlama penceresi.
///
/// Referans: `apps/assets/app-puanlama-pop-up.png`. Turkuaz halkalı altın yıldız amblemi, iki
/// satırlık başlık, içinde "5 yıldız" turkuaz olan açıklama, beş yıldızlık sıra, üç sütunluk
/// gerekçe kartı ve iki düğme — yerleşimiyle birlikte kuruldu.
///
/// Yıldızların anlamı için `StoreReviewService` sınıf notuna bakılmalı: yıldız bir JEST'tir,
/// oylama değildir; hangi yıldız seçilirse seçilsin aynı yere — mağaza sayfasına — gidilir.

/// Puanlama isteğini SINIRLARA UYARAK göster (otomatik tetikler için).
Future<void> maybeShowRatingPrompt(
  BuildContext context,
  WidgetRef ref,
  RatingTrigger trigger, {
  required int nowMs,
}) async {
  final state = ref.read(ratingPromptProvider);
  if (!shouldAskForRating(trigger: trigger, state: state, nowMs: nowMs)) return;
  await ref.read(ratingPromptProvider.notifier).recordShown(nowMs);
  if (!context.mounted) return;
  await showRatingDialog(context);
}

/// Pencereyi doğrudan aç (kullanıcı Profil'den kendisi istediğinde — sınır yok).
Future<void> showRatingDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.74),
    builder: (_) => const _RatingDialog(),
  );
}

class _RatingDialog extends ConsumerStatefulWidget {
  const _RatingDialog();

  @override
  ConsumerState<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends ConsumerState<_RatingDialog> {
  /// Kullanıcının dokunduğu yıldız (1..5) — yalnız GÖRSEL geri bildirim; hiçbir yere gitmez.
  int _picked = 0;
  bool _busy = false;

  Future<void> _rate() async {
    setState(() => _busy = true);
    final opened = await ref.read(storeReviewServiceProvider).openStoreListing();
    if (!mounted) return;
    // Mağaza açıldıysa kullanıcı istediğimizi yapmıştır; gerçekten puan verip vermediğini
    // BİLEMEYİZ (mağaza söylemez) ama tekrar sormak saygısızlık olur.
    if (opened) await ref.read(ratingPromptProvider.notifier).recordRated();
    if (!mounted) return;
    Navigator.of(context).pop();
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mağaza açılamadı. Google Play yüklü mü?')),
      );
    }
  }

  Future<void> _later() async {
    await ref
        .read(ratingPromptProvider.notifier)
        .recordSnoozed(DateTime.now().millisecondsSinceEpoch);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s6),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.surface2, p.surface],
          ),
          borderRadius: BorderRadius.circular(AppRadii.lg + 6),
          border: Border.all(color: p.primary.withValues(alpha: 0.42)),
          boxShadow: [
            BoxShadow(
              color: p.primary.withValues(alpha: 0.18),
              blurRadius: 44,
              spreadRadius: -10,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.86),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s5,
                  AppSpacing.s6,
                  AppSpacing.s5,
                  AppSpacing.s5,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _StarEmblem(),
                    const SizedBox(height: AppSpacing.s5),
                    Text(
                      'Deneyimin bizim için\nçok değerli!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: p.text,
                        fontSize: 23,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(color: p.text2, fontSize: 14, height: 1.45),
                        children: [
                          const TextSpan(text: "Ehliyet Akademi'yi beğendiysen\n"),
                          TextSpan(
                            text: '5 yıldız',
                            style: TextStyle(color: p.primary, fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(text: ' vererek bizi destekleyebilirsin.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    _StarRow(
                      picked: _picked,
                      onPick: _busy ? null : (v) => setState(() => _picked = v),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    Text(
                      _picked == 0 ? 'Puanlamak için bir yıldız seç' : 'Teşekkürler!',
                      style: TextStyle(color: p.text3, fontSize: 13),
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    _ReasonsCard(),
                    const SizedBox(height: AppSpacing.s5),
                    _PrimaryRateButton(loading: _busy, onPressed: _busy ? null : _rate),
                    const SizedBox(height: AppSpacing.s3),
                    _LaterButton(onPressed: _busy ? null : _later),
                    const SizedBox(height: AppSpacing.s3),
                    // DÜRÜSTLÜK SATIRI — referansta yok, bilinçli eklendi.
                    //
                    // Yıldızlar burada hiçbir yere kaydedilmiyor; puan Google Play'de veriliyor.
                    // Bunu söylememek, kullanıcının "puanımı verdim" sanmasına yol açardı.
                    Text(
                      "Puanını Google Play'de vereceksin.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.text3, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.s2,
              right: AppSpacing.s2,
              child: IconButton(
                tooltip: 'Kapat',
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                icon: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.surface3,
                    border: Border.all(color: p.border),
                  ),
                  child: Icon(Icons.close_rounded, color: p.text2, size: 19),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Turkuaz halka içinde altın yıldız + çevresinde küçük parıltılar (referanstaki başlık ögesi).
class _StarEmblem extends StatelessWidget {
  const _StarEmblem();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: 132,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ExcludeSemantics(child: CustomPaint(painter: _SparklePainter(p.primary))),
          ),
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.primary.withValues(alpha: 0.10),
              border: Border.all(color: p.primary, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: p.primary.withValues(alpha: 0.42),
                  blurRadius: 26,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Icon(Icons.star_rounded, color: p.accent, size: 44),
          ),
        ],
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const specs = <(double, double, double, double)>[
      (-140, 50, 1.6, 0.7),
      (-100, 58, 1.1, 0.45),
      (-45, 54, 1.9, 0.75),
      (-20, 60, 1.2, 0.4),
      (205, 52, 1.4, 0.55),
      (245, 57, 1.0, 0.35),
    ];
    final center = size.center(Offset.zero);
    for (final (deg, dist, r, a) in specs) {
      final rad = deg * math.pi / 180;
      canvas.drawCircle(
        center + Offset(math.cos(rad), math.sin(rad)) * dist,
        r,
        Paint()..color = color.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.color != color;
}

/// Beş yıldızlık sıra. Seçim GÖRSEL bir jesttir — bkz. `StoreReviewService` politika notu.
class _StarRow extends StatelessWidget {
  const _StarRow({required this.picked, required this.onPick});
  final int picked;
  final ValueChanged<int>? onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            button: true,
            selected: i <= picked,
            label: '$i yıldız',
            excludeSemantics: true,
            onTap: onPick == null ? null : () => onPick!(i),
            child: InkResponse(
              onTap: onPick == null ? null : () => onPick!(i),
              radius: 28,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                child: AnimatedScale(
                  scale: i <= picked ? 1.12 : 1.0,
                  duration: AppMotion.fast,
                  curve: AppMotion.easeOut,
                  child: Icon(
                    i <= picked ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 42,
                    color: p.accent,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Referanstaki üç sütunluk gerekçe kartı.
class _ReasonsCard extends StatelessWidget {
  static const items = <(IconData, String, String)>[
    (Icons.favorite_border_rounded, 'Desteğin Önemli', 'Geri bildiriminle bize güç verirsin.'),
    (Icons.trending_up_rounded, 'Daha İyi Olalım', 'Yorumlarınla kendimizi geliştirelim.'),
    (
      Icons.people_outline_rounded,
      'Daha Fazla Kişiye Ulaşalım',
      "Ehliyet Akademi'yi daha çok kişi keşfetsin.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4, horizontal: AppSpacing.s2),
      decoration: BoxDecoration(
        color: p.surface3.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadii.base),
        border: Border.all(color: p.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      Icon(items[i].$1, color: p.primary, size: 28),
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        items[i].$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: p.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i].$3,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.text3, fontSize: 11.5, height: 1.3),
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

/// Turkuaz degrade birincil düğme — referanstaki "Uygulamayı Puanla".
class _PrimaryRateButton extends StatelessWidget {
  const _PrimaryRateButton({required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !loading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Uygulamayı Puanla',
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppRadii.base),
            child: Ink(
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [p.primary, p.primaryBright]),
                borderRadius: BorderRadius.circular(AppRadii.base),
                boxShadow: [
                  BoxShadow(
                    color: p.primary.withValues(alpha: 0.40),
                    blurRadius: 24,
                    spreadRadius: -6,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: loading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                      child: Row(
                        children: [
                          Icon(Icons.star_rounded, color: p.accent, size: 24),
                          const SizedBox(width: AppSpacing.s3),
                          const Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Text(
                                'Uygulamayı Puanla',
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16.5,
                                ),
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
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

/// Çerçeveli ikincil düğme — referanstaki "Daha Sonra Hatırlat" (iki satırlı).
class _LaterButton extends StatelessWidget {
  const _LaterButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.base),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.base),
            border: Border.all(color: p.primary.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Icon(Icons.event_repeat_rounded, color: p.primary, size: 24),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daha Sonra Hatırlat',
                      style: TextStyle(color: p.text, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Text(
                      'Bir süre sonra tekrar sor',
                      style: TextStyle(color: p.text3, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.text3, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
