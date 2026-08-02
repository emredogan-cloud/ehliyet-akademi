import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/content/narration.dart';

/// Sesli anlatım KAYNAĞI — Premium Kalite Programı · Faz 5.
///
/// Ses sentezi bir dış servistir ve bu oturumda bağlanmıyor. Bağlanmadığı için de arayüzün
/// ne yapacağı bir tasarım kararıdır ve **sessizce kırılmamalıdır**: çalışmayan bir "oynat"
/// düğmesi koymak ölü gezinmedir (mühendislik disiplini kural 3).
///
/// Bu yüzden sözleşme "ses ver" değil, **"ses verebiliyor musun?"** diye soruyor:
/// [resolve] `null` dönerse arayüz oynatıcıyı HİÇ göstermez.
///
/// ```
/// NarrationSource                     resolve() döndürür
/// ├── SilentNarrationSource   BUGÜN   null  → oynatıcı görünmez
/// ├── AssetNarrationSource            pakete gömülü ses dosyasının yolu
/// └── RemoteNarrationSource           sunucudan indirilmiş/önbelleklenmiş dosyanın yolu
/// ```
///
/// Üçü de aynı arayüzü uyguladığı için gerçek sentez geldiğinde **ekran kodu değişmez** —
/// yalnız sağlayıcı değişir. Düello'daki `DuelOpponent` soyutlamasının aynı gerekçesi.
abstract class NarrationSource {
  const NarrationSource();

  /// Bu kaynağın adı — hangi sağlayıcının etkin olduğu günlüklerde ve testte görünsün.
  String get name;

  /// Bu parça için çalınabilir bir ses var mı?
  ///
  /// Dönen değer bir **kaynak tanıtıcısıdır** (varlık yolu ya da yerel dosya yolu), ses
  /// verisinin kendisi değil: oynatıcı platform katmanında beslenir ve büyük baytları
  /// bu katmandan geçirmenin bir anlamı yoktur.
  ///
  /// `null` = "bu parça için ses yok". Hata DEĞİLDİR ve istisna atılmaz; sesin olmaması
  /// bugünkü normal durumdur.
  Future<String?> resolve(String lessonId, NarrationSegment segment);
}

/// BUGÜNKÜ VARSAYILAN — hiçbir parça için ses yok.
///
/// Bilerek boş bir uygulama değil, **dürüst** bir uygulama: ses üretilmediği sürece
/// kullanıcıya oynatıcı gösterilmez. "Yakında" yazan bir düğme de konmaz; olmayan bir
/// özelliği varmış gibi göstermek, Faz 0 denetiminde tur metninde yakalanan kusurun aynısı.
class SilentNarrationSource extends NarrationSource {
  const SilentNarrationSource();

  @override
  String get name => 'silent';

  @override
  Future<String?> resolve(String lessonId, NarrationSegment segment) async => null;
}

/// Pakete gömülü ses dosyaları.
///
/// Dosya adı sözleşmesi ŞİMDİDEN sabit: `assets/audio/<ders-id>/<parça-id>.m4a`. Ses
/// üretildiğinde bu ada konur ve **kod değişmeden** çalar — ayrılmış levha dosya adlarıyla
/// aynı desen (`planned_signs.dart`).
///
/// [exists] enjekte edilebilir çünkü varlık listesi çalışma zamanında bilinir; testte
/// gerçek bir dosya olmadan da davranış doğrulanabilsin.
class AssetNarrationSource extends NarrationSource {
  const AssetNarrationSource({required this.exists});

  /// Verilen varlık yolu gerçekten pakette mi? (`AssetCatalog.has` bunu karşılar.)
  final bool Function(String assetPath) exists;

  @override
  String get name => 'asset';

  /// Ses varlıklarının kök dizini. Tek yerde durur ki üreten kişi ile okuyan kod
  /// aynı sözleşmeye baksın.
  static const dir = 'assets/audio';

  /// Ayrılmış ad — ses üretenin hangi dosyayı hangi ada koyacağını tek yerden söyler.
  static String pathFor(String lessonId, String segmentId) =>
      '$dir/$lessonId/$segmentId.m4a';

  @override
  Future<String?> resolve(String lessonId, NarrationSegment segment) async {
    final path = pathFor(lessonId, segment.id);
    // Dosya YOKSA null dönülür; var olmayan bir varlığı oynatıcıya vermek, kırık görsel
    // göstermekle aynı hata sınıfı olurdu.
    return exists(path) ? path : null;
  }
}

/// Sunucudan indirilen ve yerelde önbeklenen ses.
///
/// [cachedPath] önbellekte hazır dosyanın yolunu döner, yoksa `null`. İNDİRME BU KATMANDA
/// TETİKLENMEZ: kullanıcı bir ders açtığında arka planda ağ isteği başlatmak, çevrimdışı
/// öncelikli bir uygulamada beklenmeyen veri harcamasıdır. İndirme, kullanıcının açık
/// isteğiyle (ders indirme akışı) yapılır ve buraya yalnız SONUCU yansır.
class RemoteNarrationSource extends NarrationSource {
  const RemoteNarrationSource({required this.cachedPath});

  final Future<String?> Function(String lessonId, String segmentId) cachedPath;

  @override
  String get name => 'remote';

  @override
  Future<String?> resolve(String lessonId, NarrationSegment segment) =>
      cachedPath(lessonId, segment.id);
}

/// Sırayla dener; ilk ses veren kazanır.
///
/// Sıra önemlidir: **önce yerel** (gömülü varlık), sonra önbellek. Çevrimdışı öncelikli
/// uygulamada en hızlı ve en garantili kaynak öndedir.
class FallbackNarrationSource extends NarrationSource {
  const FallbackNarrationSource(this.sources);

  final List<NarrationSource> sources;

  @override
  String get name => 'fallback(${sources.map((s) => s.name).join('>')})';

  @override
  Future<String?> resolve(String lessonId, NarrationSegment segment) async {
    for (final s in sources) {
      final hit = await s.resolve(lessonId, segment);
      if (hit != null) return hit;
    }
    return null;
  }
}

/// Etkin kaynak.
///
/// BUGÜN sessiz. Ses dosyaları `assets/audio/` altına konduğunda burası
/// `FallbackNarrationSource([AssetNarrationSource(...), RemoteNarrationSource(...)])`
/// olur; ekran kodu ve oynatıcı **değişmez**.
final narrationSourceProvider = Provider<NarrationSource>(
  (ref) => const SilentNarrationSource(),
);
