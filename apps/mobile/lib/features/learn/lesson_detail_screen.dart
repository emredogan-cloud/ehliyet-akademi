import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
import '../../design/primitives.dart' as ui;
import '../../domain/content/content_enums.dart';
import '../../domain/content/content_queries.dart';
import '../../domain/content/lesson.dart';
import 'widgets/content_scope.dart';

/// Ders detayı — hedefler, bölümler (rozet + vurgu + karşılaştırma), hafıza teknikleri, sınav
/// stratejisi, sık hatalar, ipuçları, özet ve tekrar kartları. Web ders yapısıyla birebir.
class LessonDetailScreen extends StatelessWidget {
  const LessonDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context) {
    return ContentBuilder(
      builder: (context, snapshot) {
        final lesson = snapshot.lessonBySlug(slug);
        if (lesson == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const ui.AppEmptyState(emoji: '🔍', title: 'Ders bulunamadı'),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(lesson.title, overflow: TextOverflow.ellipsis)),
          body: SafeArea(top: false, child: _LessonBody(lesson: lesson)),
        );
      },
    );
  }
}

class _LessonBody extends StatelessWidget {
  const _LessonBody({required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        AppSpacing.s10,
      ),
      children: [
        // Başlık bloğu
        Row(
          children: [
            _Chip(text: lesson.subject.label, color: p.primary),
            const SizedBox(width: AppSpacing.s2),
            _Chip(text: '${lesson.minutes} dk', color: p.text3, icon: Icons.schedule_rounded),
            if (lesson.premium) ...[
              const SizedBox(width: AppSpacing.s2),
              _Chip(text: 'Premium', color: p.accent, icon: Icons.workspace_premium_rounded),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(lesson.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.s2),
        Text(lesson.summary, style: TextStyle(color: p.text2, height: 1.45, fontSize: 14.5)),

        // Hedefler
        if (lesson.objectives.isNotEmpty) ...[
          const ui.SectionTitle('Bu derste'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final o in lesson.objectives) _Bullet(o, icon: Icons.check_circle_rounded),
              ],
            ),
          ),
        ],

        // Bölümler
        for (final section in lesson.sections) ...[
          const SizedBox(height: AppSpacing.s5),
          _SectionView(section: section),
        ],

        // Hafıza teknikleri
        if (lesson.memoryTips.isNotEmpty)
          _ListBlock(
            title: 'Hafıza teknikleri',
            emoji: '🧠',
            items: lesson.memoryTips,
            tone: ui.CalloutTone.success,
          ),

        // Sınav stratejisi
        if (lesson.examStrategy.isNotEmpty)
          _ListBlock(
            title: 'Sınav stratejisi',
            emoji: '🎯',
            items: lesson.examStrategy,
            tone: ui.CalloutTone.info,
          ),

        // Sık hatalar
        if (lesson.mistakes.isNotEmpty) ...[
          const ui.SectionTitle('Sık yapılan hatalar'),
          for (final m in lesson.mistakes) ...[
            _MistakeCard(mistake: m),
            const SizedBox(height: AppSpacing.s3),
          ],
        ],

        // İpuçları
        if (lesson.tips.isNotEmpty)
          _ListBlock(
            title: 'İpuçları',
            emoji: '💡',
            items: lesson.tips,
            tone: ui.CalloutTone.warning,
          ),

        // Özet
        if (lesson.keyTakeaways.isNotEmpty) ...[
          const ui.SectionTitle('Özet'),
          AppCard(
            accent: p.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final k in lesson.keyTakeaways) _Bullet(k, icon: Icons.check_rounded),
              ],
            ),
          ),
        ],

        // Tekrar kartları
        if (lesson.reviewCards.isNotEmpty) ...[
          const ui.SectionTitle('Tekrar kartları'),
          for (final c in lesson.reviewCards) ...[
            _ReviewCardTile(card: c),
            const SizedBox(height: AppSpacing.s3),
          ],
        ],

        // Kaynaklar
        if (lesson.references.isNotEmpty) ...[
          const ui.SectionTitle('Kaynaklar'),
          for (final r in lesson.references)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $r', style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.4)),
            ),
        ],
      ],
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView({required this.section});
  final LessonSection section;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                section.heading,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5),
              ),
            ),
            if (section.badge != null) ...[
              const SizedBox(width: AppSpacing.s2),
              _Chip(text: section.badge!.label, color: p.blue),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(section.body, style: TextStyle(color: p.text2, height: 1.5, fontSize: 14)),
        if (section.callout != null) ...[
          const SizedBox(height: AppSpacing.s3),
          ui.AppCallout(
            text: section.callout!.text,
            title: section.callout!.title,
            tone: _toneOf(section.callout!.tone),
          ),
        ],
        if (section.compare != null) ...[
          const SizedBox(height: AppSpacing.s3),
          _CompareTableView(table: section.compare!),
        ],
      ],
    );
  }

  static ui.CalloutTone _toneOf(CalloutTone t) => switch (t) {
    CalloutTone.info => ui.CalloutTone.info,
    CalloutTone.success => ui.CalloutTone.success,
    CalloutTone.warning => ui.CalloutTone.warning,
    CalloutTone.danger => ui.CalloutTone.danger,
  };
}

