import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// Faz 1 — koç işaretleri (coach marks): ilk açılışta ürünü ELEMENTİN ÜSTÜNDE tanıtan tur.
///
/// TASARIM KARARI — neden hazır bir paket değil: turun anlamlı olması için işaretlerin gerçek
/// yerleşime bağlanması gerekir (alt gezinme çubuğu kabukta, kartlar kaydırılabilir bir listede).
/// Hazır paketler ya kabuğun üstünü kaplayamıyor ya da hedefi görünür alana getiremiyor. Buradaki
/// sistem üç parçadan oluşur ve üçü de yeniden kullanılabilir:
///
/// · [CoachAnchor] — "beni tanıtabilirsin" diyen sarmalayıcı; kendini bir kimlikle kaydeder.
/// · [CoachMarkHost] — kayıt defterini tutar ve turu ekranın EN ÜSTÜNDE çizer.
/// · [CoachMarkStep] — tek bir adımın içeriği.
///
/// Turun kendisi ekranlardan bağımsızdır: hangi kimliklerin tanıtılacağını çağıran belirler.

/// Tek bir tur adımı.
@immutable
class CoachMarkStep {
  const CoachMarkStep({
    required this.anchorId,
    required this.title,
    required this.body,
    required this.icon,
    this.radius = AppRadii.lg,
  });

  /// Hangi [CoachAnchor] aydınlatılacak.
  final String anchorId;
  final String title;
  final String body;
  final IconData icon;

  /// Işık halkasının köşe yarıçapı — dairesel hedefler için büyük değer verilir.
  final double radius;
}

/// Kayıt defteri: kimlik → hedefin anahtarı. [CoachMarkHost] sağlar, [CoachAnchor] kullanır.
class CoachMarkRegistry extends InheritedWidget {
  const CoachMarkRegistry({super.key, required this.keys, required super.child});

  final Map<String, GlobalKey> keys;

  static CoachMarkRegistry? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CoachMarkRegistry>();

  @override
  bool updateShouldNotify(CoachMarkRegistry old) => !identical(old.keys, keys);
}

/// Tanıtılabilir bir öğe. Turda kullanılmıyorsa hiçbir maliyeti yoktur (tek `KeyedSubtree`).
///
/// KAYDIRILAN LİSTELERDE ÖNEMLİ: `ListView` görünürlükten çıkan çocuklarını SÖKER. Çapa sökülünce
/// `GlobalKey.currentContext` null olur ve tur, hedefi "yok" sanıp adımı atlar — hatta geri
/// giderken turu tamamen bitirir. Bu yüzden çapa kendini canlı tutar ([keepAlive]); ölçülebilir
/// maliyeti yoktur (ekran başına birkaç öğe) ve karşılığında tur her yönde çalışır.
class CoachAnchor extends StatefulWidget {
  const CoachAnchor({super.key, required this.id, required this.child, this.keepAlive = true});

  final String id;
  final Widget child;

  /// Kaydırılan listelerde sökülmeyi engeller. Çok uzun listelerde (yüzlerce satır) kapatılabilir;
  /// o durumda yalnız ekranda olan çapalar tanıtılabilir.
  final bool keepAlive;

  @override
  State<CoachAnchor> createState() => _CoachAnchorState();
}

class _CoachAnchorState extends State<CoachAnchor> with AutomaticKeepAliveClientMixin {
  final GlobalKey _key = GlobalKey();
  Map<String, GlobalKey>? _registry;

  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Kayıt defteri ağaçta yoksa (ör. tekil widget testi) çapa sessizce sıradan bir sarmalayıcıya
    // dönüşür — ekran yine çalışır. Tur, olmayan bir çapayı zaten atlar.
    final registry = CoachMarkRegistry.maybeOf(context)?.keys;
    if (identical(registry, _registry)) return;
    _registry?.remove(widget.id);
    _registry = registry;
    _registry?[widget.id] = _key;
  }

  @override
  void dispose() {
    // Aynı kimlik başka bir çapa tarafından yeniden kaydedilmiş olabilir; yalnız KENDİ anahtarını
    // sil, yoksa yeni çapanın kaydını düşürürsün.
    if (_registry?[widget.id] == _key) _registry?.remove(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin sözleşmesi
    return KeyedSubtree(key: _key, child: widget.child);
  }
}

/// Turu yöneten ev sahibi. Uygulama kabuğunu sarmalar; böylece alt gezinme çubuğu da
/// aydınlatılabilir.
class CoachMarkHost extends StatefulWidget {
  const CoachMarkHost({super.key, required this.child});

