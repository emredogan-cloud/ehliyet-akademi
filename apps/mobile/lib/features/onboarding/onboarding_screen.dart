import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets.dart';
import '../../core/theme/tokens.dart';
import '../../design/brand.dart';
import '../../domain/onboarding/onboarding_controller.dart';
import '../../domain/onboarding/study_profile.dart';

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
          title: 'Hangi ehliyet türünü alıyorsun?',
          subtitle: 'Sana en uygun içerikleri sunmak için lütfen seçimini yap.',
          footnote: 'Seçimin daha sonra değiştirilebilir.',
          onNext: _next,
          child: _CategoryStep(selected: _category, onSelect: (c) => setState(() => _category = c)),
        );
      case 2:
        return _StepScaffold(
          step: 2,
          onSkip: () => _finish(completed: false),
          hero: AppImages.onbThink,
          title: 'Daha önce sınava girdin mi?',
          subtitle: 'Sana en uygun çalışma planını belirleyebilmemiz için bilgiye ihtiyacımız var.',
          onNext: _next,
          child: _ExperienceStep(selected: _experience, onSelect: (e) => setState(() => _experience = e)),
        );
      case 3:
        return _StepScaffold(
          step: 3,
          onSkip: () => _finish(completed: false),
          title: 'e-Sınav mı, Direksiyon Sınavı mı hazırlanıyorsun?',
          subtitle: 'Sana en uygun içerikleri sunmak için seçimini yap. İkisini birden seçebilirsin.',
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
          subtitle: 'Sana en uygun çalışma planını oluşturabilmemiz için seçimini yap.',
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
    final p = context.palette;
    final features = [
      (Icons.track_changes_rounded, p.primary, 'KONU ANLATIMI', 'Ayrıntılı konu anlatımları'),
      (Icons.psychology_rounded, p.purple, 'AKILLI TESTLER', 'Zeka destekli soru çözümleri'),
      (Icons.bar_chart_rounded, p.green, 'İLERLEME TAKİBİ', 'Gelişimini anlık izle'),
      (Icons.star_rounded, p.accent, 'BAŞARI ODAKLI', 'Hedefine odaklan'),
    ];
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: _SkipButton(onSkip: onSkip),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
            child: Column(
              children: [
                MascotImage(AppImages.onbWelcome, height: 240, semanticLabel: 'Ehliyet Akademi'),
                const SizedBox(height: AppSpacing.s3),
                const BrandChip(label: 'EHLİYET AKADEMİ', icon: Icons.school_rounded),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'EHLİYET AKADEMİ',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(letterSpacing: 0.5),
                ),
                const SizedBox(height: AppSpacing.s3),
                Text(
                  'B sınıfı ehliyet sınavına akıllı, kişisel ve çevrimdışı hazırlık.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.text2, height: 1.5, fontSize: 15),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'Hadi başlayalım!',
                  style: TextStyle(color: p.primary, fontSize: 22, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.s5),
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
                              Icon(f.$1, color: f.$2, size: 26),
                              const SizedBox(height: 6),
                              Text(f.$3, textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: p.text, letterSpacing: 0.2)),
                              const SizedBox(height: 2),
                              Text(f.$4, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: p.text3, height: 1.2)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s6, AppSpacing.s3, AppSpacing.s6, AppSpacing.s5),
          child: GradientPillButton(label: 'Devam', trailingIcon: Icons.chevron_right_rounded, onPressed: onNext),
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
    this.footnote,
  });
  final int step; // 1..4
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final String? hero;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s2, AppSpacing.s5, AppSpacing.s2),
          child: Row(
            children: [
              const BrandMark(size: 44),
              const SizedBox(width: AppSpacing.s4),
              Expanded(child: SegmentBar(total: 4, active: step)),
              const SizedBox(width: AppSpacing.s4),
              _SkipButton(onSkip: onSkip, padded: false),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s3, AppSpacing.s5, AppSpacing.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hero != null)
                  Center(child: MascotImage(hero!, height: 180, semanticLabel: '')),
                if (hero != null) const SizedBox(height: AppSpacing.s4),
                Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(height: 1.15)),
                const SizedBox(height: AppSpacing.s2),
                Text(subtitle, style: TextStyle(color: p.text2, height: 1.45, fontSize: 14.5)),
                const SizedBox(height: AppSpacing.s5),
                child,
                if (footnote != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Row(
                    children: [
                      Icon(Icons.verified_user_outlined, size: 16, color: p.text3),
                      const SizedBox(width: AppSpacing.s2),
                      Expanded(child: Text(footnote!, style: TextStyle(color: p.text3, fontSize: 12.5))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s2, AppSpacing.s5, AppSpacing.s5),
          child: GradientPillButton(label: 'Devam Et', trailingIcon: Icons.arrow_forward_rounded, onPressed: onNext),
        ),
      ],
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
    return Column(
      children: [
        for (final cat in LicenceCategory.values) ...[
          GlowCard(
            selected: selected == cat,
            onTap: () => onSelect(cat),
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 48,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cat == LicenceCategory.b)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: BrandChip(label: 'EN POPÜLER', icon: Icons.star_rounded, color: Color(0xFFF5A623)),
                        ),
                      Text(cat.badge, style: TextStyle(color: p.primary, fontSize: 28, fontWeight: FontWeight.w900, height: 1.05)),
                      Text(cat.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(cat.blurb, style: TextStyle(color: p.text3, fontSize: 11.5, height: 1.2)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  flex: 52,
                  child: MascotImage(_photos[cat]!, height: 74, fit: BoxFit.contain, semanticLabel: cat.title),
                ),
                const SizedBox(width: AppSpacing.s2),
                _RadioDot(selected: selected == cat),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
        ],
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
    return Column(
      children: [
        for (final e in ExamExperience.values) ...[
          _OptionRow(
            icon: icons[e]!.$1,
            color: icons[e]!.$2,
            title: e.title,
            subtitle: e.blurb,
            selected: selected == e,
            onTap: () => onSelect(e),
          ),
          const SizedBox(height: AppSpacing.s3),
        ],
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
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: MascotImage(hero, height: 96, semanticLabel: title.replaceAll('\n', ' '))),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Icon(icon, color: p.primary, size: 20),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, height: 1.1))),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(blurb, style: TextStyle(color: p.text3, fontSize: 12, height: 1.35)),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, size: 18, color: selected ? p.primary : p.text3),
              const SizedBox(width: 6),
              Text(selected ? 'Seçildi' : 'Seç', style: TextStyle(color: selected ? p.primary : p.text3, fontWeight: FontWeight.w700, fontSize: 13)),
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
    return Column(
      children: [
        for (final t in ExamTimeframe.values) ...[
          _OptionRow(
            icon: icons[t]!.$1,
            color: icons[t]!.$2,
            title: t.title,
            subtitle: t.blurb,
            selected: selected == t,
            onTap: () => onSelect(t),
          ),
          const SizedBox(height: AppSpacing.s3),
        ],
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

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final features = [
      (Icons.trending_up_rounded, p.primary, 'İlerlemeni İzler', 'Performansını analiz eder, gelişimini takip eder.'),
      (Icons.person_pin_rounded, p.purple, 'Sana Özel Önerir', 'Zayıf konularını tespit eder, sana özel çalışma planı sunar.'),
      (Icons.chat_bubble_rounded, p.accent, 'Sorularını Yanıtlar', 'Ehliyet ve trafik ile ilgili tüm sorularına anında yanıt verir.'),
    ];
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: 'AI ', style: TextStyle(color: p.primary, fontWeight: FontWeight.w900, fontSize: 38)),
                                TextSpan(text: 'Koç', style: TextStyle(color: p.text, fontWeight: FontWeight.w900, fontSize: 38)),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s2),
                          Text(
                            'İlerlemeni izleyen, sana özel öneren proaktif bir koç. Ehliyet ve trafik sorularını yanıtlar.',
                            style: TextStyle(color: p.text2, height: 1.45, fontSize: 13.5),
                          ),
                        ],
                      ),
                    ),
                    MascotImage(AppImages.owlWave, height: 150, semanticLabel: 'AI Koç'),
                  ],
                ),
                const SizedBox(height: AppSpacing.s5),
                for (final f in features) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s4),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(color: f.$2.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        IconBadge(icon: f.$1, color: f.$2, size: 52, glow: true),
                        const SizedBox(width: AppSpacing.s4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.$3, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              const SizedBox(height: 3),
                              Text(f.$4, style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.35)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: f.$2),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                ],
              ],
            ),
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
    return GlowCard(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color, size: 48, glow: selected),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.3)),
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
