import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../design/primitives.dart';

/// Öğren hub — the learning areas overview. Detail screens (lessons/signs/vehicle/videos) arrive
/// in Phase 3; this hub is a complete, real overview.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Öğren')),
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
              title: 'Öğrenme',
              emoji: '📚',
              subtitle: 'Dersler, trafik işaretleri, araç tekniği ve videolarla temeli sağlam at.',
            ),
            const SizedBox(height: AppSpacing.s2),
            OverviewTile(
              icon: Icons.menu_book_rounded,
              title: 'Dersler',
              subtitle: 'Konu anlatımları, örnekler ve tekrar kartları',
              iconColor: p.primary,
            ),
            const SizedBox(height: AppSpacing.s3),
            OverviewTile(
              icon: Icons.traffic_rounded,
              title: 'Trafik İşaretleri',
              subtitle: 'Kategorilere ayrılmış işaret galerisi',
              trailing: '121',
              iconColor: p.blue,
            ),
            const SizedBox(height: AppSpacing.s3),
            OverviewTile(
              icon: Icons.directions_car_rounded,
              title: 'Araç Tekniği',
              subtitle: 'Motor, gösterge paneli ve araç bileşenleri',
              iconColor: p.accent,
            ),
            const SizedBox(height: AppSpacing.s3),
            OverviewTile(
              icon: Icons.play_circle_outline_rounded,
              title: 'Videolar',
              subtitle: 'Kısa, öz anlatım videoları',
              trailing: '8',
              iconColor: const Color(0xFF8B5CF6),
            ),
          ],
        ),
      ),
    );
  }
}
