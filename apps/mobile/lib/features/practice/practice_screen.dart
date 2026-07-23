import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/practice/progress_repository.dart';
import '../../data/premium/entitlements_repository.dart';
import '../../data/premium/quota_repository.dart';
import '../../design/app_card.dart';
import '../../design/primitives.dart';
import '../../domain/practice/srs.dart';

/// Pratik hub — akıllı çalışma, deneme sınavı, koleksiyonlar, geçmiş sınavlar + hazırlık özeti.
class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final progress = ref.watch(progressRepositoryProvider).value;
    final answers = progress?.loadAnswers() ?? const [];
    final readiness = answers.isNotEmpty ? progress!.readiness() : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Pratik')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s2,
            AppSpacing.s4,
            AppSpacing.s10,
          ),
          children: [
            const AppPageHeader(
              title: 'Pratik & Sınav',
              emoji: '🎯',
              subtitle: 'Akıllı çalışma, gerçek MEB formatında denemeler ve koleksiyonlarla pekiştir.',
            ),
            const SizedBox(height: AppSpacing.s2),
            if (readiness != null) ...[
              _ReadinessCard(readiness: readiness, answered: answers.length),
              const SizedBox(height: AppSpacing.s4),
            ],
            OverviewTile(
              icon: Icons.bolt_rounded,
              title: 'Akıllı Çalışma',
              subtitle: 'Aralıklı tekrar ile zayıf konulara odaklan',
              iconColor: p.accent,
              onTap: () => context.push('/practice/study'),
            ),
            const SizedBox(height: AppSpacing.s3),
            OverviewTile(
              icon: Icons.timer_outlined,
              title: 'Deneme Sınavı',
              subtitle: '50 soru · 45 dk · MEB dağılımı (23/12/9/6)',
              iconColor: p.primary,
              onTap: () {
                final owned = ref.read(entitlementsProvider);
                final quota = ref.read(quotaRepositoryProvider).value;
                if (quota != null && !quota.canStartExam(owned)) {
                  context.push('/premium?product=simulator-paketi');
                  return;
                }
                quota?.consumeExam(owned);
                context.push('/practice/exam');
              },
            ),
            const SizedBox(height: AppSpacing.s3),
            OverviewTile(
              icon: Icons.grid_view_rounded,
              title: 'Koleksiyonlar',
              subtitle: 'Günün Sınavı, Zor Sorular, Yalnız İşaretler…',
              iconColor: p.blue,
              onTap: () => context.push('/practice/collections'),
            ),
            const SizedBox(height: AppSpacing.s3),
            OverviewTile(
              icon: Icons.history_edu_rounded,
              title: 'Geçmiş Sınavlar',
              subtitle: 'MEB formatında hazırlanmış özgün deneme sınavları',
              iconColor: const Color(0xFF8B5CF6),
              onTap: () => context.push('/practice/historical'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.readiness, required this.answered});
  final Readiness readiness;
  final int answered;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = switch (readiness.light) {
      TrafficLight.yesil => p.green,
      TrafficLight.sari => p.accent,
      TrafficLight.kirmizi => p.red,
    };
    return AppCard(
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Sınava hazırlık', style: TextStyle(fontWeight: FontWeight.w700, color: p.text)),
              const Spacer(),
              Text('%${readiness.overall}',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: readiness.overall / 100,
              minHeight: 8,
              backgroundColor: p.surface3,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(readiness.message, style: TextStyle(color: p.text2, height: 1.4, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            'Tahmini geçme olasılığı %${(readiness.predictedPassProbability * 100).round()} · $answered cevap',
            style: TextStyle(color: p.text3, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
