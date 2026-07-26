import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets.dart';
import '../../core/theme/tokens.dart';
import '../../design/brand.dart';
import '../../domain/onboarding/onboarding_controller.dart';
import '../../domain/onboarding/study_profile.dart';
import '../../domain/onboarding/welcome_controller.dart';
import 'widgets/centered_scroll.dart';
import 'widgets/onboarding_density.dart';
import 'widgets/coach_insight_card.dart';

/// İlk açılış — premium kişiselleştirme akışı. Karşılama → ehliyet sınıfı → sınav deneyimi →
/// sınav türü → kalan süre → AI Koç tanıtımı. Yanıtlar bir [StudyProfile]'a kaydedilir ve çalışma
/// planı / panel / koç / bildirimleri başlatır.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  // Kişiselleştirme seçimleri (mantıklı varsayılanlarla — akış hiç takılmaz).
  LicenceCategory _category = LicenceCategory.b;
  ExamExperience _experience = ExamExperience.firstTime;
  bool _direksiyon = true;
  bool _eSinav = true;
  ExamTimeframe _timeframe = ExamTimeframe.weekToMonth;

  static const _lastIndex = 5;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  ExamFocus get _focus {
    if (_direksiyon && _eSinav) return ExamFocus.both;
    if (_direksiyon) return ExamFocus.direksiyon;
    if (_eSinav) return ExamFocus.eSinav;
    return ExamFocus.both;
  }

  Future<void> _finish({required bool completed}) async {
    final profile = StudyProfile(
      category: _category,
      experience: _experience,
      focus: _focus,
      timeframe: _timeframe,
      completed: completed,
    );
    await ref.read(studyProfileProvider.notifier).save(profile);
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    // "Atla" ile geçildiyse karşılama da atlanır: seçilmemiş değerleri özetlemek yanıltıcı olurdu.
    if (!completed) await ref.read(welcomeSeenProvider.notifier).markSeen();
    if (mounted) context.go('/home');
  }

  void _next() {
    if (_index < _lastIndex) {
      _pages.nextPage(duration: AppMotion.base, curve: AppMotion.easeOut);
    } else {
      _finish(completed: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView.builder(
          controller: _pages,
          physics: const NeverScrollableScrollPhysics(), // adım adım — CTA ile ilerlenir
          itemCount: _lastIndex + 1,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) => _slide(i),
        ),
      ),
    );
  }

  Widget _slide(int i) {
    switch (i) {
      case 0:
        return _WelcomeSlide(onNext: _next, onSkip: () => _finish(completed: false));
      case 1:
        return _StepScaffold(
          step: 1,
          onSkip: () => _finish(completed: false),
          title: 'Hangi ehliyeti alıyorsun?',
          subtitle: 'İçerikler ve öneriler seçimine göre önceliklenir.',
          onNext: _next,
          child: _CategoryStep(selected: _category, onSelect: (c) => setState(() => _category = c)),
        );
      case 2:
        return _StepScaffold(
          step: 2,
          onSkip: () => _finish(completed: false),
          hero: AppImages.onbThink,
          heroFitsTight: true, // 2 seçenekli — ölçüldü, tight kademede de sığıyor
          title: 'Daha önce sınava girdin mi?',
          subtitle: 'Çalışma planını buna göre kuruyoruz.',
          onNext: _next,
          child: _ExperienceStep(selected: _experience, onSelect: (e) => setState(() => _experience = e)),
        );
      case 3:
        return _StepScaffold(
          step: 3,
          onSkip: () => _finish(completed: false),
          title: 'Hangi sınava hazırlanıyorsun?',
          subtitle: 'İkisini birden seçebilirsin.',
          onNext: _next,
          child: _FocusStep(
            direksiyon: _direksiyon,
            eSinav: _eSinav,
            onToggleDireksiyon: () => setState(() => _direksiyon = !_direksiyon),
            onToggleESinav: () => setState(() => _eSinav = !_eSinav),
          ),
        );
      case 4:
        return _StepScaffold(
          step: 4,
          onSkip: () => _finish(completed: false),
          hero: AppImages.onbCalendar,
          title: 'Sınavına ne kadar süre kaldı?',
          subtitle: 'Günlük soru hedefin buna göre belirlenir.',
          onNext: _next,
          child: _TimeframeStep(selected: _timeframe, onSelect: (t) => setState(() => _timeframe = t)),
        );
      default:
        return _CoachSlide(onFinish: () => _finish(completed: true));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide 0 — Welcome
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeSlide extends StatelessWidget {
  const _WelcomeSlide({required this.onNext, required this.onSkip});
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(alignment: Alignment.centerRight, child: _SkipButton(onSkip: onSkip)),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) => c.maxWidth > c.maxHeight
                ? _landscape(context, c)
                : _portrait(context, c),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s6, AppSpacing.s3, AppSpacing.s6, AppSpacing.s5),
          child: GradientPillButton(label: 'Devam', trailingIcon: Icons.chevron_right_rounded, onPressed: onNext),
        ),
      ],
    );
  }

  List<(IconData, Color, String, String)> _features(AppPalette p) => [
    (Icons.track_changes_rounded, p.primary, 'KONU ANLATIMI', 'Ayrıntılı anlatımlar'),
    (Icons.psychology_rounded, p.purple, 'AKILLI TESTLER', 'Zeka destekli çözüm'),
    (Icons.bar_chart_rounded, p.green, 'İLERLEME', 'Gelişimini izle'),
    (Icons.star_rounded, p.accent, 'BAŞARI ODAKLI', 'Hedefine odaklan'),
  ];

  Widget _titleBlock(BuildContext context, {required OnboardingDensity density}) {
    final p = context.palette;
    final theme = Theme.of(context).textTheme;
    final dense = density == OnboardingDensity.dense;
    final roomy = density == OnboardingDensity.roomy;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Marka çipi başlığın kendisiyle aynı metni taşıdığı için dar düzende gösterilmez.
        if (roomy) ...[
          const BrandChip(label: 'EHLİYET AKADEMİ', icon: Icons.school_rounded),
          const SizedBox(height: AppSpacing.s3),
        ],
        Text(
          'EHLİYET AKADEMİ',
          textAlign: TextAlign.center,
          style: (dense
                  ? theme.headlineSmall
                  : (roomy ? theme.displayMedium : theme.headlineMedium))
              ?.copyWith(letterSpacing: 0.5),
        ),
        // Dar bütçede alt başlık düşer: aynı vaadi koç kartı zaten anlatıyor.
        if (!dense) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Ehliyet sınavına akıllı, kişisel ve çevrimdışı hazırlık.',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.text2, height: 1.4, fontSize: 14),
          ),
        ],
      ],
    );
  }

  Widget _featureStrip(BuildContext context, {required bool tight}) {
    final p = context.palette;
    return Container(
      padding: EdgeInsets.symmetric(vertical: tight ? AppSpacing.s2 : AppSpacing.s3, horizontal: AppSpacing.s2),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          for (final f in _features(p))
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(f.$1, color: f.$2, size: tight ? 21 : 24),
                  const SizedBox(height: 4),
                  Text(f.$3, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: p.text, letterSpacing: 0.2, height: 1.15)),
                  // Dar düzende ikinci satır düşer — ikon + etiket anlamı zaten taşıyor.
                  if (!tight) ...[
                    const SizedBox(height: 2),
                    Text(f.$4, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: p.text3, height: 1.15)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _portrait(BuildContext context, BoxConstraints c) {
    final d = densityFor(context, c.maxHeight);
    final tight = d != OnboardingDensity.roomy;
    // Faz 6: görsel artık GENİŞLİĞE göre ölçekleniyor; yükseklik yalnız üst sınır.
    final box = onboardingHeroBox(
      d,
      availableWidth: c.maxWidth - AppSpacing.s5 * 2,
      availableHeight: c.maxHeight,
    );
    return CenteredScroll(
      minHeight: c.maxHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s2),
      children: [
        IdleMascot(
          AppImages.onbWelcome,
          height: box.height,
          width: box.width,
          semanticLabel: 'Ehliyet Akademi',
        ),
        SizedBox(height: tight ? AppSpacing.s2 : AppSpacing.s4),
        _titleBlock(context, density: d),
        SizedBox(height: tight ? AppSpacing.s3 : AppSpacing.s5),
        _featureStrip(context, tight: tight),
        SizedBox(height: tight ? AppSpacing.s3 : AppSpacing.s4),
        const CoachInsightCard(step: 0, compact: true),
      ],
    );
  }

  Widget _landscape(BuildContext context, BoxConstraints c) {
    final mascotH = (c.maxHeight * 0.36).clamp(64.0, 170.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CenteredScroll(
            minHeight: c.maxHeight,
            padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s2, AppSpacing.s3, AppSpacing.s2),
            children: [
              IdleMascot(AppImages.onbWelcome, height: mascotH, semanticLabel: 'Ehliyet Akademi'),
              const SizedBox(height: AppSpacing.s3),
              _titleBlock(context, density: OnboardingDensity.dense),
            ],
          ),
        ),
        Expanded(
          child: CenteredScroll(
            minHeight: c.maxHeight,
            padding: const EdgeInsets.fromLTRB(AppSpacing.s3, AppSpacing.s2, AppSpacing.s5, AppSpacing.s2),
            children: [
              _featureStrip(context, tight: true),
              const SizedBox(height: AppSpacing.s3),
              const CoachInsightCard(step: 0, compact: true),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared step scaffold (personalization steps 1–4)
// ─────────────────────────────────────────────────────────────────────────────

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onNext,
    required this.onSkip,
    this.hero,
    this.heroFitsTight = false,
  });
  final int step; // 1..4
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final String? hero;

  /// Bu adımın gövdesi ORTA (`tight`) kademede görselle birlikte kaydırmasız sığıyor mu?
  ///
  /// ÖLÇÜLDÜ (`onboarding_experience_test.dart`, 393×780): 2 seçenekli adım sığıyor;
  /// 4 seçenekli "kalan süre" adımı **158 px taşıyor** → orada görsel yalnız `roomy`
  /// kademede çizilir. Bu, tahmin değil ölçüm sonucudur; değiştirilirse test kırılır.
  final bool heroFitsTight;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s5,
            landscape ? AppSpacing.s1 : AppSpacing.s2,
            AppSpacing.s5,
            landscape ? AppSpacing.s1 : AppSpacing.s2,
          ),
          child: Row(
            children: [
              BrandMark(size: landscape ? 32 : 44),
              const SizedBox(width: AppSpacing.s4),
              Expanded(child: SegmentBar(total: 4, active: step)),
              const SizedBox(width: AppSpacing.s4),
              _SkipButton(onSkip: onSkip, padded: false),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) =>
                c.maxWidth > c.maxHeight ? _landscape(context, c) : _portrait(context, c),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s2,
            AppSpacing.s5,
            landscape ? AppSpacing.s3 : AppSpacing.s5,
          ),
          child: GradientPillButton(label: 'Devam Et', trailingIcon: Icons.arrow_forward_rounded, onPressed: onNext),
        ),
      ],
    );
  }

  Widget _titleBlock(BuildContext context, {required OnboardingDensity density}) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    // Orta kademede de titleLarge kullanılır: soru kısa, başlık yine baskın kalıyor ve
    // 4 seçenekli adımın seçenek açıklamalarını korumaya yetecek yer açılıyor (ölçüldü).
    final style = switch (density) {
      OnboardingDensity.roomy => t.headlineMedium,
      _ => t.titleLarge,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: style?.copyWith(height: 1.15)),
        // Dar bütçede alt açıklama düşer: soru zaten net, bağlamı koç kartı veriyor.
        if (density != OnboardingDensity.dense) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(subtitle, style: TextStyle(color: p.text2, height: 1.35, fontSize: 14)),
        ],
      ],
    );
  }

  /// Dikey düzen — sığıyorsa DİKEY ORTALI, sığmıyorsa kaydırılabilir (kırpma yok).
  /// Kahraman görsel yüksekliği alana göre küçülür; çok dar ekranda hiç çizilmez.
  Widget _portrait(BuildContext context, BoxConstraints c) {
    final h = c.maxHeight;
    final d = densityFor(context, h);
    final dense = d == OnboardingDensity.dense;
    // Faz 6: adım görseli de GENİŞLİĞE göre ölçekleniyor; yükseklik yalnız üst sınır.
    // Bu ekranlar form ağırlıklı olduğu için bütçe karşılama adımından dardır — oran
    // ÖLÇÜLEREK belirlendi (bkz. faz raporu).
    final heroH = (h * (d == OnboardingDensity.roomy ? 0.30 : 0.22)).clamp(72.0, 210.0);
    final heroW = c.maxWidth - AppSpacing.s5 * 2;
    // Faz 6 DÜZELTMESİ: görsel eskiden YALNIZ `roomy` kademede çiziliyordu. Gerçek cihazda
    // gövde 700 dp eşiğinin hemen ALTINA düşüyor (≈699) → adım `tight` sayılıyor, görsel hiç
    // çizilmiyor ve ekranda ~500 dp boşluk kalıyordu (cihazda görüldü, `b6_03`). Artık
    // `dense` dışındaki her kademede çizilir; `dense` kademede yer gerçekten yoktur.
    final showHero = hero != null &&
        (d == OnboardingDensity.roomy ||
            (d == OnboardingDensity.tight && heroFitsTight));
    final gap = dense ? AppSpacing.s2 : (d == OnboardingDensity.tight ? AppSpacing.s3 : AppSpacing.s5);
    return OnboardingDensityScope(
      density: d,
      child: CenteredScroll(
        minHeight: h,
        padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s2, AppSpacing.s5, AppSpacing.s2),
        children: [
          if (showHero) ...[
            Center(child: IdleMascot(hero!, height: heroH, width: heroW, semanticLabel: '')),
            const SizedBox(height: AppSpacing.s4),
          ],
          _titleBlock(context, density: d),
          SizedBox(height: gap),
          child,
          SizedBox(height: gap),
          CoachInsightCard(step: step, compact: d != OnboardingDensity.roomy),
        ],
      ),
    );
  }

  /// Yatay düzen — solda anlatım + koç kartı, sağda seçenekler. Böylece yatayda da
  /// kaydırma gerekmez ve CTA her zaman görünür kalır.
  Widget _landscape(BuildContext context, BoxConstraints c) {
    return OnboardingDensityScope(
      density: OnboardingDensity.dense,
      sideBySide: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CenteredScroll(
              minHeight: c.maxHeight,
              padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s2, AppSpacing.s3, AppSpacing.s2),
              children: [
                _titleBlock(context, density: OnboardingDensity.dense),
                const SizedBox(height: AppSpacing.s3),
                CoachInsightCard(step: step, compact: true),
              ],
            ),
          ),
          Expanded(
            child: CenteredScroll(
              minHeight: c.maxHeight,
              padding: const EdgeInsets.fromLTRB(AppSpacing.s3, AppSpacing.s2, AppSpacing.s5, AppSpacing.s2),
              children: [child],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onSkip, this.padded = true});
  final VoidCallback onSkip;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: padded ? const EdgeInsets.all(AppSpacing.s2) : EdgeInsets.zero,
      child: TextButton(
        onPressed: onSkip,
        style: TextButton.styleFrom(foregroundColor: p.primary, padding: const EdgeInsets.symmetric(horizontal: 8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Atla', style: TextStyle(color: p.primary, fontWeight: FontWeight.w700, fontSize: 15)),
            Icon(Icons.chevron_right_rounded, color: p.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Licence category
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryStep extends StatelessWidget {
  const _CategoryStep({required this.selected, required this.onSelect});
  final LicenceCategory selected;
  final ValueChanged<LicenceCategory> onSelect;

  static const _photos = {
    LicenceCategory.b: AppImages.vehicleCar,
    LicenceCategory.a: AppImages.vehicleMoto,
    LicenceCategory.d: AppImages.vehicleBus,
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final d = OnboardingDensityScope.of(context);
    final dense = d == OnboardingDensity.dense;
    final roomy = d == OnboardingDensity.roomy;
    // ÖLÇÜLDÜ: fotoğrafı esnek (flex 52) vermek metin sütununu 118 px'e düşürüyor ve açıklama
    // 4 satıra sarıp kartı 196 px yapıyordu. Fotoğraf artık SABİT genişlikte; metin sütunu geniş.
    final photo = dense ? 36.0 : (roomy ? 68.0 : 50.0);
    return OptionLayout(
      gap: roomy ? AppSpacing.s3 : AppSpacing.s2,
      items: [
        for (final cat in LicenceCategory.values)
          GlowCard(
            selected: selected == cat,
            onTap: () => onSelect(cat),
            padding: roomy
                ? const EdgeInsets.all(AppSpacing.s4)
                : EdgeInsets.symmetric(
                    horizontal: AppSpacing.s3,
                    vertical: dense ? AppSpacing.s2 : AppSpacing.s3,
                  ),
            child: Row(
              children: [
                SizedBox(
                  width: photo * 1.35,
                  child: MascotImage(_photos[cat]!, height: photo, semanticLabel: cat.title),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cat == LicenceCategory.b && roomy)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: BrandChip(
                            label: 'EN POPÜLER',
                            icon: Icons.star_rounded,
                            color: context.palette.accent,
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            cat.badge,
                            style: TextStyle(
                              color: p.primary,
                              fontSize: dense ? 20 : 26,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s2),
                          Expanded(
                            child: Text(
                              cat.title,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: dense ? 14 : 15.5),
                            ),
                          ),
                        ],
                      ),
                      // Dar bütçede açıklama düşer; sınıf harfi ve adı zaten seçimi anlatıyor.
                      if (roomy)
                        Text(cat.blurb, style: TextStyle(color: p.text3, fontSize: 11.5, height: 1.25)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                _RadioDot(selected: selected == cat),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Exam experience
// ─────────────────────────────────────────────────────────────────────────────

class _ExperienceStep extends StatelessWidget {
  const _ExperienceStep({required this.selected, required this.onSelect});
  final ExamExperience selected;
  final ValueChanged<ExamExperience> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final icons = {
      ExamExperience.firstTime: (Icons.person_add_alt_1_rounded, p.primary),
      ExamExperience.retaking: (Icons.autorenew_rounded, p.accent),
    };
    return OptionLayout(
      gap: _rowGap(context),
      items: [
        for (final e in ExamExperience.values)
          _OptionRow(
            icon: icons[e]!.$1,
            color: icons[e]!.$2,
            title: e.title,
            subtitle: e.blurb,
            selected: selected == e,
            onTap: () => onSelect(e),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Exam focus (multi-select)
// ─────────────────────────────────────────────────────────────────────────────

class _FocusStep extends StatelessWidget {
  const _FocusStep({
    required this.direksiyon,
    required this.eSinav,
    required this.onToggleDireksiyon,
    required this.onToggleESinav,
  });
  final bool direksiyon;
  final bool eSinav;
  final VoidCallback onToggleDireksiyon;
  final VoidCallback onToggleESinav;

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight verir → iki kart eşit boyda (stretch), dikey kaydırma içinde sonsuz yükseklik yok.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _FocusCard(
              hero: AppImages.onbWheel,
              icon: Icons.sports_esports_rounded,
              title: 'Direksiyon\nSınavı',
              blurb: 'Direksiyon sınavına yönelik özel içerikler, ipuçları ve pratik eğitimler.',
              selected: direksiyon,
              onTap: onToggleDireksiyon,
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: _FocusCard(
              hero: AppImages.onbTablet,
              icon: Icons.description_rounded,
              title: 'e-Sınav\n(Trafik)',
              blurb: 'e-Sınav (Trafik) konularına yönelik soru çözümleri ve konu anlatımları.',
              selected: eSinav,
              onTap: onToggleESinav,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.hero,
    required this.icon,
    required this.title,
    required this.blurb,
    required this.selected,
    required this.onTap,
  });
  final String hero;
  final IconData icon;
  final String title;
  final String blurb;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlowCard(
      selected: selected,
      onTap: onTap,
      padding: EdgeInsets.all(
        OnboardingDensityScope.of(context) == OnboardingDensity.dense ? AppSpacing.s3 : AppSpacing.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: MascotImage(
              hero,
              height: OnboardingDensityScope.of(context) == OnboardingDensity.dense ? 56 : 88,
              semanticLabel: title.replaceAll('\n', ' '),
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Icon(icon, color: p.primary, size: 20),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, height: 1.1))),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          if (OnboardingDensityScope.of(context) != OnboardingDensity.dense) ...[
            Text(blurb, style: TextStyle(color: p.text3, fontSize: 12, height: 1.35)),
            const SizedBox(height: AppSpacing.s3),
          ] else
            const SizedBox(height: AppSpacing.s2),
          Row(
            children: [
              Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, size: 18, color: selected ? p.primary : p.text3),
              const SizedBox(width: 6),
              // Büyük yazı ölçeğinde bu satır taşıyordu (ölçüldü) → esnek + tek satır.
              Flexible(
                child: Text(
                  selected ? 'Seçildi' : 'Seç',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: selected ? p.primary : p.text3, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — Timeframe
// ─────────────────────────────────────────────────────────────────────────────

class _TimeframeStep extends StatelessWidget {
  const _TimeframeStep({required this.selected, required this.onSelect});
  final ExamTimeframe selected;
  final ValueChanged<ExamTimeframe> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final icons = {
      ExamTimeframe.lessThanWeek: (Icons.calendar_today_rounded, p.primary),
      ExamTimeframe.weekToMonth: (Icons.event_available_rounded, p.primary),
      ExamTimeframe.moreThanMonth: (Icons.event_note_rounded, p.primary),
      ExamTimeframe.notSure: (Icons.help_outline_rounded, p.accent),
    };
    return OptionLayout(
      gap: _rowGap(context),
      items: [
        for (final t in ExamTimeframe.values)
          _OptionRow(
            icon: icons[t]!.$1,
            color: icons[t]!.$2,
            title: t.title,
            subtitle: t.blurb,
            selected: selected == t,
            onTap: () => onSelect(t),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide 5 — AI Koç intro
// ─────────────────────────────────────────────────────────────────────────────

class _CoachSlide extends StatelessWidget {
  const _CoachSlide({required this.onFinish});
  final VoidCallback onFinish;

  List<(IconData, Color, String, String)> _features(AppPalette p) => [
    (Icons.trending_up_rounded, p.primary, 'İlerlemeni İzler', 'Performansını analiz eder.'),
    (Icons.person_pin_rounded, p.purple, 'Sana Özel Önerir', 'Zayıf konularına plan kurar.'),
    (Icons.chat_bubble_rounded, p.accent, 'Sorularını Yanıtlar', 'Trafik sorularına anında yanıt.'),
  ];

  Widget _header(BuildContext context, OnboardingDensity d, double owlH) {
    final p = context.palette;
    final dense = d == OnboardingDensity.dense;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'AI ', style: TextStyle(color: p.primary, fontWeight: FontWeight.w900, fontSize: dense ? 26 : 36)),
                    TextSpan(text: 'Koç', style: TextStyle(color: p.text, fontWeight: FontWeight.w900, fontSize: dense ? 26 : 36)),
                  ],
                ),
              ),
              if (!dense) ...[
                const SizedBox(height: AppSpacing.s2),
                Text(
                  'İlerlemeni izleyen, sana özel öneren proaktif bir koç.',
                  style: TextStyle(color: p.text2, height: 1.4, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        IdleMascot(AppImages.owlWave, height: owlH, semanticLabel: 'AI Koç'),
      ],
    );
  }

  List<Widget> _featureCards(BuildContext context, OnboardingDensity d) {
    final p = context.palette;
    final dense = d == OnboardingDensity.dense;
    return [
      for (final f in _features(p)) ...[
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s3,
            vertical: dense ? 6 : AppSpacing.s4,
          ),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: f.$2.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              IconBadge(icon: f.$1, color: f.$2, size: dense ? 36 : 50, glow: true),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(f.$3, style: TextStyle(fontWeight: FontWeight.w800, fontSize: dense ? 14 : 15.5)),
                    if (!dense) ...[
                      const SizedBox(height: 3),
                      Text(f.$4, style: TextStyle(color: p.text3, fontSize: 12, height: 1.3)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: dense ? 6 : AppSpacing.s3),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s3),
            child: IconButton(
              onPressed: onFinish,
              tooltip: 'Kapat',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.border)),
                child: Icon(Icons.close_rounded, color: p.text2, size: 20),
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final landscape = c.maxWidth > c.maxHeight;
              final d = landscape ? OnboardingDensity.dense : densityFor(context, c.maxHeight);
              final owlH = (c.maxHeight * (d == OnboardingDensity.dense ? 0.16 : 0.20)).clamp(56.0, 140.0);
              if (landscape) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CenteredScroll(
                        minHeight: c.maxHeight,
                        padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s2, AppSpacing.s3, AppSpacing.s2),
                        children: [
                          _header(context, d, owlH),
                          const SizedBox(height: AppSpacing.s3),
                          const CoachInsightCard(step: 5, compact: true),
                        ],
                      ),
                    ),
                    Expanded(
                      child: CenteredScroll(
                        minHeight: c.maxHeight,
                        padding: const EdgeInsets.fromLTRB(AppSpacing.s3, AppSpacing.s2, AppSpacing.s5, AppSpacing.s2),
                        children: _featureCards(context, d),
                      ),
                    ),
                  ],
                );
              }
              return CenteredScroll(
                minHeight: c.maxHeight,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s2),
                children: [
                  _header(context, d, owlH),
                  SizedBox(height: d == OnboardingDensity.roomy ? AppSpacing.s5 : AppSpacing.s3),
                  ..._featureCards(context, d),
                  CoachInsightCard(step: 5, compact: d != OnboardingDensity.roomy),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s2, AppSpacing.s5, AppSpacing.s5),
          child: GradientPillButton(
            label: 'Koç ile Başla',
            trailingIcon: Icons.chevron_right_rounded,
            onPressed: onFinish,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

double _rowGap(BuildContext context) =>
    OnboardingDensityScope.of(context) == OnboardingDensity.dense ? AppSpacing.s2 : AppSpacing.s3;

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final d = OnboardingDensityScope.of(context);
    final dense = d == OnboardingDensity.dense;
    return GlowCard(
      selected: selected,
      onTap: onTap,
      padding: switch (d) {
        OnboardingDensity.roomy => const EdgeInsets.all(AppSpacing.s4),
        OnboardingDensity.tight => const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: 10,
        ),
        OnboardingDensity.dense => const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: 6,
        ),
      },
      child: Row(
        children: [
          IconBadge(
            icon: icon,
            color: color,
            size: switch (d) {
              OnboardingDensity.roomy => 46.0,
              OnboardingDensity.tight => 40.0,
              OnboardingDensity.dense => 30.0,
            },
            glow: selected,
          ),
          SizedBox(width: dense ? AppSpacing.s3 : AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: dense ? 14.5 : 16)),
                // Dar bütçede alt açıklama düşer; başlık seçimi tek başına anlatıyor.
                if (!dense) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.3)),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          _RadioDot(selected: selected),
        ],
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedContainer(
      duration: AppMotion.fast,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? p.primary : Colors.transparent,
        border: Border.all(color: selected ? p.primary : p.borderStrong, width: 2),
      ),
      child: selected ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
    );
  }
}
