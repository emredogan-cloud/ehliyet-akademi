import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets.dart';
import '../../core/theme/tokens.dart';
import '../../design/brand.dart';
import '../../domain/premium/campaign.dart';
import '../../domain/premium/conversion.dart';
import '../../domain/premium/paywall_offer.dart';
import '../../data/premium/entitlements_repository.dart';
import '../../domain/premium/premium_prompt.dart';
import '../../domain/premium/products.dart';
import '../../domain/premium/retention.dart';
import 'premium_popups.dart';

/// Faz 3 — ilk deneme sınavı sonrası DÖNÜŞÜM AKIŞI.
///
/// ## Neden iki adım
///
/// Kullanıcı hayatındaki ilk sınavı yeni bitirdi. O anda doğrudan ödeme ekranı açmak, emeğin
/// karşılığını "para iste" ile vermektir. Akış bilinçli olarak ikiye ayrıldı:
///
/// 1. **Tebrik** — koç sonucu okur ve dürüstçe yorumlar. Burada satış YOKTUR.
/// 2. **Teklif** — kullanıcı "öneriyi gör" derse açılır. Kapatırsa akış biter.
///
/// İkinci adım yalnız kullanıcı istediğinde gelir; bu, "kapatılamayan satış hunisi" ile
/// "koçun önerisi" arasındaki farktır.
///
/// ## Ne YOKTUR
///
/// · Sonuçtan bağımsız övgü (bkz. [coachExamRead]).
/// · Kampanya yokken sayaç ya da üstü çizili fiyat (bkz. [Campaign]).
/// · Sahte "sana özel" iddiası — gösterilen sayılar kullanıcının kendi sınav sonucudur.
Future<void> showFirstExamConversion(
  BuildContext context,
  WidgetRef ref, {
  required int correct,
  required int total,
  required int passMark,
  required int nowMs,
}) async {
  final read = coachExamRead(correct: correct, total: total, passMark: passMark);

  final wantsOffer = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (_) => _CoachCongratsDialog(
      title: read.title,
      body: read.body,
      correct: correct,
      total: total,
      passMark: passMark,
    ),
  );

  // Kapatıldıysa (null ya da false) burada biter — ikinci pencere AÇILMAZ.
  if (wantsOffer != true || !context.mounted) return;

  await ref.read(premiumPromptProvider.notifier).recordShown(nowMs);
  if (!context.mounted) return;
  await showCoachOffer(context, ref, correct: correct, total: total, passMark: passMark);
}

/// Koçun sunduğu teklif penceresi. Ödeme ekranından farkı: burada koç KONUŞUR ve gerekçesini
/// kullanıcının kendi verisine dayandırır.
Future<void> showCoachOffer(
  BuildContext context,
  WidgetRef ref, {
  required int correct,
  required int total,
  required int passMark,
}) {
  final now = DateTime.now();
  final campaign = activeCampaign(
    ref.read(campaignCatalogProvider),
    now,
    kind: CampaignKind.firstExam,
  );
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (_) => _CoachOfferDialog(
      intro: coachOfferIntro(correct: correct, total: total, passMark: passMark),
      campaign: campaign,
    ),
  );
}

class _CoachCongratsDialog extends StatelessWidget {
  const _CoachCongratsDialog({
    required this.title,
    required this.body,
    required this.correct,
    required this.total,
    required this.passMark,
  });

  final String title;
  final String body;
  final int correct;
  final int total;
  final int passMark;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PremiumDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MascotImage(AppImages.owlWave, height: 140, semanticLabel: 'AI Koç'),
          const SizedBox(height: AppSpacing.s2),
          BrandChip(label: 'AI KOÇ', icon: Icons.auto_awesome_rounded, color: p.primary),
          const SizedBox(height: AppSpacing.s3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.text, fontWeight: FontWeight.w900, fontSize: 22, height: 1.2),
          ),
          const SizedBox(height: AppSpacing.s3),
          // Sonucun kendisi — koçun yorumu bu sayılara dayanıyor, kullanıcı ikisini
          // birlikte görmeli.
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.s4,
              horizontal: AppSpacing.s2,
            ),
            decoration: BoxDecoration(
              color: p.surface2,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Expanded(child: _Stat(value: '$correct', label: 'doğru', color: p.primary)),
                Expanded(child: _Stat(value: '$total', label: 'soru')),
                Expanded(child: _Stat(value: '$passMark', label: 'geçme', color: p.accent)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.text2, fontSize: 13.5, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.s5),
          GradientPillButton(
            label: 'Koçun önerisini gör',
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: AppSpacing.s2),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Şimdi değil', style: TextStyle(color: p.text3)),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.color});
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color ?? p.text,
            ),
          ),
        ),
        Text(label, style: TextStyle(color: p.text3, fontSize: 11.5)),
      ],
    );
  }
}

class _CoachOfferDialog extends StatefulWidget {
  const _CoachOfferDialog({required this.intro, required this.campaign});
  final String intro;
  final Campaign? campaign;

