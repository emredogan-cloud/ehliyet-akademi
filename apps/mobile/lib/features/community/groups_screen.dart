import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/community/community_repository.dart';
import '../../data/community/groups_repository.dart';
import '../../design/app_card.dart';
import '../../design/primitives.dart';
import '../../domain/community/group_models.dart';

/// Evolution Faz E10 — çalışma gruplarım.
///
/// Grup kurma ve **kodla katılma** aynı ekrandan yapılır; kod insan tarafından okunup yazılabilen
/// 6 karakterdir (karışan harfler alfabede yok). Tavanlar sunucudadır; istemci yalnız sunucunun
/// döndürdüğü hatayı gösterir — kuralı ikinci kez uygulamaya çalışmaz.
class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  Future<List<StudyGroup>>? _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    if (!mounted) return;
    final future = ref.read(groupsApiProvider).fetchGroups();
    unawaited(future.catchError((Object _) => <StudyGroup>[]));
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
        title: const Text('Çalışma grupları'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : () => _showCreateSheet(context),
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('Grup kur'),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<StudyGroup>>(
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
                  title: 'Gruplar alınamadı',
                  subtitle: 'Çalışma grupları internet gerektirir. Bağlantını kontrol et.',
                  action: FilledButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Tekrar dene'),
                  ),
                ),
              );
            }
            final groups = snap.data ?? const <StudyGroup>[];
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s4,
                AppSpacing.s4,
                AppSpacing.s10,
              ),
              children: [
                _JoinByCodeCard(busy: _busy, onJoin: _joinByCode),
                const SizedBox(height: AppSpacing.s4),
                if (groups.isEmpty)
                  const AppEmptyState(
                    emoji: '👥',
                    title: 'Henüz grubun yok',
                    subtitle:
                        'Bir grup kur ve kodu arkadaşlarınla paylaş; ya da sana verilen kodla katıl.',
                  )
                else ...[
                  SectionTitle('Gruplarım  ·  ${groups.length}'),
                  for (final g in groups) ...[
                    _GroupCard(
                      group: g,
                      onOpen: () => context.push('/community/groups/${g.id}'),
                      onCopy: () => _copyCode(g.joinCode),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                  ],
                ],
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'Grup istatistikleri üyelerin doğrulanmış sayaçlarından toplanır — kimse elle '
                  'değer giremez.',
                  style: TextStyle(color: p.text3, fontSize: 12, height: 1.4),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Katılım kodu kopyalandı: $code')));
  }

  Future<void> _joinByCode(String raw) async {
    final code = normalizeJoinCode(raw);
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kod 6 karakter olmalı (0, O, 1, I ve L yoktur).')),
      );
      return;
    }
    await _act(() => ref.read(groupsApiProvider).joinByCode(code), 'Gruba katıldın.');
  }

  void _showCreateSheet(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.s4,
          right: AppSpacing.s4,
          top: AppSpacing.s4,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Yeni çalışma grubu',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.s3),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: kGroupNameMax,
              decoration: const InputDecoration(
                labelText: 'Grup adı',
                hintText: 'Sabah çalışma ekibi',
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            FilledButton(
              onPressed: () {
                final err = validateGroupName(controller.text);
                if (err != null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(err)));
                  return;
                }
                Navigator.pop(ctx);
                _act(
                  () => ref
                      .read(groupsApiProvider)
                      .createGroup(name: controller.text.trim(), licence: 'b'),
                  'Grup kuruldu. Kodu arkadaşlarınla paylaş.',
                );
              },
              child: const Text('Kur'),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinByCodeCard extends StatefulWidget {
  const _JoinByCodeCard({required this.busy, required this.onJoin});
  final bool busy;
  final Future<void> Function(String code) onJoin;

  @override
  State<_JoinByCodeCard> createState() => _JoinByCodeCardState();
}

class _JoinByCodeCardState extends State<_JoinByCodeCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kodla katıl', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: AppSpacing.s1),
          Text(
            'Arkadaşının paylaştığı 6 karakterlik kodu gir.',
            style: TextStyle(color: p.text3, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 8, // boşluk/tire payı
                  decoration: const InputDecoration(hintText: 'ABC123', counterText: ''),
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              FilledButton(
                onPressed: widget.busy ? null : () => widget.onJoin(_controller.text),
                child: const Text('Katıl'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.onOpen, required this.onCopy});
  final StudyGroup group;
  final VoidCallback onOpen;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      onTap: onOpen,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    if (group.isOwner) ...[
                      const SizedBox(width: AppSpacing.s2),
                      const _OwnerTag(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${group.memberCount} üye  ·  ${group.totalXp} XP  ·  ${group.totalAnswered} soru',
                  style: TextStyle(color: p.text3, fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.s1),
                Row(
                  children: [
                    Icon(Icons.key_rounded, size: 14, color: p.text3),
                    const SizedBox(width: 4),
                    Text(
                      group.joinCode,
                      style: TextStyle(
                        color: p.text3,
                        fontSize: 13,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Kodu kopyala',
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
    );
  }
}

/// "kurucu" rozeti — grup listesinde sahipliği tek bakışta gösterir.
class _OwnerTag extends StatelessWidget {
  const _OwnerTag();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 2),
      decoration: BoxDecoration(
        color: p.primary050,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: p.primary),
      ),
      child: Text(
        'kurucu',
        style: TextStyle(color: p.primary, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }
}
