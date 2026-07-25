import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/content_repository.dart';
import '../../domain/content/content_queries.dart';
import '../../domain/onboarding/study_profile.dart';
import '../../design/brand.dart';
import '../../domain/content/dash_lights.dart';
import '../../domain/content/vehicle_visuals.dart';

/// Öğren hub — öğrenme alanlarına giriş (dersler, işaretler, araç, videolar). Sayılar içerik
/// anlık görüntüsünden gelir; navigasyon içerik yüklenmeden de çalışır.
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final snapshot = ref.watch(contentSnapshotProvider).value;
    final counts = snapshot?.counts;
    final licence = ref.watch(studyProfileProvider).category;

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
              subtitle: snapshot != null && snapshot.licenceLessons(licence).isNotEmpty
                  ? 'Ortak teori + ${licence.badge} sınıfına özel dersler'
                  : 'Konu anlatımları, örnekler ve tekrar kartları',
              count: snapshot == null ? n(counts?.lessons) : '${snapshot.lessonCountFor(licence)}',
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
              count: snapshot == null ? '—' : '${snapshot.partCountFor(licence)}',
              onTap: () => context.push('/learn/vehicle'),
            ),
            const SizedBox(height: AppSpacing.s3),
            HubRow(
              icon: Icons.warning_amber_rounded,
              color: p.red,
              title: 'İkaz Işıkları',
              subtitle: 'Gösterge panelindeki uyarılar ve ne yapman gerektiği',
              count: '${kDashLights.length}',
              onTap: () => context.push('/learn/lights'),
            ),
            const SizedBox(height: AppSpacing.s3),
            HubRow(
              icon: Icons.toggle_on_rounded,
              color: p.blue,
              title: 'Kabin Kumandaları',
              subtitle: 'Gerçek düğme, kol ve soket fotoğraflarıyla tanıma',
              count: '${kCabinControls.length}',
              onTap: () => context.push('/learn/cabin'),
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
