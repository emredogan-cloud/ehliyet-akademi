import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../domain/community/avatar_image.dart';

/// Beta Faz 7 — profil fotoğrafı: seçme, kırpma/sıkıştırma ve sunucuya yazma.
///
/// MİMARİ (yerleşik desen): platforma bağlı her şey **arayüz + uygulama**. Galeri/kamera bir
/// platform kanalıdır ve widget testinde örneklenemez; bu yüzden yüzey [AvatarPicker] ile
/// konuşur, testler sahte uygulamayla çalışır.
///
/// ⚠️ İZİN NOTU: modern Android'de `image_picker` **izin gerektirmeyen** sistem foto seçicisini
/// kullanır. `READ_MEDIA_IMAGES` **EKLENMEMELİDİR** — eklenirse Play Console'da ayrı bir gerekçe
/// formu açılır ve uygulamanın izin listesi (yalnız `POST_NOTIFICATIONS` +
/// `RECEIVE_BOOT_COMPLETED`) bozulur. Bkz. `PLAY_CONSOLE_SETUP.md` §5.8.

/// Kullanıcının fotoğrafı nereden seçtiği.
enum AvatarSource { gallery, camera }

/// Seçilmiş ham görsel — kırpma ekranına girdi.
class PickedImage {
  const PickedImage(this.bytes);
  final Uint8List bytes;
}

abstract class AvatarPicker {
  /// Fotoğraf seç. Kullanıcı vazgeçerse **null** — bu bir hata DEĞİLDİR.
  Future<PickedImage?> pick(AvatarSource source);
}

class ImagePickerAvatarPicker implements AvatarPicker {
  ImagePickerAvatarPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  @override
  Future<PickedImage?> pick(AvatarSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == AvatarSource.camera ? ImageSource.camera : ImageSource.gallery,
        // Çok büyük görselleri belleğe hiç almamak için seçicide küçültülür.
        maxWidth: AvatarSpec.pickMaxSide,
        maxHeight: AvatarSpec.pickMaxSide,
        imageQuality: 90,
      );
      if (file == null) return null; // vazgeçme
      return PickedImage(await file.readAsBytes());
    } catch (_) {
      return null;
    }
  }
}

/// Kırpma + yeniden boyutlandırma + JPEG kodlama.
///
/// Saf Dart (`image` paketi) — platform kanalı gerekmez, testte de çalışır.
class AvatarEncoder {
  const AvatarEncoder();

  /// [bytes] görselini [rect] ile kırpar, [AvatarSpec.outputSize] kareye indirir ve JPEG üretir.
  /// Görsel çözülemezse **null** döner (çağıran dürüst bir hata gösterir).
  Uint8List? encode(Uint8List bytes, ({int x, int y, int size}) rect) {
    // Bozuk/desteklenmeyen veri `decodeImage` içinde İSTİSNA da fırlatabilir (yalnız null
    // dönmez) — kullanıcı seçtiği her şeyi verebileceği için burada yakalanır.
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // Kırpma kutusunu her koşulda görselin içinde tut (bozuk girdiye karşı emniyet).
      final shortest = decoded.width < decoded.height ? decoded.width : decoded.height;
      final size = rect.size.clamp(1, shortest);
      final x = rect.x.clamp(0, decoded.width - size);
      final y = rect.y.clamp(0, decoded.height - size);

      final cropped = img.copyCrop(decoded, x: x, y: y, width: size, height: size);
      final square = img.copyResize(
        cropped,
        width: AvatarSpec.outputSize,
        height: AvatarSpec.outputSize,
        interpolation: img.Interpolation.average,
      );
      return img.encodeJpg(square, quality: AvatarSpec.jpegQuality);
    } catch (_) {
      return null;
    }
  }
}

/// Sunucu sözleşmesi.
abstract class AvatarApi {
  /// Fotoğrafı yükle → yeni `avatarUrl`. Hata olursa mesaj fırlatılmaz; `null` döner ve
  /// [lastError] okunur — çağıran dürüst mesajı gösterir.
  Future<String?> upload(Uint8List jpeg);

  /// Fotoğrafı kaldır → maskota dön.
  Future<bool> remove();

  /// Son hatanın kullanıcıya gösterilecek metni.
  String? get lastError;
}

class DioAvatarApi implements AvatarApi {
  DioAvatarApi(this._dio);
  final Dio _dio;

  @override
  String? lastError;

  @override
  Future<String?> upload(Uint8List jpeg) async {
    lastError = null;
    final data = base64Encode(jpeg);
    if (!fitsUploadBudget(base64Bytes(data))) {
      lastError = 'Fotoğraf çok büyük. Lütfen daha küçük bir görsel seç.';
      return null;
    }
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/community/avatar',
        data: {'mime': 'image/jpeg', 'dataBase64': data},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode == 201) return res.data?['avatarUrl']?.toString();
      lastError = res.data?['error']?.toString() ?? 'Fotoğraf yüklenemedi.';
      return null;
    } on DioException catch (_) {
      lastError = 'Bağlantı hatası. İnternetini kontrol et.';
      return null;
    }
  }

  @override
  Future<bool> remove() async {
    lastError = null;
    try {
      final res = await _dio.delete<Map<String, dynamic>>(
        '/api/community/avatar',
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode == 200) return true;
      lastError = res.data?['error']?.toString() ?? 'Fotoğraf kaldırılamadı.';
      return false;
    } on DioException catch (_) {
      lastError = 'Bağlantı hatası. İnternetini kontrol et.';
      return false;
    }
  }
}

final avatarPickerProvider = Provider<AvatarPicker>((ref) => ImagePickerAvatarPicker());
final avatarEncoderProvider = Provider<AvatarEncoder>((ref) => const AvatarEncoder());
final avatarApiProvider = Provider<AvatarApi>((ref) => DioAvatarApi(ref.watch(dioProvider)));
