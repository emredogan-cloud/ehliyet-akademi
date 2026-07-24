import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/content_repository.dart';
import '../../design/brand.dart';

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
          padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s2, AppSpacing.s4, AppSpacing.s10),
          children: [
            const HubHeader(
              title: 'Öğrenme',
              subtitle: 'Dersler, trafik işaretleri, araç tekniği ve videolarla temeli sağlam at.',
              mascot: AppImages.owlReading,
            ),
            const SizedBox(height: AppSpacing.s5),
            HubRow(
              icon: Icons.menu_book_rounded,
              color: p.primary,
              title: 'Dersler',
              subtitle: 'Konu anlatımları, örnekler ve tekrar kartları',
              count: n(counts?.lessons),
              onTap: () => context.push('/learn/lessons'),
            ),
            const SizedBox(height: AppSpacing.s3),
            HubRow(
              icon: Icons.traffic_rounded,
              color: p.blue,
              title: 'Trafik İşaretleri',
              subtitle: 'Kategorilere ayrılmış işaret galerisi',
              count: n(counts?.signs),
              onTap: () => context.push('/learn/signs'),
            ),
            const SizedBox(height: AppSpacing.s3),
            HubRow(
              icon: Icons.directions_car_rounded,
              color: p.accent,
              title: 'Araç Tekniği',
              subtitle: 'Motor, gösterge paneli ve araç bileşenleri',
              count: n(counts?.vehicleParts),
              onTap: () => context.push('/learn/vehicle'),
            ),
            const SizedBox(height: AppSpacing.s3),
            HubRow(
              icon: Icons.play_circle_outline_rounded,
              color: p.purple,
              title: 'Videolar',
              subtitle: 'Kısa, öz anlatım videoları',
              count: n(counts?.videos),
              onTap: () => context.push('/learn/videos'),
            ),
          ],
        ),
      ),
    );
  }
}
