import '../../core/assets.dart';
import 'content_enums.dart';
import 'lesson.dart';

/// Beta Faz 11 — ders sayfasının **saf** kural katmanı.
///
/// Neden ayrı dosya: zorluk ve görsel seçimi ekranın içine gömülürse test edilemez ve iki yerde
/// (liste + detay) tutarsızlaşır. Proje genelindeki desen budur (`entitlement_status.dart`,
/// `avatar_image.dart`): kural saf, ekran aptal.

/// Dersin zorluk kademesi.
enum LessonDifficulty {
  kolay('Kolay'),
  orta('Orta'),
  zor('Zor');

  const LessonDifficulty(this.label);
  final String label;
}

/// Zorluk — **ölçülebilir sinyallerden türetilir, veriye elle yazılmaz.**
///
/// NEDEN TÜRETİLİYOR: 19 dersin her birine elle "zorluk" etiketi yazmak, kaynağı olmayan bir
/// iddia üretmek olurdu; ilk içerik güncellemesinde de bayatlardı. Bunun yerine dersin KENDİ
/// ölçülebilir özellikleri kullanılır:
///
/// · `minutes`      — okuma yükü,
/// · `sections`     — konunun kaç parçaya bölündüğü (kavramsal genişlik),
/// · `mistakes`     — kaç ayrı tuzağı olduğu (kafa karıştırıcılık).
///
/// Puan = dakika/5 + bölüm sayısı + hata sayısı. Eşikler ölçülerek seçildi (mevcut 19 dersin
/// dağılımı yaklaşık üçte bir olacak biçimde): <6 kolay, <10 orta, üstü zor.
///
/// Kural değişirse `lesson_meta_test.dart` kırılır — sessizce kaymaz.
LessonDifficulty lessonDifficulty(Lesson lesson) {
  final score = lesson.minutes / 5 + lesson.sections.length + lesson.mistakes.length;
  if (score < 6) return LessonDifficulty.kolay;
  if (score < 10) return LessonDifficulty.orta;
  return LessonDifficulty.zor;
}

/// Konuya göre ders illüstrasyonu.
///
/// Ders başına ayrı görsel YOKTUR (19 ders × özel görsel üretilmedi); konu başına tutarlı bir
/// maskot kullanmak, rastgele bir görsel koymaktan daha dürüst ve daha okunur bir hiyerarşi
/// üretir — kullanıcı konuyu görselden de tanır.
String lessonHeroAsset(Subject subject) => switch (subject) {
  Subject.trafik => AppImages.owlWheel,
  Subject.ilkyardim => AppImages.owlShield,
  Subject.motor => AppImages.owlClipboard,
  Subject.adab => AppImages.owlBookBadge,
  Subject.pratik => AppImages.owlTeacher,
};

/// Okuma ilerlemesi (0..1).
///
/// `maxScrollExtent == 0` (içerik ekrana sığıyor) durumunda ilerleme **1** kabul edilir: sayfa
/// zaten tamamen görünüyordur. 0 dönmek, kısa derste çubuğu hep boş bırakırdı.
double lessonReadingProgress({required double offset, required double maxExtent}) {
  if (maxExtent <= 0) return 1;
  final v = offset / maxExtent;
  return v.isNaN ? 0 : v.clamp(0.0, 1.0);
}
