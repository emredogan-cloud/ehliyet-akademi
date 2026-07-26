import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets.dart';
import '../../core/theme/tokens.dart';
import '../../data/auth/google_auth_service.dart';
import '../../design/brand.dart';
import '../../domain/auth/auth_controller.dart';

/// Giriş / kayıt ekranı. Sekme kabuğunun üstünde tam ekran; misafirler Profil'den ulaşır.
///
/// Beta Faz 5 — yeniden tasarım. Referanslar `apps/assets/interface-assets/`:
/// · `022` → **hero görseli** (`AppImages.authHero`; üst kısmı kırpıldı, gerekçe `assets.dart`)
/// · `023` → giriş formu **mockup'ı**; raster sevk EDİLMEZ, widget olarak uygulanır
/// · `024` → güven şeridi **mockup'ı**; widget olarak uygulanır
///
/// Mockup'lardan bilinçli SAPMALAR (gerekçeleri `BETA_PHASE_5_REPORT.md`):
/// · **"Apple ile giriş" YOK** — iOS derlemesi yok; çalışmayan düğme ölü gezinmedir.
/// · **"Şifremi unuttum?" GERÇEK** — `POST /api/auth/forgot` çağırır; süs değildir.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isRegister = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final ctrl = ref.read(authControllerProvider.notifier);
    final err = _isRegister
        ? await ctrl.register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          )
        : await ctrl.login(email: _email.text.trim(), password: _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      if (context.canPop()) context.pop();
    } else {
      setState(() => _error = err);
    }
  }

  /// Beta Faz 2 — Google ile giriş.
  ///
  /// Vazgeçme ('' dönüşü) hata DEĞİLDİR: hesap seçiciyi kapatan kullanıcıya mesaj gösterilmez.
  Future<void> _google() async {
    setState(() {
      _error = null;
      _busy = true;
    });
    final err = await ref.read(authControllerProvider.notifier).loginWithGoogle();
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      if (context.canPop()) context.pop();
    } else if (err.isNotEmpty) {
      setState(() => _error = err);
    }
  }

  /// Beta Faz 5 — parola sıfırlama.
  ///
  /// Sunucu hesabın varlığını **sızdırmaz**; bu yüzden yanıt ne olursa olsun aynı, dürüst mesaj
  /// gösterilir: "hesap varsa gönderdik". Sıfırlama web'deki sayfada tamamlanır.
  Future<void> _forgotPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(initialEmail: _email.text.trim()),
    );
    if (email == null || !mounted) return;

    setState(() => _busy = true);
    final err = await ref.read(authControllerProvider.notifier).requestPasswordReset(email);
    if (!mounted) return;
    setState(() => _busy = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          err ??
              'Bu adrese kayıtlı bir hesap varsa sıfırlama bağlantısını gönderdik. '
                  'E-postanı kontrol et.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Yapılandırılmadıysa düğme HİÇ gösterilmez — çalışmayan düğme ölü gezinmedir.
    final googleReady = ref.watch(googleAuthServiceProvider).isConfigured;

    return Scaffold(
      // AppBar YOK — bilinçli. Saydam bir AppBar kullanıldığında, ekran kaydırıldıkça geri oku
      // hero'daki marka işaretinin ÜSTÜNE biniyordu (cihazda görüldü). Üst alanı hero'nun
      // kendisi yönetiyor; geri düğmesi hero'nun içinde, durum çubuğu boşluğuna saygılı duruyor.
      body: SingleChildScrollView(
        child: Column(
          children: [
            _AuthHero(isRegister: _isRegister),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s5,
                AppSpacing.s5,
                AppSpacing.s5,
                AppSpacing.s6,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlowCard(
                        padding: const EdgeInsets.all(AppSpacing.s5),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isRegister ? 'Hesabını oluştur' : 'Tekrar hoş geldin',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: AppSpacing.s2),
                              Text(
                                _isRegister
                                    ? 'Birkaç saniye sürer; ilerlemen bu hesaba kaydedilir.'
                                    : 'Devam etmek için bilgilerini gir.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: p.text3, fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: AppSpacing.s5),
                              if (_isRegister) ...[
                                TextFormField(
                                  controller: _name,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Ad Soyad',
                                    prefixIcon: Icon(Icons.person_outline_rounded),
                                  ),
                                  validator: (v) => (v == null || v.trim().length < 2)
                                      ? 'Adını gir.'
                                      : null,
                                ),
                                const SizedBox(height: AppSpacing.s3),
                              ],
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  labelText: 'E-posta',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                ),
                                validator: (v) =>
                                    (v == null || !v.contains('@') || !v.contains('.'))
                                    ? 'Geçerli bir e-posta gir.'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.s3),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Parola',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    // Faz E13 erişilebilirlik: ipucu yoksa ekran okuyucu bu
                                    // düğmeyi anlamlı biçimde seslendiremiyordu.
                                    tooltip: _obscure ? 'Parolayı göster' : 'Parolayı gizle',
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.length < 8) ? 'En az 8 karakter.' : null,
                              ),
                              // Sıfırlama yalnız GİRİŞ kipinde anlamlı — kayıtta parolayı
                              // kullanıcı zaten belirliyor.
                              if (!_isRegister)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _busy ? null : _forgotPassword,
                                    child: const Text('Şifremi unuttum?'),
                                  ),
                                ),
                              if (_error != null) ...[
                                const SizedBox(height: AppSpacing.s2),
                                Text(
                                  _error!,
                                  style: TextStyle(color: p.red, fontSize: 13),
                                ),
                              ],
                              SizedBox(height: _isRegister ? AppSpacing.s5 : AppSpacing.s2),
                              GradientPillButton(
                                label: _isRegister ? 'Kayıt ol' : 'Giriş yap',
                                loading: _busy,
                                trailingIcon: Icons.arrow_forward_rounded,
                                onPressed: _busy ? null : _submit,
                              ),
                              if (googleReady) ...[
                                const SizedBox(height: AppSpacing.s4),
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: p.border)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.s3,
                                      ),
                                      child: Text(
                                        'veya',
                                        style: TextStyle(color: p.text3, fontSize: 13),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: p.border)),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.s4),
                                OutlinedButton.icon(
                                  onPressed: _busy ? null : _google,
                                  icon: const _GoogleMark(),
                                  label: const Text('Google ile devam et'),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.s2),
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => setState(() {
                                        _isRegister = !_isRegister;
                                        _error = null;
                                      }),
                                child: Text(
                                  _isRegister
                                      ? 'Zaten hesabın var mı? Giriş yap'
                                      : 'Hesabın yok mu? Kayıt ol',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s5),
                      const _TrustStrip(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Giriş ekranının hero şeridi (referans `022`).
///
/// Görselin sağ tarafı doludur (araç, işaretler, silüet); **sol tarafı bilinçli olarak boştur** ve
/// marka kimliği oraya yerleşir. Alt kenarda zemine eriyen bir geçiş var — böylece görsel
/// kartın altına doğru kesintisiz akar ve sert bir kenar oluşmaz.
class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.isRegister});
  final bool isRegister;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final topPad = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: 232 + topPad,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppImages.authHero,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            // Büyük görselin çözünürlüğü gösterim genişliğine indirilir (bellek).
            cacheWidth: 1080,
            // Görsel dekoratiftir; içeriği metinle zaten anlatılıyor.
            excludeFromSemantics: true,
          ),
          // Zemine eriyen geçiş — metin okunurluğu ve kesintisiz akış.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  p.bg.withValues(alpha: 0.15),
                  p.bg.withValues(alpha: 0.55),
                  p.bg,
                ],
                stops: const [0.0, 0.62, 1.0],
              ),
            ),
          ),
          // Geri düğmesi hero'nun içinde: durum çubuğu boşluğuna saygılı, koyu görselin
          // üstünde okunur. Ayrı bir AppBar olsaydı kaydırmada marka işaretiyle çakışırdı.
          Positioned(
            top: topPad + AppSpacing.s1,
            left: AppSpacing.s2,
            child: IconButton(
              tooltip: 'Geri',
              icon: const Icon(Icons.arrow_back_rounded),
              color: p.text,
              onPressed: () => context.canPop() ? context.pop() : null,
            ),
          ),
          Positioned(
            left: AppSpacing.s5,
            right: AppSpacing.s5,
            bottom: AppSpacing.s5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(size: 44),
                const SizedBox(height: AppSpacing.s3),
                Text(
                  'Ehliyet Akademi',
                  style: TextStyle(
                    color: p.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  isRegister
                      ? 'Hesabını oluştur, ilerlemen kaybolmasın.'
                      : 'Sınava hazırlığın kaldığı yerden devam etsin.',
                  style: TextStyle(color: p.text2, fontSize: 13.5, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Güven şeridi (referans `024`) — üç kısa güvence.
///
/// Dar ekranda yan yana üç sütun sıkışacağı için **dikey listeye** düşer; mockup'ın yatay
/// düzeni geniş ekranlarda korunur.
class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  static const _items = <({IconData icon, String title, String subtitle})>[
    (
      icon: Icons.verified_user_outlined,
      title: 'Güvenli Platform',
      subtitle: 'Verilerin korunur',
    ),
    (
      icon: Icons.menu_book_outlined,
      title: 'Güncel İçerik',
      // Bu ifade ürünün MEVCUT ve yayında olan iddiasıdır (web giriş sayfası) — burada
      // yeni bir iddia üretilmiyor, var olanla tutarlı kalınıyor.
      subtitle: 'MEB/MTSK müfredatına uygun',
    ),
    (
      icon: Icons.emoji_events_outlined,
      title: 'Sınava Hazırlık',
      subtitle: 'Başarıya giden yol',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Widget item(({IconData icon, String title, String subtitle}) e, {required bool row}) {
      final text = Column(
        crossAxisAlignment: row ? CrossAxisAlignment.start : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            e.title,
            style: TextStyle(color: p.text, fontSize: 13.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(e.subtitle, style: TextStyle(color: p.text3, fontSize: 11.5, height: 1.3)),
        ],
      );
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBadge(icon: e.icon, color: p.primary, size: 36),
          const SizedBox(width: AppSpacing.s3),
          row ? Flexible(child: text) : Expanded(child: text),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: p.border),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          // Üç sütun ancak yeterli genişlikte okunur kalır; altında dikey listeye düşer.
          if (c.maxWidth >= 420) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < _items.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 1,
                      height: 34,
                      color: p.border,
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
                    ),
                  Flexible(child: item(_items[i], row: true)),
                ],
              ],
            );
          }
          return Column(
            children: [
              for (var i = 0; i < _items.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.s4),
                item(_items[i], row: false),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Parola sıfırlama e-postası sorma diyaloğu.
class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail});
  final String initialEmail;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _email = TextEditingController(text: widget.initialEmail);
  final _key = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _send() {
    if (!_key.currentState!.validate()) return;
    Navigator.of(context).pop(_email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      title: const Text('Parolamı sıfırla'),
      content: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'E-posta adresini gir; sıfırlama bağlantısını gönderelim.',
              style: TextStyle(color: p.text3, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.s4),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (v) => (v == null || !v.contains('@') || !v.contains('.'))
                  ? 'Geçerli bir e-posta gir.'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Vazgeç')),
        FilledButton(onPressed: _send, child: const Text('Gönder')),
      ],
    );
  }
}

/// Google'ın dört renkli "G" işareti.
///
/// Google marka kılavuzu, işaretin renklerinin değiştirilmemesini ister; bu yüzden bu widget
/// tasarım token'larını KULLANMAZ ve tema ile değişmez — bilinçli bir istisnadır.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  // Google marka renkleri — sabit olmak ZORUNDA (marka kılavuzu).
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final stroke = r * 0.42;
    final rect = Rect.fromCircle(center: c, radius: r - stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Dört çeyrek yay — sadeleştirilmiş "G".
    canvas.drawArc(rect, -0.45, 1.25, false, paint..color = _blue);
    canvas.drawArc(rect, 0.85, 1.35, false, paint..color = _green);
    canvas.drawArc(rect, 2.25, 1.35, false, paint..color = _yellow);
    canvas.drawArc(rect, 3.65, 1.35, false, paint..color = _red);

    // "G"nin yatay çubuğu.
    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - stroke / 2, r - stroke / 2, stroke),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
