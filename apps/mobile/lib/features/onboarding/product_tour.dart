import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../design/coach_marks.dart';

/// Faz 1 — ürün turu: hangi öğe, hangi sırayla ve hangi cümleyle tanıtılıyor.
///
/// TASARIM KARARI — tur TEK EKRANDA geçer (Ana Sayfa + alt gezinme çubuğu).
///
/// Alternatif, her adımda sekme değiştiren bir turdu. Denemeye değmez: sekme geçişi bir animasyon
/// başlatır, hedef widget yeni ağaçta henüz ölçülmemiştir ve ışık halkası bir kare boyunca yanlış
/// yere düşer. Bunun yerine Ana Sayfa GERÇEK bir merkez hâline getirildi — tanıtılan her özelliğin
/// oradan bir girişi var. Tur böylece hem kararlı hem dürüst: gösterdiği düğmeler gerçekten orada.
class ProductTourAnchors {
  const ProductTourAnchors._();

  static const home = 'tour.home';
  static const smartStudy = 'tour.smartStudy';
  static const practiceExam = 'tour.practiceExam';
  static const realExam = 'tour.realExam';
  static const aiCoach = 'tour.aiCoach';
  static const progress = 'tour.progress';
  static const premium = 'tour.premium';
  static const bottomNav = 'tour.bottomNav';

  /// Topluluk, Ana Sayfa'da bir kartla DEĞİL, kendi SEKMESİYLE tanıtılır — kullanıcının ona
  /// gerçekten ulaşacağı yer orası. Kimlik `AppShell.tabs` içinde bu sabite bağlanır.
  static const community = 'tour.tab.community';
}

/// Turun adımları — sıra, kullanıcının doğal öğrenme akışını izler:
/// nerede olduğunu gör → çalış → ölç → sor → paylaş → aç.
const List<CoachMarkStep> productTourSteps = [
  CoachMarkStep(
    anchorId: ProductTourAnchors.home,
    icon: Icons.home_rounded,
    title: 'Ana Sayfa',
    body:
        'Sınava ne kadar hazır olduğunu tek bakışta burada görürsün. Sen çözdükçe hazırlık oranın, '
        'doğruluğun ve seviyen canlı olarak güncellenir.',
  ),
  CoachMarkStep(
    anchorId: ProductTourAnchors.smartStudy,
    icon: Icons.bolt_rounded,
    title: 'Akıllı Çalışma',
    body:
        'Rastgele soru çözmezsin: sistem zayıf konularını ve tekrar zamanı gelen soruları seçer. '
        'Her gün en çok işine yarayacak soruları görürsün.',
    radius: AppRadii.base,
  ),
  CoachMarkStep(
    anchorId: ProductTourAnchors.practiceExam,
    icon: Icons.timer_outlined,
    title: 'Deneme Sınavı',
    body:
        'Gerçek e-Sınav düzeni: 50 soru, 45 dakika, 35 doğru barajı. Süre ve dağılım birebir aynı — '
        'sınav gününü provası burada.',
    radius: AppRadii.base,
  ),
  CoachMarkStep(
    anchorId: ProductTourAnchors.realExam,
    icon: Icons.history_edu_rounded,
    title: 'Çıkmış Sınavlar',
    body:
        'Geçmiş dönemlerde sorulmuş gerçek sınavları olduğu gibi çöz. Nelerin sorulduğunu görmek, '
        'neyi çalışacağını da söyler.',
    radius: AppRadii.base,
  ),
  CoachMarkStep(
    anchorId: ProductTourAnchors.aiCoach,
    icon: Icons.auto_awesome_rounded,
    title: 'AI Koç',
    body:
        'Takıldığın soruyu sor, anlaşılır bir açıklama al. Koç ayrıca ilerlemene bakıp sana ne '
        'çalışman gerektiğini kendisi söyler.',
  ),
  CoachMarkStep(
    anchorId: ProductTourAnchors.progress,
    icon: Icons.insights_rounded,
    title: 'İlerleme',
    body:
        'Ders bazında ustalık radarı, çalışma haritan, seviyen ve rozetlerin. Nerede güçlü, nerede '
        'eksik olduğunu tahmin etmezsin — ölçersin.',
  ),
  CoachMarkStep(
    anchorId: ProductTourAnchors.premium,
    icon: Icons.workspace_premium_rounded,
    title: 'Premium',
    body:
        'Sınırsız deneme, sınırsız AI Koç ve tüm video dersler tek pakette. Ücretsiz sürümle de '
        'çalışabilirsin — premium, sınırları kaldırır.',
    radius: AppRadii.base,
  ),
  CoachMarkStep(
    anchorId: ProductTourAnchors.community,
    icon: Icons.groups_rounded,
    title: 'Topluluk',
    body:
        'Aynı sınava hazırlananlarla sıralamanı karşılaştır, gruplara katıl, soru tartış. '
        'Tamamen isteğe bağlı — katılmadığın sürece hiçbir bilgin paylaşılmaz.',
    radius: AppRadii.sm,
  ),
  CoachMarkStep(
    anchorId: ProductTourAnchors.bottomNav,
    icon: Icons.dashboard_rounded,
    title: 'Alt menü',
    body:
        'Uygulamanın altı bölümü hep burada. Bulunduğun sekmeye yeniden dokunursan o bölümün '
        'başına dönersin. Hazırsan başlayalım!',
    radius: AppRadii.sm,
  ),
];
