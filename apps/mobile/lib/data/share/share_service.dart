import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Faz 10 — paylaşım yüzeyi.
///
/// MİMARİ (projedeki kalıp): platforma bağlı her şey **arayüz + uygulama**; testler sahte
/// uygulamayla, platform kanalı olmadan çalışır.
///
/// GİZLİLİK: paylaşılan kart CİHAZDA çizilir ve geçici dizine yazılır. Hiçbir şey sunucuya
/// yüklenmez, hiçbir kimlik gönderilmez — kartta yalnız kullanıcının kendi ilerlemesi vardır.
abstract class ShareService {
  /// Bir görseli (PNG baytları) sistem paylaşım sayfasıyla paylaş.
  ///
  /// [fileName] uzantısız verilir. Dönüş: paylaşım sayfası açılabildiyse `true`.
  Future<bool> shareImage({
    required Uint8List pngBytes,
    required String fileName,
    required String text,
  });

  /// Yalnız metin paylaş (görsel üretilemediğinde yedek yol).
  Future<bool> shareText(String text);
}

class PlatformShareService implements ShareService {
  @override
  Future<bool> shareImage({
    required Uint8List pngBytes,
    required String fileName,
    required String text,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = XFile.fromData(
        pngBytes,
        name: '$fileName.png',
        mimeType: 'image/png',
        path: '${dir.path}/$fileName.png',
      );
      await SharePlus.instance.share(ShareParams(files: [file], text: text));
      return true;
    } catch (_) {
      // Paylaşım sayfası açılamadı (nadir) → çağıran metin yedeğine düşer.
      return false;
    }
  }

  @override
  Future<bool> shareText(String text) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text));
      return true;
    } catch (_) {
      return false;
    }
  }
}

final shareServiceProvider = Provider<ShareService>((ref) => PlatformShareService());

/// Bir [RepaintBoundary]'yi PNG'ye çevir.
///
/// [pixelRatio] 3.0: sosyal uygulamalar görseli büyütüp gösterir; 1.0'da kart bulanık çıkıyordu.
///
/// `null` dönebilir ve bu NORMALDİR: sınır henüz boyanmamışsa görüntü alınamaz. Çağıran bu
/// durumda metin paylaşımına düşer — çökmez.
///
/// ZAMAN AŞIMI ŞART: `toImage`, MOTORUN rasterleştirmesine bağlı bir Future döndürür. Kare hiç
/// çizilmezse bu Future ASLA tamamlanmaz ve kullanıcı sonsuza kadar "Hazırlanıyor…" görür. Aynı
/// durum widget testlerinde de yaşanır (test sahte-zaman bölgesinde motor işini bitiremez) —
/// oradaki `pumpAndSettle` zaman aşımı bu hatayı ortaya çıkardı.
///
/// Gerçek görüntü alma yolu bu yüzden CİHAZ testinde doğrulanır; widget testi yedek (metin)
/// yolunu doğrular.
Future<Uint8List?> captureBoundary(
  GlobalKey boundaryKey, {
  double pixelRatio = 3.0,
  Duration timeout = const Duration(seconds: 4),
}) async {
  try {
    final object = boundaryKey.currentContext?.findRenderObject();
    if (object is! RenderRepaintBoundary) return null;
    final image = await object.toImage(pixelRatio: pixelRatio).timeout(timeout);
    final data = await image.toByteData(format: ui.ImageByteFormat.png).timeout(timeout);
    image.dispose();
    return data?.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}
