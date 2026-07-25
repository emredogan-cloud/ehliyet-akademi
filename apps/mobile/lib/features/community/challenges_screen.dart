import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/community/community_repository.dart';
import '../../data/community/groups_repository.dart';
import '../../design/app_card.dart';
import '../../design/primitives.dart';
import '../../domain/community/group_models.dart';

/// Evolution Faz E10 — topluluk meydan okumaları.
///
/// İLERLEME İSTEMCİDEN BİLDİRİLMEZ. Sunucu, E8'de kırpılmış istatistiklerden türetir; bu ekran
/// yalnız gösterir. Bu yüzden "ilerlemeyi güncelle" düğmesi YOKTUR — çalıştıkça ilerler.
class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  Future<List<Challenge>>? _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    if (!mounted) return;
    final future = ref.read(groupsApiProvider).fetchChallenges();
    unawaited(future.catchError((Object _) => <Challenge>[]));
    setState(() {
      _future = future;
    });
  }

  Future<void> _join(Challenge c) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(groupsApiProvider).joinChallenge(c.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Katıldın. Çalıştıkça ilerlemen kendiliğinden işlenir.')),
        );
      }
    } on CommunityException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('İşlem yapılamadı. Bağlantını kontrol et.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meydan okumalar'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<Challenge>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: AppEmptyState(
                  emoji: '📡',
                  title: 'Meydan okumalar alınamadı',
                  subtitle: 'Bu bölüm internet gerektirir. Bağlantını kontrol et.',
                  action: FilledButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Tekrar dene'),
                  ),
                ),
              );
            }
            final items = snap.data ?? const <Challenge>[];
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.s4),
                child: AppEmptyState(
                  emoji: '🎯',
                  title: 'Şu an etkin meydan okuma yok',
                  subtitle: 'Yeni meydan okumalar başladığında burada görünür.',
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s4,
                AppSpacing.s4,
                AppSpacing.s10,
              ),
              children: [
                for (final c in items) ...[
                  _ChallengeCard(challenge: c, busy: _busy, onJoin: () => _join(c)),
                  const SizedBox(height: AppSpacing.s3),
                ],
                const SizedBox(height: AppSpacing.s2),
                Text(
                  'İlerlemen çalışmalarından kendiliğinden hesaplanır — elle bildirim yoktur, '
                  'bu yüzden kimse ilerlemesini şişiremez.',
                  style: TextStyle(color: p.text3, fontSize: 12, height: 1.4),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge, required this.busy, required this.onJoin});
  final Challenge challenge;
  final bool busy;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = challenge;
    return AppCard(
      accent: c.done ? p.green : (c.joined ? p.primary : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              if (c.done)
                Icon(Icons.check_circle_rounded, color: p.green, size: 20)
              else if (c.joined)
                Text(
                  '%${c.percent}',
                  style: TextStyle(color: p.primary, fontWeight: FontWeight.w900),
                ),
            ],
          ),
          if (c.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(c.description, style: TextStyle(color: p.text2, fontSize: 13, height: 1.4)),
          ],
          const SizedBox(height: AppSpacing.s3),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: (c.percent / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: p.surface2,
              valueColor: AlwaysStoppedAnimation<Color>(c.done ? p.green : p.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${c.value} / ${c.target} ${c.metricLabel}',
                  style: TextStyle(color: p.text3, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              if (!c.joined)
                FilledButton(
                  onPressed: busy ? null : onJoin,
                  child: const Text('Katıl'),
                )
              else if (c.done)
                Text(
                  'Tamamlandı',
                  style: TextStyle(color: p.green, fontWeight: FontWeight.w800, fontSize: 13),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
