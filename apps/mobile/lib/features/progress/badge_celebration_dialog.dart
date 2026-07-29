import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/share/share_service.dart';
import '../../design/confetti.dart';
import '../../design/share_card.dart';
import '../../domain/progress/gamification.dart';

/// Faz 10 — rozet açılışı kutlaması.
///
/// SES: uygulamada ses varlığı ya da ses eklentisi YOK. Talep "varsa ses desteği" diyordu; olmayan
/// bir şeye kanca takmak yerine cihazda GERÇEKTEN bulunan geri bildirim kullanılıyor:
/// [HapticFeedback.mediumImpact]. Sessiz ortamda da çalışır ve varlık eklemez.
Future<void> showBadgeCelebration(
  BuildContext context,
  WidgetRef ref,
  Achievement achievement,
) {
  HapticFeedback.mediumImpact();
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.80),
    builder: (_) => _BadgeCelebrationDialog(achievement: achievement),
  );
}

class _BadgeCelebrationDialog extends ConsumerStatefulWidget {
  const _BadgeCelebrationDialog({required this.achievement});
  final Achievement achievement;

  @override
  ConsumerState<_BadgeCelebrationDialog> createState() => _BadgeCelebrationDialogState();
}

class _BadgeCelebrationDialogState extends ConsumerState<_BadgeCelebrationDialog> {
  /// Paylaşılacak kartın görüntüsünü almak için sınır anahtarı.
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    final a = widget.achievement;
    final text = 'Ehliyet Akademi’de "${a.title}" rozetini kazandım! ${a.icon}';
    final png = await captureBoundary(_cardKey);
    final service = ref.read(shareServiceProvider);
    // Görüntü alınamazsa (ilk kare henüz boyanmamışsa) METİN paylaşılır — kullanıcı bir şey
    // paylaşamadan kalmaz.
    final ok = png == null
        ? await service.shareText(text)
        : await service.shareImage(pngBytes: png, fileName: 'ehliyet-rozet-${a.id}', text: text);
    if (!mounted) return;
    setState(() => _sharing = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paylaşım açılamadı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Stack(
        // `Clip.none` ŞART — süs değil.
        //
        // `Stack` varsayılan olarak çocuklarını sınırlarına KIRPAR (`Clip.hardEdge`). Ekran dışına
        // konan paylaşım kartı bu yüzden hiç BOYANMIYOR, boyanmayan bir sınırın `toImage`'ı da
        // hiçbir zaman tamamlanmıyordu — paylaşım sonsuza kadar "Hazırlanıyor…" kalıyordu
        // (testte `pumpAndSettle` zaman aşımıyla yakalandı).
        clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ConfettiBurst(colors: [p.primary, p.accent, p.green, p.blue, p.purple]),
        ),
        Center(
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s5,
                AppSpacing.s6,
                AppSpacing.s5,
                AppSpacing.s5,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [p.surface2, p.surface],
                ),
                borderRadius: BorderRadius.circular(AppRadii.lg + 6),
                border: Border.all(color: p.accent.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: p.accent.withValues(alpha: 0.24),
                    blurRadius: 46,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ROZET KAZANDIN',
                    style: TextStyle(
                      color: p.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  _RevealedBadge(achievement: widget.achievement),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    widget.achievement.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: p.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 23,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    widget.achievement.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.text2, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _sharing ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: p.text2,
                            side: BorderSide(color: p.border),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                            ),
                          ),
                          child: const Text('Kapat'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _sharing ? null : _share,
                          icon: _sharing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.ios_share_rounded, size: 18),
                          label: const Text('Paylaş'),
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Paylaşılacak kart EKRANIN DIŞINDA çizilir.
        //
        // Neden görünmez bir kopya: paylaşılan görsel, penceredeki yerleşimden bağımsız ve sabit
        // oranlı olmalı (sosyal uygulamalar 1:1 / 4:5 bekler). Pencerenin kendisini fotoğraflamak,
        // telefonun genişliğine göre değişen bir kart üretirdi.
        Positioned(
          left: -3000,
          top: 0,
          child: RepaintBoundary(
            key: _cardKey,
            child: BadgeShareCard(achievement: widget.achievement),
          ),
        ),
      ],
    );
  }
}

/// Rozetin ortaya çıkışı — büyüyerek gelir, hafifçe yaylanır, arkasında ışıma.
class _RevealedBadge extends StatelessWidget {
  const _RevealedBadge({required this.achievement});
  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final badge = Container(
      width: 116,
      height: 116,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [p.accent.withValues(alpha: 0.32), p.accent.withValues(alpha: 0.05)],
        ),
        border: Border.all(color: p.accent, width: 2.4),
        boxShadow: [
          BoxShadow(color: p.accent.withValues(alpha: 0.45), blurRadius: 34, spreadRadius: -6),
        ],
      ),
      child: Text(achievement.icon, style: const TextStyle(fontSize: 52)),
    );

    if (reduceMotion) return badge;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: v.clamp(0.0, 1.25), child: child),
      child: badge,
    );
  }
}
