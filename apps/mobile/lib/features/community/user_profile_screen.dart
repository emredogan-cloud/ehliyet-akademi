import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/community/community_repository.dart';
import '../../design/brand.dart';
import '../../design/primitives.dart';
import '../../domain/community/community_models.dart';
import '../../domain/progress/gamification.dart';

/// Evolution Faz E8 — başka bir kullanıcının topluluk profili.
///
/// MODERASYON: engelleme ve bildirme bu ekranda HER ZAMAN erişilebilir (mağaza politikası gereği,
/// kullanıcı metni doğuran özelliklerden önce). Engelleme sunucuda uygulanır: engellenen kullanıcı
/// sıralamadan ve profilden karşılıklı olarak düşer.
class CommunityUserScreen extends ConsumerStatefulWidget {
  const CommunityUserScreen({super.key, required this.userId});
  final String userId;

  @override
  ConsumerState<CommunityUserScreen> createState() => _CommunityUserScreenState();
}

class _CommunityUserScreenState extends ConsumerState<CommunityUserScreen> {
  Future<CommunityUser?>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final future = ref.read(communityApiProvider).fetchUser(widget.userId);
        setState(() {
          _future = future;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        top: false,
        child: FutureBuilder<CommunityUser?>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = snap.data;
            if (user == null) {
              // 404 = yok / gizli / engellenmiş — ayrım kasıtlı olarak SIZDIRILMAZ.
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.s4),
                child: AppEmptyState(
                  emoji: '🔒',
                  title: 'Profil görüntülenemiyor',
                  subtitle: 'Bu kullanıcı gizli olabilir veya artık erişilebilir değil.',
                ),
              );
            }
            return _body(context, user);
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, CommunityUser user) {
    final p = context.palette;
    // Sunucu yalnız rozet KİMLİKLERİ döner; başlık/ikon yerel katalogdan çözülür.
    final earned = user.achievements
        .map(achievementById)
        .whereType<Achievement>()
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s10,
      ),
      children: [
        Center(child: MascotImage(user.avatar.asset, height: 120, semanticLabel: user.avatar.label)),
        const SizedBox(height: AppSpacing.s3),
        Text(
          user.displayName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.s2),
        Center(child: BrandChip(label: '${user.licence.toUpperCase()} sınıfı', icon: Icons.badge_rounded)),
        const SizedBox(height: AppSpacing.s5),

        Row(
          children: [
            Expanded(child: StatTile(label: 'XP', value: '${user.stats.xp}')),
            const SizedBox(width: AppSpacing.s3),
            Expanded(child: StatTile(label: 'Seri', value: '${user.stats.streak} gün')),
            const SizedBox(width: AppSpacing.s3),
            Expanded(child: StatTile(label: 'Doğruluk', value: '%${user.stats.accuracy}')),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        Row(
          children: [
            Expanded(child: StatTile(label: 'Çözülen', value: '${user.stats.answered}')),
            const SizedBox(width: AppSpacing.s3),
            Expanded(child: StatTile(label: 'Sınav', value: '${user.stats.exams}')),
          ],
        ),

        const SectionTitle('Rozetler'),
        if (earned.isEmpty)
          Text('Henüz rozet yok.', style: TextStyle(color: p.text3, fontSize: 13))
        else
          Wrap(
            spacing: AppSpacing.s3,
            runSpacing: AppSpacing.s3,
            children: [
              for (final a in earned)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s3,
                    vertical: AppSpacing.s2,
                  ),
                  decoration: BoxDecoration(
                    color: p.surface2,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(color: p.accent.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(a.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),

        if (!user.isSelf) ...[
          const SectionTitle('Güvenlik'),
          Text(
            'Rahatsız edici bir davranış görürsen bu kullanıcıyı engelleyebilir veya bildirebilirsin. '
            'Bildirimler insan incelemesine gider.',
            style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _block(user),
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: const Text('Engelle'),
                  style: OutlinedButton.styleFrom(foregroundColor: p.red),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _report(user),
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: const Text('Bildir'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _block(CommunityUser user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${user.displayName} engellensin mi?'),
        content: const Text(
          'Engellediğin kişiyi sıralamada ve profilde göremezsin; o da seni göremez. '
          'İstediğin an geri alabilirsin.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Engelle')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(communityApiProvider).block(user.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.displayName} engellendi.')),
      );
      if (context.mounted) context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Engellenemedi. Tekrar dene.')));
    }
  }

  Future<void> _report(CommunityUser user) async {
    final reason = await showModalBottomSheet<ReportReason>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.s4),
              child: Text(
                'Bildirme sebebi',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            for (final r in ReportReason.values)
              ListTile(
                title: Text(r.label),
                onTap: () => Navigator.pop(ctx, r),
              ),
            const SizedBox(height: AppSpacing.s2),
          ],
        ),
      ),
    );
    if (reason == null) return;
    try {
      await ref.read(communityApiProvider).report(userId: user.userId, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bildirimin alındı. İnceleyeceğiz.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bildirim gönderilemedi. Tekrar dene.')));
    }
  }
}
