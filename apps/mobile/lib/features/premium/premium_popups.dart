import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets.dart';
import '../../core/theme/tokens.dart';
import '../../data/premium/entitlements_repository.dart';
import '../../design/brand.dart';
import '../../domain/premium/premium_prompt.dart';
import '../../domain/premium/products.dart';


/// Bağlamsal premium teşviki — sık-gösterim sınırlarına uyar. Gösterilmesi gerekiyorsa pencereyi açar
/// ve gösterimi kaydeder. `nowMs` çağıran taraftan verilir (test edilebilirlik + saf çekirdek).
Future<void> maybeShowPremiumIncentive(
  BuildContext context,
  WidgetRef ref,
  PremiumTrigger trigger, {
  required int nowMs,
}) async {
  final premium = isPremium(ref.read(entitlementsProvider));
  final promptState = ref.read(premiumPromptProvider);
  if (!shouldPromptPremium(premium: premium, state: promptState, nowMs: nowMs)) return;
  await ref.read(premiumPromptProvider.notifier).recordShown(nowMs);
  if (!context.mounted) return;
  await showPremiumIncentive(context, trigger: trigger);
}

/// Teşvik penceresini doğrudan aç (kilit tıklaması gibi açık kullanıcı eylemlerinde — sınır yok).
Future<void> showPremiumIncentive(BuildContext context, {PremiumTrigger? trigger}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (ctx) => _PremiumIncentiveDialog(trigger: trigger),
  );
}

/// Satın alma başarı penceresi.
Future<void> showPremiumSuccess(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (ctx) => const _PremiumSuccessDialog(),
  );
}

class _PremiumIncentiveDialog extends StatelessWidget {
  const _PremiumIncentiveDialog({this.trigger});
  final PremiumTrigger? trigger;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final features = [
      (Icons.menu_book_rounded, 'Tüm Konulara Sınırsız Erişim', 'Dersler, video ve görsel içerik'),
      (Icons.track_changes_rounded, 'Sınırsız Deneme Sınavı', 'Gerçek sınav deneyimi, detaylı analiz'),
      (Icons.smart_toy_rounded, 'AI Koç ile Akıllı Destek', 'Sorularını sor, anında öğren'),
      (Icons.event_note_rounded, 'Kişisel Çalışma Planı', 'Sana özel planlama ve hatırlatıcılar'),
    ];
    return _DialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MascotImage(AppImages.illLockGold, height: 150, semanticLabel: 'Premium'),
          const SizedBox(height: AppSpacing.s2),
          BrandChip(label: "PREMIUM'A GEÇ", icon: Icons.workspace_premium_rounded, color: context.palette.accent),
          const SizedBox(height: AppSpacing.s3),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(color: p.text, fontWeight: FontWeight.w900, fontSize: 24, height: 1.15),
              children: [
                const TextSpan(text: 'Tüm Potansiyelini\n'),
                TextSpan(text: 'Kilidi Aç!', style: TextStyle(color: context.palette.accent)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            trigger?.headline ?? 'Eğitimini bir üst seviyeye taşı ve sınavda fark yarat.',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.text2, fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.s4),
          for (final f in features) ...[
            Row(
              children: [
                Icon(f.$1, color: p.primary, size: 22),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(f.$3, style: TextStyle(color: p.text3, fontSize: 11.5, height: 1.2)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                Icon(Icons.lock_rounded, color: context.palette.accent, size: 18),
              ],
            ),
            if (f != features.last)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
                child: Divider(height: 1, color: p.border),
              ),
          ],
          const SizedBox(height: AppSpacing.s5),
          GradientPillButton(
            label: "PREMIUM'A GEÇ",
            gold: true,
            leading: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/premium?from=incentive-popup');
            },
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_rounded, size: 15, color: p.text3),
              const SizedBox(width: 6),
              Text('7 gün para iade garantisi', style: TextStyle(color: p.text3, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumSuccessDialog extends StatelessWidget {
  const _PremiumSuccessDialog();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final features = [
      (Icons.menu_book_rounded, p.primary, 'Tüm Konular', 'Sınırsız erişim'),
      (Icons.track_changes_rounded, p.accent, 'Akıllı Denemeler', 'Detaylı analiz'),
      (Icons.bar_chart_rounded, p.primary, 'Kişisel Plan', 'Size özel çalışma'),
      (Icons.smart_toy_rounded, p.primary, 'Sınırsız AI Koç', 'Her zaman yanında'),
    ];
    return _DialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MascotImage(AppImages.illWheelCheck, height: 150, semanticLabel: 'Premium aktif'),
          const SizedBox(height: AppSpacing.s2),
          const BrandChip(label: 'PREMIUM UNLOCKED', icon: Icons.workspace_premium_rounded),
          const SizedBox(height: AppSpacing.s3),
          Text('Tebrikler!', style: Theme.of(context).textTheme.headlineMedium),
          Text(
            'Premium Paketiniz Aktif!',
            style: TextStyle(color: p.primary, fontWeight: FontWeight.w900, fontSize: 22),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Tüm premium özelliklerin kilidi açıldı. Artık sürüş yolculuğuna hazırsınız!',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.text2, fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.s4),
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4, horizontal: AppSpacing.s2),
            decoration: BoxDecoration(
              color: p.surface2,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                for (final f in features)
                  Expanded(
                    child: Column(
                      children: [
                        Icon(f.$1, color: f.$2, size: 24),
                        const SizedBox(height: 6),
                        Text(f.$3, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                        Text(f.$4, textAlign: TextAlign.center, style: TextStyle(color: p.text3, fontSize: 9.5, height: 1.2)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          GradientPillButton(
            label: 'Öğrenmeye Başla',
            gold: true,
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Ortak pencere kabuğu — koyu kart, kaydırılabilir içerik, kapatma düğmesi.
class _DialogShell extends StatelessWidget {
  const _DialogShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s6),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.surface2, p.surface],
          ),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: p.primary.withValues(alpha: 0.35)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 12))],
        ),
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.86),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s5, AppSpacing.s5, AppSpacing.s5),
                child: child,
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Kapat',
                icon: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.border), color: p.surface),
                  child: Icon(Icons.close_rounded, color: p.text2, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
