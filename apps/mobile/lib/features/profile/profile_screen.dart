import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
import '../../design/primitives.dart';
import '../../domain/auth/auth_controller.dart';

/// Profil — profile header (bound to auth) + settings. The theme toggle is a real feature.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final mode = ref.watch(themeModeProvider);
    final auth = ref.watch(authControllerProvider);
    final platformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = mode == ThemeMode.dark || (mode == ThemeMode.system && platformDark);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
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
            _ProfileHeader(auth: auth),
            SectionTitle('Ayarlar'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    value: isDark,
                    onChanged: (_) => ref
                        .read(themeModeProvider.notifier)
                        .toggle(MediaQuery.platformBrightnessOf(context)),
                    secondary: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: p.primary),
                    title: const Text('Koyu tema'),
                    activeThumbColor: p.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                  ),
                  Divider(height: 1, color: p.border),
                  const _SettingRow(icon: Icons.notifications_outlined, title: 'Bildirimler'),
                  Divider(height: 1, color: p.border),
                  const _SettingRow(icon: Icons.workspace_premium_outlined, title: 'Premium'),
                  Divider(height: 1, color: p.border),
                  const _SettingRow(icon: Icons.info_outline_rounded, title: 'Hakkında'),
                  if (auth.isAuthenticated) ...[
                    Divider(height: 1, color: p.border),
                    ListTile(
                      leading: Icon(Icons.logout_rounded, color: p.red),
                      title: Text('Çıkış yap', style: TextStyle(color: p.red)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                      onTap: () => ref.read(authControllerProvider.notifier).logout(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            Center(
              child: Text('Ehliyet Akademi · v1.0 (geliştirme)',
                  style: TextStyle(color: p.text3, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.auth});
  final AuthState auth;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = auth.user;
    final authed = auth.isAuthenticated && user != null;
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: p.primary.withValues(alpha: 0.16),
                child: Text(authed ? user.initials : 'EA',
                    style: TextStyle(color: p.primary, fontWeight: FontWeight.w800, fontSize: 18)),
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(authed ? user.name : 'Misafir',
                        style: Theme.of(context).textTheme.titleMedium),
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
          if (!authed) ...[
            const SizedBox(height: AppSpacing.s4),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.push('/auth'),
                child: const Text('Giriş yap / Kayıt ol'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListTile(
      leading: Icon(icon, color: p.text2),
      title: Text(title),
      trailing: Icon(Icons.chevron_right_rounded, color: p.text3),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      // Detail screens arrive in later phases; disabled to avoid dead navigation.
      enabled: false,
    );
  }
}
