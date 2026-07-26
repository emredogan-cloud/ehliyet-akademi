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

/// Karşılama anı — kişiselleştirme bittikten sonra, Ana Sayfa'dan önce.
///
/// **Evolution E7** bu ekranı "seçimlerinin özeti" olarak kurmuştu. **Beta Faz 8** onun ÜSTÜNE
/// bir AI tanıtım adımı ekler; zincir ve tek-seferlik işaret AYNEN korunur:
///
/// ```
/// tanıtım (onboarding) → KARŞILAMA [ tanıtım adımı → özet adımı ] → ana sayfa
/// ```
///
/// TEK SEFERLİK: `ea:welcomeSeen:v1`. **Her çıkış yolu** (iki adımın "Atla"sı ve son CTA) bu
/// işareti koyar; ikinci açılışta doğrudan Ana Sayfa gelir. İşaret yalnız TEK yerde konur
/// ([_leave]) — yeni bir çıkış yolu eklenirse unutulması zorlaşsın diye.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Karşılamadan çıkışın TEK yolu — işaret burada konur.
  Future<void> _leave() async {
    await ref.read(welcomeSeenProvider.notifier).markSeen();
    if (mounted) context.go('/home');
  }

  void _next() => _pages.nextPage(duration: AppMotion.base, curve: AppMotion.easeOut);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: AppSpacing.s5),
                // SegmentBar kendi içinde Expanded kullanıyor → genişliği SINIRLI olmalı.
                Expanded(child: SegmentBar(total: 2, active: _index)),
                const SizedBox(width: AppSpacing.s4),
                _SkipButton(onSkip: _leave),
              ],
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                // Adım adım — CTA ile ilerlenir (onboarding ile aynı desen).
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _IntroPage(onNext: _next),
                  _SummaryPage(onStart: _leave),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onSkip});
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s2),
      child: TextButton(
        onPressed: onSkip,
        style: TextButton.styleFrom(
          foregroundColor: p.text3,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Text(
          'Atla',
          style: TextStyle(color: p.text3, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Adım 1 — AI Koç tanıtımı (Beta Faz 8)
// ─────────────────────────────────────────────────────────────────────────────

/// AI Koç'un ağzından uygulamanın beş sütununu tanıtan adım.
///
/// **Vaat edilenler gerçekten var:** her satır uygulamada bulunan bir yüzeye karşılık gelir
/// (öğrenme, pratik, topluluk, AI Koç, premium). Olmayan bir şey tanıtılmaz — testle sabit.
class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.onNext});
  final VoidCallback onNext;

  static const pillars = <(IconData, String, String)>[
    (Icons.menu_book_rounded, 'Öğren', 'Dersler, trafik işaretleri, araç tekniği ve videolar.'),
    (Icons.psychology_rounded, 'Pratik yap', 'Soru çöz, deneme sınavına gir, eksiğini gör.'),
    (Icons.groups_rounded, 'Topluluk', 'İstersen katıl; sıralama ve çalışma grupları seni bekler.'),
    (Icons.auto_awesome_rounded, 'AI Koç', 'Takıldığın yeri sor, anlaşılır bir açıklama al.'),
    (Icons.workspace_premium_rounded, 'Premium', 'Dilersen her şeyin kilidini tek pakette aç.'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              // Onboarding ile AYNI yoğunluk kuralı — tanıtım da kaydırmasız sığmalı.
              final d = densityFor(context, c.maxHeight);
              final dense = d == OnboardingDensity.dense;
              final tight = d != OnboardingDensity.roomy;
              final mascotH = (c.maxHeight * (dense ? 0.13 : 0.18)).clamp(56.0, 150.0);

              return CenteredScroll(
                minHeight: c.maxHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s5,
                  vertical: AppSpacing.s2,
                ),
                children: [
                  // En dar bütçede maskot DÜŞER: beş sütun listesi ve CTA öncelikli, başlık
                  // zaten "AI Koç" anlatısını taşıyor (ölçüldü: 360×640 @1.3× ancak böyle
                  // kaydırmasız sığıyor).
                  if (!dense) ...[
                    IdleMascot(AppImages.owlWave, height: mascotH, semanticLabel: 'AI Koç'),
                    SizedBox(height: tight ? AppSpacing.s2 : AppSpacing.s4),
                  ],
                  Text(
                    'Tanışalım',
                    textAlign: TextAlign.center,
                    style: dense
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (!dense) ...[
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      'Ben AI Koç. Sınava kadar seninleyim — uygulamada seni neler bekliyor?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.text2, height: 1.4, fontSize: 14),
                    ),
                  ],
                  SizedBox(height: tight ? AppSpacing.s3 : AppSpacing.s5),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.s4,
                      vertical: dense ? AppSpacing.s1 : AppSpacing.s2,
                    ),
                    decoration: BoxDecoration(
                      color: p.surface2,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(color: p.border),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < pillars.length; i++) ...[
                          if (i != 0) Divider(height: 1, color: p.border),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: dense ? 5 : AppSpacing.s2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(pillars[i].$1, color: p.primary, size: 20),
                                const SizedBox(width: AppSpacing.s3),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        pillars[i].$2,
                                        style: TextStyle(
                                          color: p.text,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      // Dar bütçede ikinci satır düşer — başlık anlamı taşıyor.
                                      if (!dense) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          pillars[i].$3,
                                          style: TextStyle(
                                            color: p.text3,
                                            fontSize: 12,
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
            label: 'Devam',
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Adım 2 — kişiselleştirme özeti (Evolution E7 — DEĞİŞTİRİLMEDİ)
// ─────────────────────────────────────────────────────────────────────────────

/// Kişiselleştirmenin karşılığını GÖSTERİR: seçilen ehliyet sınıfı, hazırlanılan sınav, tempo ve
/// günlük hedef doğrudan kaydedilmiş [StudyProfile]'dan okunur — burada hiçbir değer yeniden
/// hesaplanmaz veya varsayılmaz, böylece ekranda yazan şey uygulamanın gerçekten kullandığı ayardır.
class _SummaryPage extends ConsumerWidget {
  const _SummaryPage({required this.onStart});
  final VoidCallback onStart;

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
      (Icons.flag_rounded, p.accent, 'Günlük hedefin', '${profile.sessionSize} soru'),
    ];

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
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
                  // Faz 8: en dar bütçede (ör. 360×640 @1.3×) maskot düşer — özet satırları ve
                  // CTA önceliklidir. Ölçüldü: iki adım da ancak böyle kaydırmasız sığıyor.
                  if (!dense) ...[
                    IdleMascot(AppImages.owlWave, height: mascotH, semanticLabel: 'AI Koç'),
                    SizedBox(height: tight ? AppSpacing.s2 : AppSpacing.s4),
                  ],
                  Text(
                    'Her şey hazır!',
                    textAlign: TextAlign.center,
                    style: dense
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.headlineMedium,
                  ),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(rows[i].$1, color: rows[i].$2, size: 20),
                                const SizedBox(width: AppSpacing.s3),
                                // Faz 8: büyük yazı ölçeğinde etiket ve değer yan yana
                                // SIĞMIYORDU (ölçüldü: 360×640 @1.3× → 24 px yatay taşma).
                                // Dar bütçede alt alta yığılır; geniş bütçede eski düzen sürer.
                                Expanded(
                                  child: dense
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              rows[i].$3,
                                              style: TextStyle(color: p.text3, fontSize: 12.5),
                                            ),
                                            Text(
                                              rows[i].$4,
                                              style: TextStyle(
                                                color: p.text,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
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
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // En dar bütçede koç kartı da düşer: özet satırları ekranın ASIL yüküdür,
                  // içgörü ikincildir (yoğunluk felsefesi: ikincil içerik önce düşer).
                  if (!dense) ...[
                    SizedBox(height: tight ? AppSpacing.s3 : AppSpacing.s4),
                    const CoachInsightCard(step: 5, compact: true),
                  ],
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
            onPressed: onStart,
          ),
        ),
      ],
    );
  }
}
