import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
import '../../design/coach_card.dart';
import '../../design/primitives.dart';
import '../../design/readiness_ring.dart';

/// Home — the app's center. A scroll of live cards (readiness, AI nudge, daily plan, quick
/// actions, continue). Phase 1 uses representative static data; Phase 2+ binds real progress.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s4,
            AppSpacing.s4,
            AppSpacing.s10,
          ),
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Merhaba 👋', style: TextStyle(color: p.text3, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('Bugün de çalışalım',
                          style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
                _StreakChip(days: 3),
              ],
            ),
            const SizedBox(height: AppSpacing.s5),

            // Readiness + summary
            AppCard(
              child: Row(
                children: [
                  const ReadinessRing(value: 0.72),
                  const SizedBox(width: AppSpacing.s5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sınava hazırlık', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.s2),
                        Text('İyi gidiyorsun — birkaç zayıf konu kaldı.',
                            style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.3)),
                        const SizedBox(height: AppSpacing.s3),
                        Row(
                          children: [
                            StatTile(value: '1562', label: 'soru', color: p.primary),
                            const SizedBox(width: AppSpacing.s5),
                            StatTile(value: '%78', label: 'doğruluk'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s4),

            // AI Coach proactive nudge
            CoachCard(
              message:
                  '“Işıklı işaretler” konusunda %55 başarındasın. 5 soruyla toparlayalım mı?',
              actionLabel: 'Zayıf konuyu çöz',
              onAction: () => context.go('/practice'),
            ),

            SectionTitle('Bugünkü plan'),
            AppCard(
              child: Column(
                children: [
                  _PlanRow(icon: Icons.bolt_rounded, text: '10 soru akıllı çalışma', done: true),
                  Divider(height: AppSpacing.s6, color: p.border),
                  _PlanRow(icon: Icons.refresh_rounded, text: 'Tekrar zamanı gelen 8 kart'),
                  Divider(height: AppSpacing.s6, color: p.border),
                  _PlanRow(icon: Icons.assignment_turned_in_rounded, text: '1 deneme sınavı'),
                ],
              ),
            ),

            SectionTitle('Hızlı işlemler'),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.s3,
              crossAxisSpacing: AppSpacing.s3,
              childAspectRatio: 0.82,
              children: [
                QuickAction(
                    icon: Icons.timer_outlined,
                    label: 'Deneme çöz',
                    color: p.primary,
                    onTap: () => context.go('/practice')),
                QuickAction(
                    icon: Icons.bolt_rounded,
                    label: 'Akıllı çalış',
                    color: p.accent,
                    onTap: () => context.go('/practice')),
                QuickAction(
                    icon: Icons.traffic_rounded,
                    label: 'İşaretler',
                    color: p.blue,
                    onTap: () => context.go('/learn')),
                QuickAction(
                    icon: Icons.auto_awesome_rounded,
                    label: 'AI Koç',
                    color: const Color(0xFF8B5CF6),
                    onTap: () => context.go('/coach')),
              ],
            ),

            SectionTitle('Devam et'),
            OverviewTile(
              icon: Icons.menu_book_rounded,
              title: 'Trafik İşaretleri',
              subtitle: 'Kaldığın yerden devam et · 12/23',
              iconColor: p.blue,
              onTap: () => context.go('/learn'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});
  final int days;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 4),
          Text('$days gün',
              style: TextStyle(fontWeight: FontWeight.w700, color: p.accent, fontSize: 13)),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.icon, required this.text, this.done = false});
  final IconData icon;
  final String text;
  final bool done;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Icon(done ? Icons.check_circle_rounded : icon, color: done ? p.green : p.text3, size: 22),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: done ? p.text3 : p.text,
              decoration: done ? TextDecoration.lineThrough : null,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
