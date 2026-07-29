import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/app_version.dart';
import '../../core/theme/tokens.dart';
import '../../data/practice/progress_repository.dart';
import '../../design/brand.dart';
import '../../design/primitives.dart';
import '../../domain/auth/auth_controller.dart';
import '../../domain/onboarding/study_profile.dart';
import '../../domain/practice/srs.dart';
import '../../domain/progress/gamification.dart';
import '../feedback/rating_dialog.dart';
import 'delete_account_dialog.dart';

/// Profil — profil başlığı (auth'a bağlı) + istatistikler + ayarlar. Tema geçişi gerçek bir özellik.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final mode = ref.watch(themeModeProvider);
    final auth = ref.watch(authControllerProvider);
    final progress = ref.watch(progressRepositoryProvider).value;
    final profile = ref.watch(studyProfileProvider);
    final platformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = mode == ThemeMode.dark || (mode == ThemeMode.system && platformDark);

    final answers = progress?.loadAnswers() ?? const [];
    final streak = progress?.loadStreak() ?? StreakState.empty;
    final badges = computeAchievements(
      answers: answers,
      streak: streak,
      examsFinished: progress?.examsFinished() ?? 0,
    ).where((a) => a.unlocked).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            tooltip: 'Ayarlar',
            icon: Icon(Icons.settings_outlined, color: p.text2),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s2,
            AppSpacing.s4,
            AppSpacing.s10,
          ),
          children: [
            _ProfileHeader(
              auth: auth,
              badges: badges,
              answered: answers.length,
              streakDays: streak.current,
            ),
            SectionTitle('Ayarlar'),
            GlowCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _ToggleRow(
                    icon: Icons.dark_mode_rounded,
                    color: p.primary,
                    title: 'Koyu tema',
                    subtitle: 'Uygulama temasını değiştir',
                    value: isDark,
                    onChanged: (_) => ref
                        .read(themeModeProvider.notifier)
                        .toggle(MediaQuery.platformBrightnessOf(context)),
                  ),
                  _divider(p),
                  _SettingRow(
                    icon: Icons.badge_rounded,
                    color: p.blue,
                    title: 'Ehliyet sınıfı',
                    subtitle: '${profile.category.badge} · ${profile.category.title}',
                    onTap: () => _showLicencePicker(context, ref),
                  ),
                  _divider(p),
                  // Faz 4: Topluluk artık alt gezinmede birinci sınıf sekme. Buradaki satır
                  // ONUN KOPYASI DEĞİL — topluluk KİMLİĞİNİN ayarına (görünen ad, avatar, ayrılma)
                  // gider. Aynı yere iki kapı açmak menüyü şişirir, keşfedilebilirliği artırmaz.
                  _SettingRow(
                    icon: Icons.groups_rounded,
                    color: p.green,
                    title: 'Topluluk profilim',
                    subtitle: 'Görünen adın, avatarın ve katılım durumun',
                    onTap: () => context.push('/community/join'),
                  ),
                  _divider(p),
                  _SettingRow(
                    icon: Icons.notifications_rounded,
                    color: p.purple,
                    title: 'Bildirimler',
                    subtitle: 'Bildirim tercihlerini yönet',
                    onTap: () => context.push('/notifications'),
                  ),
                  _divider(p),
                  _SettingRow(
                    icon: Icons.workspace_premium_rounded,
                    color: p.accent,
                    title: 'Premium',
                    subtitle: 'Premium özellikleri keşfet',
                    onTap: () => context.push('/premium'),
                  ),
                  _divider(p),
                  // Faz 7 — kullanıcının KENDİSİ istediği yol. Buradan açıldığında sıklık
                  // sınırları uygulanmaz: kendi isteğiyle açtığı pencereyi "çok erken" diye
                  // kapatmak saçma olurdu.
                  _SettingRow(
                    icon: Icons.star_rounded,
                    color: p.accent,
                    title: 'Uygulamayı puanla',
                    subtitle: 'Google Play’de bize destek ol',
                    onTap: () => showRatingDialog(context),
                  ),
                  _divider(p),
                  _SettingRow(
                    icon: Icons.info_outline_rounded,
                    color: p.blue,
                    title: 'Hakkında',
                    subtitle: 'Uygulama hakkında bilgi al',
                    onTap: () => _showAbout(context),
                  ),
                  if (auth.isAuthenticated) ...[
                    _divider(p),
                    _SettingRow(
                      icon: Icons.logout_rounded,
                      color: p.red,
                      title: 'Çıkış yap',
                      subtitle: 'Hesabından güvenle çık',
                      onTap: () => _logout(context, ref),
                    ),
                    _divider(p),
                    // Faz 5 — KVKK m.7 / GDPR "silme hakkı". Yıkıcı eylem listenin EN ALTINDA ve
                    // "Çıkış yap"tan sonra durur: yanlışlıkla dokunma olasılığı en düşük yer.
                    _SettingRow(
                      icon: Icons.delete_outline_rounded,
                      color: p.red,
                      title: 'Hesabımı sil',
                      subtitle: 'Hesabını ve tüm verilerini kalıcı olarak sil',
                      onTap: () => _deleteAccount(context, ref),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s5),
            _PromoCard(),
            const SizedBox(height: AppSpacing.s5),
            Center(
              // GERÇEK sürüm — sabit dize DEĞİL. Derleme numarası, cihazdaki yapının hangi AAB
              // olduğunu kesin olarak söyler; teşhis için tek güvenilir işaret budur.
              child: FutureBuilder<AppVersion>(
                future: AppVersion.load(),
                builder: (context, snap) => Text(
                  'Ehliyet Akademi · ${(snap.data ?? AppVersion.unknown).label}',
                  style: TextStyle(color: p.text3, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _divider(AppPalette p) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
    child: Divider(height: 1, color: p.border),
  );

  /// Faz 3 — çıkış: oturumu kapat → **gezinme yığınını temizle** → Giriş ekranına in.
  ///
  /// NEDEN yığın temizlenir: eskiden yalnız durum sıfırlanıyordu; kullanıcı Profil'de kalıyor ve
  /// hiçbir şey olmamış gibi görünüyordu. `context.go` tüm yığını değiştirir — geri tuşuyla oturumlu
  /// bir ekrana dönülemez. Bu yüzden `push` DEĞİL `go` kullanılır.
  static Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(authControllerProvider.notifier).logout();
    router.go('/auth');
    messenger.showSnackBar(const SnackBar(content: Text('Çıkış yapıldı.')));
  }

  /// Faz 5 — hesap silme. Sunucudaki satır gittikten sonra CİHAZDA da hiçbir iz kalmamalı.
  ///
  /// Sıra önemli: silme başarılı olduktan SONRA yerel oturum temizlenir (`logout`) ve yığın
  /// değiştirilir. Tersi yapılsaydı, silme başarısız olduğunda kullanıcı sebepsiz yere çıkmış
  /// olurdu.
  static Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final deleted = await showDeleteAccountDialog(context);
    if (!deleted || !context.mounted) return;

    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Sunucu oturumu zaten yok (satır silindi, cascade oturumları da düşürdü); bu çağrı yerel
    // jetonu, Google oturumunu ve sahiplik önbelleğini temizler.
    await ref.read(authControllerProvider.notifier).logout();
    router.go('/auth');
    messenger.showSnackBar(
      const SnackBar(content: Text('Hesabın ve tüm verilerin silindi.')),
    );
  }

  static Future<void> _showAbout(BuildContext context) async {
    final version = await AppVersion.load();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: 'Ehliyet Akademi',
      applicationVersion: version.label,
      applicationLegalese:
          'B sınıfı ehliyet sınavına akıllı, kişisel ve çevrimdışı hazırlık.\n'
          'Kesin ve güncel kural için MEB/MTSK esastır.',
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.auth,
    required this.badges,
    required this.answered,
    required this.streakDays,
  });
  final AuthState auth;
  final int badges;
  final int answered;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = auth.user;
    final authed = auth.isAuthenticated && user != null;
    return GlowCard(
      selected: true,
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s4, 0, AppSpacing.s4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.primary.withValues(alpha: 0.16),
                        border: Border.all(color: p.primary.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        authed ? user.initials : 'EA',
                        style: TextStyle(
                          color: p.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authed ? user.name : 'Misafir',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            authed ? user.email : 'Giriş yaparak ilerlemeni kaydet',
                            style: TextStyle(color: p.text3, fontSize: 12.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.emoji_events_rounded,
                      value: '$badges',
                      label: 'Rozet',
                      color: p.accent,
                    ),
                    _MiniStat(
                      icon: Icons.trending_up_rounded,
                      value: '$answered',
                      label: 'İlerleme',
                      color: p.primary,
                    ),
                    _MiniStat(
                      icon: Icons.local_fire_department_rounded,
                      value: '$streakDays',
                      label: 'Gün',
                      color: p.red,
                    ),
                  ],
                ),
                if (!authed) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.s4),
                    child: GradientPillButton(
                      label: 'Giriş yap / Kayıt ol',
                      height: 50,
                      leading: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                      onPressed: () => context.push('/auth'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          MascotImage(AppImages.owlShield, height: 128, semanticLabel: ''),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s5),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: p.text),
              ),
              Text(label, style: TextStyle(color: p.text3, fontSize: 10.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color, size: 44),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(subtitle, style: TextStyle(color: p.text3, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: p.primary,
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
        child: Row(
          children: [
            IconBadge(icon: icon, color: color, size: 44),
            const SizedBox(width: AppSpacing.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(subtitle, style: TextStyle(color: p.text3, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.text3),
          ],
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlowCard(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Row(
        children: [
          const BrandMark(size: 56),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ehliyet Akademi', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  'Sürüş bilgini geliştir, sınavlarda bir adım önde ol!',
                  style: TextStyle(color: p.text2, fontSize: 12.5, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ehliyet sınıfı seçici — seçim anında tüm uygulamanın kapsamını değiştirir ve kalıcıdır
/// (Evolution Faz E4). Teori ilerlemesi sınıfa göre BÖLÜNMEZ; e-Sınav soru bankası ortaktır.
Future<void> _showLicencePicker(BuildContext context, WidgetRef ref) async {
  final p = context.palette;
  final current = ref.read(studyProfileProvider).category;
  final picked = await showModalBottomSheet<LicenceCategory>(
    context: context,
    backgroundColor: p.surface2,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
    ),
    isScrollControlled: true,
    // küçük ekranlarda taşmasın diye kaydırılabilir (ve en fazla ekranın %85'i)
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.s4),
            Text('Ehliyet sınıfı', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
              child: Text(
                'Dersler, araç bilgisi ve öneriler seçtiğin sınıfa göre önceliklenir. '
                'Teori ilerlemen korunur.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.4),
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            for (final c in LicenceCategory.values)
              ListTile(
                leading: IconBadge(
                  icon: switch (c) {
                    LicenceCategory.b => Icons.directions_car_rounded,
                    LicenceCategory.a => Icons.two_wheeler_rounded,
                    LicenceCategory.d => Icons.directions_bus_rounded,
                  },
                  color: c == current ? p.primary : p.text3,
                  size: 42,
                ),
                title: Text('${c.badge} · ${c.title}'),
                subtitle: Text(c.blurb, style: TextStyle(color: p.text3, fontSize: 12)),
                trailing: c == current ? Icon(Icons.check_circle_rounded, color: p.primary) : null,
                onTap: () => Navigator.of(context).pop(c),
              ),
            const SizedBox(height: AppSpacing.s4),
          ],
        ),
      ),
    ),
  );
  if (picked != null && picked != current) {
    final profile = ref.read(studyProfileProvider);
    await ref.read(studyProfileProvider.notifier).save(profile.copyWith(category: picked));
  }
}
