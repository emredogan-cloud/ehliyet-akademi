import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../design/primitives.dart';

/// Pratik hub — practice & exam modes overview. Runners (SRS practice, exam, collections,
/// historical) arrive in Phase 4; this hub is a complete, real overview.
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
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
            OverviewTile(
              icon: Icons.bolt_rounded,
              title: 'Akıllı Çalışma',
              subtitle: 'Aralıklı tekrar ile zayıf konulara odaklan',
              iconColor: p.accent,
            ),
            const SizedBox(height: AppSpacing.s3),
            OverviewTile(
              icon: Icons.timer_outlined,
              title: 'Deneme Sınavı',
              subtitle: '50 soru · 45 dk · MEB dağılımı (23/12/9/6)',
              iconColor: p.primary,
            ),
            const SizedBox(height: AppSpacing.s3),
            OverviewTile(
              icon: Icons.grid_view_rounded,
              title: 'Koleksiyonlar',
              subtitle: "Günün Sınavı, Zor Sorular, Yalnız İşaretler…",
              trailing: '10',
              iconColor: p.blue,
            ),
            const SizedBox(height: AppSpacing.s3),
            OverviewTile(
              icon: Icons.history_edu_rounded,
              title: 'Çıkmış Sınav Formatları',
              subtitle: 'MEB formatında hazırlanmış özgün deneme sınavları',
              iconColor: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: AppSpacing.s3),
            OverviewTile(
              icon: Icons.image_outlined,
              title: 'Görsel Quiz',
              subtitle: 'İşaret ve araç parçalarını görselinden tanı',
              iconColor: p.green,
            ),
          ],
        ),
      ),
    );
  }
}
