import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

/// Faz 7 — mağaza puanlama yüzeyi.
///
/// MİMARİ (projedeki kalıbın aynısı): platforma bağlı her şey **arayüz + uygulama** olarak
/// yazılır; testler sahte uygulamayla platform kanalı olmadan çalışır.
///
/// ## POLİTİKA NOTU — neden mağaza sayfası açılıyor, `requestReview` çağrılmıyor
///
/// Google Play, puanlamayı **filtrelemeyi** yasaklar: "önce bize kaç yıldız verirdin diye sor,
/// beğenenleri mağazaya gönder, beğenmeyenleri geri bildirim formuna al" kalıbı politikaya
/// aykırıdır. Ayrıca Play, uygulama-içi inceleme akışının (`requestReview`) ÖNÜNE kendi
/// penceresini koymamayı ister.
///
/// Referans tasarım yıldızlı bir pencere gösteriyor. İkisini uzlaştırmanın dürüst yolu şudur:
/// · yıldızlar bir JEST'tir, bir OYLAMA DEĞİL — hiçbir yere kaydedilmez,
/// · hangi yıldız seçilirse seçilsin AYNI yere gidilir: mağaza sayfası,
/// · pencere bunu açıkça söyler ("Puanını Google Play'de vereceksin").
/// Böylece tasarım korunur, filtreleme yapılmaz ve kullanıcı yanıltılmaz.
abstract class StoreReviewService {
  /// Mağazadaki uygulama sayfasını aç. Başarılıysa `true`.
  Future<bool> openStoreListing();
}

class InAppReviewStoreService implements StoreReviewService {
  InAppReviewStoreService({InAppReview? review}) : _review = review ?? InAppReview.instance;
  final InAppReview _review;

  @override
  Future<bool> openStoreListing() async {
    try {
      await _review.openStoreListing();
      return true;
    } catch (_) {
      // Play yüklü değil / mağaza açılamadı → uygulama ÇÖKMEZ, ekran dürüst bir mesaj gösterir.
      return false;
    }
  }
}

final storeReviewServiceProvider = Provider<StoreReviewService>(
  (ref) => InAppReviewStoreService(),
);
