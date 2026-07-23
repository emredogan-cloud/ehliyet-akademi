import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/content/content_repository.dart';
import '../../design/primitives.dart';

/// Öğren hub — öğrenme alanlarına giriş (dersler, işaretler, araç, videolar). Sayılar içerik
/// anlık görüntüsünden gelir; navigasyon içerik yüklenmeden de çalışır.
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final counts = ref.watch(contentSnapshotProvider).value?.counts;

    String? n(int? v) => v == null ? null : '$v';

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
              trailing: n(counts?.lessons),
              iconColor: p.primary,
              onTap: () => context.push('/learn/lessons'),
            ),
            const SizedBox(height: AppSpacing.s3),
            OverviewTile(
              icon: Icons.traffic_rounded,
              title: 'Trafik İşaretleri',
              subtitle: 'Kategorilere ayrılmış işaret galerisi',
              trailing: n(counts?.signs),
              iconColor: p.blue,
              onTap: () => context.push('/learn/signs'),
            ),
            const SizedBox(height: AppSpacing.s3),
            OverviewTile(
              icon: Icons.directions_car_rounded,
              title: 'Araç Tekniği',
              subtitle: 'Motor, gösterge paneli ve araç bileşenleri',
              trailing: n(counts?.vehicleParts),
              iconColor: p.accent,
              onTap: () => context.push('/learn/vehicle'),
            ),
            const SizedBox(height: AppSpacing.s3),
            OverviewTile(
              icon: Icons.play_circle_outline_rounded,
              title: 'Videolar',
              subtitle: 'Kısa, öz anlatım videoları',
              trailing: n(counts?.videos),
              iconColor: const Color(0xFF8B5CF6),
              onTap: () => context.push('/learn/videos'),
            ),
          ],
        ),
      ),
    );
  }
}
