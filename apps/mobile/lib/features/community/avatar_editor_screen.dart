import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/community/avatar_service.dart';
import '../../design/brand.dart';
import '../../domain/community/avatar_image.dart';

/// Beta Faz 7 — profil fotoğrafı düzenleyici: seç → kırp → yükle.
///
/// Kırpma **etkileşimlidir**: kare pencerede `InteractiveViewer` ile yakınlaştırılıp kaydırılır;
/// kaydederken pencerede GÖRÜNEN alan kaynağa geri eşlenir ([cropFromViewport]) ve yalnız o alan
/// kodlanır. Böylece kullanıcı neyi gördüyse onu yükler.
///
/// Sonuç `Navigator.pop` ile döner: yeni `avatarUrl` (yüklendi) · `''` (fotoğraf kaldırıldı) ·
/// `null` (vazgeçildi — hata DEĞİLDİR).
class AvatarEditorScreen extends ConsumerStatefulWidget {
  const AvatarEditorScreen({super.key, this.hasPhoto = false});

  /// Kullanıcının hâlihazırda bir fotoğrafı var mı — "Kaldır" seçeneği ona göre gösterilir.
  final bool hasPhoto;

  @override
  ConsumerState<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends ConsumerState<AvatarEditorScreen> {
  final _controller = TransformationController();
  Uint8List? _picked;
  ({int width, int height})? _size;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick(AvatarSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final picked = await ref.read(avatarPickerProvider).pick(source);
    if (!mounted) return;
    if (picked == null) {
      // Vazgeçme HATA DEĞİLDİR — mesaj gösterilmez.
      setState(() => _busy = false);
      return;
    }
    final decoded = await decodeImageFromList(picked.bytes);
    if (!mounted) return;
    setState(() {
      _picked = picked.bytes;
      _size = (width: decoded.width, height: decoded.height);
      _controller.value = Matrix4.identity();
      _busy = false;
    });
  }

  Future<void> _save(double viewport) async {
    final bytes = _picked;
    final size = _size;
    if (bytes == null || size == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final m = _controller.value;
    final rect = cropFromViewport(
      imageWidth: size.width,
      imageHeight: size.height,
      viewport: viewport,
      scale: m.getMaxScaleOnAxis(),
      translateX: m.getTranslation().x,
      translateY: m.getTranslation().y,
    );

    final jpeg = ref.read(avatarEncoderProvider).encode(bytes, rect);
    if (jpeg == null) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Bu görsel işlenemedi. Başka bir fotoğraf dene.';
        });
      }
      return;
    }

    final api = ref.read(avatarApiProvider);
    final url = await api.upload(jpeg);
    if (!mounted) return;
    if (url == null) {
      setState(() {
        _busy = false;
        _error = api.lastError ?? 'Fotoğraf yüklenemedi.';
      });
      return;
    }
    Navigator.of(context).pop(url);
  }

  Future<void> _remove() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = ref.read(avatarApiProvider);
    final ok = await api.remove();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = api.lastError ?? 'Fotoğraf kaldırılamadı.';
      });
      return;
    }
    Navigator.of(context).pop('');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final picked = _picked;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil fotoğrafı')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            // Kırpma penceresi kare; genişliğe göre ama ekranı taşırmayacak biçimde.
            final viewport = (c.maxWidth - AppSpacing.s5 * 2).clamp(200.0, c.maxHeight * 0.52);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (picked == null)
                    _EmptyState(size: viewport)
                  else
                    Center(
                      child: ClipOval(
                        child: SizedBox(
                          width: viewport,
                          height: viewport,
                          child: InteractiveViewer(
                            transformationController: _controller,
                            minScale: 1,
                            maxScale: 4,
                            // Pencere her zaman görselle dolu kalsın diye sınır dışına taşma yok.
                            boundaryMargin: EdgeInsets.zero,
                            clipBehavior: Clip.hardEdge,
                            child: Image.memory(picked, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    picked == null
                        ? 'Galeriden seç ya da yeni bir fotoğraf çek.'
                        : 'Yakınlaştır ve kaydırarak çerçeveyi ayarla.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.4),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.s3),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.red, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s5),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : () => _pick(AvatarSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Galeri'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : () => _pick(AvatarSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Kamera'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  GradientPillButton(
                    label: 'Kaydet',
                    loading: _busy,
                    trailingIcon: Icons.check_rounded,
                    onPressed: (picked == null || _busy) ? null : () => _save(viewport),
                  ),
                  // Fotoğrafı olan kullanıcı HER ZAMAN maskota dönebilir.
                  if (widget.hasPhoto) ...[
                    const SizedBox(height: AppSpacing.s2),
                    TextButton.icon(
                      onPressed: _busy ? null : _remove,
                      icon: Icon(Icons.delete_outline_rounded, color: p.red, size: 18),
                      label: Text('Fotoğrafı kaldır', style: TextStyle(color: p.red)),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    'Fotoğrafın topluluk yüzeylerinde görünür. Uygunsuz fotoğraflar şikâyet '
                    'edilebilir ve kaldırılabilir. Fotoğraf yüklemek zorunda değilsin — '
                    'maskotunla devam edebilirsin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.text3, fontSize: 11.5, height: 1.4),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: p.surface2,
          border: Border.all(color: p.border),
        ),
        child: Icon(Icons.add_a_photo_outlined, size: size * 0.28, color: p.text3),
      ),
    );
  }
}
