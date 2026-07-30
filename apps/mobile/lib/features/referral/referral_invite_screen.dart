import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/theme/tokens.dart';
import '../../design/brand.dart';
import '../../domain/auth/auth_controller.dart';
import '../../domain/referral/pending_referral.dart';

/// Beta Faz 1 — davet derin bağlantısının indiği ekran (`/davet/<KOD>`).
///
/// Bu ekran, bağlantıya tıklayan kişinin uygulamada gördüğü İLK şeydir. İki farklı kişi buraya
/// gelir ve ikisine aynı şeyi söylemek yanlış olurdu:
///
/// · **Hesabı olmayan** → daveti kullanabilir. Ekran onu kayıt akışına, kod DOLU olarak gönderir.
/// · **Hesabı olan** → daveti KULLANAMAZ. Davet, kayıt anında kurulan bir ilişkidir; var olan bir
///   hesaba sonradan davet eden eklenmez. Bunu açıkça söylemek zorunludur — söylenmezse kullanıcı
///   kodu bir yere yazmayı dener, olmaz, ve hatanın kendisinde olduğunu sanır. Onun yerine ona
///   KENDİ davet bağlantısı önerilir; zaten yapabileceği tek şey odur.
class ReferralInviteScreen extends ConsumerStatefulWidget {
  const ReferralInviteScreen({super.key, required this.code});

  /// URL'den gelen kod. Yönlendirici bunu kanonikleştirilmiş hâlde verir.
  final String code;

  @override
  ConsumerState<ReferralInviteScreen> createState() => _ReferralInviteScreenState();
}

class _ReferralInviteScreenState extends ConsumerState<ReferralInviteScreen> {
  @override
  void initState() {
    super.initState();
    // Olay BİR KEZ, ekran kurulduğunda gönderilir — `build` içinde olsaydı her yeniden çizimde
    // tekrar giderdi (tema değişimi, klavye açılması, döndürme…).
    final signedIn = ref.read(authControllerProvider).isAuthenticated;
    ref.read(analyticsProvider).log(AnalyticsEvent.referralLinkOpened(signedIn: signedIn));
    // Karşılama yapıldı: yönlendirici artık Ana Sayfa'yı bu davet için ele geçirmez.
    ref.read(pendingReferralProvider).markGreeted();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(authControllerProvider).isAuthenticated;
    return Scaffold(
      appBar: AppBar(title: const Text('Davet bağlantısı')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CodeCard(code: widget.code),
              const SizedBox(height: AppSpacing.s5),
              if (signedIn) _AlreadySignedIn(code: widget.code) else _AcceptInvite(code: widget.code),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kodun kendisi — büyük, okunur, kopyalanabilir görünümde.
class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s5, horizontal: AppSpacing.s4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.45)),
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
      ),
      child: Column(
        children: [
          Text('🎁', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.s3),
          Text(
            'Bir arkadaşın seni davet etti',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            'DAVET KODU',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              code,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                letterSpacing: 4,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hesabı olmayan kullanıcı: daveti kabul edebilir.
class _AcceptInvite extends StatelessWidget {
  const _AcceptInvite({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Hesabını açtığında bu kod kayıt formunda hazır olacak. E-postanı doğruladığında seni '
          'davet eden kişi ödülüne bir adım yaklaşır — sana bir ücret çıkmaz.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.s5),
        GradientPillButton(
          label: 'Hesap oluştur ve kodu kullan',
          leading: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 18),
          // Kod `PendingReferral` içinde zaten duruyor; kayıt ekranı onu okuyup doldurur.
          onPressed: () => context.push('/auth?kayit=1'),
        ),
        const SizedBox(height: AppSpacing.s3),
        OutlinedButton(
          onPressed: () => context.go('/home'),
          child: const Text('Şimdilik sadece gezineyim'),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          'Hesap açmadan da soru çözebilir, ders okuyabilir, işaretleri öğrenebilirsin. Kod, '
          'kayıt olduğun ana kadar burada bekler.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Oturumu açık kullanıcı: daveti kabul EDEMEZ — bunu dürüstçe söyle ve yapabileceğini öner.
class _AlreadySignedIn extends ConsumerWidget {
  const _AlreadySignedIn({required this.code});
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.base),
            border: Border.all(color: theme.colorScheme.tertiary.withValues(alpha: 0.5)),
            color: theme.colorScheme.tertiary.withValues(alpha: 0.10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 20, color: theme.colorScheme.tertiary),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  'Davet kodu yalnız YENİ bir hesap açılırken kullanılabilir. Senin hesabın zaten '
                  'var, bu yüzden bu kod sana işlemez.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s5),
        Text(
          'Ama sen de davet edebilirsin: kendi kodunu paylaştığın her arkadaş ödüle sayılır.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.s4),
        GradientPillButton(
          label: 'Kendi davet kodumu gör',
          leading: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 18),
          onPressed: () {
            // Bekleyen kod TEMİZLENİR: bu cihazda kullanılamayacağı kesin. Bırakılsa, kullanıcı
            // ileride çıkış yapıp yeni hesap açtığında beklenmedik biçimde geri gelirdi.
            ref.read(pendingReferralProvider).clear();
            context.pushReplacement('/davet');
          },
        ),
        const SizedBox(height: AppSpacing.s3),
        OutlinedButton(
          onPressed: () => context.go('/home'),
          child: const Text('Ana sayfaya dön'),
        ),
      ],
    );
  }
}
