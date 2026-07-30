import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
import '../../design/primitives.dart';
import '../../domain/coach/notification_prefs.dart';
import '../../domain/notifications/notification_kind.dart';

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
                    title: const Text('Bildirimler'),
                    subtitle: Text(
                      'Kapalıyken hiçbir bildirim gönderilmez',
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
            const SizedBox(height: AppSpacing.s5),

            // Beta Faz 6 — TÜR başına tercih.
            //
            // Tek bir anahtar kullanıcıya "hepsi ya da hiçbiri" dayatıyordu. Haftalık özetten
            // rahatsız olan kişi çalışma hatırlatmasını da kaybediyor ve pratikte bildirimlerin
            // tamamını kapatıyordu — kapatılan bildirim bir daha açılmaz.
            const SectionTitle('Neler bildirilsin?'),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s2),
              child: Text(
                'Her birini ayrı ayrı açıp kapatabilirsin.',
                style: TextStyle(color: p.text3, fontSize: 12.5),
              ),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final kind in NotificationKind.values) ...[
                    if (kind != NotificationKind.values.first) Divider(height: 1, color: p.border),
                    SwitchListTile(
                      value: prefs.effectiveKinds.contains(kind),
                      // Ana anahtar kapalıyken tür anahtarları da kapalı görünür ama
                      // DEĞİŞTİRİLEBİLİR kalır: kullanıcı önce neyi isteyeceğini seçip sonra
                      // ana anahtarı açabilmeli.
                      onChanged: (v) => ctrl.setKind(kind, v),
                      title: Text(kind.label),
                      subtitle: Text(
                        kind.description,
                        style: TextStyle(color: p.text3, fontSize: 12.5),
                      ),
                      dense: true,
                    ),
                  ],
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
                  'Gece 23:00–08:00 arasında bildirim gönderilmez. '
                  'Sunucudan gönderilen anlık bildirimler (push) ileride eklenecek.',
            ),
          ],
        ),
      ),
    );
  }
}
