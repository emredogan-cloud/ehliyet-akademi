import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// Ders görselleri — Premium Kalite Programı · Faz 4.
///
/// ## Neden RASTER DEĞİL, ÇİZİM
///
/// Web tarafında (`apps/web/components/LessonFigure.tsx`) 12 satır içi SVG vardı ve mobil
/// `Lesson` modeli `figureId` alanını **taşıyordu** ama hiçbir yerde çizmiyordu: denetimde
/// `grep -rn "figureId" apps/mobile/lib` yalnız alan tanımını ve üretilmiş freezed dosyalarını
/// buldu. Yani ürünün asıl yüzü olan uygulamada ders görselleri **hiç görünmüyordu**.
///
/// Kapatmanın iki yolu vardı; `CustomPainter` seçildi çünkü raster görsel:
///
/// · **temaya uymaz** — aynı PNG hem açık hem koyu temada doğru görünmez, iki takım dosya ister
/// · **yazı tipi ölçeğiyle büyümez** — erişilebilirlik ayarı görselin içindeki metni etkilemez
/// · **çevrilemez** — gömülü metin başka dile geçemez
/// · **APK'ya bayt ekler** — 12 şema × 2 tema × 3 yoğunluk = onlarca dosya
///
/// Çizim bunların dördünü birden çözer: renkler [AppPalette]'ten gelir, metin gerçek `Text`
/// widget'ıdır (bu yüzden çizim değil **widget bileşimi** tercih edildi; yalnız çizgi ve şekil
/// `CustomPainter`'a bırakıldı), tek satır kod değişmeden tema ve dil değişir.
///
/// ## Neden şema, fotoğraf değil
///
/// Bu görsellerin anlattığı şey bir NESNE değil, bir İLİŞKİ: kimin önce geçtiği, mesafenin ne
/// kadar olduğu, hangi sıranın izlendiği. İlişkiyi en net anlatan biçim çizgidir; fotoğraf
/// ayrıntı ekler ama ilişkiyi gizler.

/// Bir ders şemasının kimliği. `Lesson.figureId` ile eşleşir.
///
/// Web'deki 12 şemanın karşılığı + denetimde eksik bulunan yeni konular.
enum LessonFigureId {
  signs,
  abc,
  dashboard,
  junction,
  followingDistance,
  overtaking,
  pedestrian,
  cpr,
  vehicle,
  hillStart,
  parking,
  roundabout,
  // Premium Kalite Programı · Faz 4 — yeni şemalar
  blindSpot,
  loadPlacement,
  roadLines,
  officerSignals,
  recoveryPosition,
  stoppingDistance;

  /// `figureId` dizesinden çözüm. Bilinmeyen kimlik `null` döner ve hiçbir şey çizilmez —
  /// içerik yeni bir kimlik gönderirse uygulama kırılmaz, yalnız o blok görünmez.
  static LessonFigureId? parse(String? id) => switch (id) {
    'signs' => LessonFigureId.signs,
    'abc' => LessonFigureId.abc,
    'dashboard' => LessonFigureId.dashboard,
    'junction' => LessonFigureId.junction,
    'following-distance' => LessonFigureId.followingDistance,
    'overtaking' => LessonFigureId.overtaking,
    'pedestrian' => LessonFigureId.pedestrian,
    'cpr' => LessonFigureId.cpr,
    'vehicle' => LessonFigureId.vehicle,
    'hill-start' => LessonFigureId.hillStart,
    'parking' => LessonFigureId.parking,
    'roundabout' => LessonFigureId.roundabout,
    'blind-spot' => LessonFigureId.blindSpot,
    'load-placement' => LessonFigureId.loadPlacement,
    'road-lines' => LessonFigureId.roadLines,
    'officer-signals' => LessonFigureId.officerSignals,
    'recovery-position' => LessonFigureId.recoveryPosition,
    'stopping-distance' => LessonFigureId.stoppingDistance,
    _ => null,
  };

