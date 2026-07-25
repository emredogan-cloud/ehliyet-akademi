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

/// Evolution Faz E10 — grup ayrıntısı: katılım kodu, toplu istatistik, üye sıralaması.
///
/// ERİŞİM: sunucu yalnız ÜYEYE döner; üye olmayan 404 alır ve bu ekran "bulunamadı" gösterir —
/// grubun varlığı sızdırılmaz.
class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  Future<GroupDetail?>? _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    if (!mounted) return;
    final future = ref.read(groupsApiProvider).fetchGroup(widget.groupId);
    unawaited(future.catchError((Object _) => null));
    setState(() {
      _future = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grup'),
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
        child: FutureBuilder<GroupDetail?>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final detail = snap.data;
            if (detail == null) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.s4),
                child: AppEmptyState(
                  emoji: '🔒',
                  title: 'Grup bulunamadı',
                  subtitle: 'Bu grup silinmiş olabilir ya da artık üyesi değilsin.',
                ),
              );
            }
            final g = detail.group;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s4,
                AppSpacing.s4,
                AppSpacing.s10,
              ),
              children: [
                Text(
                  g.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.2),
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  '${g.memberCount} üye  ·  ${g.licence.toUpperCase()} sınıfı',
                  style: TextStyle(color: p.text3, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.s4),
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Katılım kodu',
                              style: TextStyle(color: p.text3, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              g.joinCode,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Kodu kopyala',
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: g.joinCode));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Katılım kodu kopyalandı.')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                Row(
                  children: [
                    Expanded(child: _StatTile(label: 'Toplam XP', value: '${g.totalXp}')),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(child: _StatTile(label: 'Çözülen soru', value: '${g.totalAnswered}')),
                  ],
                ),
                SectionTitle('Üyeler  ·  ${detail.members.length}'),
                for (final m in detail.members) _MemberRow(member: m),
                const SizedBox(height: AppSpacing.s6),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _confirmLeave(g),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(g.isOwner ? 'Gruptan ayrıl (sahiplik devredilir)' : 'Gruptan ayrıl'),
                ),
                if (g.isOwner) ...[
                  const SizedBox(height: AppSpacing.s2),
                  TextButton.icon(
                    onPressed: _busy ? null : () => _confirmDelete(g),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Grubu sil'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmLeave(StudyGroup g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gruptan ayrıl'),
        content: Text(
          g.isOwner
              ? 'Ayrılırsan sahiplik en eski üyeye geçer. Son üye sensen grup silinir.'
              : 'Grubun istatistiklerinde artık görünmeyeceksin.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ayrıl')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(() => ref.read(groupsApiProvider).leaveGroup(g.id), 'Gruptan ayrıldın.');
  }

  Future<void> _confirmDelete(StudyGroup g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Grubu sil'),
        content: const Text('Grup ve bütün üyelikleri kalıcı olarak silinir. Geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(() => ref.read(groupsApiProvider).deleteGroup(g.id), 'Grup silindi.');
  }

  Future<void> _run(Future<void> Function() action, String okMessage) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(okMessage)));
      context.pop();
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
    }
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: p.text3, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});
  final GroupMember member;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s3,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '${member.rank}',
                style: TextStyle(
                  color: member.rank <= 3 ? p.yellow : p.text3,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Image.asset(member.avatar.asset, width: 40, height: 40),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: member.isSelf ? p.primary : p.text,
                          ),
                        ),
                      ),
                      if (member.isOwner) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.star_rounded, size: 14, color: p.yellow),
                      ],
                    ],
                  ),
                  Text(
                    '${member.streak} gün seri',
                    style: TextStyle(color: p.text3, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${member.xp}',
              style: TextStyle(color: p.primary, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
