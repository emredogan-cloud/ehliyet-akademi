import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/practice/progress_repository.dart';
import '../../design/app_card.dart';
import '../../design/coach_card.dart';
import '../../design/primitives.dart';
import '../../design/readiness_ring.dart';
import '../../domain/coach/nudge.dart';
import '../../domain/practice/srs.dart';
import '../../domain/progress/gamification.dart';

/// Home — the app's center, bound to real local progress (readiness, streak, accuracy, a proactive
/// nudge, today's plan). Falls back to gentle "get started" copy before any practice.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final progress = ref.watch(progressRepositoryProvider).value;
    final answers = progress?.loadAnswers() ?? const [];
    final readiness = answers.isNotEmpty ? progress!.readiness() : null;
    final streak = progress?.loadStreak() ?? StreakState.empty;
    final now = DateTime.now().millisecondsSinceEpoch;
    final dueCount = progress == null
        ? 0
        : progress.loadCards().values.where((c) => c.dueAt <= now).length;
    final correct = answers.where((a) => a.correct).length;
    final accuracy = answers.isEmpty ? 0 : (correct / answers.length * 100).round();
    final level = levelForXp(xpFromAnswers(answers));

    final nudges = computeNudges(
      readiness: readiness,
      streak: streak,
      dueCount: dueCount,
      answered: answers.length,
      nowMs: now,
    );
    final topNudge = nudges.isNotEmpty ? nudges.first : null;

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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Merhaba 👋', style: TextStyle(color: p.text3, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('Bugün de çalışalım', style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
                if (streak.current > 0) _StreakChip(days: streak.current),
              ],
            ),
            const SizedBox(height: AppSpacing.s5),

            // Readiness + summary → tap for the full progress screen.
            AppCard(
              onTap: () => context.push('/progress'),
              child: Row(
                children: [
                  ReadinessRing(value: (readiness?.overall ?? 0) / 100),
                  const SizedBox(width: AppSpacing.s5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Sınava hazırlık',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ),
                            Icon(Icons.chevron_right_rounded, color: p.text3),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        Text(
                          readiness?.message ?? 'Çözmeye başla — ilerlemen ve zayıf konuların burada belirir.',
                          style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.3),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        Row(
                          children: [
                            StatTile(value: '${answers.length}', label: 'soru', color: p.primary),
                            const SizedBox(width: AppSpacing.s5),
                            StatTile(value: '%$accuracy', label: 'doğruluk'),
                            const SizedBox(width: AppSpacing.s5),
                            StatTile(value: 'Lv ${level.level}', label: 'seviye', color: p.accent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s4),

            // Proactive nudge (real, deterministic).
            if (topNudge != null)
              CoachCard(
                message: '${topNudge.icon} ${topNudge.body}',
                actionLabel: topNudge.title,
                onAction: () => context.go(topNudge.action),
              ),

            SectionTitle('Bugünkü plan'),
            AppCard(
              child: Column(
                children: [
                  _PlanRow(
                    icon: Icons.bolt_rounded,
                    text: 'Akıllı çalışma oturumu (10 soru)',
                    done: streak.lastDay == _todayKey(now),
                  ),
                  Divider(height: AppSpacing.s6, color: p.border),
                  _PlanRow(
                    icon: Icons.refresh_rounded,
                    text: dueCount > 0
                        ? 'Tekrar zamanı gelen $dueCount kart'
                        : 'Vadesi gelen kart yok',
                    done: dueCount == 0 && answers.isNotEmpty,
                  ),
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
                  onTap: () => context.go('/practice/exam'),
                ),
                QuickAction(
                  icon: Icons.bolt_rounded,
                  label: 'Akıllı çalış',
                  color: p.accent,
                  onTap: () => context.go('/practice/study'),
                ),
                QuickAction(
                  icon: Icons.traffic_rounded,
                  label: 'İşaretler',
                  color: p.blue,
                  onTap: () => context.go('/learn/signs'),
                ),
                QuickAction(
                  icon: Icons.auto_awesome_rounded,
                  label: 'AI Koç',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => context.go('/coach'),
                ),
              ],
            ),

            SectionTitle('İlerleme'),
            OverviewTile(
              icon: Icons.insights_rounded,
              title: 'İstatistiklerim',
              subtitle: 'Radar, çalışma haritası, rozetler ve seviyeni gör',
              iconColor: p.primary,
              onTap: () => context.push('/progress'),
            ),
          ],
        ),
      ),
    );
  }

  static String _todayKey(int nowMs) {
    final d = DateTime.fromMillisecondsSinceEpoch(nowMs);
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${pad(d.month)}-${pad(d.day)}';
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