  /// Şemanın altında görünen açıklama — aynı zamanda ekran okuyucu etiketi.
  String get caption => switch (this) {
    LessonFigureId.signs => 'İşaret grupları: şekil ve renk anlam taşır.',
    LessonFigureId.abc => 'ABC değerlendirme sırası bozulmaz.',
    LessonFigureId.dashboard => 'İkaz rengi aciliyeti gösterir.',
    LessonFigureId.junction => 'Işıksız eşit kavşakta sağdaki önce geçer.',
    LessonFigureId.followingDistance => 'Kuru zeminde en az iki saniyelik takip mesafesi.',
    LessonFigureId.overtaking => 'Sollama soldan; karşı yön boş ve görüş açıkken.',
    LessonFigureId.pedestrian => 'Yaya geçidinde geçiş önceliği yayanındır.',
    LessonFigureId.cpr => 'Yetişkinde kalp masajı: 100–120/dk, ~5 cm, 30:2.',
    LessonFigureId.vehicle => 'Sürüşe başlamadan önceki hazırlık sırası.',
    LessonFigureId.hillStart => 'Rampada geri kaymadan kalkış.',
    LessonFigureId.parking => 'Paralel park manevrası.',
    LessonFigureId.roundabout => 'Dönel kavşakta içerideki araç önceliklidir.',
    LessonFigureId.blindSpot => 'Aynaların görmediği alan: kör nokta.',
    LessonFigureId.loadPlacement => 'Ağır yük alçakta ve aksa yakın durur.',
    LessonFigureId.roadLines => 'Yatay işaretler: devamlı, kesik ve sarı kenar çizgisi.',
    LessonFigureId.officerSignals => 'Trafik görevlisinin kol işaretleri.',
    LessonFigureId.recoveryPosition => 'Koma (derlenme) pozisyonu.',
    LessonFigureId.stoppingDistance => 'Hız iki katına çıkınca durma mesafesi dörde katlanır.',
  };
}

/// Ders şemasını çerçeve + başlık ile çizen blok.
///
/// [figureId] çözülemezse hiçbir şey çizilmez (`SizedBox.shrink`). Bu bilinçli: içerik
/// tarafında yeni bir kimlik belirdiğinde uygulama kırık bir kutu göstermez, sessizce atlar.
class LessonFigure extends StatelessWidget {
  const LessonFigure({super.key, required this.figureId});

  final String? figureId;

