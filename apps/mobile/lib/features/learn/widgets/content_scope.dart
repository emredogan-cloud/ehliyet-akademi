import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../data/content/content_repository.dart';
import '../../../design/primitives.dart';
import '../../../domain/content/content_snapshot.dart';

/// İçerik anlık görüntüsünü (yükleniyor / hata / veri) yöneten ortak sarmalayıcı. Çevrimdışı-öncelik:
/// önbellek varsa hemen veri gelir; ilk kez çevrimiçi indirme başarısızsa tekrar-dene hata durumu.
class ContentBuilder extends ConsumerWidget {
  const ContentBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, ContentSnapshot snapshot) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contentSnapshotProvider);
    return async.when(
      data: (snapshot) => builder(context, snapshot),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ContentError(onRetry: () => ref.invalidate(contentSnapshotProvider)),
    );
  }
}

class _ContentError extends StatelessWidget {
  const _ContentError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: AppEmptyState(
        emoji: '📡',
        title: 'İçerik yüklenemedi',
        subtitle: 'İnternet bağlantını kontrol edip tekrar dene. İlk indirmeden sonra içerik çevrimdışı çalışır.',
        action: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Tekrar dene'),
        ),
      ),
    );
  }
}
