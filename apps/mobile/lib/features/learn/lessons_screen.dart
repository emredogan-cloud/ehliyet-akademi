import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/premium/entitlements_repository.dart';
import '../../design/app_card.dart';
import '../../design/markdown_text.dart';
import '../../design/primitives.dart';
// `CalloutTone` hem içerik enum'unda hem tasarım primitifinde var → yalnız gerekeni al.
import '../../domain/content/content_enums.dart' show Subject;
import '../../domain/content/content_queries.dart';
import '../../domain/content/lesson.dart';
import '../../domain/onboarding/study_profile.dart';
import '../../domain/premium/products.dart';
import 'widgets/content_scope.dart';

/// Dersler — seçilen ehliyet sınıfına göre kapsamlanmış liste (Faz E5).
/// Sınıfa ÖZGÜ dersler en üstte kendi bölümünde, ortak teori dersleri altında konuya göre gruplanır.
class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licence = ref.watch(studyProfileProvider).category;
    return Scaffold(
      appBar: AppBar(title: Text('Dersler · ${licence.badge}')),
      body: SafeArea(
        top: false,
        child: ContentBuilder(
          builder: (context, snapshot) {
            final specific = snapshot.licenceLessons(licence);
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
                if (specific.isNotEmpty) ...[
                  SectionTitle('Sınıfına özel · ${licence.badge} ${licence.title}'),
                  const AppCallout(
                    tone: CalloutTone.info,
                    text:
                        'Teori sınavı tüm sınıflarda **ortaktır**. Bu dersler ortak teoriye **ek** olarak, sınıfının araç kullanma tekniğini, mekaniğini ve mevzuat farkını anlatır.',
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  for (final lesson in specific) ...[
                    _LessonCard(lesson: lesson, licenceBadge: licence.badge),
                    const SizedBox(height: AppSpacing.s3),
                  ],
                ],
                for (final subject in subjects) ...[
                  SectionTitle(subject.label),
                  for (final lesson in grouped[subject]!.where((l) => l.licences.isEmpty)) ...[
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
  const _LessonCard({required this.lesson, this.licenceBadge});
  final Lesson lesson;

  /// Doluysa kartta sınıf rozeti gösterilir ("Sınıfına özel" bölümündeki dersler).
  final String? licenceBadge;

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
                    if (licenceBadge != null) ...[
                      const SizedBox(width: AppSpacing.s2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.green.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          border: Border.all(color: p.green.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          licenceBadge!,
                          style: TextStyle(
                            color: p.green,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
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
                // Beta Faz 11 — üstveri satırı 320 dp'de taşıyordu (17 px). İki rozet yan yana
                // sığmadığında ALT SATIRA geçer; kırpmak yerine sarmak doğru: "12 dk" ve
                // "3 hedef" ikisi de okunabilir kalmalı.
                Wrap(
                  spacing: AppSpacing.s3,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule_rounded, size: 13, color: p.text3),
                        const SizedBox(width: 4),
                        Text(
                          '${lesson.minutes} dk',
                          style: TextStyle(color: p.text3, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.text3),
        ],
      ),
    );
  }
}
