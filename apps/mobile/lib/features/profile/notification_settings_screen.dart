import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
import '../../design/primitives.dart';
import '../../domain/coach/notification_prefs.dart';

/// Bildirim ayarları — günlük çalışma hatırlatması (yerel bildirim, çevrimdışı) + test.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final prefs = ref.watch(notificationSettingsProvider);
    final ctrl = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s3,
            AppSpacing.s4,
            AppSpacing.s10,
          ),
          children: [
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    value: prefs.enabled,
                    onChanged: (v) async {
                      final ok = await ctrl.setEnabled(v);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bildirim izni verilmedi. Ayarlardan açabilirsin.'),
                          ),
                        );
                      }
                    },
                    title: const Text('Çalışma hatırlatması'),
                    subtitle: Text(
                      'Her gün seçtiğin saatte kısa bir hatırlatma',
                      style: TextStyle(color: p.text3, fontSize: 12.5),
                    ),
                    secondary: Icon(Icons.notifications_active_outlined, color: p.primary),
                  ),
                  Divider(height: 1, color: p.border),
                  ListTile(
                    enabled: prefs.enabled,
                    leading: Icon(Icons.schedule_rounded, color: prefs.enabled ? p.primary : p.text3),
                    title: const Text('Hatırlatma saati'),
                    trailing: Text(
                      prefs.timeLabel,
                      style: TextStyle(
                        color: prefs.enabled ? p.primary : p.text3,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    onTap: prefs.enabled
                        ? () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(hour: prefs.hour, minute: prefs.minute),
                            );
                            if (picked != null) await ctrl.setTime(picked.hour, picked.minute);
                          }
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            OutlinedButton.icon(
              onPressed: () => ctrl.sendTest(),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Test bildirimi gönder'),
            ),
            const SizedBox(height: AppSpacing.s5),
            const AppCallout(
              tone: CalloutTone.info,
              title: 'Nasıl çalışır?',
              text:
                  'Hatırlatmalar cihazında yerel olarak planlanır ve internet olmadan da çalışır. '
                  'Sunucudan gönderilen anlık bildirimler (push) ileride eklenecek.',
            ),
          ],
        ),
      ),
    );
  }
}
