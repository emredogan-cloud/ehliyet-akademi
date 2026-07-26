import 'dart:convert';
import 'dart:typed_data';

import 'package:ehliyet_akademi/data/community/avatar_service.dart';
import 'package:ehliyet_akademi/domain/community/avatar_image.dart';
import 'package:ehliyet_akademi/domain/community/community_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Beta Faz 7 — profil fotoğrafı.
///
/// ⚠️ E8'de "fotoğraf yükleme YOK" bilinçli bir moderasyon/PII kararıydı. Bu faz onu değiştiriyor;
/// bu testler geri gelen yüzeyin istemci tarafındaki sınırlarını sabitler.
void main() {
  group('kırpma matematiği (saf)', () {
    test('merkez kare: geniş görselde yatay ortalanır', () {
      final sq = centerSquare(1000, 600);
      expect(sq.size, 600);
      expect(sq.x, 200);
      expect(sq.y, 0);
    });

    test('merkez kare: uzun görselde dikey ortalanır', () {
      final sq = centerSquare(600, 1000);
      expect(sq.size, 600);
      expect(sq.x, 0);
      expect(sq.y, 200);
    });

    test('kare görselde tam kaynak alınır', () {
      final sq = centerSquare(512, 512);
      expect((sq.x, sq.y, sq.size), (0, 0, 512));
    });

    test('dokunulmamış pencere (ölçek 1) merkez kareyi verir', () {
      final r = cropFromViewport(
        imageWidth: 1000,
        imageHeight: 600,
        viewport: 300,
        scale: 1,
        translateX: 0,
        translateY: 0,
      );
      expect(r.size, 600);
      expect(r.x, 200);
      expect(r.y, 0);
    });

    test('yakınlaştırma kaynaktan DAHA KÜÇÜK alan alır', () {
      final r = cropFromViewport(
        imageWidth: 800,
        imageHeight: 800,
        viewport: 400,
        scale: 2,
        translateX: 0,
        translateY: 0,
      );
      expect(r.size, 400); // 800 / 2
    });

    test('ölçek 1’in altına düşemez — pencere hep DOLU kalır', () {
      final r = cropFromViewport(
        imageWidth: 500,
        imageHeight: 500,
        viewport: 250,
        scale: 0.3,
        translateX: 0,
        translateY: 0,
      );
      expect(r.size, 500);
    });

    test('kaydırma kırpma alanını taşır', () {
      final base = cropFromViewport(
        imageWidth: 800,
        imageHeight: 800,
        viewport: 400,
        scale: 2,
        translateX: 0,
        translateY: 0,
      );
      final moved = cropFromViewport(
        imageWidth: 800,
        imageHeight: 800,
        viewport: 400,
        scale: 2,
        translateX: -100,
        translateY: 0,
      );
      expect(moved.x, greaterThan(base.x));
    });

    test('aşırı kaydırmada kutu SINIRLARA yapışır — boş piksel içermez', () {
      final r = cropFromViewport(
        imageWidth: 800,
        imageHeight: 800,
        viewport: 400,
        scale: 2,
        translateX: -100000,
        translateY: -100000,
      );
      expect(r.x + r.size, lessThanOrEqualTo(800));
      expect(r.y + r.size, lessThanOrEqualTo(800));
      expect(r.x, greaterThanOrEqualTo(0));
      expect(r.y, greaterThanOrEqualTo(0));
    });
  });

  group('yükleme bütçesi', () {
    test('base64 bayt hesabı sunucudaki ile aynı', () {
      expect(base64Bytes(base64Encode(Uint8List.fromList([1]))), 1);
      expect(base64Bytes(base64Encode(Uint8List.fromList([1, 2]))), 2);
      expect(base64Bytes(base64Encode(Uint8List.fromList([1, 2, 3]))), 3);
      expect(base64Bytes(''), 0);
    });

    test('sınır sunucuyla AYNI (512 KB) ve boş gövde reddedilir', () {
      expect(AvatarSpec.maxBytes, 512 * 1024);
      expect(fitsUploadBudget(0), isFalse);
      expect(fitsUploadBudget(AvatarSpec.maxBytes), isTrue);
      expect(fitsUploadBudget(AvatarSpec.maxBytes + 1), isFalse);
    });
  });

  group('kodlayıcı — gerçek görselle', () {
    /// Ölçülebilir bir test görseli (sol yarı siyah, sağ yarı beyaz).
    Uint8List sourcePng(int w, int h) {
      final im = img.Image(width: w, height: h);
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final v = x < w ~/ 2 ? 0 : 255;
          im.setPixelRgb(x, y, v, v, v);
        }
      }
      return img.encodePng(im);
    }

    test('çıktı KARE ve hedef ölçüde', () {
      final out = const AvatarEncoder().encode(
        sourcePng(1000, 600),
        centerSquare(1000, 600),
      );
      expect(out, isNotNull);
      final decoded = img.decodeImage(out!)!;
      expect(decoded.width, AvatarSpec.outputSize);
      expect(decoded.height, AvatarSpec.outputSize);
    });

    test('çıktı yükleme bütçesine RAHATLIKLA sığar', () {
      final out = const AvatarEncoder().encode(sourcePng(1600, 1600), centerSquare(1600, 1600))!;
      expect(fitsUploadBudget(base64Bytes(base64Encode(out))), isTrue);
      // Bütçenin yarısından da küçük olmalı — 512 KB yalnız emniyet kemeri.
      expect(out.length, lessThan(AvatarSpec.maxBytes ~/ 2));
    });

    test('kırpma kutusu GERÇEKTEN uygulanır (sağ yarı seçilince beyaz gelir)', () {
      final src = sourcePng(800, 400); // sol siyah, sağ beyaz
      final right = const AvatarEncoder().encode(src, (x: 400, y: 0, size: 400))!;
      final decoded = img.decodeImage(right)!;
      final px = decoded.getPixel(decoded.width ~/ 2, decoded.height ~/ 2);
      expect(px.r, greaterThan(200), reason: 'sağ yarı beyazdı');
    });

    test('sınır dışı kutu güvenle kırpılır (çökme yok)', () {
      final out = const AvatarEncoder().encode(
        sourcePng(300, 300),
        (x: -50, y: 9999, size: 100000),
      );
      expect(out, isNotNull);
    });

    test('çözülemeyen veri null döner — çağıran dürüst hata gösterir', () {
      final out = const AvatarEncoder().encode(Uint8List.fromList([1, 2, 3, 4]), (
        x: 0,
        y: 0,
        size: 10,
      ));
      expect(out, isNull);
    });
  });

  group('maskota dönüş — E8 temeli korunur', () {
    test('avatarUrl yoksa model maskotu taşımaya devam eder', () {
      const p = CommunityProfile(
        displayName: 'Deneme',
        avatarId: 'owl-teacher',
        licence: 'b',
        visibility: 'public',
      );
      expect(p.avatarUrl, isNull);
      expect(p.avatar, CommunityAvatar.owlTeacher);
    });

    test('avatarUrl JSON’dan okunur ve maskot yine durur', () {
      final p = CommunityProfile.fromJson({
        'displayName': 'Deneme',
        'avatarId': 'owl-shield',
        'avatarUrl': '/api/media/abc',
        'licence': 'b',
        'visibility': 'public',
      });
      expect(p.avatarUrl, '/api/media/abc');
      expect(p.avatar, CommunityAvatar.owlShield);
    });

    test('bilinmeyen maskot kimliği güvenli varsayılana düşer', () {
      expect(CommunityAvatar.fromId('yok-boyle'), CommunityAvatar.owlWave);
      expect(CommunityAvatar.fromId(null), CommunityAvatar.owlWave);
    });
  });

  group('şikâyet yüzeyi — avatar hedef olabilir', () {
    test('“Uygunsuz avatar” sebebi vardır ve sunucudaki değerle aynıdır', () {
      final avatarReason = ReportReason.values.firstWhere((r) => r.wire == 'avatar');
      expect(avatarReason.label.toLowerCase(), contains('avatar'));
    });
  });
}
