import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kişiselleştirme (onboarding) profili — kullanıcının hedeflerini yakalar ve çalışma planı,
/// adaptif öğrenme, AI Koç bağlamı, bildirimler ve panel önerilerini başlatır. Saf + kalıcı
/// (SharedPreferences `ea:studyProfile:v1`).

/// Ehliyet sınıfı.
enum LicenceCategory {
  b('b', 'B', 'Otomobil', 'Manuel ve otomatik binek araçlar'),
  a('a', 'A', 'Motosiklet', 'Her sınıf motosikletler'),
  d('d', 'D', 'Otobüs', 'Yolcu taşımacılığı otobüsler');

  const LicenceCategory(this.wire, this.badge, this.title, this.blurb);
  final String wire;
  final String badge;
  final String title;
  final String blurb;

  static LicenceCategory fromWire(String? w) =>
      LicenceCategory.values.firstWhere((e) => e.wire == w, orElse: () => LicenceCategory.b);
}

/// Sınava daha önce girdi mi?
enum ExamExperience {
  firstTime('first', 'İlk Kez', 'Bu sınava ilk defa hazırlanıyorum.'),
  retaking('retake', 'Tekrar Giriyorum', 'Daha önce girdim, tekrar hazırlanıyorum.');

  const ExamExperience(this.wire, this.title, this.blurb);
  final String wire;
  final String title;
  final String blurb;

  static ExamExperience fromWire(String? w) =>
      ExamExperience.values.firstWhere((e) => e.wire == w, orElse: () => ExamExperience.firstTime);
}

/// Hangi sınava hazırlanıyor?
enum ExamFocus {
  direksiyon('direksiyon', 'Direksiyon Sınavı'),
  eSinav('e-sinav', 'e-Sınav (Trafik)'),
  both('both', 'e-Sınav + Direksiyon');

  const ExamFocus(this.wire, this.title);
  final String wire;
  final String title;

  static ExamFocus fromWire(String? w) =>
      ExamFocus.values.firstWhere((e) => e.wire == w, orElse: () => ExamFocus.both);
}

/// Sınava kalan süre → çalışma planı yoğunluğu.
enum ExamTimeframe {
  lessThanWeek('lt-week', '1 Haftadan Az', 'Sınavın çok yakın, hızlı bir planla ilerleyelim.', 30, 'Yoğun tempo'),
  weekToMonth('week-month', '1 Hafta – 1 Ay', 'Düzenli çalışmayla yetiştirebilirsin.', 20, 'Düzenli tempo'),
  moreThanMonth('gt-month', '1 Aydan Fazla', 'Uzun vadeli, sağlam bir plan yapalım.', 12, 'Rahat tempo'),
  notSure('unsure', 'Emin Değilim', 'Henüz net değil, planı sonra belirlerim.', 10, 'Dengeli tempo');

  const ExamTimeframe(this.wire, this.title, this.blurb, this.dailyGoal, this.paceLabel);
  final String wire;
  final String title;
  final String blurb;

  /// Günlük hedef soru sayısı (çalışma planı).
  final int dailyGoal;
  final String paceLabel;

  static ExamTimeframe fromWire(String? w) =>
      ExamTimeframe.values.firstWhere((e) => e.wire == w, orElse: () => ExamTimeframe.notSure);
}

/// Kişiselleştirme profili (değişmez).
class StudyProfile {
  const StudyProfile({
    required this.category,
    required this.experience,
    required this.focus,
    required this.timeframe,
    required this.completed,
    this.completedAtMs,
  });

  final LicenceCategory category;
  final ExamExperience experience;
  final ExamFocus focus;
  final ExamTimeframe timeframe;

  /// Onboarding kişiselleştirmesi tamamlandı mı (atlanmadı mı).
  final bool completed;
  final int? completedAtMs;

  /// Kişiselleştirilmemiş varsayılan (atlandı / henüz yapılmadı).
  static const empty = StudyProfile(
    category: LicenceCategory.b,
    experience: ExamExperience.firstTime,
    focus: ExamFocus.both,
    timeframe: ExamTimeframe.notSure,
    completed: false,
  );

  /// Günlük hedef soru sayısı — çalışma planının çekirdeği.
  int get dailyGoal => timeframe.dailyGoal;
  String get paceLabel => timeframe.paceLabel;

  /// Bir akıllı-çalışma oturumunun boyu (panelde ve SRS koşucusunda gösterilir; 10..25 sınırlı).
  int get sessionSize => dailyGoal.clamp(10, 25);

  /// Direksiyon içeriği vurgulanmalı mı?
  bool get includesDireksiyon => focus == ExamFocus.direksiyon || focus == ExamFocus.both;

  /// e-Sınav (teori/trafik) içeriği vurgulanmalı mı?
  bool get includesTheory => focus == ExamFocus.eSinav || focus == ExamFocus.both;

  StudyProfile copyWith({
    LicenceCategory? category,
    ExamExperience? experience,
    ExamFocus? focus,
    ExamTimeframe? timeframe,
    bool? completed,
    int? completedAtMs,
  }) => StudyProfile(
    category: category ?? this.category,
    experience: experience ?? this.experience,
    focus: focus ?? this.focus,
    timeframe: timeframe ?? this.timeframe,
    completed: completed ?? this.completed,
    completedAtMs: completedAtMs ?? this.completedAtMs,
  );

  Map<String, dynamic> toJson() => {
    'cat': category.wire,
    'exp': experience.wire,
    'focus': focus.wire,
    'time': timeframe.wire,
    'completed': completed,
    if (completedAtMs != null) 'at': completedAtMs,
    'v': 1,
  };

  static StudyProfile fromJson(Map<String, dynamic> j) => StudyProfile(
    category: LicenceCategory.fromWire(j['cat'] as String?),
    experience: ExamExperience.fromWire(j['exp'] as String?),
    focus: ExamFocus.fromWire(j['focus'] as String?),
    timeframe: ExamTimeframe.fromWire(j['time'] as String?),
    completed: j['completed'] as bool? ?? true,
    completedAtMs: j['at'] as int?,
  );
}

const _kProfile = 'ea:studyProfile:v1';

/// Profil kalıcılığı + durumu. Başlangıç değeri main()'de senkron okunur (panelde flaş yok).
class StudyProfileController extends Notifier<StudyProfile> {
  StudyProfileController(this._initial);
  final StudyProfile _initial;

  @override
  StudyProfile build() => _initial;

  Future<void> save(StudyProfile profile) async {
    state = profile;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProfile, jsonEncode(profile.toJson()));
    } catch (_) {}
  }
}

/// main() override eder; testlerde de override edilebilir.
final studyProfileProvider = NotifierProvider<StudyProfileController, StudyProfile>(
  () => StudyProfileController(StudyProfile.empty),
);

/// main()'de bir kez senkron okunur.
Future<StudyProfile> readStudyProfile() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kProfile);
    if (raw == null || raw.isEmpty) return StudyProfile.empty;
    return StudyProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return StudyProfile.empty;
  }
}
