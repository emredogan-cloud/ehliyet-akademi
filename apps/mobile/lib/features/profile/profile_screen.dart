import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
import '../../design/primitives.dart';

/// Profil — profile header + settings. The theme toggle is fully functional in Phase 1
/// (real feature). Auth/premium/progress bind in later phases.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final mode = ref.watch(themeModeProvider);
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
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: p.primary.withValues(alpha: 0.16),
                    child: Text('EA',
                        style: TextStyle(
                            color: p.primary, fontWeight: FontWeight.w800, fontSize: 18)),
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Misafir', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text('Giriş yaparak ilerlemeni kaydet',
                            style: TextStyle(color: p.text3, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                  _SettingRow(icon: Icons.notifications_outlined, title: 'Bildirimler'),
                  Divider(height: 1, color: p.border),
                  _SettingRow(icon: Icons.workspace_premium_outlined, title: 'Premium'),
                  Divider(height: 1, color: p.border),
                  _SettingRow(icon: Icons.info_outline_rounded, title: 'Hakkında'),
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
      // Settings detail screens arrive in later phases; disabled here to avoid dead navigation.
      enabled: false,
    );
  }
}
