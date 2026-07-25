import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets.dart';
import '../../core/theme/tokens.dart';
import '../../design/brand.dart';
import '../../domain/onboarding/study_profile.dart';
import '../../domain/practice/collections.dart';
import '../../domain/practice/exam.dart';
import 'widgets/bank_scope.dart';

/// Sınav koleksiyonları — her gün yenilenen, temalı otomatik setler.
class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final licence = ref.watch(studyProfileProvider).category;
    final palette = [p.primary, p.primary, p.green, p.accent, p.red, p.purple, p.blue];
    return Scaffold(
      appBar: AppBar(title: const Text('Koleksiyonlar')),
      body: SafeArea(
        top: false,
        child: PracticeContentBuilder(
          builder: (context, bank) {
            final now = DateTime.now();
            String p2(int n) => n.toString().padLeft(2, '0');
            final daySeed = seedFromDate('${now.year}-${p2(now.month)}-${p2(now.day)}');
            final weekSeed = seedFromDate('week:${now.year}-${p2(now.month)}');
            final collections = examCollections(
              bank.questions,
              daySeed: daySeed,
              weekSeed: weekSeed,
              licence: licence,
            );
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s2, AppSpacing.s4, AppSpacing.s10),
              children: [
                HubHeader(
                  title: 'Koleksiyonlar',
                  subtitle: 'Konu bazlı soru koleksiyonları ile hedefine adım adım ilerle.',
                  mascot: AppImages.illFolder,
                  mascotHeight: 120,
                ),
                const SizedBox(height: AppSpacing.s5),
                for (var i = 0; i < collections.length; i++) ...[
                  _CollectionCard(collection: collections[i], color: palette[i % palette.length]),
                  const SizedBox(height: AppSpacing.s3),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.collection, required this.color});
  final CollectionSpec collection;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlowCard(
      onTap: () => context.push('/practice/collection/${collection.id}'),
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.26), color.withValues(alpha: 0.10)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Text(collection.emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(collection.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                const SizedBox(height: 3),
                Text(collection.description, style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          Column(
            children: [
              Text('${collection.count}', style: TextStyle(color: p.primary, fontWeight: FontWeight.w900, fontSize: 18)),
              Text('soru', style: TextStyle(color: p.text3, fontSize: 11)),
            ],
          ),
          Icon(Icons.chevron_right_rounded, color: p.text3),
        ],
      ),
    );
  }
}