  @override
  Widget build(BuildContext context) {
    final id = LessonFigureId.parse(figureId);
    if (id == null) return const SizedBox.shrink();
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
      child: Semantics(
        image: true,
        label: id.caption,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(AppSpacing.s3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.s3 - 1)),
                child: ColoredBox(
                  color: p.surface2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s3),
                    child: _FigureBody(id: id),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: p.border)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s3,
                  vertical: AppSpacing.s2,
                ),
                // ExcludeSemantics: başlık zaten Semantics.label olarak okundu; iki kez
                // okunması ekran okuyucu kullanıcısı için gürültüdür.
                child: ExcludeSemantics(
                  child: Text(
                    id.caption,
                    style: TextStyle(fontSize: 12, color: p.text3, height: 1.35),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Şemanın gövdesi. Metin taşıyanlar widget bileşimi, saf geometri olanlar `CustomPainter`.
class _FigureBody extends StatelessWidget {
  const _FigureBody({required this.id});
  final LessonFigureId id;

  @override
  Widget build(BuildContext context) {
    return switch (id) {
      LessonFigureId.signs => const _SignGroups(),
      LessonFigureId.abc => const _StepRow(
        steps: [('A', 'Hava yolu'), ('B', 'Solunum'), ('C', 'Dolaşım')],
        note: 'Sıra bozulmaz: hava yolu açık değilse solunum değerlendirilemez.',
      ),
      LessonFigureId.dashboard => const _DashColours(),
      LessonFigureId.junction => const _PaintedFigure(kind: _PaintKind.junction, ratio: 1.9),
      LessonFigureId.followingDistance => const _PaintedFigure(
        kind: _PaintKind.followingDistance,
        ratio: 2.6,
      ),
      LessonFigureId.overtaking => const _PaintedFigure(kind: _PaintKind.overtaking, ratio: 2.6),
      LessonFigureId.pedestrian => const _PaintedFigure(kind: _PaintKind.pedestrian, ratio: 2.4),
      LessonFigureId.cpr => const _MetricRow(
        metrics: [('100–120', 'bası / dakika'), ('≈ 5 cm', 'bası derinliği'), ('30:2', 'masaj : soluk')],
        note: 'Önce bilinç ve solunumu kontrol et, 112’yi ara; göğüs ortasına kesintisiz bası uygula.',
      ),
      LessonFigureId.vehicle => const _StepRow(
        steps: [('1', 'Koltuk'), ('2', 'Aynalar'), ('3', 'Kemer'), ('4', 'Vites boşta')],
        note: 'Motoru çalıştırmadan önce vites boşta ve debriyaja basılı olmalı.',
      ),
      LessonFigureId.hillStart => const _StepRow(
        steps: [('1', 'El freni'), ('2', 'Kavrama noktası'), ('3', 'Hafif gaz'), ('4', 'El frenini bırak')],
        note: 'Araç öne yüklendiği hissedildiği anda el freni indirilir; erken bırakmak geri kaydırır.',
      ),
      LessonFigureId.parking => const _PaintedFigure(kind: _PaintKind.parking, ratio: 2.4),
      LessonFigureId.roundabout => const _PaintedFigure(kind: _PaintKind.roundabout, ratio: 1.7),
      LessonFigureId.blindSpot => const _PaintedFigure(kind: _PaintKind.blindSpot, ratio: 1.9),
      LessonFigureId.loadPlacement => const _PaintedFigure(kind: _PaintKind.loadPlacement, ratio: 2.2),
      LessonFigureId.roadLines => const _RoadLines(),
      LessonFigureId.officerSignals => const _OfficerSignals(),
      LessonFigureId.recoveryPosition => const _PaintedFigure(
        kind: _PaintKind.recoveryPosition,
        ratio: 2.2,
      ),
      LessonFigureId.stoppingDistance => const _StoppingDistance(),
    };
  }
}

/* ══════════════════════════ metin taşıyan şemalar (widget bileşimi) ══════════════════════════ */

/// Numaralı adım dizisi — hazırlık sırası, ABC, rampada kalkış.
class _StepRow extends StatelessWidget {
  const _StepRow({required this.steps, required this.note});
  final List<(String, String)> steps;
  final String note;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s1),
                  child: Icon(Icons.arrow_forward_rounded, size: 14, color: p.text3),
                ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle),
                      child: Text(
                        steps[i].$1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      steps[i].$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: p.text2, height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(note, style: TextStyle(fontSize: 11.5, color: p.text3, height: 1.35)),
      ],
    );
  }
}

/// Sayısal ölçü kartları — TYD gibi rakamın kendisinin bilgi olduğu konular.
class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metrics, required this.note});
  final List<(String, String)> metrics;
  final String note;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < metrics.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3, horizontal: 6),
                  decoration: BoxDecoration(
                    color: p.surface,
                    border: Border.all(color: p.red.withValues(alpha: 0.45)),
                    borderRadius: BorderRadius.circular(AppSpacing.s2),
                  ),
                  child: Column(
                    children: [
                      FittedBox(
                        child: Text(
                          metrics[i].$1,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: p.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        metrics[i].$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10.5, color: p.text3, height: 1.2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(note, style: TextStyle(fontSize: 11.5, color: p.text3, height: 1.35)),
      ],
    );
  }
}

/// İşaret grupları — şekil + renk → anlam.
class _SignGroups extends StatelessWidget {
  const _SignGroups();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget cell(Widget shape, String title, String sub) => Expanded(
      child: Column(
        children: [
          SizedBox(height: 46, child: Center(child: shape)),
          const SizedBox(height: AppSpacing.s2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.text),
          ),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: p.text3, height: 1.2),
          ),
        ],
      ),
    );

    return Row(
      children: [
        cell(
          CustomPaint(size: const Size(44, 40), painter: _ShapePainter(_Shape.triangle, p.red, p)),
          'Tehlike uyarı',
          'üçgen · kırmızı kenar',
        ),
        cell(
          CustomPaint(size: const Size(42, 42), painter: _ShapePainter(_Shape.circle, p.red, p)),
          'Yasak / tanzim',
          'kırmızı daire',
        ),
        cell(
          CustomPaint(size: const Size(42, 42), painter: _ShapePainter(_Shape.disc, p.blue, p)),
          'Mecburiyet / bilgi',
          'mavi daire',
        ),
      ],
    );
  }
}

