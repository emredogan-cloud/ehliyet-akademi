import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
import '../../design/primitives.dart';
import '../../domain/content/video_content.dart';
import 'widgets/content_scope.dart';

/// Göreli medya yolunu (ör. `/videos/x.mp4`) API tabanına göre mutlak URL'ye çevirir.
String absoluteMediaUrl(String path) {
  if (path.startsWith('http')) return path;
  final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
  return '$base$path';
}

/// Videolar — oynatılabilir (available) ve yakında (planned) ayrımıyla dürüst liste.
class VideosScreen extends StatelessWidget {
  const VideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Videolar')),
      body: SafeArea(
        top: false,
        child: ContentBuilder(
          builder: (context, snapshot) {
            final available = snapshot.videos.where((v) => v.isAvailable).toList();
            final planned = snapshot.videos.where((v) => !v.isAvailable).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s2,
                AppSpacing.s4,
                AppSpacing.s10,
              ),
              children: [
                if (available.isNotEmpty) ...[
                  const SectionTitle('İzlenebilir'),
                  for (final v in available) ...[
                    _VideoCard(video: v),
                    const SizedBox(height: AppSpacing.s3),
                  ],
                ],
                if (planned.isNotEmpty) ...[
                  const SectionTitle('Yakında'),
                  for (final v in planned) ...[
                    _VideoCard(video: v),
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

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video});
  final VideoContent video;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final available = video.isAvailable;
    return AppCard(
      onTap: available ? () => context.push('/learn/videos/${video.id}') : null,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.base)),
              child: _Thumb(video: video, available: available),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(video.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  video.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.video, required this.available});
  final VideoContent video;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (video.poster != null)
          Image.network(
            absoluteMediaUrl(video.poster!),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => ColoredBox(color: p.surface3),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [p.primary.withValues(alpha: 0.25), p.blue.withValues(alpha: 0.18)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: Icon(
              available ? Icons.play_arrow_rounded : Icons.lock_clock_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.s2,
          top: AppSpacing.s2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 3),
            decoration: BoxDecoration(
              color: (available ? p.green : p.text3).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(
              available ? 'İZLE' : 'YAKINDA',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10),
            ),
          ),
        ),
        if (available && video.duration != null)
          Positioned(
            right: AppSpacing.s2,
            bottom: AppSpacing.s2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _fmt(video.duration!),
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  static String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