class _CompareTableView extends StatelessWidget {
  const _CompareTableView({required this.table});
  final CompareTable table;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final border = TableBorder.symmetric(
      inside: BorderSide(color: p.border),
      outside: BorderSide(color: p.border),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (table.caption != null) ...[
          Text(table.caption!, style: TextStyle(color: p.text3, fontSize: 12.5)),
          const SizedBox(height: AppSpacing.s2),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Table(
            border: border,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: BoxDecoration(color: p.surface3),
                children: [
                  for (final h in table.headers) _cell(h, p, bold: true),
                ],
              ),
              for (final row in table.rows)
                TableRow(children: [for (final c in row) _cell(c, p)]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(String text, AppPalette p, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        height: 1.35,
        color: bold ? p.text : p.text2,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      ),
    ),
  );
}

class _ListBlock extends StatelessWidget {
  const _ListBlock({required this.title, required this.emoji, required this.items, required this.tone});
  final String title;
  final String emoji;
  final List<String> items;
  final ui.CalloutTone tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ui.SectionTitle('$emoji  $title'),
          for (final it in items) ...[
            ui.AppCallout(text: it, tone: tone),
            const SizedBox(height: AppSpacing.s2),
          ],
        ],
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  const _MistakeCard({required this.mistake});
  final LessonMistake mistake;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      accent: p.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, size: 16, color: p.red),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(mistake.text, style: TextStyle(color: p.text2, height: 1.4, fontSize: 13.5)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 16, color: p.green),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(
                  mistake.fix,
                  style: TextStyle(color: p.text, height: 1.4, fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewCardTile extends StatefulWidget {
  const _ReviewCardTile({required this.card});
  final ReviewCard card;

  @override
  State<_ReviewCardTile> createState() => _ReviewCardTileState();
}

class _ReviewCardTileState extends State<_ReviewCardTile> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      onTap: () => setState(() => _revealed = !_revealed),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.card.front, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          const SizedBox(height: AppSpacing.s2),
          AnimatedCrossFade(
            duration: AppMotion.base,
            crossFadeState: _revealed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: Row(
              children: [
                Icon(Icons.visibility_rounded, size: 15, color: p.primary),
                const SizedBox(width: 6),
                Text(
                  'Cevabı göster',
                  style: TextStyle(color: p.primary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.s3),
              decoration: BoxDecoration(
                color: p.primary050,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Text(widget.card.back, style: TextStyle(color: p.text, height: 1.45, fontSize: 13.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text, {required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: p.primary),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Text(text, style: TextStyle(color: p.text2, height: 1.4, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color, this.icon});
  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
