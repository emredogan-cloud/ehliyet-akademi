import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/practice/progress_repository.dart';
import '../../design/app_card.dart';
import '../../design/primitives.dart';
import '../../domain/content/content_enums.dart';
import '../../domain/practice/srs.dart';
import '../../domain/progress/gamification.dart';
import 'widgets/readiness_radar.dart';
import 'widgets/study_heatmap.dart';

/// İlerleme & oyunlaştırma — seviye/XP, ders bazlı radar, çalışma ısı haritası, rozetler.
/// Tümü yerel cevap/seri/sayaç verilerinden (çevrimdışı).
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  static const _shortLabel = {
    Subject.trafik: 'Trafik',
    Subject.ilkyardim: 'İlk Yardım',
    Subject.motor: 'Araç Tekniği',
    Subject.adab: 'Trafik Adabı',
  };
  static const _theory = [Subject.trafik, Subject.ilkyardim, Subject.motor, Subject.adab];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('İlerleme')),
      body: SafeArea(
        top: false,
        child: ref
            .watch(progressRepositoryProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const AppEmptyState(emoji: '⚠️', title: 'İlerleme yüklenemedi'),
              data: (progress) {
                final answers = progress.loadAnswers();
                if (answers.isEmpty) {
                  return const AppEmptyState(
                    emoji: '📊',
                    title: 'Henüz veri yok',
                    subtitle: 'Birkaç soru çözünce ilerlemen, radar grafiğin ve rozetlerin burada belirir.',
                  );
                }
                return _Body(progress: progress);
              },
            ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.progress});
  final ProgressRepository progress;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final answers = progress.loadAnswers();
    final streak = progress.loadStreak();
    final exams = progress.examsFinished();
    final correct = answers.where((a) => a.correct).length;
    final accuracy = answers.isEmpty ? 0 : (correct / answers.length * 100).round();
    final xp = xpFromAnswers(answers);
    final level = levelForXp(xp);
    final stats = statsFromAnswers(answers);
    final masteryBySubject = {for (final s in stats.subjects) s.subject: s.mastery};
    final axes = [
      for (final s in ProgressScreen._theory)
        (label: ProgressScreen._shortLabel[s]!, value: masteryBySubject[s] ?? 0.0),
    ];
    final achievements = computeAchievements(answers: answers, streak: streak, examsFinished: exams);
    final unlocked = achievements.where((a) => a.unlocked).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s3, AppSpacing.s4, AppSpacing.s10),
      children: [
        // Seviye + XP
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.primary050,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text('${level.level}',
                        style: TextStyle(color: p.primary, fontWeight: FontWeight.w800, fontSize: 20)),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seviye ${level.level}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text('$xp XP · sonraki seviyeye ${level.xpToNext} XP',
                            style: TextStyle(color: p.text3, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s3),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: LinearProgressIndicator(
                  value: level.progress,
                  minHeight: 8,
                  backgroundColor: p.surface3,
                  color: p.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        // Hızlı istatistikler
        Row(
          children: [
            _StatBox(value: '${answers.length}', label: 'Soru', color: p.primary),
            _StatBox(value: '%$accuracy', label: 'Doğruluk', color: p.green),
            _StatBox(value: '${streak.current}', label: 'Seri', color: p.accent),
            _StatBox(value: '$exams', label: 'Deneme', color: p.blue),
          ],
        ),
        // Radar
        const SectionTitle('Ders bazında ustalık'),
        AppCard(
          child: Center(child: ReadinessRadar(axes: axes)),
        ),
        // Isı haritası
        const SectionTitle('Çalışma haritası'),
        AppCard(child: StudyHeatmap(perDay: answersPerDay(answers))),
        // Rozetler
        SectionTitle('Rozetler  ·  $unlocked/${achievements.length}'),
        Wrap(
          spacing: AppSpacing.s3,
          runSpacing: AppSpacing.s3,
          children: [for (final a in achievements) _Badge(achievement: a)],
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AppRadii.base),
          border: Border.all(color: p.border),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11.5, color: p.text3)),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.achievement});
  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = achievement.unlocked;
    final width = (MediaQuery.sizeOf(context).width - AppSpacing.s4 * 2 - AppSpacing.s3 * 2) / 3;
    return SizedBox(
      width: width,
      child: Opacity(
        opacity: on ? 1 : 0.45,
        child: AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3, horizontal: AppSpacing.s2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(on ? achievement.icon : '🔒', style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                achievement.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.text),
              ),
              const SizedBox(height: 2),
              Text(
                achievement.description,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: p.text3, height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
