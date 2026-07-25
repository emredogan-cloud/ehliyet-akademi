import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/community/community_repository.dart';
import '../../design/brand.dart';
import '../../design/primitives.dart';
import '../../domain/community/community_models.dart';

/// Evolution Faz E9 — engellenen kullanıcılar ve **engel kaldırma**.
///
/// Engellemek tek yönlü bir eylem olmamalı: kullanıcı kimi engellediğini görebilmeli ve geri
/// alabilmelidir. Engel kaldırıldığında sunucu erişimi tekrar açar (sıralama, profil, mesaj).
class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  Future<List<BlockedUser>>? _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    if (!mounted) return;
    final future = ref.read(communityApiProvider).fetchBlocked();
    unawaited(future.catchError((Object _) => <BlockedUser>[]));
    setState(() {
      _future = future;
    });
  }

  Future<void> _unblock(BlockedUser u) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(communityApiProvider).unblock(u.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${u.displayName} için engel kaldırıldı.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Engel kaldırılamadı.')));
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
      appBar: AppBar(title: const Text('Engellenenler')),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<BlockedUser>>(
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
                  title: 'Liste alınamadı',
                  subtitle: 'Bağlantını kontrol edip tekrar dene.',
                  action: FilledButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Tekrar dene'),
                  ),
                ),
              );
            }
            final blocked = snap.data ?? const <BlockedUser>[];
            if (blocked.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.s4),
                child: AppEmptyState(
                  emoji: '🛡️',
                  title: 'Kimseyi engellemedin',
                  subtitle:
                      'Rahatsız eden birini profilinden engelleyebilirsin; engellediklerin burada listelenir.',
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s3,
                AppSpacing.s4,
                AppSpacing.s10,
              ),
              itemCount: blocked.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s2),
              itemBuilder: (context, i) {
                final u = blocked[i];
                return GlowCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s3,
                    vertical: AppSpacing.s3,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: MascotImage(
                          CommunityAvatar.fromId(u.avatarId).asset,
                          height: 44,
                          semanticLabel: u.displayName,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: Text(
                          u.displayName.isEmpty ? 'Bilinmeyen kullanıcı' : u.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                        ),
                      ),
                      TextButton(
                        onPressed: _busy ? null : () => _unblock(u),
                        style: TextButton.styleFrom(foregroundColor: p.primary),
                        child: const Text('Engeli kaldır'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
