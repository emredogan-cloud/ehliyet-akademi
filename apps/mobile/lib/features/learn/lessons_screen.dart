import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/premium/entitlements_repository.dart';
import '../../design/app_card.dart';
import '../../design/markdown_text.dart';
import '../../design/primitives.dart';
import '../../domain/content/content_enums.dart';
import '../../domain/content/content_queries.dart';
import '../../domain/content/lesson.dart';
import '../../domain/premium/products.dart';
import 'widgets/content_scope.dart';

/// Dersler — konuya göre gruplanmış liste. Kartlar detay ekranına götürür.
class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dersler')),
      body: SafeArea(
        top: false,
        child: ContentBuilder(
          builder: (context, snapshot) {
            final grouped = snapshot.lessonsBySubject();
            final subjects = Subject.values.where((s) => grouped.containsKey(s)).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s2,
                AppSpacing.s4,
                AppSpacing.s10,
              ),
              children: [
                for (final subject in subjects) ...[
                  SectionTitle(subject.label),
                  for (final lesson in grouped[subject]!) ...[
                    _LessonCard(lesson: lesson),
                    const SizedBox(height: AppSpacing.s3),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LessonCard extends ConsumerWidget {
  const _LessonCard({required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final owned = ref.watch(entitlementsProvider);
    final locked = !canAccessLesson(slug: lesson.slug, premium: lesson.premium, owned: owned);
    return AppCard(
      onTap: () => locked
          ? context.push('/premium?product=${productForLesson(lesson.slug).id}')
          : context.push('/learn/lessons/${lesson.slug}'),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.primary050,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(
              '${lesson.no}',
              style: TextStyle(fontWeight: FontWeight.w800, color: p.primary, fontSize: 15),
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lesson.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    if (lesson.premium) ...[
                      const SizedBox(width: AppSpacing.s2),
                      Icon(
                        locked ? Icons.lock_rounded : Icons.workspace_premium_rounded,
                        size: 16,
                        color: p.accent,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                MarkdownText(
                  lesson.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.35),
                ),
                const SizedBox(height: AppSpacing.s2),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 13, color: p.text3),
                    const SizedBox(width: 4),
                    Text(
                      '${lesson.minutes} dk',
                      style: TextStyle(color: p.text3, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Icon(Icons.checklist_rounded, size: 13, color: p.text3),
                    const SizedBox(width: 4),
                    Text(
                      '${lesson.objectives.length} hedef',
                      style: TextStyle(color: p.text3, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.text3),
        ],
      ),
    );
  }
}
