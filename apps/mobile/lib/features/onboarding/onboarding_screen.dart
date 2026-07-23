import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../domain/onboarding/onboarding_controller.dart';

class _Slide {
  const _Slide(this.emoji, this.title, this.body, this.color);
  final String emoji;
  final String title;
  final String body;
  final Color Function(AppPalette) color;
}

const List<_Slide> _slides = [
  _Slide(
    '🎓',
    'Ehliyet Akademi',
    'B sınıfı ehliyet sınavına akıllı, kişisel ve çevrimdışı hazırlık. Hadi başlayalım!',
    _primary,
  ),
  _Slide(
    '📚',
    'Öğren',
    '19 ders, 121 trafik işareti, araç tekniği ve videolar — hepsi cebinde, çevrimdışı çalışır.',
    _blue,
  ),
  _Slide(
    '🎯',
    'Pratik & Sınav',
    'Aralıklı tekrar (SRS) ile zayıf konulara odaklan; gerçek MEB formatında 50 soruluk denemeler çöz.',
    _accent,
  ),
  _Slide(
    '🤖',
    'AI Koç',
    'İlerlemeni izleyen, sana özel öneren proaktif bir koç. Ehliyet ve trafik sorularını yanıtlar.',
    _green,
  ),
];

Color _primary(AppPalette p) => p.primary;
Color _blue(AppPalette p) => p.blue;
Color _accent(AppPalette p) => p.accent;
Color _green(AppPalette p) => p.green;

/// İlk açılış tanıtımı — 4 slaytlık kaydırmalı karşılama. "Başla" ile tamamlanır → ana ekran.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    if (mounted) context.go('/home');
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _pages.nextPage(duration: AppMotion.base, curve: AppMotion.easeOut);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final last = _index == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s2),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(last ? '' : 'Atla', style: TextStyle(color: p.text3)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  final color = s.color(p);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Text(s.emoji, style: const TextStyle(fontSize: 64)),
                        ),
                        const SizedBox(height: AppSpacing.s6),
                        Text(s.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayMedium),
                        const SizedBox(height: AppSpacing.s3),
                        Text(
                          s.body,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.text2, height: 1.5, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Sayfa noktaları
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: AppMotion.base,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index ? p.primary : p.border,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s5),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(last ? 'Başla' : 'Devam'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
