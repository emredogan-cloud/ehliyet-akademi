import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/referral/referral_api.dart';
import '../../data/share/share_service.dart';
import '../../design/brand.dart';
import '../../design/primitives.dart';
import '../../domain/auth/auth_controller.dart';

/// Faz 8 — davet ekranı: kodun, bağlantın, ilerlemen ve ödüllerin.
///
/// DÜRÜSTLÜK: "davet ettiklerin" ile "sayılanlar" AYRI gösterilir. Bir davetin ödüle sayılması
/// için arkadaşın e-postasını doğrulaması gerekir; bunu gizlemek, kullanıcının "5 kişi davet
/// ettim, ödül nerede?" diye desteğe yazmasına yol açardı.
class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Arkadaşını davet et')),
      body: SafeArea(
        top: false,
        child: !auth.isAuthenticated
            ? _SignInFirst()
            : ref
                  .watch(referralSummaryProvider)
                  .when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => _Unavailable(onRetry: () => ref.invalidate(referralSummaryProvider)),
                    data: (summary) => summary == null
                        ? _Unavailable(onRetry: () => ref.invalidate(referralSummaryProvider))
                        : _Body(summary: summary),
                  ),
      ),
    );
  }
}

/// Davet, hesaba bağlıdır: kod bir kullanıcıya aittir ve ödül ona verilir.
class _SignInFirst extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      emoji: '🎁',
      title: 'Önce giriş yap',
      subtitle:
          'Davet kodun hesabına bağlıdır. Giriş yaptığında kodun oluşur ve '
          'davet ettiklerin buradan sayılır.',
      action: GradientPillButton(
        label: 'Giriş yap / Kayıt ol',
        leading: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
        onPressed: () => context.push('/auth'),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      emoji: '📡',
      title: 'Davet bilgin alınamadı',
      subtitle: 'Bağlantını kontrol edip tekrar dene.',
      action: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Tekrar dene'),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.summary});
  final ReferralSummary summary;

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final text =
        'Ehliyet sınavına Ehliyet Akademi ile hazırlanıyorum. '
        'Sen de katıl — davet kodum: ${summary.code}\n${summary.link}';
    final ok = await ref.read(shareServiceProvider).shareText(text);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paylaşım açılamadı.')),
      );
    }
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: summary.code));
    if (!context.mounted) return;
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Davet kodun kopyalandı.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final next = summary.nextMilestone;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s3, AppSpacing.s4, AppSpacing.s10),
      children: [
        const HubHeader(
          title: 'Davet et, premium kazan',
          subtitle: 'Arkadaşların kodunla kayıt olup e-postasını doğruladıkça ödül kazanırsın.',
          mascot: 'assets/img/owl_wave.webp',
        ),
        const SizedBox(height: AppSpacing.s4),

        // ── Kod + paylaş ────────────────────────────────────────────────────
        GlowCard(
          selected: true,
          padding: const EdgeInsets.all(AppSpacing.s5),
          child: Column(
            children: [
              Text(
                'DAVET KODUN',
                style: TextStyle(
                  color: p.text3,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              // Kod SEÇİLEBİLİR: kullanıcı elle de kopyalayabilmeli.
              SelectableText(
                summary.code,
                style: TextStyle(
                  color: p.primary,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              GradientPillButton(
                label: 'Arkadaşını davet et',
                leading: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 19),
                onPressed: () => _share(context, ref),
              ),
              const SizedBox(height: AppSpacing.s3),
              OutlinedButton.icon(
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_rounded, size: 17),
                label: const Text('Kodu kopyala'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.text2,
                  side: BorderSide(color: p.border),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
                ),
              ),
            ],
          ),
        ),

        // ── İlerleme ────────────────────────────────────────────────────────
        SectionTitle('İlerlemen'),
        GlowCard(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatTile(value: '${summary.qualified}', label: 'sayılan', color: p.primary),
                  const SizedBox(width: AppSpacing.s6),
                  StatTile(value: '${summary.pending}', label: 'bekleyen', color: p.accent),
                  const SizedBox(width: AppSpacing.s6),
                  StatTile(value: '${summary.invited}', label: 'toplam davet'),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              if (next != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: LinearProgressIndicator(
                    value: (summary.qualified / next.count).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: p.surface3,
                    color: p.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                Text(
                  'Sonraki ödül: ${next.count} sayılan davette ${next.months} ay premium '
                  '(${summary.qualified}/${next.count})',
                  style: TextStyle(color: p.text2, fontSize: 13.5, height: 1.4),
                ),
              ] else
                Text(
                  'Tüm ödülleri kazandın. Teşekkürler! 🎉',
                  style: TextStyle(color: p.green, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              if (summary.pending > 0) ...[
                const SizedBox(height: AppSpacing.s3),
                // DÜRÜSTLÜK: bekleyen davetin neden sayılmadığı açıkça yazılır.
                AppCallout(
                  tone: CalloutTone.info,
                  title: 'Bekleyen ${summary.pending} davet',
                  text:
                      'Bir davetin sayılması için arkadaşının e-posta adresini doğrulaması '
                      'gerekiyor. Doğrulama e-postası kayıt olurken gönderiliyor.',
                ),
              ],
            ],
          ),
        ),

        // ── Ödüller ─────────────────────────────────────────────────────────
        SectionTitle('Ödüller'),
        GlowCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
          child: Column(
            children: [
              for (final m in summary.milestones)
                _MilestoneRow(
                  milestone: m,
                  reached: summary.qualified >= m.count,
                  granted: summary.rewards.any((r) => r.milestone == m.count),
                ),
            ],
          ),
        ),
        if (summary.rewards.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s4),
          _ActiveReward(rewards: summary.rewards),
        ],
        const SizedBox(height: AppSpacing.s4),
        Text(
          'Davetler, aynı kişinin birden çok hesabıyla ödül toplamasını önlemek için '
          'kontrol edilir. Kurala aykırı davetler sayılmaz.',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.text3, fontSize: 11.5, height: 1.4),
        ),
      ],
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.milestone, required this.reached, required this.granted});
  final ReferralMilestone milestone;
  final bool reached;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = granted ? p.green : (reached ? p.accent : p.text3);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
      child: Row(
        children: [
          IconBadge(
            icon: granted ? Icons.check_circle_rounded : Icons.card_giftcard_rounded,
            color: color,
            size: 44,
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${milestone.count} davet → ${milestone.months} ay premium',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                Text(
                  granted ? 'Kazanıldı' : 'Henüz kazanılmadı',
                  style: TextStyle(color: p.text3, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Etkin ödülün ne zaman biteceğini AÇIKÇA söyler — süreli erişimde en çok sorulan soru budur.
class _ActiveReward extends StatelessWidget {
  const _ActiveReward({required this.rewards});
  final List<ReferralReward> rewards;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final active = rewards
        .map((r) => r.expiresAt)
        .whereType<DateTime>()
        .where((d) => d.isAfter(now))
        .toList()
      ..sort();
    if (active.isEmpty) return const SizedBox.shrink();

    final until = active.last;
    String two(int n) => n.toString().padLeft(2, '0');
    return AppCallout(
      tone: CalloutTone.success,
      title: 'Premium erişimin açık',
      text:
          'Davet ödülünle kazandığın premium erişim '
          '${two(until.day)}.${two(until.month)}.${until.year} tarihine kadar geçerli.',
    );
  }
}
