import '../onboarding/study_profile.dart';
import 'vehicle_part.dart';

/// Evolution Faz E4 — seçilen ehliyet sınıfına göre içerik kapsamlama (saf, test edilebilir).
///
/// KURAL: içerik `licences` alanı BOŞSA her sınıf için geçerlidir (motor, sıvılar, lastik, acil
/// ekipman gibi ortak konular). Doluysa yalnız listelenen sınıflarda gösterilir.
///
/// NOT (bilinçli tasarım): e-Sınav teori soru bankası Türkiye'de sınıftan bağımsız ORTAKTIR.
/// Bu yüzden ilerleme/SRS verisi sınıfa göre BÖLÜNMEZ — sınıf değiştiren kullanıcı teori
/// ilerlemesini kaybetmez. Sınıfa özgü olan şey İÇERİK KAPSAMI ve önceliklendirmedir.
bool matchesLicence(List<String> licences, LicenceCategory category) =>
    licences.isEmpty || licences.contains(category.wire);

/// Bu sınıfa özgü mü (ortak içerik değil)?
bool isLicenceSpecific(List<String> licences) => licences.isNotEmpty;

extension LicenceScopedParts on List<VehiclePart> {
  /// Yalnız bu sınıfta geçerli parçalar.
  List<VehiclePart> forLicence(LicenceCategory category) =>
      where((p) => matchesLicence(p.licences, category)).toList();

  /// Sınıfa ÖZGÜ parçalar önce, ortak parçalar sonra — kaynak sırası korunur.
  /// (Kullanıcı önce kendi aracına ait olanı görür; ortak konular hemen ardından gelir.)
  List<VehiclePart> prioritizedFor(LicenceCategory category) {
    final scoped = forLicence(category);
    final specific = scoped.where((p) => isLicenceSpecific(p.licences)).toList();
    final shared = scoped.where((p) => !isLicenceSpecific(p.licences)).toList();
    return [...specific, ...shared];
  }
}
