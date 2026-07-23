import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../data/practice/question_repository.dart';
import '../../../design/primitives.dart';
import '../../../domain/practice/question_bank.dart';

/// Soru bankasını (yükleniyor / hata / veri) yöneten ortak sarmalayıcı. Çevrimdışı-öncelik:
/// önbellek varsa hemen; ilk indirme başarısızsa tekrar-dene.
class PracticeContentBuilder extends ConsumerWidget {
  const PracticeContentBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, QuestionBank bank) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(questionBankProvider);
    return async.when(
      data: (bank) => builder(context, bank),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _BankError(onRetry: () => ref.invalidate(questionBankProvider)),
    );
  }
}

class _BankError extends StatelessWidget {
  const _BankError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: AppEmptyState(
        emoji: '📡',
        title: 'Sorular yüklenemedi',
        subtitle: 'İnternet bağlantını kontrol edip tekrar dene. İlk indirmeden sonra sorular çevrimdışı çalışır.',
        action: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Tekrar dene'),
        ),
      ),
    );
  }
}
