import 'content_enums.dart';
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

  /// Dersler → konuya göre (kaynak sırası korunur).
  Map<Subject, List<Lesson>> lessonsBySubject() {
    final map = <Subject, List<Lesson>>{};
    for (final l in lessons) {
      (map[l.subject] ??= []).add(l);
    }
    return map;
  }

  /// İşaretler → kategoriye göre.
  Map<SignCategory, List<TrafficSign>> signsByCategory() {
    final map = <SignCategory, List<TrafficSign>>{};
    for (final s in signs) {
      (map[s.category] ??= []).add(s);
    }
    return map;
  }

  /// Araç parçaları → sisteme göre.
  Map<VehicleSystem, List<VehiclePart>> partsBySystem() {
    final map = <VehicleSystem, List<VehiclePart>>{};
    for (final p in vehicleParts) {
      (map[p.system] ??= []).add(p);
    }
    return map;
  }
}
