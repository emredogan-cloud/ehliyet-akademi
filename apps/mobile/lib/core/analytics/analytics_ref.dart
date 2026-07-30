import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics.dart';
import 'analytics_event.dart';

/// Beta Faz 3 — çağrı yerlerindeki tek satırlık analitik erişimi.
///
/// ## Neden bir uzantı
///
/// Olmasaydı her çağrı yeri şunu yazardı:
///
/// ```dart
/// ref.read(analyticsProvider).log(AnalyticsEvent.login);
/// ```
///
/// Bu satırın `ref.read(analyticsProvider)` kısmı otuz küsur yerde tekrar ederdi ve tekrar eden
/// her kalıp, zamanla **sapan** bir kalıptır: biri `read` yerine `watch` yazar (olay her yeniden
/// çizimde gider), biri `await` eder (akışı ölçüm hızına bağlar), biri `try/catch` ekler
/// (gereksiz — `log` zaten yutar). Tek bir giriş noktası bu üç sapmayı da kapatır.
///
/// ## Neden `await` edilmiyor
///
/// [track] bilinçli olarak `void` döner. Analitik hiçbir kullanıcı akışını BEKLETMEMELİDİR; bir
/// olayın diske yazılması ya da ağa çıkması, kullanıcının bir sonraki ekranı görmesini
/// geciktiremez. `Future` döndürülseydi çağrı yerlerinin yarısı onu bekler, yarısı beklemezdi.
extension AnalyticsRefX on Ref {
  /// Olayı kaydet (beklemeden).
  void track(AnalyticsEvent event) => read(analyticsProvider).log(event).ignore();

  /// Olayı cihaz ömründe bir kez kaydet (`app_installed`, `first_exam` gibi).
  void trackOnce(AnalyticsEvent event) => read(analyticsProvider).logOnce(event).ignore();
}

/// Widget tarafındaki karşılığı — aynı sözleşme, aynı gerekçeler.
extension AnalyticsWidgetRefX on WidgetRef {
  void track(AnalyticsEvent event) => read(analyticsProvider).log(event).ignore();

  void trackOnce(AnalyticsEvent event) => read(analyticsProvider).logOnce(event).ignore();
}
