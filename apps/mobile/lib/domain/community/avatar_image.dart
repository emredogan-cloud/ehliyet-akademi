/// Beta Faz 7 — profil fotoğrafının SAF kuralları.
///
/// Bu dosya hiçbir eklentiye, dosya sistemine veya ekrana bağlı DEĞİLDİR: kırpma penceresinin
/// kaynak görselde neye denk geldiği ve çıktı bütçesi burada hesaplanır, doğrudan test edilir.
/// (Proje disiplini: "saf kural katmanı ekrandan/uçtan ayrı".)
library;

import 'dart:math' as math;

/// Çıktı sözleşmesi. Sunucu sınırıyla (`AVATAR_MAX_BYTES`) **bilerek aynı** tutulur; istemci
/// zaten bu bütçenin çok altında bir görsel üretir, sınır yalnız son bir emniyet kemeridir.
class AvatarSpec {
  const AvatarSpec._();

  /// Kare çıktı kenarı (px). 512, 3× cihazda ~170 dp'lik bir avatarı net gösterir ve
  /// JPEG olarak onlarca KB'de kalır.
  static const int outputSize = 512;

  /// JPEG kalitesi — 82, gözle fark edilmeyen kayıpla belirgin boyut kazancı verir.
  static const int jpegQuality = 82;

  /// Sunucunun kabul ettiği tavan (512 KB). İstemci bunun çok altını üretir.
  static const int maxBytes = 512 * 1024;

  /// Seçiciden istenecek azami kenar. Kırpma öncesi çok büyük görselleri belleğe almamak için
  /// doğrudan seçicide küçültülür.
  static const double pickMaxSide = 1600;
}

/// Kaynak görselden alınacak **kare** bölge.
///
/// Kırpma penceresi ekranda kare olduğu için sonuç da karedir; bu tür kaynak görselin
/// merkezinden alınabilecek en büyük karedir.
({int x, int y, int size}) centerSquare(int width, int height) {
  final size = math.min(width, height);
  return (x: ((width - size) / 2).round(), y: ((height - size) / 2).round(), size: size);
}

/// Etkileşimli kırpmada, kare pencerede GÖRÜNEN alanın kaynak görseldeki karşılığı.
///
/// MODEL (uygulamayla birebir): kare pencerenin (kenarı [viewport]) içine, görselin merkez
/// karesi `BoxFit.cover` ile yerleştirilir. Kullanıcı `InteractiveViewer` ile yakınlaştırıp
/// kaydırır; bu da bir ölçek ([scale]) ve öteleme ([translateX]/[translateY]) üretir.
///
/// Pencere noktası `(x, y)` → çocuk koordinatı `((x - tx) / s, (y - ty) / s)`. Çocuk uzayı
/// `[0, viewport]²` olduğundan, oradan kaynak merkez karesine doğrusal eşlenir.
///
/// Sonuç her zaman kaynağın İÇİNDE kalır: kullanıcı kenardan dışarı kaydırsa bile kırpma alanı
/// sınırlara yapıştırılır, yani kutu asla boş piksel içermez.
({int x, int y, int size}) cropFromViewport({
  required int imageWidth,
  required int imageHeight,
  required double viewport,
  required double scale,
  required double translateX,
  required double translateY,
}) {
  // Ölçek 1'in altına inemez: pencere her zaman görselle DOLU kalmalı.
  final s = scale < 1.0 ? 1.0 : scale;
  final sq = centerSquare(imageWidth, imageHeight);
  // Çocuk uzayındaki bir birim, kaynakta kaç piksel eder.
  final factor = sq.size / viewport;

  // Pencerenin sol-üst köşesinin çocuk koordinatı.
  final childX = -translateX / s;
  final childY = -translateY / s;

  final size = (sq.size / s).clamp(1.0, sq.size.toDouble());
  var x = sq.x + childX * factor;
  var y = sq.y + childY * factor;

  // Kaynak sınırlarına yapıştır.
  x = x.clamp(sq.x.toDouble(), (sq.x + sq.size - size).toDouble());
  y = y.clamp(sq.y.toDouble(), (sq.y + sq.size - size).toDouble());

  return (x: x.round(), y: y.round(), size: size.round());
}

/// Yüklenecek gövdenin sunucu bütçesine sığıp sığmadığı.
bool fitsUploadBudget(int bytes) => bytes > 0 && bytes <= AvatarSpec.maxBytes;

/// base64 dizgisinin çözülünce kaç bayt edeceği — sunucudaki hesapla aynı.
int base64Bytes(String data) {
  if (data.isEmpty) return 0;
  var padding = 0;
  if (data.endsWith('==')) {
    padding = 2;
  } else if (data.endsWith('=')) {
    padding = 1;
  }
  return (data.length * 3) ~/ 4 - padding;
}
