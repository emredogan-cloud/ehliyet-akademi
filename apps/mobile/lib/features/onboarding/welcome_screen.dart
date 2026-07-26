import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets.dart';
import '../../core/theme/tokens.dart';
import '../../design/brand.dart';
import '../../domain/onboarding/study_profile.dart';
import '../../domain/onboarding/welcome_controller.dart';
import 'widgets/centered_scroll.dart';
import 'widgets/coach_insight_card.dart';
import 'widgets/onboarding_density.dart';

/// Evolution Faz E7 — kişiselleştirme bittikten sonraki karşılama anı.
///
/// Kişiselleştirmenin karşılığını GÖSTERİR: seçilen ehliyet sınıfı, hazırlanılan sınav, tempo ve
/// günlük hedef doğrudan kaydedilmiş [StudyProfile]'dan okunur — burada hiçbir değer yeniden
/// hesaplanmaz veya varsayılmaz, böylece ekranda yazan şey uygulamanın gerçekten kullandığı ayardır.
///
/// TEK SEFERLİK: `ea:welcomeSeen:v1`. Hem "Başla" hem "Atla" bu işareti koyar; ikinci açılışta
/// doğrudan Ana Sayfa gelir.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    await ref.read(welcomeSeenProvider.notifier).markSeen();
    if (context.mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final profile = ref.watch(studyProfileProvider);

    final rows = <(IconData, Color, String, String)>[
      (
        Icons.badge_rounded,
        p.primary,
        'Ehliyet sınıfın',
        '${profile.category.badge} · ${profile.category.title}',
      ),
      (Icons.assignment_rounded, p.blue, 'Hazırlandığın sınav', profile.focus.title),
      (Icons.speed_rounded, p.purple, 'Çalışma tempon', profile.timeframe.paceLabel),
      (
        Icons.flag_rounded,
        p.accent,
        'Günlük hedefin',
        '${profile.sessionSize} soru',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s2),
                child: TextButton(
                  onPressed: () => _continue(context, ref),
                  style: TextButton.styleFrom(
                    foregroundColor: p.text3,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    'Atla',
                    style: TextStyle(color: p.text3, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  // Onboarding ile AYNI yoğunluk kuralı: özet ekranı da kaydırmasız sığmalı.
                  final d = densityFor(context, c.maxHeight);
                  final dense = d == OnboardingDensity.dense;
                  final tight = d != OnboardingDensity.roomy;
                  final mascotH = (c.maxHeight * (dense ? 0.16 : 0.22)).clamp(68.0, 190.0);
                  return CenteredScroll(
                    minHeight: c.maxHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s5,
                      vertical: AppSpacing.s2,
                    ),
                    children: [
                      IdleMascot(AppImages.owlWave, height: mascotH, semanticLabel: 'AI Koç'),
                      SizedBox(height: tight ? AppSpacing.s2 : AppSpacing.s4),
                      Text(
                        'Her şey hazır!',
                        textAlign: TextAlign.center,
                        style: dense
                            ? Theme.of(context).textTheme.titleLarge
                            : Theme.of(context).textTheme.headlineMedium,
                      ),
                      // Dar bütçede alt açıklama düşer; aynı bilgi özet satırlarında zaten var.
                      if (!dense) ...[
                        const SizedBox(height: AppSpacing.s2),
                        Text(
                          'Planını sana göre kurduk. İstediğin zaman Profil\'den değiştirebilirsin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.text2, height: 1.4, fontSize: 14),
                        ),
                      ],
                      SizedBox(height: tight ? AppSpacing.s3 : AppSpacing.s5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s4,
                          vertical: AppSpacing.s2,
                        ),
                        decoration: BoxDecoration(
                          color: p.surface2,
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          border: Border.all(color: p.border),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < rows.length; i++) ...[
                              if (i != 0) Divider(height: 1, color: p.border),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: dense ? 6 : (tight ? AppSpacing.s2 : AppSpacing.s3),
                                ),
                                child: Row(
                                  children: [
                                    Icon(rows[i].$1, color: rows[i].$2, size: 20),
                                    const SizedBox(width: AppSpacing.s3),
                                    Expanded(
                                      child: Text(
                                        rows[i].$3,
                                        style: TextStyle(color: p.text3, fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.s2),
                                    Flexible(
                                      child: Text(
                                        rows[i].$4,
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                          color: p.text,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: tight ? AppSpacing.s3 : AppSpacing.s4),
                      const CoachInsightCard(step: 5, compact: true),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s5,
                AppSpacing.s2,
                AppSpacing.s5,
                AppSpacing.s5,
              ),
              child: GradientPillButton(
                label: 'Çalışmaya başla',
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: () => _continue(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
