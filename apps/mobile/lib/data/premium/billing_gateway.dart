import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/premium/entitlement_status.dart';
import '../../domain/premium/products.dart';
import 'play_billing_gateway.dart';

export '../../domain/premium/entitlement_status.dart' show EntitlementFacts;

// `BillingPeriod` ALAN katmanında tanımlıdır (`domain/premium/products.dart`) ve buradan yeniden
// dışa verilir: katalogla mağaza yanıtı aynı türü kullansın diye. İki ayrı kopya varken
// "mağazanın bildirdiği dönem, sattığımız paketin dönemi mi?" sorusu sorulamıyordu.
export '../../domain/premium/products.dart' show BillingPeriod;

/// Beta Faz 3 — ödeme altyapısı SOYUTLAMASI.
///
/// MİMARİ (Evolution'dan devam, Faz 2'de Google girişinde uygulanan kalıbın aynısı): platforma
/// bağlı her şey **arayüz + uygulama** olarak yazılır. Bu dosya hiçbir ödeme eklentisinin türünü
/// dışarı sızdırmaz; `in_app_purchase`'ın `ProductDetails`'i burada [BillingProduct]'a indirgenir.
/// Böylece ödeme ekranı tek bir sözleşme görür ve widget testleri sahte ağ geçidiyle, platform
/// kanalı olmadan çalışır.
///
/// Soyutlamanın DEĞERİ bu turda kanıtlandı: hiç kullanılmayan ikinci bir sağlayıcı
/// (RevenueCat) tek bir satır değiştirilerek kaldırıldı ve ödeme ekranı ile testlerin hiçbiri
/// etkilenmedi. Ayrıntı [billingGatewayProvider] üzerinde.

/// Satın almanın sunucudaki yetkilendirmeye hangi yolla dönüştüğü.
///
/// Bu, iki altyapı arasındaki **gerçek** mimari farktır ve gizlenmez: sunucu her iki durumda da
/// yetkinin tek kaynağıdır, ama ona ulaşan yol farklıdır.
enum BillingServerBridge {
  /// Makbuz (Play `purchaseToken`) istemciden alınır ve `POST /api/iap/validate` ile sunucuda
  /// doğrulanır. Bugünkü `in_app_purchase` yolu budur.
  clientReceipt,

  /// Sunucu yetkilendirmeyi bir aracının **webhook**'undan alır; istemci ham Play makbuzunu
  /// görmez.
  ///
  /// BUGÜN KULLANILMIYOR ve bilerek duruyor: bu ayrım, ödeme altyapısı değiştiğinde
  /// **gerçekten değişen** şeyin ne olduğunu tek satırda anlatıyor (yetkiye ulaşan yol).
  /// Kaldırmak, bir sonraki entegrasyonda aynı ayrımı yeniden keşfetmek demekti.
  externalWebhook,
}

/// Mağaza ürünü — hangi altyapı kullanılırsa kullanılsın aynı biçim.
class BillingProduct {
  const BillingProduct({
    required this.storeProductId,
    required this.priceLabel,
    this.title,
    this.period = BillingPeriod.unknown,
  });

  /// Mağazadaki ürün kimliği (ör. `komple_ehliyet`).
  final String storeProductId;

  /// Mağazanın **yerelleştirdiği** fiyat metni (ör. `₺399,00`). Uygulama fiyatı kendisi biçimlemez —
  /// para birimi ve biçim ülkeye göre değişir.
  final String priceLabel;

  final String? title;
  final BillingPeriod period;
}

/// Tamamlanmış (veya geri yüklenmiş) bir satın alma.
class BillingPurchase {
  const BillingPurchase({
    required this.storeProductId,
    this.purchaseToken,
    this.entitlements = const {},
  });

  final String storeProductId;

  /// Play satın alma token'ı. **Yalnız [BillingServerBridge.clientReceipt] yolunda doludur**;
  /// RevenueCat yolunda `null`'dır (SDK ham token'ı sunmaz).
  final String? purchaseToken;

  /// Sağlayıcının bildirdiği etkin yetki kimlikleri (ör. `{premium}`).
  final Set<String> entitlements;
}

/// Bir ödeme işleminin sonucu.
sealed class BillingResult {
  const BillingResult();
}

/// Satın alma/geri yükleme başarılı.
class BillingSuccess extends BillingResult {
  const BillingSuccess(this.purchases);

  /// Geri yüklemede birden çok olabilir; satın almada tek öğe.
  final List<BillingPurchase> purchases;
}

/// Kullanıcı vazgeçti — **bu bir HATA DEĞİLDİR**, mesaj gösterilmez (Faz 2'deki kalıp).
class BillingCancelled extends BillingResult {
  const BillingCancelled();
}

/// Gerçek hata; [message] kullanıcıya gösterilir.
class BillingFailure extends BillingResult {
  const BillingFailure(this.message, {this.alreadyOwned = false});
  final String message;

  /// Play "bu ürüne zaten sahipsin" dedi.
  ///
  /// AYRI BİR ALAN OLMASI ŞART: bu, kullanıcının düzeltebileceği bir hata DEĞİL, satın almanın
  /// gerçekten var olduğunun kanıtıdır. Doğru davranış hata göstermek değil, geri yüklemeyi
  /// tetiklemektir. Ekranın bunu metin karşılaştırarak anlaması kırılgan olurdu.
  final bool alreadyOwned;
}