  final Widget child;

  /// En yakın ev sahibini bul (tur buradan başlatılır).
  static CoachMarkHostState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<CoachMarkHostState>();

  @override
  CoachMarkHostState createState() => CoachMarkHostState();
}

class CoachMarkHostState extends State<CoachMarkHost> with SingleTickerProviderStateMixin {
  final Map<String, GlobalKey> _keys = {};

  List<CoachMarkStep> _steps = const [];
  int _index = 0;
  bool _active = false;
  Rect? _spot;
  VoidCallback? _onFinished;

  /// DİKKAT — `late final ... = AnimationController(...)` KULLANILMAZ.
  ///
  /// Tembel alan hiç okunmadıysa (tur hiç başlamadıysa) `dispose()` içindeki ilk okuma denetleyiciyi
  /// SÖKÜLME sırasında kurar; `TickerMode` araması o anda "deactivated widget" hatası verir.
  /// Testlerin çoğunda tur kapalı olduğu için bu her koşuda patlıyordu. Erken kurulum, sorunu
  /// baştan yok eder ve maliyeti yok denecek kadar azdır.
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  }

  /// Turu başlat. Çapası bulunamayan adımlar SESSİZCE atlanır — eksik bir çapa yüzünden
  /// kullanıcının karşısına boş bir ışık halkası çıkmaz.
  Future<void> start(List<CoachMarkStep> steps, {VoidCallback? onFinished}) async {
    if (_active || steps.isEmpty || !mounted) return;
    _steps = steps;
    _index = 0;
    _onFinished = onFinished;
    setState(() => _active = true);
    if (!MediaQuery.disableAnimationsOf(context)) _pulse.repeat(reverse: true);
    await _goTo(0);
  }

  /// Turu bitir (Atla ya da son adımdan sonra).
  void finish() {
    if (!_active) return;
    _pulse.stop();
    setState(() {
      _active = false;
      _spot = null;
    });
    final done = _onFinished;
    _onFinished = null;
    done?.call();
  }

  void next() {
    if (_index >= _steps.length - 1) {
      finish();
    } else {
      _goTo(_index + 1);
    }
  }

  void previous() {
    if (_index > 0) _goTo(_index - 1);
  }

  /// Hedefe git: önce görünür alana KAYDIR, sonra ışığı oraya taşı.
  ///
  /// Kaydırma şart: kartlar uzun bir listede; ikinci adımın hedefi çoğu telefonda ekranın altında
  /// kalıyor ve ışık halkası ekran dışında çiziliyordu.
  Future<void> _goTo(int index) async {
    if (!mounted) return;
    var target = index;
    Rect? rect;
    while (target >= 0 && target < _steps.length) {
      rect = await _resolve(_steps[target]);
      if (rect != null) break;
      // Çapa yok → aynı yönde ilerlemeye devam et.
      target = target >= _index ? target + 1 : target - 1;
    }
    if (!mounted) return;
    if (rect == null) {
      finish();
      return;
    }
    setState(() {
      _index = target;
      _spot = rect;
    });
  }

  /// Bir adımın ekrandaki dikdörtgenini bul; çapa yoksa (ya da bu arada söküldüyse) null.
  Future<Rect?> _resolve(CoachMarkStep step) async {
    final key = _keys[step.anchorId];
    final anchorContext = key?.currentContext;
    if (anchorContext == null || !anchorContext.mounted) return null;

    // `Scrollable.maybeOf` DEĞİL: o, çapa öğesine bir BAĞIMLILIK kaydeder (her kaydırmada çapa
    // yeniden kurulur) ve sökülmüş bir öğede çağrılırsa "deactivated widget" hatası verir.
    // Durum aramak yan etkisizdir.
    final scrollable = anchorContext.findAncestorStateOfType<ScrollableState>();
    if (scrollable != null) {
      await Scrollable.ensureVisible(
        anchorContext,
        alignment: 0.35,
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.base,
        curve: AppMotion.easeOut,
      );
      if (!mounted) return null;
      // Kaydırma bittikten SONRA ölç: kaydırmadan önceki dikdörtgen artık geçerli değil.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return null;
    }

    final box = key?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    final origin = box.localToGlobal(Offset.zero);
    final rect = origin & box.size;
    // Ekran dışına düşen bir hedefi aydınlatmak anlamsızdır (kaydırma başarısız olmuş demektir).
    return rect.isEmpty ? null : rect;
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CoachMarkRegistry(
      keys: _keys,
      child: Stack(
        children: [
          widget.child,
          if (_active && _spot != null)
            Positioned.fill(
              child: _CoachMarkOverlay(
                step: _steps[_index],
                index: _index,
                total: _steps.length,
                spot: _spot!,
                pulse: _pulse,
                onNext: next,
                onPrevious: _index > 0 ? previous : null,
                onSkip: finish,
              ),
            ),
        ],
      ),
    );
  }
}

