import '../onboarding/study_profile.dart';
import 'content_enums.dart';
import 'licence_scope.dart';
import 'content_snapshot.dart';
import 'lesson.dart';
import 'traffic_sign.dart';
import 'vehicle_part.dart';
import 'video_content.dart';

/// İçerik anlık görüntüsü üzerinde gruplama/arama yardımcıları (web `lessonBySlug`/`signById`… eşleniği).
extension ContentQueries on ContentSnapshot {
  Lesson? lessonBySlug(String slug) {
    for (final l in lessons) {
      if (l.slug == slug) return l;
    }
    return null;
  }

  TrafficSign? signById(String id) {
    for (final s in signs) {
      if (s.id == id) return s;
    }
    return null;
  }

  VehiclePart? partById(String id) {
    for (final p in vehicleParts) {
      if (p.id == id) return p;
    }
    return null;
  }

  VideoContent? videoById(String id) {
    for (final v in videos) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// Dersler → konuya göre (kaynak sırası korunur). `licence` verilirse o sınıfta geçerli
  /// dersler kalır (Evolution Faz E5); etiketsiz ortak teori dersleri her sınıfta görünür.
  Map<Subject, List<Lesson>> lessonsBySubject({LicenceCategory? licence}) {
    final source = licence == null ? lessons : lessons.forLicence(licence);
    final map = <Subject, List<Lesson>>{};
    for (final l in source) {
      (map[l.subject] ??= []).add(l);
    }
    return map;
  }

  /// Bu sınıfa ÖZGÜ dersler (ortak teori hariç) — "Sınıfına özel" bölümü.
  List<Lesson> licenceLessons(LicenceCategory licence) => lessons.specificFor(licence);

  /// Bu sınıfta görünen ders sayısı (hub sayacı).
  int lessonCountFor(LicenceCategory licence) => lessons.forLicence(licence).length;

  /// Bu sınıf için öne çıkan işaretler — yalnız anlık görüntüde GERÇEKTEN bulunan işaretler döner
  /// (ölü bağ üretmez). Ağırlıklandırmadır: galeri kısılmaz.
  List<({TrafficSign sign, String why})> focusSignsFor(LicenceCategory licence) {
    final out = <({TrafficSign sign, String why})>[];
    for (final f in signFocusFor(licence)) {
      final s = signById(f.signId);
      if (s != null) out.add((sign: s, why: f.why));
    }
    return out;
  }

  /// İşaretler → kategoriye göre.
  Map<SignCategory, List<TrafficSign>> signsByCategory() {
    final map = <SignCategory, List<TrafficSign>>{};
    for (final s in signs) {
      (map[s.category] ??= []).add(s);
    }
    return map;
  }

  /// Araç parçaları → sisteme göre. `licence` verilirse o sınıfta geçerli olanlar kalır ve
  /// sınıfa ÖZGÜ parçalar öne alınır (Evolution Faz E4).
  Map<VehicleSystem, List<VehiclePart>> partsBySystem({LicenceCategory? licence}) {
    final source = licence == null ? vehicleParts : vehicleParts.prioritizedFor(licence);
    final map = <VehicleSystem, List<VehiclePart>>{};
    for (final p in source) {
      (map[p.system] ??= []).add(p);
    }
    return map;
  }

  /// Bu sınıfta görünen parça sayısı (hub sayacı).
  int partCountFor(LicenceCategory licence) => vehicleParts.forLicence(licence).length;
}