/// İkaz rengi → aciliyet.
class _DashColours extends StatelessWidget {
  const _DashColours();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rows = <(Color, String, String)>[
      (p.red, 'Kırmızı', 'Güvenli yerde DUR — sürüşe devam risk taşır'),
      (p.yellow, 'Sarı', 'Dikkat — en kısa sürede kontrol ettir'),
      (p.green, 'Yeşil / mavi', 'Bilgi — bir sistem açık, arıza değil'),
    ];
    return Column(
      children: [
        for (final (c, label, meaning) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s2),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.18),
                    border: Border.all(color: c, width: 2),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                SizedBox(
                  width: 78,
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.text),
                  ),
                ),
                Expanded(
                  child: Text(
                    meaning,
                    style: TextStyle(fontSize: 11, color: p.text3, height: 1.25),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Yatay işaretlemeler — devamlı, kesik, sarı kenar.
class _RoadLines extends StatelessWidget {
  const _RoadLines();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rows = <(_LineKind, String, String)>[
      (_LineKind.solid, 'Devamlı çizgi', 'Geçilemez; şeritten ayrılmak yasaktır'),
      (_LineKind.dashed, 'Kesik çizgi', 'Koşullar uygunsa geçilebilir'),
      (_LineKind.yellow, 'Sarı kenar çizgisi', 'Duraklama ve park yasaktır'),
    ];
    return Column(
      children: [
        for (final (kind, label, meaning) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s2),
            child: Row(
              children: [
                CustomPaint(size: const Size(52, 14), painter: _LinePainter(kind, p)),
                const SizedBox(width: AppSpacing.s2),
                SizedBox(
                  width: 96,
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.text),
                  ),
                ),
                Expanded(
                  child: Text(
                    meaning,
                    style: TextStyle(fontSize: 11, color: p.text3, height: 1.25),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Görevli kol işaretleri.
class _OfficerSignals extends StatelessWidget {
  const _OfficerSignals();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final items = <(_ArmPose, String)>[
      (_ArmPose.up, 'Kol dik yukarı:\ntüm yönler DUR'),
      (_ArmPose.side, 'Kollar yana açık:\naçık yönler geçer'),
      (_ArmPose.front, 'Kol öne uzatılmış:\nkarşıdan gelen durur'),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (pose, label) in items)
          Expanded(
            child: Column(
              children: [
                CustomPaint(size: const Size(44, 54), painter: _OfficerPainter(pose, p)),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10.5, color: p.text2, height: 1.25),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Hız ↔ durma mesafesi ilişkisi. Rakam bilgi taşıdığı için çubuklar ORANTILI çizilir.
class _StoppingDistance extends StatelessWidget {
  const _StoppingDistance();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Kareyle artış: 50 → 1 birim, 100 → 4 birim. Çubuk uzunluğu bu oranı gösterir.
    final bars = <(String, double, Color)>[
      ('50 km/s', 0.25, p.green),
      ('70 km/s', 0.49, p.yellow),
      ('100 km/s', 1.0, p.red),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, factor, c) in bars)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s2),
            child: Row(
              children: [
                SizedBox(
                  width: 62,
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.text),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c2) => Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 12,
                        width: math.max(6, c2.maxWidth * factor),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.s1),
        Text(
          'Hız iki katına çıktığında durma mesafesi yaklaşık DÖRT katına çıkar; '
          'çubuk uzunlukları bu oranı gösterir.',
          style: TextStyle(fontSize: 11.5, color: p.text3, height: 1.35),
        ),
      ],
    );
  }
}

/* ══════════════════════════ saf geometri (CustomPainter) ══════════════════════════ */

enum _PaintKind {
  junction,
  followingDistance,
  overtaking,
  pedestrian,
  parking,
  roundabout,
  blindSpot,
  loadPlacement,
  recoveryPosition,
}

/// En-boy oranı sabit bir çizim alanı. Genişlik ekrandan gelir; yükseklik orandan türer,
/// böylece 320 dp'den 600 dp'ye kadar aynı kompozisyon korunur.
class _PaintedFigure extends StatelessWidget {
  const _PaintedFigure({required this.kind, required this.ratio});
  final _PaintKind kind;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AspectRatio(
      aspectRatio: ratio,
      child: CustomPaint(painter: _SchematicPainter(kind, p), size: Size.infinite),
    );
  }
}

class _SchematicPainter extends CustomPainter {
  const _SchematicPainter(this.kind, this.p);
  final _PaintKind kind;
  final AppPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case _PaintKind.junction:
        _junction(canvas, size);
      case _PaintKind.followingDistance:
        _following(canvas, size);
      case _PaintKind.overtaking:
        _overtaking(canvas, size);
      case _PaintKind.pedestrian:
        _pedestrian(canvas, size);
      case _PaintKind.parking:
        _parking(canvas, size);
      case _PaintKind.roundabout:
        _roundabout(canvas, size);
      case _PaintKind.blindSpot:
        _blindSpot(canvas, size);
      case _PaintKind.loadPlacement:
        _loadPlacement(canvas, size);
      case _PaintKind.recoveryPosition:
        _recovery(canvas, size);
    }
  }

  Paint get _road => Paint()..color = p.surface3;
  Paint _fill(Color c) => Paint()..color = c;
  Paint _stroke(Color c, [double w = 2.4]) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  void _car(Canvas canvas, Rect r, Color c) {
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), _fill(c));
  }

  /// Kesikli ok — niyet/hareket yönü.
  void _arrow(Canvas canvas, Offset from, Offset to, Color c) {
    final paint = _stroke(c, 2.2);
    final d = to - from;
    final len = d.distance;
    if (len < 1) return;
    final unit = d / len;
    // Kesikli gövde
    const dash = 5.0, gap = 4.0;
    var t = 0.0;
    while (t < len - 7) {
      final a = from + unit * t;
      final b = from + unit * math.min(t + dash, len - 7);
      canvas.drawLine(a, b, paint);
      t += dash + gap;
    }
    // Uç
    final tip = to;
    final back = tip - unit * 7;
    final perp = Offset(-unit.dy, unit.dx) * 4;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(back.dx + perp.dx, back.dy + perp.dy)
        ..lineTo(back.dx - perp.dx, back.dy - perp.dy)
        ..close(),
      _fill(c),
    );
  }

  void _junction(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.drawRect(Rect.fromLTWH(w * 0.42, 0, w * 0.16, h), _road);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.36, w, h * 0.28), _road);
    // SEN — aşağıdan gelen
    _car(canvas, Rect.fromLTWH(w * 0.455, h * 0.74, w * 0.055, h * 0.18), p.primary);
    _arrow(canvas, Offset(w * 0.482, h * 0.72), Offset(w * 0.482, h * 0.6), p.primary);
    // Sağdan gelen — öncelikli
    _car(canvas, Rect.fromLTWH(w * 0.72, h * 0.44, w * 0.1, h * 0.12), p.red);
    _arrow(canvas, Offset(w * 0.71, h * 0.5), Offset(w * 0.6, h * 0.5), p.red);
  }

  void _following(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.drawRect(Rect.fromLTWH(0, h * 0.34, w, h * 0.34), _road);
    // Şerit çizgisi
    final y = h * 0.51;
    for (var x = 0.0; x < w; x += 22) {
      canvas.drawLine(Offset(x, y), Offset(x + 12, y), _stroke(p.surface, 1.6));
    }
    _car(canvas, Rect.fromLTWH(w * 0.7, h * 0.38, w * 0.13, h * 0.24), p.green);
    _car(canvas, Rect.fromLTWH(w * 0.16, h * 0.38, w * 0.13, h * 0.24), p.primary);
    // Mesafe oku — çift yönlü
    final ay = h * 0.5;
    _arrow(canvas, Offset(w * 0.32, ay), Offset(w * 0.68, ay), p.yellow);
    _arrow(canvas, Offset(w * 0.68, ay), Offset(w * 0.32, ay), p.yellow);
  }

  void _overtaking(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.drawRect(Rect.fromLTWH(0, h * 0.42, w, h * 0.34), _road);
    final y = h * 0.59;
    for (var x = 0.0; x < w; x += 24) {
      canvas.drawLine(Offset(x, y), Offset(x + 13, y), _stroke(p.yellow, 1.6));
    }
    _car(canvas, Rect.fromLTWH(w * 0.56, h * 0.6, w * 0.12, h * 0.14), p.text3);
    _car(canvas, Rect.fromLTWH(w * 0.16, h * 0.6, w * 0.12, h * 0.14), p.primary);
    // Sollama yayı: sola çık, geç, sağa dön
    final path = Path()
      ..moveTo(w * 0.29, h * 0.66)
      ..cubicTo(w * 0.42, h * 0.66, w * 0.42, h * 0.48, w * 0.56, h * 0.48)
      ..cubicTo(w * 0.7, h * 0.48, w * 0.74, h * 0.66, w * 0.86, h * 0.66);
    canvas.drawPath(path, _stroke(p.primary, 2.4));
    _arrow(canvas, Offset(w * 0.82, h * 0.66), Offset(w * 0.9, h * 0.66), p.primary);
  }

  void _pedestrian(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.drawRect(Rect.fromLTWH(0, h * 0.3, w, h * 0.44), _road);
    // Zebra
    for (var i = 0; i < 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(w * (0.44 + i * 0.045), h * 0.31, w * 0.026, h * 0.42),
        _fill(p.surface),
      );
    }
    _car(canvas, Rect.fromLTWH(w * 0.14, h * 0.4, w * 0.14, h * 0.2), p.yellow);
    _arrow(canvas, Offset(w * 0.3, h * 0.5), Offset(w * 0.4, h * 0.5), p.yellow);
    // Yaya — daire + gövde
    final cx = w * 0.53, cy = h * 0.44;
    canvas.drawCircle(Offset(cx, cy), h * 0.06, _fill(p.green));
    canvas.drawLine(Offset(cx, cy + h * 0.07), Offset(cx, cy + h * 0.2), _stroke(p.green, 2.6));
    canvas.drawLine(
      Offset(cx, cy + h * 0.2),
      Offset(cx - h * 0.06, cy + h * 0.3),
      _stroke(p.green, 2.6),
    );
    canvas.drawLine(
      Offset(cx, cy + h * 0.2),
      Offset(cx + h * 0.06, cy + h * 0.3),
      _stroke(p.green, 2.6),
    );
  }

  void _parking(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.drawRect(Rect.fromLTWH(0, h * 0.52, w, h * 0.32), _road);
    _car(canvas, Rect.fromLTWH(w * 0.08, h * 0.58, w * 0.17, h * 0.2), p.text3);
    _car(canvas, Rect.fromLTWH(w * 0.62, h * 0.58, w * 0.17, h * 0.2), p.text3);
    _car(canvas, Rect.fromLTWH(w * 0.33, h * 0.59, w * 0.16, h * 0.18), p.primary);
    // Manevra yayı: hizala → geri + direksiyon → düzelt
    final path = Path()
      ..moveTo(w * 0.74, h * 0.44)
      ..cubicTo(w * 0.6, h * 0.42, w * 0.5, h * 0.56, w * 0.42, h * 0.62);
    canvas.drawPath(path, _stroke(p.primary, 2.4));
    _arrow(canvas, Offset(w * 0.46, h * 0.59), Offset(w * 0.4, h * 0.64), p.primary);
  }

  void _roundabout(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final c = Offset(w * 0.5, h * 0.46);
    final r = h * 0.3;
    canvas.drawCircle(c, r, _stroke(p.surface3, h * 0.2));
    canvas.drawCircle(c, r * 0.44, _fill(p.surface3));
    // İçeride dönen — öncelikli
    final arc = Path()
      ..addArc(Rect.fromCircle(center: c, radius: r), -math.pi * 0.55, math.pi * 0.75);
    canvas.drawPath(arc, _stroke(p.green, 2.6));
    // SEN — aşağıdan giren
    _car(canvas, Rect.fromLTWH(w * 0.47, h * 0.82, w * 0.06, h * 0.16), p.primary);
    _arrow(canvas, Offset(w * 0.5, h * 0.8), Offset(w * 0.5, h * 0.72), p.primary);
  }

  void _blindSpot(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.drawRect(Rect.fromLTWH(0, h * 0.2, w, h * 0.6), _road);
    final car = Rect.fromLTWH(w * 0.4, h * 0.36, w * 0.16, h * 0.28);
    _car(canvas, car, p.primary);
    // Ayna görüş konileri
    final mirror = Offset(car.left, car.top + car.height * 0.3);
    final cone = Path()
      ..moveTo(mirror.dx, mirror.dy)
      ..lineTo(w * 0.06, h * 0.12)
      ..lineTo(w * 0.06, h * 0.42)
      ..close();
    canvas.drawPath(cone, _fill(p.green.withValues(alpha: 0.18)));
    // Kör nokta bölgesi
    final blind = Path()
      ..moveTo(car.left, car.bottom)
      ..lineTo(w * 0.1, h * 0.72)
      ..lineTo(w * 0.1, h * 0.95)
      ..lineTo(car.left, h * 0.86)
      ..close();
    canvas.drawPath(blind, _fill(p.red.withValues(alpha: 0.22)));
    canvas.drawPath(blind, _stroke(p.red, 1.6));
    // Kör noktadaki araç
    _car(canvas, Rect.fromLTWH(w * 0.15, h * 0.72, w * 0.12, h * 0.16), p.red);
  }

  void _loadPlacement(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    // Araç kesiti — yandan
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.34, w * 0.84, h * 0.4),
      const Radius.circular(6),
    );
    canvas.drawRRect(body, _stroke(p.borderStrong, 2));
    // Tekerlekler
    canvas.drawCircle(Offset(w * 0.24, h * 0.78), h * 0.09, _fill(p.text3));
    canvas.drawCircle(Offset(w * 0.74, h * 0.78), h * 0.09, _fill(p.text3));
    // DOĞRU: alçak, aksa yakın, öne yaslı
    canvas.drawRect(
      Rect.fromLTWH(w * 0.6, h * 0.56, w * 0.2, h * 0.16),
      _fill(p.green.withValues(alpha: 0.8)),
    );
    // YANLIŞ: yüksek ve en arkada
    canvas.drawRect(
      Rect.fromLTWH(w * 0.83, h * 0.36, w * 0.08, h * 0.14),
      _fill(p.red.withValues(alpha: 0.55)),
    );
    canvas.drawLine(
      Offset(w * 0.83, h * 0.36),
      Offset(w * 0.91, h * 0.5),
      _stroke(p.red, 2),
    );
    canvas.drawLine(
      Offset(w * 0.91, h * 0.36),
      Offset(w * 0.83, h * 0.5),
      _stroke(p.red, 2),
    );
  }

  void _recovery(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.drawRect(Rect.fromLTWH(0, h * 0.76, w, h * 0.08), _fill(p.surface3));
    // Yan yatmış gövde
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.3, h * 0.5, w * 0.42, h * 0.24),
        const Radius.circular(10),
      ),
      _fill(p.primary.withValues(alpha: 0.85)),
    );
    // Baş — hafif geriye, yüz aşağı bakacak biçimde
    canvas.drawCircle(Offset(w * 0.24, h * 0.56), h * 0.1, _fill(p.primary));
    // Üstteki diz bükülü — gövdeyi devrilmeye karşı destekler
    canvas.drawLine(Offset(w * 0.68, h * 0.6), Offset(w * 0.8, h * 0.72), _stroke(p.primary, 6));
    canvas.drawLine(Offset(w * 0.8, h * 0.72), Offset(w * 0.72, h * 0.76), _stroke(p.primary, 6));
    // Hava yolunun açık kaldığını gösteren ok
    _arrow(canvas, Offset(w * 0.16, h * 0.72), Offset(w * 0.1, h * 0.82), p.green);
  }

  @override
  bool shouldRepaint(covariant _SchematicPainter old) => old.kind != kind || old.p != p;
}