/// Karartma + ışık halkası + baloncuk. Tek bir katman; içerik yeniden boyanmaz.
class _CoachMarkOverlay extends StatelessWidget {
  const _CoachMarkOverlay({
    required this.step,
    required this.index,
    required this.total,
    required this.spot,
    required this.pulse,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
  });

  final CoachMarkStep step;
  final int index;
  final int total;
  final Rect spot;
  final Animation<double> pulse;
  final VoidCallback onNext;
  final VoidCallback? onPrevious;
  final VoidCallback onSkip;

  /// Işık halkasının hedefin çevresinde bıraktığı nefes payı.
  static const double _padding = 8;

  /// Işıkla baloncuk arasındaki mesafe.
  static const double _gap = 16;

  @override
  Widget build(BuildContext context) {
    // ÖLÇÜ KAYNAĞI: `MediaQuery.size` DEĞİL, gerçek kısıtlar.
    //
    // Bindirme `Positioned.fill` ile kabuğun tamamını kaplar; kısıtları ekranın GERÇEK boyutudur.
    // `MediaQuery.size` ise testte `setSurfaceSize` ile büyütülmüş yüzeyi yansıtmaz (görünüm 1400
    // yüksekliğinde çizilirken MediaQuery 600 diyordu) — baloncuk bu yüzden ekranın dışına
    // konumlanıyor ve düğmeleri dokunulamaz oluyordu.
    return LayoutBuilder(builder: (context, constraints) => _build(context, constraints.biggest));
  }

  Widget _build(BuildContext context, Size size) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final media = MediaQuery.of(context);
    final hole = spot.inflate(_padding);