  @override
  State<_CoachOfferDialog> createState() => _CoachOfferDialogState();
}

class _CoachOfferDialogState extends State<_CoachOfferDialog> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Sayaç yoksa zamanlayıcı da KURULMAZ — kampanyasız pencerede saniyede bir kare çizilmez.
    if (widget.campaign?.hasCountdownAt(_now) ?? false) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _now = DateTime.now());
        if (!(widget.campaign?.hasCountdownAt(_now) ?? false)) {
          _ticker?.cancel();
          _ticker = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final presentation = campaignPresentation(widget.campaign, _now);
    return PremiumDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              MascotImage(AppImages.owlWave, height: 64, semanticLabel: 'AI Koç'),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BrandChip(
                      label: 'AI KOÇ',
                      icon: Icons.auto_awesome_rounded,
                      color: p.primary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Senin için bir önerim var',
                      style: TextStyle(
                        color: p.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          // Koçun gerekçesi — kullanıcının KENDİ sonucundan türetilmiş.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.s4),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: p.primary.withValues(alpha: 0.30)),
            ),
            child: Text(
              widget.intro,
              style: TextStyle(color: p.text2, fontSize: 13.5, height: 1.45),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),

          // ── Görsel karşılaştırma — ücretsiz ↔ premium ────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ücretsiz ile Premium farkı',
              style: TextStyle(color: p.text, fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          _ComparisonTable(rows: premiumComparison),

          // ── Kampanya kartı — YALNIZ yürürlükte bir kampanya varsa ────────────────────
          if (presentation.showCard) ...[
            const SizedBox(height: AppSpacing.s4),
            _CampaignCard(
              campaign: widget.campaign!,
              showCountdown: presentation.showCountdown,
              remaining: presentation.remaining,
            ),
          ],

          const SizedBox(height: AppSpacing.s5),
          GradientPillButton(
            label: 'Premium paketi incele',
            gold: true,
            leading: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/premium?from=coach-offer');
            },
          ),
          const SizedBox(height: AppSpacing.s2),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Şimdi değil', style: TextStyle(color: p.text3)),
          ),
        ],
      ),
    );
  }
}

/// Ücretsiz ↔ Premium tablosu. Premium sütunu vurgulu, ücretsiz sütunu DÜRÜST.
class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.rows});
  final List<ComparisonRow> rows;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s3,
              AppSpacing.s3,
              AppSpacing.s3,
              AppSpacing.s2,
            ),
            child: Row(
              children: [
                const Expanded(flex: 5, child: SizedBox.shrink()),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Ücretsiz',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.text3, fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Premium',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: p.accent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s3,
                vertical: AppSpacing.s2,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      r.feature,
                      style: TextStyle(color: p.text2, fontSize: 12.5),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.free,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.text3, fontSize: 12.5),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.premium,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: p.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.s2),
        ],
      ),
    );
  }
}