/// Ödeme altyapısı sözleşmesi.
abstract class BillingGateway {
  /// Bu ağ geçidi kullanılabilir biçimde **yapılandırıldı mı**. False ise seçim mekanizması onu
  /// hiç kullanmaz; uygulama çökmez.
  bool get isConfigured;

  /// Satın almanın sunucuya hangi yolla ulaştığı.
  BillingServerBridge get serverBridge;

  /// Teşhis için kısa ad (raporlarda/geliştirici yüzeyinde).
  String get name;

  /// Mağaza şu an satın almaya açık mı (Play Store yüklü, oturum var, ürünler tanımlı).
  Future<bool> available();

  /// Katalogdaki ürünlerin mağaza detayları. Mağaza yoksa/ürün tanımlı değilse **boş liste** —
  /// istisna fırlatılmaz.
  Future<List<BillingProduct>> products();

  /// Satın alma akışını başlat.
  Future<BillingResult> purchase(BillingProduct product);

  /// Önceki satın almaları geri yükle. **Play politikası gereği bu yüzey her koşulda bulunmalıdır.**
  Future<BillingResult> restore();

  /// Sağlayıcının bildirdiği yetkilerin ham gerçekleri (yaşam döngüsü mesajlarının kaynağı).
  /// Sağlayıcı yaşam döngüsü bilgisi taşımıyorsa **boş liste** — uydurma durum üretilmez.
  Future<List<EntitlementFacts>> entitlementFacts();

  /// Sağlayıcının bildirdiği **etkin** yetki kimlikleri. Yetkinin **tek kaynağı sunucudur**; bu,
  /// ödeme ekranının anlık geri bildirimi içindir. [entitlementFacts]'tan türetilir.
  Future<Set<String>> entitlements() async {
    final facts = await entitlementFacts();
    return {
      for (final f in facts)
        if (f.isActive) f.identifier,
    };
  }

  /// Uygulama dışında tamamlanan satın almalar (ör. kesintiden sonra Play'in tamamladığı işlem)
  /// için dinleyici. `in_app_purchase` yolunda bu ŞARTTIR.
  ///
  /// Faz 2 — [onError] eklendi. Mağaza akışı yalnız başarıyı değil HATAYI da bildirir; en
  /// önemlisi "bu ürüne zaten sahipsin". Bu olay yutulduğunda kullanıcı satın alma düğmesine
  /// basıyor ve hiçbir şey olmuyordu (sahadaki asıl şikâyet buydu).
  ///
  /// Beta Faz 2 — [onCancelled] ve [onPending] eklendi.
  ///
  /// **Bu iki geri çağırım isteğe bağlı GÖRÜNÜR ama `clientReceipt` yolunda ZORUNLUDUR.** Sebebi
  /// sözleşmenin asenkron olması: `purchase()` yalnız akışın BAŞLATILDIĞINI bildirir, sonucu
  /// bildirmez. Dolayısıyla "kullanıcı vazgeçti" ve "ödeme beklemede" haberleri buradan gelmezse
  /// ödeme ekranının beklemesi hiç bitmez — gerçek cihazda düğme sonsuza kadar dönüyordu.
  void listen(
    Future<void> Function(BillingPurchase) onPurchase, {
    Future<void> Function(BillingFailure)? onError,

    /// Kullanıcı Play sayfasını kapattı. **Hata değildir**; mesaj gösterilmez, yalnız bekleme biter.
    Future<void> Function()? onCancelled,

    /// Satın alma BEKLEMEDE (nakit ödeme / operatör faturası). Para henüz alınmadı → hak VERİLMEZ,
    /// ama kullanıcıya durumu söylenmelidir; sessizlik "ödedim mi?" sorusunu doğurur.
    Future<void> Function(BillingPurchase)? onPending,
  });

  void dispose();
}

/// Etkin ödeme ağ geçidi — **Play Billing** (`in_app_purchase`).
///
/// ## RevenueCat neden KALDIRILDI (Premium Kalite Programı · Faz 6)
///
/// Bir dönem ikinci bir ağ geçidi (`RevenueCatGateway`) vardı ve yalnız
/// `--dart-define=REVENUECAT_PUBLIC_KEY` verilmişse seçiliyordu. O bayrak hiçbir derlemede
/// verilmedi; dolayısıyla ağ geçidi **hiçbir zaman çalışmadı**.
///
/// Buna karşılık bedeli ölçüldü: yayınlanan sürüm APK'sının `classes.dex` dosyasında
/// **3114 RevenueCat sembolü** duruyordu. Yani her kullanıcı, hiç kullanılmayan bir ödeme
/// SDK'sını indiriyordu.
///
/// Kaldırma **davranışı değiştirmez** ve bu kanıtlanabilir: seçim koşulu
/// `isConfigured` idi, o da anahtar boş olduğu için daima `false` dönüyordu — yani sevk
/// edilen her derleme zaten bu satırdaki yolu kullanıyordu.
final billingGatewayProvider = Provider<BillingGateway>((ref) {
  final gateway = PlayBillingGateway();
  ref.onDispose(gateway.dispose);
  return gateway;
});
