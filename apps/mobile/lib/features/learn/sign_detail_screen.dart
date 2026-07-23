import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
import '../../design/primitives.dart';
import '../../domain/content/content_queries.dart';
import '../../domain/content/traffic_sign.dart';
import 'widgets/content_scope.dart';
import 'widgets/traffic_sign_view.dart';

/// Trafik işareti detayı — büyük çizim + anlam + hafıza tekniği + sık hata + ilgili ders.
class SignDetailScreen extends StatelessWidget {
  const SignDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return ContentBuilder(
      builder: (context, snapshot) {
        final sign = snapshot.signById(id);
        if (sign == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const AppEmptyState(emoji: '🔍', title: 'İşaret bulunamadı'),
          );
        }
        final hasLesson = sign.relatedLessonSlug != null && snapshot.lessonBySlug(sign.relatedLessonSlug!) != null;
        return Scaffold(
          appBar: AppBar(title: Text(sign.name, overflow: TextOverflow.ellipsis)),
          body: SafeArea(top: false, child: _Body(sign: sign, hasLesson: hasLesson)),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.sign, required this.hasLesson});
  final TrafficSign sign;
  final bool hasLesson;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s10,
      ),
      children: [
        Center(
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.s6),
            child: TrafficSignView(sign: sign, size: 150),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(sign.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.s3),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s2,
          children: [
            _Chip(text: sign.category.label, color: p.blue),
            _Chip(text: 'Sınav önemi: ${sign.examImportance.label}', color: _importanceColor(sign, p)),
          ],
        ),
        const SizedBox(height: AppSpacing.s5),
        _LabeledCard(icon: Icons.info_outline_rounded, label: 'Anlamı', color: p.primary, body: sign.meaning),
        const SizedBox(height: AppSpacing.s3),
        AppCallout(text: sign.memoryTip, title: '🧠 Hafıza tekniği', tone: CalloutTone.success),
        if (sign.commonMistake != null) ...[
          const SizedBox(height: AppSpacing.s3),
          AppCallout(text: sign.commonMistake!, title: '⚠️ Sık yapılan hata', tone: CalloutTone.danger),
        ],
        if (sign.keywords.isNotEmpty) ...[
          const SectionTitle('Anahtar kelimeler'),
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [for (final k in sign.keywords) _Chip(text: k, color: p.text3)],
          ),
        ],
        if (hasLesson) ...[
          const SizedBox(height: AppSpacing.s5),
          OverviewTile(
            icon: Icons.menu_book_rounded,
            title: 'İlgili dersi aç',
            subtitle: 'Bu işaretin konusunu derinlemesine öğren',
            iconColor: p.primary,
            onTap: () => context.push('/learn/lessons/${sign.relatedLessonSlug}'),
          ),
        ],
      ],
    );
  }

  Color _importanceColor(TrafficSign s, AppPalette p) => switch (s.examImportance.label) {
    'Çok yüksek' => p.red,
    'Yüksek' => p.accent,
    _ => p.text3,
  };
}

class _LabeledCard extends StatelessWidget {
  const _LabeledCard({required this.icon, required this.label, required this.color, required this.body});
  final IconData icon;
  final String label;
  final Color color;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.s2),
              Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: p.text, fontSize: 13.5)),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(body, style: TextStyle(color: p.text2, height: 1.5, fontSize: 14)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