/// Kampanya kartı — başlık, indirim, eski→yeni fiyat, açıklama ve (varsa) sayaç.
///
/// Bu bileşen kampanyanın KENDİSİNİ çizer; hangi kampanyanın yürürlükte olduğuna karar vermez.
/// Karar [activeCampaign] içinde, gösterim kararı [campaignPresentation] içindedir.
class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.campaign,
    required this.showCountdown,
    required this.remaining,
  });

  final Campaign campaign;
  final bool showCountdown;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = countdownParts(remaining);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.accent.withValues(alpha: 0.18), p.accent.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: p.accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  campaign.title,
                  style: TextStyle(color: p.text, fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
              if (campaign.hasDiscountAt(DateTime.now()))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.accent,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text(
                    '%${campaign.discountPercent}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          if (campaign.explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              campaign.explanation,
              style: TextStyle(color: p.text2, fontSize: 12.5, height: 1.4),
            ),
          ],
          if ((campaign.oldPriceLabel ?? '').isNotEmpty ||
              (campaign.newPriceLabel ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if ((campaign.oldPriceLabel ?? '').isNotEmpty)
                  Text(
                    campaign.oldPriceLabel!,
                    style: TextStyle(
                      color: p.text3,
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                if ((campaign.newPriceLabel ?? '').isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.s2),
                  Text(
                    campaign.newPriceLabel!,
                    style: TextStyle(
                      color: p.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (showCountdown) ...[
            const SizedBox(height: AppSpacing.s3),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 15, color: p.accent),
                const SizedBox(width: 6),
                Text(
                  'Bitmesine ${t.hours}:${t.minutes}:${t.seconds}',
                  style: TextStyle(color: p.accent, fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════════════════════
// Faz 4 + 5 — tutundurma: ödeme ekranı hatırlatması ve erişim kaybı sonrası geri kazanım
// ═══════════════════════════════════════════════════════════════════════════════════════════════

/// Açılışta çağrılır. **En fazla BİR pencere** açar ve önceliği daha somut olana verir.
///
/// SIRA — geri kazanım önce: erişimini kaybetmiş bir kullanıcıya "ödeme ekranına bakmıştın"
/// demek, olan biteni görmezden gelmektir. İkisi aynı anda AÇILMAZ; ikinci koşul bir sonraki
/// açılışa kalır (ve zaten her ikisi de ömür boyu tek seferliktir).
Future<void> maybeShowRetentionPrompt(
  BuildContext context,
  WidgetRef ref, {
  required int nowMs,
}) async {
  final premium = isPremium(ref.read(entitlementsProvider));

  // Sahiplik geçişlerini her açılışta gözle — kayıp anı buradan damgalanır.
  await ref.read(winBackProvider.notifier).observePremium(premium: premium, nowMs: nowMs);
  if (!context.mounted) return;

  if (shouldOfferWinBack(state: ref.read(winBackProvider), premium: premium, nowMs: nowMs)) {
    await ref.read(winBackProvider.notifier).recordOffered();
    if (!context.mounted) return;
    final campaign = activeCampaign(
      ref.read(campaignCatalogProvider),
      DateTime.fromMillisecondsSinceEpoch(nowMs),
      kind: CampaignKind.winBack,
    );
    await showWinBack(context, campaign: campaign);
    return;
  }

  if (shouldRemindAfterPaywall(
    state: ref.read(paywallReminderProvider),
    premium: premium,
    nowMs: nowMs,
  )) {
    await ref.read(paywallReminderProvider.notifier).recordReminded();
    if (!context.mounted) return;
    await showPaywallReminder(context);
  }
}

/// Faz 4 — ödeme ekranını satın almadan terk edenlere **tek** hatırlatma.
///
/// Ton bilinçli olarak alçak: baskı yok, sayaç yok, indirim iddiası yok. Yalnız "orada
/// bırakmıştın" der ve iki eşit seçenek sunar.
Future<void> showPaywallReminder(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (_) => const _PaywallReminderDialog(),
  );
}

/// Faz 5 — erişim sona erdi. Kampanya VARSA teklif, yoksa yalnız dürüst bilgilendirme.
Future<void> showWinBack(BuildContext context, {required Campaign? campaign}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (_) => _WinBackDialog(campaign: campaign),
  );
}

class _PaywallReminderDialog extends StatelessWidget {
  const _PaywallReminderDialog();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PremiumDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MascotImage(AppImages.owlWave, height: 120, semanticLabel: 'AI Koç'),
          const SizedBox(height: AppSpacing.s2),
          BrandChip(label: 'AI KOÇ', icon: Icons.auto_awesome_rounded, color: p.primary),
          const SizedBox(height: AppSpacing.s3),
          Text(
            'Premium paketine bakmıştın',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.text, fontWeight: FontWeight.w900, fontSize: 20, height: 1.2),
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            'Kararını vermek için acele etmene gerek yok — ücretsiz sürümle çalışmaya devam '
            'edebilirsin. Merak edersen paket burada duruyor.',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.text2, fontSize: 13.5, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.s5),
          GradientPillButton(
            label: 'Pakete tekrar bak',
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/premium?from=reminder');
            },
          ),
          const SizedBox(height: AppSpacing.s2),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Çalışmaya devam et', style: TextStyle(color: p.text3)),
          ),
        ],
      ),
    );
  }
}

class _WinBackDialog extends StatelessWidget {
  const _WinBackDialog({required this.campaign});
  final Campaign? campaign;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = DateTime.now();
    final presentation = campaignPresentation(campaign, now);
    return PremiumDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MascotImage(AppImages.owlWave, height: 120, semanticLabel: 'AI Koç'),
          const SizedBox(height: AppSpacing.s2),
          BrandChip(label: 'AI KOÇ', icon: Icons.auto_awesome_rounded, color: p.primary),
          const SizedBox(height: AppSpacing.s3),
          Text(
            'Premium erişimin sona erdi',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.text, fontWeight: FontWeight.w900, fontSize: 20, height: 1.2),
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            'İlerlemen, rozetlerin ve çalışma geçmişin duruyor — hiçbiri silinmedi. '
            'Ücretsiz sürümle çalışmaya devam edebilir, istediğinde geri dönebilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.text2, fontSize: 13.5, height: 1.45),
          ),
          // Kampanya VARSA gösterilir. Yoksa uydurma indirim ÜRETİLMEZ — pencere yalnız
          // dürüst bilgilendirme olarak kalır.
          if (presentation.showCard) ...[
            const SizedBox(height: AppSpacing.s4),
            _CampaignCard(
              campaign: campaign!,
              showCountdown: presentation.showCountdown,
              remaining: presentation.remaining,
            ),
          ],
          const SizedBox(height: AppSpacing.s5),
          GradientPillButton(
            label: presentation.showCard ? 'Teklife bak' : 'Premium paketi incele',
            gold: presentation.showCard,
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/premium?from=winback');
            },
          ),
          const SizedBox(height: AppSpacing.s2),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Ücretsiz devam et', style: TextStyle(color: p.text3)),
          ),
        ],
      ),
    );
  }
}
