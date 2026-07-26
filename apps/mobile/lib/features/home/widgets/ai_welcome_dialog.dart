import 'package:flutter/material.dart';

import '../../../core/assets.dart';
import '../../../core/theme/tokens.dart';
import '../../../design/brand.dart';

/// Beta R1 — Ana Sayfa göründükten SONRA açılan, ortalanmış premium AI karşılama popup'ı.
///
/// KONUM BİLİNÇLİ: onboarding'e sayfa EKLENMEZ. Kullanıcı önce uygulamanın içine iner, ürünü
/// görür; tanıtım ondan sonra gelir. Böylece tanıtım bir engel değil, bir karşılama olur.
///
/// TEK SEFERLİK: kapı çağıranda ([aiWelcomeSeenProvider]) — bu widget durum tutmaz. Popup
/// **hangi yolla kapanırsa kapansın** (CTA · zemin dokunuşu · geri tuşu) çağıran işareti koyar.
///
/// Etkileşim konsepti `FormAI-FitnessKoçu`'nun premium karşılama sayfasından alındı; **kodu
/// değil**: renkler, tipografi ve bileşenler bu projenin tasarım token'larından gelir
/// (`design_tokens_test.dart` sabit renk kullanımını zaten engelliyor).
class AiWelcomeDialog extends StatelessWidget {
  const AiWelcomeDialog({super.key});

  /// Popup'ı açar ve kapanınca tamamlanır.
  ///
  /// Zemin dokunuşuyla kapanabilir (`barrierDismissible: true`) — "doğal biçimde kapanır"
  /// şartı budur; kullanıcı hapsedilmez.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => const AiWelcomeDialog(),
    );
  }

  static const _rows = <(IconData, String, String)>[
    (
      Icons.auto_awesome_rounded,
      'AI Koç yanında',
      'Takıldığın yeri sor; anlaşılır, kaynağa dayalı bir açıklama al.',
    ),
    (
      Icons.menu_book_rounded,
      'Öğrenme sistemi',
      'Dersler, trafik işaretleri, araç tekniği ve videolar tek akışta.',
    ),
    (
      Icons.insights_rounded,
      'Sana özel öneriler',
      'Zayıf konuların ölçülür, günlük planın buna göre kurulur.',
    ),
    (
      Icons.groups_rounded,
      'Topluluk',
      'İstersen katıl; sıralama, gruplar ve arkadaşların seni bekler.',
    ),
    (
      Icons.workspace_premium_rounded,
      'Premium',
      'Dilersen her şeyin kilidini tek pakette açarsın.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final media = MediaQuery.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s5,
        vertical: AppSpacing.s6,
      ),
      child: ConstrainedBox(
        // Küçük ekranda/büyük yazıda taşmasın: yükseklik sınırlanır, içerik kendi içinde kayar.
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: media.size.height * 0.86,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg + 6),
            border: Border.all(color: p.primary.withValues(alpha: 0.45), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: p.primary.withValues(alpha: 0.22),
                blurRadius: 32,
                spreadRadius: -6,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s5,
                    AppSpacing.s6,
                    AppSpacing.s5,
                    AppSpacing.s3,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Crest(),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        'Hoş geldin!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        'Ben AI Koç. Sınava kadar seninleyim — uygulamada seni neler bekliyor?',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.text2, fontSize: 13.5, height: 1.45),
                      ),
                      const SizedBox(height: AppSpacing.s5),
                      for (var i = 0; i < _rows.length; i++) ...[
                        if (i != 0) const SizedBox(height: AppSpacing.s4),
                        _Row(icon: _rows[i].$1, title: _rows[i].$2, body: _rows[i].$3),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s5,
                  AppSpacing.s2,
                  AppSpacing.s5,
                  AppSpacing.s5,
                ),
                child: GradientPillButton(
                  label: 'Hadi başlayalım',
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Parlayan yuvarlak amblem — içinde maskot.
class _Crest extends StatelessWidget {
  const _Crest();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [p.primary.withValues(alpha: 0.28), p.primary700.withValues(alpha: 0.16)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: p.primary.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [
          BoxShadow(color: p.primary.withValues(alpha: 0.35), blurRadius: 26, spreadRadius: -4),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: MascotImage(AppImages.owlWave, semanticLabel: 'AI Koç'),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.base - 2),
            color: p.primary.withValues(alpha: 0.14),
            border: Border.all(color: p.primary.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, color: p.primary, size: 21),
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(color: p.text, fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(body, style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}
