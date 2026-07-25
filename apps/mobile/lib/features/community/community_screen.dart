import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets.dart';
import '../../core/theme/tokens.dart';
import '../../data/community/community_repository.dart';
import '../../design/brand.dart';
import '../../design/primitives.dart';
import '../../domain/community/community_models.dart';

/// Evolution Faz E8 — topluluk ana ekranı: katılım daveti (katılmadıysa) veya sıralama.
///
/// GERÇEK ZAMANLILIK: sunucusuz ortamda kalıcı WebSocket yoktur; liste açılışta ve elle yenilemede
/// tazelenir. "Canlı" olduğu iddia edilmez (roadmap'te belgelenmiş karar).
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  /// null = tüm sınıflar
  String? _licence;
  Future<LeaderboardPage>? _future;
  bool _scheduled = false;

  void _reload() {
    if (!mounted) return;
    final future = ref.read(communityApiProvider).fetchLeaderboard(licence: _licence);
    // ZAMANLAMA: hata, `FutureBuilder` dinleyicisini bağlamadan önce gelebilir; o durumda çalışma
    // zamanı bunu "yakalanmamış hata" olarak raporlar. Burada da bir işleyici bağlayarak hatayı
    // işlenmiş sayarız — `FutureBuilder` yine kendi dinleyicisinde hatayı görür ve dürüst hata
    // durumunu çizer.
    unawaited(future.catchError((Object _) => LeaderboardPage.empty));
    setState(() {
      _future = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    final community = ref.watch(communityProvider);
    // Sıralama YALNIZ katıldıktan sonra istenir: katılmayan kullanıcı için istek yapılmaz.
    if (community.joined && _future == null && !_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topluluk'),
        actions: [
          if (community.joined)
            IconButton(
              tooltip: 'Topluluk profilim',
              onPressed: () => context.push('/profile/community/join'),
              icon: const Icon(Icons.manage_accounts_rounded),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: community.joined ? _leaderboard(context, community) : _invite(context),
      ),
    );
  }

  // ── Katılmadıysa: dürüst davet ────────────────────────────────────────────
  Widget _invite(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        AppSpacing.s10,
      ),
      children: [
        const HubHeader(
          title: 'Topluluk',
          subtitle: 'Aynı sınava hazırlananlarla ilerlemeni karşılaştır — istersen.',
          mascot: AppImages.owlShield,
        ),
        const SizedBox(height: AppSpacing.s5),
        const AppCallout(
          tone: CalloutTone.info,
          title: 'Varsayılan olarak KAPALI',
          text:
              'Topluluk isteğe bağlıdır. Katılmadığın sürece hiçbir bilgin paylaşılmaz ve kimse seni göremez.',
        ),
        const SizedBox(height: AppSpacing.s4),
        for (final row in const [
          (Icons.visibility_off_rounded, 'Gerçek adın görünmez', 'Kendi seçtiğin görünen adı kullanırsın.'),
          (Icons.photo_camera_outlined, 'Fotoğraf yüklenmez', 'Avatarını uygulamanın maskotlarından seçersin.'),
          (Icons.shield_outlined, 'Engelle ve bildir', 'Rahatsız eden birini her ekrandan engelleyebilirsin.'),
          (Icons.delete_outline_rounded, 'İstediğin an ayrıl', 'Ayrıldığında topluluk verin sunucudan silinir.'),
        ]) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(row.$1, color: p.primary, size: 20),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.$2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                    Text(row.$3, style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
        ],
        GradientPillButton(
          label: 'Topluluğa katıl',
          trailingIcon: Icons.arrow_forward_rounded,
          onPressed: () async {
            await context.push('/profile/community/join');
            _reload();
          },
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(
          'Katılmak için hesabınla giriş yapmış olman gerekir.',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.text3, fontSize: 12),
        ),
      ],
    );
  }

  // ── Katıldıysa: sıralama ──────────────────────────────────────────────────
  Widget _leaderboard(BuildContext context, MyCommunityState community) {
    final p = context.palette;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s2,
            AppSpacing.s4,
            AppSpacing.s2,
          ),
          child: Row(
            children: [
              for (final entry in <(String?, String)>[
                (null, 'Tümü'),
                ('b', 'B'),
                ('a', 'A'),
                ('d', 'D'),
              ]) ...[
                _FilterChip(
                  label: entry.$2,
                  selected: _licence == entry.$1,
                  onTap: () {
                    _licence = entry.$1;
                    _reload();
                  },
                ),
                const SizedBox(width: AppSpacing.s2),
              ],
              const Spacer(),
              IconButton(
                tooltip: 'Yenile',
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        // Faz E9 + E10 — sosyal yüzeylere giriş (katıldıktan sonra).
        //
        // TEK SATIR, YATAY KAYDIRILIR. İki satıra yaymak dikey alanı kalıcı olarak yerdi ve
        // küçük ekranlarda sıralamayı taşırıyordu (E10'da ölçüldü: 31 px taşma). Yatay kaydırma
        // hem yüksekliği sabit tutar hem de sonraki fazlar yeni yüzey eklediğinde ölçeklenir.
        SizedBox(
          height: 92,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 0, AppSpacing.s4, AppSpacing.s2),
            children: [
              for (final e in const <(IconData, String, String)>[
                (Icons.people_alt_rounded, 'Arkadaşlar', 'friends'),
                (Icons.chat_bubble_rounded, 'Mesajlar', 'messages'),
                (Icons.forum_rounded, 'Tartışma', 'discussions'),
                (Icons.groups_rounded, 'Gruplar', 'groups'),
                (Icons.flag_rounded, 'Meydan okuma', 'challenges'),
              ]) ...[
                SizedBox(
                  width: 108,
                  child: _SocialButton(
                    icon: e.$1,
                    label: e.$2,
                    onTap: () => context.push('/profile/community/${e.$3}'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
              ],
            ],
          ),
        ),
        if (!(community.profile?.isPublic ?? false))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: AppCallout(
              tone: CalloutTone.warning,
              text:
                  'Profilin **gizli**. Sıralamayı görebilirsin ama sen listede görünmezsin. '
                  'Görünmek için topluluk profilinden "Sıralamada görün" seçeneğini aç.',
            ),
          ),
        Expanded(
          child: FutureBuilder<LeaderboardPage>(
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
                    title: 'Sıralama alınamadı',
                    subtitle:
                        'Topluluk paylaşılan bir alandır ve internet gerektirir. Bağlantını kontrol edip tekrar dene.',
                    action: FilledButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Tekrar dene'),
                    ),
                  ),
                );
              }
              final page = snap.data ?? LeaderboardPage.empty;
              final meOutsidePage =
                  page.me != null && !page.rows.any((r) => r.userId == page.me!.userId);
              if (page.rows.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.s4),
                  child: AppEmptyState(
                    emoji: '🏁',
                    title: 'Henüz kimse yok',
                    subtitle: 'Bu sınıfta sıralamaya katılan ilk kişi sen olabilirsin.',
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
                  // Kendi sıran YALNIZ görünen sayfanın DIŞINDAYSAN üstte sabitlenir. Sayfadaysan
                  // zaten listede vurgulu görünüyorsun — ikisini birden çizmek aynı satırı
                  // iki kez gösteriyordu (cihaz doğrulamasında yakalandı).
                  if (meOutsidePage) ...[
                    _RankRow(entry: page.me!, highlight: true, onTap: null),
                    const SizedBox(height: AppSpacing.s3),
                    Divider(color: p.border),
                  ],
                  for (final row in page.rows) ...[
                    _RankRow(
                      entry: row,
                      highlight: row.userId == page.me?.userId,
                      onTap: () => context.push('/profile/community/user/${row.userId}'),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                  ],
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    'Hafta başlangıcı: ${page.weekStart} · ${page.total} kişi',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.text3, fontSize: 12),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Topluluk hub'ındaki sosyal kısayol düğmesi (Faz E9).
class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.base),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(AppRadii.base),
            border: Border.all(color: p.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: p.primary, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: p.text2,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? p.primary050 : p.surface2,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: selected ? p.primary : p.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? p.primary : p.text2,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry, required this.highlight, required this.onTap});
  final LeaderboardEntry entry;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlowCard(
      selected: highlight,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s3),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: entry.rank <= 3 ? p.accent : p.text3,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(width: 40, height: 40, child: MascotImage(entry.avatar.asset, height: 40)),
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
                  '${entry.licence.toUpperCase()} sınıfı · ${entry.streak} gün seri',
                  style: TextStyle(color: p.text3, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.xp}',
                style: TextStyle(color: p.primary, fontWeight: FontWeight.w900, fontSize: 16),
              ),
              Text('XP', style: TextStyle(color: p.text3, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
