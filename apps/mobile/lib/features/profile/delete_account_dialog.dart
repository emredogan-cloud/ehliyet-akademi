import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/auth/account_api.dart';

/// Faz 5 — hesap silme penceresi.
///
/// Referans: `apps/assets/delete-account-pop-up.png`. Yerleşim, hiyerarşi ve metinler referanstan
/// birebir alındı: kırmızı halkalı çöp kutusu amblemi, iki satırlık başlık, içinde "geri alınamaz"
/// kırmızı olan açıklama, "Silinecek verileriniz" listesi (dört satır, ince ayıraçlar), kırmızı
/// zeminli bilgi kutusu ve iki düğme.
///
/// BİLİNÇLİ SAPMA — ikinci adım. Referans tek adımlı; oysa silme geri alınamaz ve oturum 30 gün
/// açık kalıyor. Kilidi açık bir telefon, tek dokunuşla hesabı yok etmeye yeterdi. Bu yüzden
/// "Evet, hesabımı sil" doğrudan silmez; sunucunun bildirdiği koşula göre ikinci bir onay alır:
/// · parolası olan hesapta **parola**,
/// · Google ile açılmış hesapta (parola YOK, istenemez) **e-posta yazdırma**.
/// Sunucu da aynı kuralı uygular; istemcideki adım tek başına bir güvenlik iddiası değildir.
Future<bool> showDeleteAccountDialog(BuildContext context) async {
  final deleted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (_) => const _DeleteAccountDialog(),
  );
  return deleted ?? false;
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _confirmController = TextEditingController();

  /// İkinci onay adımına geçildi mi?
  bool _confirming = false;
  bool _busy = false;
  String? _error;

  /// Sunucunun bildirdiği koşullar; gelmediyse (ağ yok) en TEMKİNLİ varsayım: parola iste.
  AccountDeletionRequirements? _requirements;
  bool _loadingRequirements = true;

  @override
  void initState() {
    super.initState();
    _loadRequirements();
  }

  Future<void> _loadRequirements() async {
    final req = await ref.read(accountApiProvider).requirements();
    if (!mounted) return;
    setState(() {
      _requirements = req;
      _loadingRequirements = false;
    });
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool get _needsPassword => _requirements?.requiresPassword ?? true;
  String get _email => _requirements?.email ?? '';

  /// İkinci adımdaki giriş geçerli mi?
  bool get _confirmationValid {
    final value = _confirmController.text.trim();
    if (_needsPassword) return value.isNotEmpty;
    return value.toLowerCase() == _email.toLowerCase() && _email.isNotEmpty;
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(accountApiProvider)
        .delete(password: _needsPassword ? _confirmController.text : null);
    if (!mounted) return;
    switch (result) {
      case AccountDeleted():
        Navigator.of(context).pop(true);
      case AccountDeletionWrongPassword(:final message):
        setState(() {
          _busy = false;
          _error = message;
        });
      case AccountDeletionFailed(:final message):
        setState(() {
          _busy = false;
          _error = message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s6),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.surface2, p.surface],
          ),
          borderRadius: BorderRadius.circular(AppRadii.lg + 6),
          // Referanstaki turkuaz kenar ışıması — tehlike kırmızısı İÇERİDE kalır; çerçeve markanın.
          border: Border.all(color: p.primary.withValues(alpha: 0.42)),
          boxShadow: [
            BoxShadow(
              color: p.primary.withValues(alpha: 0.16),
              blurRadius: 44,
              spreadRadius: -10,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.86),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s5,
                  AppSpacing.s6,
                  AppSpacing.s5,
                  AppSpacing.s5,
                ),
                child: _confirming ? _confirmStep(p) : _warningStep(p),
              ),
            ),
            Positioned(
              top: AppSpacing.s2,
              right: AppSpacing.s2,
              child: IconButton(
                tooltip: 'Kapat',
                onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                icon: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.surface3,
                    border: Border.all(color: p.border),
                  ),
                  child: Icon(Icons.close_rounded, color: p.text2, size: 19),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. adım — uyarı (referans tasarım) ─────────────────────────────────────
  Widget _warningStep(AppPalette p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _DangerEmblem(),
        const SizedBox(height: AppSpacing.s5),
        Text(
          'Hesabınızı silmek\nistediğinize emin misiniz?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: p.text,
            fontSize: 23,
            height: 1.25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        // "geri alınamaz" vurgusu referanstaki gibi kırmızı — cümlenin ağırlık merkezi orada.
        Text.rich(
          TextSpan(
            style: TextStyle(color: p.text2, fontSize: 14, height: 1.45),
            children: [
              const TextSpan(text: 'Bu işlem '),
              TextSpan(
                text: 'geri alınamaz',
                style: TextStyle(color: p.red, fontWeight: FontWeight.w700),
              ),
              const TextSpan(
                text: '. Hesabınızı silerseniz tüm verileriniz kalıcı olarak silinecektir.',
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s5),
        _DeletedDataCard(),
        const SizedBox(height: AppSpacing.s4),
        _ReassuranceBox(),
        const SizedBox(height: AppSpacing.s5),
        _DangerButton(
          label: 'Evet, hesabımı sil',
          icon: Icons.delete_outline_rounded,
          // Koşullar gelmeden ilerlenmez: hangi onayın isteneceğini bilmiyoruz.
          onPressed: _loadingRequirements ? null : () => setState(() => _confirming = true),
          loading: _loadingRequirements,
        ),
        const SizedBox(height: AppSpacing.s3),
        _GhostButton(
          label: 'İptal, vazgeçtim',
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }

  // ── 2. adım — yeniden kimlik doğrulama ─────────────────────────────────────
  Widget _confirmStep(AppPalette p) {
    final label = _needsPassword ? 'Parolan' : 'E-posta adresin';
    final hint = _needsPassword
        ? 'Devam etmek için parolanı gir.'
        : 'Onaylamak için e-posta adresini yaz: $_email';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _DangerEmblem(),
        const SizedBox(height: AppSpacing.s5),
        Text(
          'Son bir adım',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: p.text,
            fontSize: 23,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: TextStyle(color: p.text2, fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: AppSpacing.s5),
        TextField(
          controller: _confirmController,
          obscureText: _needsPassword,
          autofocus: true,
          enabled: !_busy,
          autofillHints: _needsPassword ? const [AutofillHints.password] : null,
          keyboardType: _needsPassword ? null : TextInputType.emailAddress,
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(
            labelText: label,
            errorText: _error,
            prefixIcon: Icon(_needsPassword ? Icons.lock_outline_rounded : Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.s5),
        _DangerButton(
          label: 'Hesabımı kalıcı olarak sil',
          icon: Icons.delete_forever_rounded,
          loading: _busy,
          onPressed: _confirmationValid && !_busy ? _delete : null,
        ),
        const SizedBox(height: AppSpacing.s3),
        _GhostButton(
          label: 'Vazgeç',
          onPressed: _busy ? null : () => setState(() => _confirming = false),
        ),
      ],
    );
  }
}

/// Kırmızı halkalı çöp kutusu amblemi + çevresindeki küçük kıvılcımlar (referanstaki başlık ögesi).
class _DangerEmblem extends StatelessWidget {
  const _DangerEmblem();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: 132,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Kıvılcımlar salt dekoratiftir → ekran okuyucudan gizlenir.
          Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(painter: _SparkPainter(p.red)),
            ),
          ),
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.red.withValues(alpha: 0.10),
              border: Border.all(color: p.red, width: 2.2),
              boxShadow: [
                BoxShadow(color: p.red.withValues(alpha: 0.42), blurRadius: 26, spreadRadius: -4),
              ],
            ),
            child: Icon(Icons.delete_outline_rounded, color: p.red, size: 38),
          ),
        ],
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Sabit açılar/uzaklıklar — rastgelelik yok, her açılışta aynı görünür.
    const specs = <(double angleDeg, double distance, double radius, double alpha)>[
      (-120, 52, 1.8, 0.75),
      (-95, 60, 1.2, 0.5),
      (-58, 54, 2.0, 0.8),
      (-30, 62, 1.3, 0.45),
      (200, 50, 1.5, 0.6),
      (250, 58, 1.1, 0.4),
    ];
    final center = size.center(Offset.zero);
    for (final (deg, dist, r, a) in specs) {
      final rad = deg * math.pi / 180;
      canvas.drawCircle(
        center + Offset(math.cos(rad), math.sin(rad)) * dist,
        r,
        Paint()..color = color.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.color != color;
}

/// "Silinecek verileriniz" listesi — referanstaki dört satır, ince ayıraçlarla.
class _DeletedDataCard extends StatelessWidget {
  static const rows = <(IconData, String, String)>[
    (Icons.person_outline_rounded, 'Kişisel bilgileriniz', 'Ad, e-posta, profil bilgileri'),
    (Icons.menu_book_outlined, 'Öğrenme verileriniz', 'İlerleme, test sonuçları, istatistikler'),
    (Icons.bookmark_border_rounded, 'Kayıtlı içerikleriniz', 'Yer işaretleri, notlar, favoriler'),
    (Icons.chat_bubble_outline_rounded, 'Topluluk verileriniz', 'Yorumlarınız, paylaşımlarınız'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s4, AppSpacing.s4, AppSpacing.s2),
      decoration: BoxDecoration(
        color: p.surface3.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadii.base),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          Text(
            'Silinecek verileriniz:',
            style: TextStyle(color: p.red, fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
          const SizedBox(height: AppSpacing.s3),
          for (var i = 0; i < rows.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(rows[i].$1, color: p.primary, size: 24),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rows[i].$2,
                        style: TextStyle(color: p.text, fontWeight: FontWeight.w600, fontSize: 14.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rows[i].$3,
                        style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (i != rows.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
                child: Divider(height: 1, color: p.border),
              )
            else
              const SizedBox(height: AppSpacing.s3),
          ],
        ],
      ),
    );
  }
}

/// Referanstaki kırmızı zeminli bilgi kutusu — "aynı e-posta ile yeniden açabilirsin".
class _ReassuranceBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: p.red.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadii.base),
        border: Border.all(color: p.red.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: p.red, size: 24),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              'Hesabınızı sildikten sonra aynı e-posta ile yeni hesap oluşturabilirsiniz.',
              style: TextStyle(color: p.text2, fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kırmızı degrade birincil düğme (yıkıcı eylem).
class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !loading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppRadii.base),
            child: Ink(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [p.red, Color.lerp(p.red, Colors.black, 0.22)!],
                ),
                borderRadius: BorderRadius.circular(AppRadii.base),
                boxShadow: [
                  BoxShadow(
                    color: p.red.withValues(alpha: 0.38),
                    blurRadius: 22,
                    spreadRadius: -6,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    // `FittedBox` ŞART: "Hesabımı kalıcı olarak sil" + simge, dar telefonlarda
                    // (ve büyük sistem yazı ölçeğinde) düğmeye sığmıyor ve satır TAŞIYOR
                    // (testte 418 dp'de yakalandı). Kırpmak yerine yazıyı küçültmek doğru:
                    // yıkıcı bir eylemin etiketi yarım okunmamalı.
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, color: Colors.white, size: 21),
                              const SizedBox(width: AppSpacing.s2),
                              Text(
                                label,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Çerçeveli ikincil düğme (güvenli çıkış yolu) — referanstaki turkuaz kenarlı düğme.
class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          side: BorderSide(color: p.primary.withValues(alpha: 0.55)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.base)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
        ),
        child: Text(label),
      ),
    );
  }
}
