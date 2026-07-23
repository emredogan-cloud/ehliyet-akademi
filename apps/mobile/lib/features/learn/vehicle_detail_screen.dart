import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
import '../../design/markdown_text.dart';
import '../../design/primitives.dart';
import '../../domain/content/content_queries.dart';
import '../../domain/content/vehicle_part.dart';
import 'vehicle_screen.dart' show vehicleSystemIcon;
import 'widgets/content_scope.dart';

/// Araç bileşeni detayı — görev + ipucu + muayene adımları + sık hata + ilgili ders.
class VehicleDetailScreen extends StatelessWidget {
  const VehicleDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return ContentBuilder(
      builder: (context, snapshot) {
        final part = snapshot.partById(id);
        if (part == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const AppEmptyState(emoji: '🔍', title: 'Bileşen bulunamadı'),
          );
        }
        final hasLesson =
            part.relatedLessonSlug != null && snapshot.lessonBySlug(part.relatedLessonSlug!) != null;
        return Scaffold(
          appBar: AppBar(title: Text(part.name, overflow: TextOverflow.ellipsis)),
          body: SafeArea(top: false, child: _Body(part: part, hasLesson: hasLesson)),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.part, required this.hasLesson});
  final VehiclePart part;
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
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: p.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.base),
              ),
              child: Icon(vehicleSystemIcon(part.system), color: p.accent, size: 26),
            ),
            const SizedBox(width: AppSpacing.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(part.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(part.system.label, style: TextStyle(color: p.text3, fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s5),
        MarkdownText(part.desc, style: TextStyle(color: p.text2, height: 1.5, fontSize: 14.5)),
        const SizedBox(height: AppSpacing.s4),
        AppCallout(text: part.tip, title: '💡 İpucu', tone: CalloutTone.info),
        if (part.mistake != null) ...[
          const SizedBox(height: AppSpacing.s3),
          AppCallout(text: part.mistake!, title: '⚠️ Sık yapılan hata', tone: CalloutTone.danger),
        ],
        if (part.inspection.isNotEmpty) ...[
          const SectionTitle('Kontrol adımları'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < part.inspection.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.primary050,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(color: p.primary, fontWeight: FontWeight.w800, fontSize: 11.5),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s3),
                        Expanded(
                          child: MarkdownText(
                            part.inspection[i],
                            style: TextStyle(color: p.text2, height: 1.4, fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (hasLesson) ...[
          const SizedBox(height: AppSpacing.s5),
          OverviewTile(
            icon: Icons.menu_book_rounded,
            title: 'İlgili dersi aç',
            subtitle: 'Bu bileşenin konusunu derinlemesine öğren',
            iconColor: p.primary,
            onTap: () => context.push('/learn/lessons/${part.relatedLessonSlug}'),
          ),
        ],
      ],
    );
  }
}