/* ── küçük yardımcı çiziciler ───────────────────────────────────────────────────────────── */

enum _Shape { triangle, circle, disc }

class _ShapePainter extends CustomPainter {
  const _ShapePainter(this.shape, this.color, this.p);
  final _Shape shape;
  final Color color;
  final AppPalette p;

  @override
  void paint(Canvas canvas, Size s) {
    final fill = Paint()..color = p.surface;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round;
    switch (shape) {
      case _Shape.triangle:
        final path = Path()
          ..moveTo(s.width / 2, 3)
          ..lineTo(s.width - 3, s.height - 4)
          ..lineTo(3, s.height - 4)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      case _Shape.circle:
        canvas.drawCircle(s.center(Offset.zero), s.width / 2 - 3, fill);
        canvas.drawCircle(s.center(Offset.zero), s.width / 2 - 3, stroke);
      case _Shape.disc:
        canvas.drawCircle(s.center(Offset.zero), s.width / 2 - 2, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter old) =>
      old.shape != shape || old.color != color || old.p != p;
}

enum _LineKind { solid, dashed, yellow }

class _LinePainter extends CustomPainter {
  const _LinePainter(this.kind, this.p);
  final _LineKind kind;
  final AppPalette p;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = p.surface3);
    final y = s.height / 2;
    final paint = Paint()
      ..strokeWidth = 2.6
      ..color = kind == _LineKind.yellow ? p.yellow : p.surface;
    if (kind == _LineKind.dashed) {
      for (var x = 2.0; x < s.width; x += 12) {
        canvas.drawLine(Offset(x, y), Offset(x + 6, y), paint);
      }
    } else if (kind == _LineKind.yellow) {
      canvas.drawLine(Offset(2, s.height - 3), Offset(s.width - 2, s.height - 3), paint);
    } else {
      canvas.drawLine(Offset(2, y), Offset(s.width - 2, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => old.kind != kind || old.p != p;
}

enum _ArmPose { up, side, front }

class _OfficerPainter extends CustomPainter {
  const _OfficerPainter(this.pose, this.p);
  final _ArmPose pose;
  final AppPalette p;

  @override
  void paint(Canvas canvas, Size s) {
    final c = p.primary;
    final stroke = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final w = s.width, h = s.height;
    final headR = h * 0.11;
    final headC = Offset(w / 2, h * 0.16);
    canvas.drawCircle(headC, headR, Paint()..color = c);
    // Gövde
    canvas.drawLine(Offset(w / 2, h * 0.28), Offset(w / 2, h * 0.66), stroke);
    // Bacaklar
    canvas.drawLine(Offset(w / 2, h * 0.66), Offset(w * 0.34, h * 0.94), stroke);
    canvas.drawLine(Offset(w / 2, h * 0.66), Offset(w * 0.66, h * 0.94), stroke);
    // Kollar — poza göre
    switch (pose) {
      case _ArmPose.up:
        canvas.drawLine(Offset(w / 2, h * 0.36), Offset(w * 0.62, h * 0.04), stroke);
        canvas.drawLine(Offset(w / 2, h * 0.36), Offset(w * 0.3, h * 0.52), stroke);
      case _ArmPose.side:
        canvas.drawLine(Offset(w / 2, h * 0.38), Offset(w * 0.06, h * 0.38), stroke);
        canvas.drawLine(Offset(w / 2, h * 0.38), Offset(w * 0.94, h * 0.38), stroke);
      case _ArmPose.front:
        canvas.drawLine(Offset(w / 2, h * 0.38), Offset(w * 0.94, h * 0.3), stroke);
        canvas.drawLine(Offset(w / 2, h * 0.38), Offset(w * 0.32, h * 0.54), stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _OfficerPainter old) => old.pose != pose || old.p != p;
}