    // YERLEŞİM, "hedef ekranın üst yarısında mı" gibi bir tahminle DEĞİL, ölçülen BOŞLUKLA
    // belirlenir. Tahminle yapıldığında ekranın tam ortasındaki bir hedefin altına konan uzun
    // baloncuk ekranın dışına taşıyor ve düğmeleri dokunulamaz hâle getiriyordu (testte yakalandı).
    final safeTop = media.padding.top;
    final safeBottom = media.padding.bottom;
    final spaceBelow = size.height - safeBottom - hole.bottom - _gap;
    final spaceAbove = hole.top - safeTop - _gap;
    final below = spaceBelow >= spaceAbove;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      // `Material` ŞART — süs değil.
      //
      // Bindirme kabuğun `Scaffold`'unun ÜSTÜNDE duruyor, yani ağaçta bir `Material` atası YOK.
      // Flutter bu durumda metni "eksik stil" işaretiyle çizer: daktilo yazı tipi + SARI ÇİFT
      // ALT ÇİZGİ. Widget testleri bunu yakalamadı (metin bulunuyordu, yalnız YANLIŞ çiziliyordu);
      // cihazda ilk bakışta görüldü. Saydam Material, metne varsayılan stili verir ve mürekkep
      // dalgalarını da mümkün kılar.
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
        children: [
          // Karartma + delik. Zemine dokunmak ilerletir (yaygın kalıp) ama arkadaki gerçek
          // arayüze dokunuş GEÇMEZ: tur sırasında yanlışlıkla bir şey açılmamalı.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onNext,
              child: AnimatedBuilder(
                animation: pulse,
                builder: (context, _) => CustomPaint(
                  painter: _SpotlightPainter(
                    hole: hole,
                    radius: step.radius,
                    // Hareket azaltıldığında halka nefes almaz; sabit ve net durur.
                    pulse: reduceMotion ? 0 : pulse.value,
                    ring: context.palette.primary,
                  ),
                ),
              ),
            ),
          ),
          _TooltipCard(
            step: step,
            index: index,
            total: total,
            hole: hole,
            below: below,
            screenHeight: size.height,
            // Baloncuk asla ekranın dışına taşmaz: sığmıyorsa KENDİ İÇİNDE kaydırılır.
            maxHeight: (below ? spaceBelow : spaceAbove).clamp(140.0, size.height),
            reduceMotion: reduceMotion,
            onNext: onNext,
            onPrevious: onPrevious,
            onSkip: onSkip,
          ),
        ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({
    required this.hole,
    required this.radius,
    required this.pulse,
    required this.ring,
  });

  final Rect hole;
  final double radius;
  final double pulse;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(hole, Radius.circular(radius));

    // Karartma: tam ekran eksi delik. `Path.combine` tek geçişte çizilir; iki ayrı katman
    // (karartma + kırpma) yerine bunu seçmek, saydamlık karışımını da tek adımda bitirir.
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(rrect),
      ),
      Paint()..color = const Color(0xFF03070F).withValues(alpha: 0.82),
    );

    // Net kenar halkası.
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ring.withValues(alpha: 0.95),
    );

    // Nefes alan dış halka — hedefin "canlı" olduğunu söyler.
    if (pulse > 0) {
      final grow = 4 + pulse * 10;
      canvas.drawRRect(
        RRect.fromRectAndRadius(hole.inflate(grow), Radius.circular(radius + grow)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = ring.withValues(alpha: 0.38 * (1 - pulse)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.hole != hole || old.pulse != pulse || old.radius != radius || old.ring != ring;
}

class _TooltipCard extends StatelessWidget {
  const _TooltipCard({
    required this.step,
    required this.index,
    required this.total,
    required this.hole,
    required this.below,
    required this.screenHeight,
    required this.maxHeight,
    required this.reduceMotion,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
  });

  final CoachMarkStep step;
  final int index;
  final int total;
  final Rect hole;
  final bool below;

  /// Gerçek ekran yüksekliği (bindirmenin kısıtlarından ölçüldü — MediaQuery'den DEĞİL).
  final double screenHeight;
  final double maxHeight;
  final bool reduceMotion;
  final VoidCallback onNext;
  final VoidCallback? onPrevious;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final last = index == total - 1;

    final card = Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s4, AppSpacing.s5, AppSpacing.s4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.surface2, p.surface],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: p.primary.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: p.primary.withValues(alpha: 0.22),
            blurRadius: 34,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(step.icon, color: p.primary, size: 19),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  step.title,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: p.text),
                ),
              ),
              Text(
                '${index + 1}/$total',
                style: TextStyle(color: p.text3, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(step.body, style: TextStyle(color: p.text2, fontSize: 13.5, height: 1.45)),
          const SizedBox(height: AppSpacing.s3),
          // İlerleme çizgisi — turun ne kadarında olduğunu tek bakışta söyler.
          Row(
            children: [
              for (var i = 0; i < total; i++)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
                    decoration: BoxDecoration(
                      color: i <= index ? p.primary : p.border,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(foregroundColor: p.text3),
                child: const Text('Atla'),
              ),
              const Spacer(),
              if (onPrevious != null)
                TextButton(
                  onPressed: onPrevious,
                  style: TextButton.styleFrom(foregroundColor: p.text2),
                  child: const Text('Geri'),
                ),
              const SizedBox(width: AppSpacing.s2),
              FilledButton(
                onPressed: onNext,
                child: Text(last ? 'Başla' : 'İleri'),
              ),
            ],
          ),
        ],
      ),
    );

    // Sığmayan içerik kutuyu büyütüp ekran dışına İTMEZ; kutunun içinde kaydırılır.
    final bounded = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(child: card),
    );

    Widget content = Align(alignment: Alignment.topCenter, child: bounded);

    if (!reduceMotion) {
      // Giriş hareketi: hedefin bulunduğu yönden süzülerek gelir — "bu kutu şunu anlatıyor" bağını
      // hareketle de kurar.
      content = TweenAnimationBuilder<double>(
        // Anahtar ŞART: adım değişince animasyon baştan başlasın.
        key: ValueKey(index),
        tween: Tween(begin: 0, end: 1),
        duration: AppMotion.slow,
        curve: AppMotion.easeOut,
        builder: (context, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (below ? 14 : -14) * (1 - v)),
            child: child,
          ),
        ),
        child: content,
      );
    }

    return Positioned(
      left: AppSpacing.s4,
      right: AppSpacing.s4,
      top: below ? hole.bottom + _CoachMarkOverlay._gap : null,
      bottom: below ? null : (screenHeight - hole.top) + _CoachMarkOverlay._gap,
      child: content,
    );
  }
}
