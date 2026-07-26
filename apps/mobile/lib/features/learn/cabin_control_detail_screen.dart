import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
import '../../design/mech_image.dart';
import '../../design/primitives.dart';
import '../../domain/content/vehicle_visuals.dart';

/// Beta Faz 10 — kabin kumandası detay sayfası.
///
/// Faz öncesi durum: kumanda kartları **hiçbir yere gitmiyordu**; kullanıcı 62 px'lik bir
/// küçük resim ve tek satır açıklamayla baş başaydı. Yol haritasının şartı, mekanik
/// kütüphanesiyle **aynı kalite**: büyük görsel · zoom · açıklama · ipuçları · öğrenme kartları.
///
/// Kalite çıtası olarak `vehicle_detail_screen.dart` alındı (aynı bölüm sırası, aynı bileşenler)
/// — böylece iki kütüphane arasında geçen kullanıcı yeni bir düzen öğrenmek zorunda kalmaz.
class CabinControlDetailScreen extends StatelessWidget {
  const CabinControlDetailScreen({super.key, required this.asset});

  /// Kumandanın görsel kimliği; aynı zamanda yönlendirme anahtarıdır.
  final String asset;

  @override
  Widget build(BuildContext context) {
    final control = cabinControlByAsset(asset);
    if (control == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const AppEmptyState(emoji: '🔍', title: 'Kumanda bulunamadı'),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(control.title, overflow: TextOverflow.ellipsis)),
      body: SafeArea(top: false, child: _Body(control: control)),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.control});
  final CabinControl control;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s10,
      ),
      children: [
        _ZoomableImage(asset: control.asset, title: control.title),
        const SizedBox(height: AppSpacing.s4),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(control.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(control.group, style: TextStyle(color: p.text3, fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(control.desc, style: TextStyle(color: p.text2, height: 1.5, fontSize: 14.5)),
        const SizedBox(height: AppSpacing.s4),
        AppCallout(text: control.tip, title: '💡 İpucu', tone: CalloutTone.info),
        if (control.mistake != null) ...[
          const SizedBox(height: AppSpacing.s3),
          AppCallout(text: control.mistake!, title: '⚠️ Sık yapılan hata', tone: CalloutTone.danger),
        ],
        const SectionTitle('Nasıl kullanılır'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < control.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: p.primary050,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: p.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: Text(
                          control.steps[i],
                          style: TextStyle(color: p.text2, height: 1.4, fontSize: 13.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Büyük görsel + **çift dokunuş / parmakla** yakınlaştırma.
///
/// Neden zoom şart: bu görseller gerçek araç içi fotoğraflardır ve ayırt edici ayrıntı
/// (sembolün üstündeki minik yazı, kademe çizgileri) küçük ölçekte okunamaz. Tanımayı öğreten
/// bir kütüphanede ayrıntıyı gizlemek, kütüphanenin amacını boşa çıkarır.
class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.asset, required this.title});
  final String asset;
  final String title;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final _controller = TransformationController();

  /// Çift dokunuşta hangi noktaya odaklanılacağı — dokunulan yer merkeze alınır.
  TapDownDetails? _lastTap;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _zoomed => _controller.value.getMaxScaleOnAxis() > 1.05;

  void _toggleZoom() {
    if (_zoomed) {
      _controller.value = Matrix4.identity();
    } else {
      final pos = _lastTap?.localPosition ?? Offset.zero;
      const scale = 2.5;
      // Dokunulan nokta ekranda yerinde kalsın diye önce oraya taşınır, sonra ölçeklenir.
      _controller.value = Matrix4.identity()
        ..translateByDouble(-pos.dx * (scale - 1), -pos.dy * (scale - 1), 0, 1)
        ..scaleByDouble(scale, scale, scale, 1);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            color: p.surface2,
            height: 260,
            width: double.infinity,
            child: GestureDetector(
              onDoubleTapDown: (d) => _lastTap = d,
              onDoubleTap: _toggleZoom,
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: 1,
                maxScale: 4,
                // Yakınlaştırılmışken sürüklemek görseli kaydırır; sayfayı değil.
                panEnabled: true,
                child: Center(child: MechImage(id: widget.asset, size: 240)),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          _zoomed ? 'Sürükleyerek gez · çift dokun: küçült' : 'Çift dokun veya parmakla yakınlaştır',
          style: TextStyle(color: p.text3, fontSize: 12),
        ),
      ],
    );
  }
}
