import 'package:flutter/services.dart';

/// Faz 8 — içerik kimliğinden VARLIK YOLUNA çözümleme.
///
/// ## Çözülen sorun
///
/// `official_signs.dart`, `dash_assets.dart` ve `mech_assets.dart` **elle yazılmış eşleme
/// tabloları** taşıyor (`'abs' → 'assets/dash/abs.webp'`). `pubspec.yaml` klasörün tamamını
/// bildirdiği için (`- assets/dash/`) klasöre bırakılan yeni bir dosya **pakete girer** ama
/// tabloya elle satır eklenmedikçe **hiçbir yerde kullanılmaz**. Yani varlık üretim hattının
/// çıktısı, kod değişmeden ürüne ulaşamıyordu.
///
/// Bu çözümleyici sırayı tersine çevirir:
///
/// 1. **Sözleşme (convention):** `assets/<kategori>/<id>.<uzantı>` gerçekten paketteyse o kullanılır.
/// 2. **İstisna tablosu:** dosya adı kimlikten FARKLIYSA (resmî işaret kodları gibi:
///    `agirlik-siniri` → `tt-24.svg`) mevcut tablo devreye girer.
///
/// Sonuç: doğru adla üretilmiş bir görsel klasöre bırakıldığında **kod değişmeden** kullanılır.
///
/// ## DÜRÜST SINIR — "otomatik" ne demek, ne demek değil
///
/// Flutter varlıkları **derleme zamanında** pakete gömülür. Bu çözümleyici "kod değişmeden
/// kullanılır" sözünü verir; "kurulu uygulamaya dosya eklenince görünür" sözünü **vermez** —
/// öyle bir şey mümkün değildir. Yeni varlık için **yeniden derleme şarttır**. Kazanç, elle
/// tablo bakımının ortadan kalkmasıdır.
class AssetCatalog {
  AssetCatalog._(this._assets);

  final Set<String> _assets;

  static AssetCatalog? _instance;

  /// Test/önizleme için doğrudan kurulum.
  static AssetCatalog forTest(Iterable<String> assets) => AssetCatalog._(assets.toSet());

  /// Paketteki varlık listesini bir kez okur.
  ///
  /// Okuma başarısız olursa **boş katalog** döner: çözümleyici o zaman yalnız istisna tablosuna
  /// güvenir ve uygulama eskisi gibi çalışır. Varlık listesi okunamadı diye ekran boş kalmaz.
  static Future<AssetCatalog> load([AssetBundle? bundle]) async {
    final existing = _instance;
    if (existing != null) return existing;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(bundle ?? rootBundle);
      return _instance = AssetCatalog._(manifest.listAssets().toSet());
    } catch (_) {
      return _instance = AssetCatalog._(const {});
    }
  }

  /// Yalnız testlerin sıfırlaması için.
  static void resetForTest() => _instance = null;

  /// Yalnız testlerin doğrudan kurması için.
  static void setForTest(Iterable<String> assets) => _instance = AssetCatalog._(assets.toSet());

  /// Zaten YÜKLENMİŞ katalog — yoksa null.
  ///
  /// Senkron erişim gerekiyor çünkü çağıranlar `StatelessWidget` (ör. `TrafficSignView`) ve
  /// çizim sırasında `await` edemezler. Katalog açılışta bir kez yüklenir ([load]); yüklenmeden
  /// önce çizilen birkaç kare için null döner ve çağıran güvenli varsayılana (prosedürel çizim)
  /// düşer — kırık görsel çıkmaz.
  static AssetCatalog? get currentOrNull => _instance;

  bool has(String path) => _assets.contains(path);

  /// [id] için `assets/<category>/<id>.<ext>` yollarından paketteki İLKİNİ döndür.
  ///
  /// Uzantı sırası anlamlıdır: vektör (`svg`) rasterin önünde gelir — aynı işaretin hem svg hem
  /// webp hâli varsa ölçeklenebilir olanı tercih edilir.
  String? byConvention(String category, String id, {List<String> extensions = const ['svg', 'webp', 'png']}) {
    for (final ext in extensions) {
      final path = 'assets/$category/$id.$ext';
      if (has(path)) return path;
    }
    return null;
  }

  /// Tam çözümleme: önce sözleşme, sonra istisna tablosu.
  ///
  /// SIRA NEDEN BÖYLE: üretim hattı bir varlığı KİMLİĞİYLE üretir. Aynı kimlik için hem
  /// sözleşmeye uyan yeni bir dosya hem eski bir istisna satırı varsa, yeni dosya kazanmalı —
  /// yoksa varlık yenileme her seferinde tablo düzenlemeyi gerektirirdi.
  String? resolve({
    required String category,
    required String id,
    Map<String, String> overrides = const {},
    List<String> extensions = const ['svg', 'webp', 'png'],
  }) {
    final conventional = byConvention(category, id, extensions: extensions);
    if (conventional != null) return conventional;
    return overrides[id];
  }
}
