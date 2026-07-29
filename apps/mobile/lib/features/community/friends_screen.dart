import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/community/community_repository.dart';
import '../../data/community/social_repository.dart';
import '../../design/brand.dart';
import '../../design/primitives.dart';
import '../../domain/community/social_models.dart';

/// Evolution Faz E9 — arkadaşlar ve bekleyen istekler.
///
/// Üç bölüm: **gelen istekler** (kabul/reddet), **gönderilen istekler** (geri al), **arkadaşlar**
/// (mesaj/çıkar). Her eylem sunucuya gider ve liste tazelenir; iyimser güncelleme YAPILMAZ —
/// sunucu engel/durum kurallarının tek sahibidir.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  Future<FriendsPage>? _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    if (!mounted) return;
    final future = ref.read(socialApiProvider).fetchFriends();
    // Hata, FutureBuilder bağlanmadan gelirse "yakalanmamış hata" olmasın (E8'de öğrenildi).
    unawaited(future.catchError((Object _) => FriendsPage.empty));
    setState(() {
      _future = future;
    });
  }

  Future<void> _act(Future<void> Function() action, String okMessage) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(okMessage)));
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
        title: const Text('Arkadaşlar'),
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
        child: FutureBuilder<FriendsPage>(
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
                  title: 'Arkadaşlar alınamadı',
                  subtitle: 'Sosyal özellikler internet gerektirir. Bağlantını kontrol et.',
                  action: FilledButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Tekrar dene'),
                  ),
                ),
              );
            }
            final page = snap.data ?? FriendsPage.empty;
            if (page.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.s4),
                child: AppEmptyState(
                  emoji: '👋',
                  title: 'Henüz arkadaşın yok',
                  subtitle:
                      'Sıralamada birine dokunup profilinden arkadaşlık isteği gönderebilirsin.',
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s2,
                AppSpacing.s4,
                AppSpacing.s10,
              ),
              children: [
                if (page.incoming.isNotEmpty) ...[
                  SectionTitle('Gelen istekler  ·  ${page.incoming.length}'),
                  for (final f in page.incoming) ...[
                    _FriendCard(
                      entry: f,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Kabul et',
                            onPressed: _busy
                                ? null
                                : () => _act(
                                    () => ref
                                        .read(socialApiProvider)
                                        .acceptFriendRequest(f.userId),
                                    '${f.displayName} artık arkadaşın.',
                                  ),
                            icon: Icon(Icons.check_circle_rounded, color: p.green),
                          ),
                          IconButton(
                            tooltip: 'Reddet',
                            onPressed: _busy
                                ? null
                                : () => _act(
                                    () => ref.read(socialApiProvider).removeFriend(f.userId),
                                    'İstek reddedildi.',
                                  ),
                            icon: Icon(Icons.cancel_rounded, color: p.text3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                  ],
                ],
                if (page.outgoing.isNotEmpty) ...[
                  SectionTitle('Gönderilen istekler  ·  ${page.outgoing.length}'),
                  for (final f in page.outgoing) ...[
                    _FriendCard(
                      entry: f,
                      subtitleOverride: 'Yanıt bekleniyor',
                      trailing: TextButton(
                        onPressed: _busy
                            ? null
                            : () => _act(
                                () => ref.read(socialApiProvider).removeFriend(f.userId),
                                'İstek geri alındı.',
                              ),
                        child: const Text('Geri al'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                  ],
                ],
                if (page.friends.isNotEmpty) ...[
                  SectionTitle('Arkadaşların  ·  ${page.friends.length}'),
                  for (final f in page.friends) ...[
                    _FriendCard(
                      entry: f,
                      onTap: () => context.push('/community/chat/${f.userId}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Mesaj gönder',
                            onPressed: () =>
                                context.push('/community/chat/${f.userId}'),
                            icon: Icon(Icons.chat_bubble_outline_rounded, color: p.primary),
                          ),
                          IconButton(
                            tooltip: 'Arkadaşlıktan çıkar',
                            onPressed: _busy ? null : () => _confirmRemove(f),
                            icon: Icon(Icons.person_remove_rounded, color: p.text3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmRemove(FriendEntry f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${f.displayName} çıkarılsın mı?'),
        content: const Text('Arkadaşlıktan çıkarırsan mesajlaşmanız da sona erer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Çıkar')),
        ],
      ),
    );
    if (ok != true) return;
    await _act(
      () => ref.read(socialApiProvider).removeFriend(f.userId),
      '${f.displayName} arkadaşlıktan çıkarıldı.',
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.entry,
    required this.trailing,
    this.onTap,
    this.subtitleOverride,
  });

  final FriendEntry entry;
  final Widget trailing;
  final VoidCallback? onTap;
  final String? subtitleOverride;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlowCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s3),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: MascotImage(entry.avatar.asset, height: 44, semanticLabel: entry.displayName),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                ),
                Text(
                  subtitleOverride ?? '${entry.licence.toUpperCase()} sınıfı',
                  style: TextStyle(color: p.text3, fontSize: 12),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
