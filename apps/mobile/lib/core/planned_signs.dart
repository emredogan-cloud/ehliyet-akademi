import 'asset_resolver.dart';
import 'official_signs.dart';

/// Ürün Evrimi v1.1 · Faz 3 — HENÜZ ÜRETİLMEMİŞ resmî levha vektörlerinin ayrılmış dosya adları.
///
/// Denetimde 121 işaretin 35'inin resmî SVG'si olmadığı ölçüldü. Bunların 17'si sayı taşıyan hız
/// levhası; onlarda prosedürel çizim DOĞRU çözüm (rakam veridir, çizim değil) ve görsel
/// üretilmeyecek — gerekçe `ASSET_GENERATION_LIBRARY.md` §7.2.
///
/// Kalan 18'i gerçek bir piktogram istiyor. Dosya adları burada ŞİMDİDEN ayrıldı ki görsel
/// `assets/signs/` altına konduğu an, **kod değişmeden** görünsün. `pubspec.yaml` bu dizinin
/// tamamını kaydettiği için yeni dosya derlemede kendiliğinden paketlenir.
///
/// DOSYA ADI KURALI: `assets/signs/<işaret-id>.svg`. Üretilmiş levhalar KGM kodunu kullanıyor
/// (`t-9`, `b-30`…) ama o kodların hangisinin boş olduğunu buradan bilemeyiz — ilk denemede
/// `t-9.svg` seçildi ve zaten kullanımdaydı (test yakaladı). İşaret kimliği hem benzersiz hem
/// okunur; ayrıca `AssetCatalog.byConvention('signs', id)` ile birebir örtüşür.
///
/// NEDEN doğrudan `kOfficialSignAsset`'e eklenmedi: o haritadaki her giriş VAR OLAN bir dosyayı
/// gösterir ve `SvgPicture.asset` doğrudan çağrılır. Olmayan bir dosyayı oraya yazmak, işareti
/// prosedürel çizimden alıp kırık bir görsele düşürürdü — yani mevcut durumu KÖTÜLEŞTİRİRDİ.
/// Buradaki yol yalnız [AssetCatalog] dosyanın gerçekten paketlendiğini doğrularsa kullanılır.
const Map<String, String> kPlannedSignAsset = {
  // Tehlike — kırmızı kenarlı üçgen
  'kaygan-yol': 'assets/signs/kaygan-yol.svg',
  'tehlikeli-viraj-sag': 'assets/signs/tehlikeli-viraj-sag.svg',
  'dik-cikis': 'assets/signs/dik-cikis.svg',
  'vahsi-hayvan': 'assets/signs/vahsi-hayvan.svg',

  // Yasak / park
  'park-yasak': 'assets/signs/park-yasak.svg',
  'park-yasagi-sonu': 'assets/signs/park-yasagi-sonu.svg',
  'park-saat-sinirli': 'assets/signs/park-saat-sinirli.svg',
  'engelli-parki': 'assets/signs/engelli-parki.svg',

  // Mecburiyet — mavi disk
  'saga-donus-mecburi': 'assets/signs/saga-donus-mecburi.svg',
  'sola-donus-mecburi': 'assets/signs/sola-donus-mecburi.svg',

  // Bilgi — mavi dikdörtgen
  'lokanta': 'assets/signs/lokanta.svg',
  'taksi-duragi': 'assets/signs/taksi-duragi.svg',
  'tunel': 'assets/signs/tunel.svg',
  'havalimani': 'assets/signs/havalimani.svg',
  'motorlu-tasit-yolu': 'assets/signs/motorlu-tasit-yolu.svg',

  // Otoyol / yönlendirme
  'otoyol-cikisi': 'assets/signs/otoyol-cikisi.svg',
  'otoyol-cikisi-300m': 'assets/signs/otoyol-cikisi-300m.svg',
  'devlet-yolu': 'assets/signs/devlet-yolu.svg',
};

/// Sayı taşıdığı için GÖRSEL ÜRETİLMEYECEK işaretler.
///
/// Kayıt amacı belgeleme: "bu neden eksik?" sorusunun cevabı kodda dursun. Bir test bu kümeyle
/// [kPlannedSignAsset]'in kesişmediğini doğrular — yani yanlışlıkla ikisine birden girmesin.
const Set<String> kProceduralBySign = {
  'azami-hiz-20', 'azami-hiz-30', 'azami-hiz-40', 'azami-hiz-50',
  'azami-hiz-60', 'azami-hiz-70', 'azami-hiz-80', 'azami-hiz-90',
  'azami-hiz-100', 'azami-hiz-110', 'azami-hiz-120',
  'asgari-hiz-30', 'asgari-hiz-40', 'asgari-hiz-50',
  'hiz-siniri-sonu', 'tum-yasaklarin-sonu', 'yukseklik-siniri',
};

/// Bu işaret için çizilecek resmî vektör — varsa.
///
/// Sıra: (1) üretilmiş resmî levha, (2) ayrılmış ad ALTINDA gerçekten paketlenmiş dosya,
/// (3) yok → çağıran prosedürel çizime düşer.
///
/// [catalog] verilmezse yalnız (1) denenir; böylece katalog henüz yüklenmemişken de doğru
/// çalışır ve hiçbir yerde kırık görsel çıkmaz.
String? signAssetFor(String signId, {AssetCatalog? catalog}) {
  final official = officialSignAsset(signId);
  if (official != null) return official;
  final planned = kPlannedSignAsset[signId];
  if (planned != null && catalog != null && catalog.has(planned)) return planned;
  return null;
}
