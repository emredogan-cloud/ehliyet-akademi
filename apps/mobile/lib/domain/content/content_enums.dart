import 'package:json_annotation/json_annotation.dart';

/// Ders konusu (MEB dağılımı) — web `Subject` ile birebir.
@JsonEnum()
enum Subject {
  @JsonValue('trafik')
  trafik,
  @JsonValue('ilkyardim')
  ilkyardim,
  @JsonValue('motor')
  motor,
  @JsonValue('adab')
  adab,
  @JsonValue('pratik')
  pratik;

  /// Türkçe etiket (web `SUBJECT_LABEL`).
  String get label => switch (this) {
    Subject.trafik => 'Trafik ve Çevre Bilgisi',
    Subject.ilkyardim => 'İlk Yardım Bilgisi',
    Subject.motor => 'Araç Tekniği',
    Subject.adab => 'Trafik Adabı',
    Subject.pratik => 'Direksiyon (Uygulama)',
  };
}

/// Bilgi sınıflandırma rozeti (web `Badge`).
@JsonEnum()
enum Badge {
  @JsonValue('official')
  official,
  @JsonValue('examiner')
  examiner,
  @JsonValue('instructor')
  instructor,
  @JsonValue('best')
  best,
  @JsonValue('safety')
  safety;

  /// Türkçe etiket (web `BADGE_LABEL`).
  String get label => switch (this) {
    Badge.official => 'Resmî Kural',
    Badge.examiner => 'Sınav Uygulaması',
    Badge.instructor => 'Eğitmen Tavsiyesi',
    Badge.best => 'En İyi Uygulama',
    Badge.safety => 'Güvenlik İpucu',
  };
}

/// Trafik işareti kategorisi (web `SignCategory`).
@JsonEnum()
enum SignCategory {
  @JsonValue('tehlike')
  tehlike,
  @JsonValue('yasak')
  yasak,
  @JsonValue('mecburiyet')
  mecburiyet,
  @JsonValue('bilgi')
  bilgi,
  @JsonValue('park')
  park,
  @JsonValue('otoyol')
  otoyol,
  @JsonValue('gecici')
  gecici,
  @JsonValue('oncelik')
  oncelik;

  /// Türkçe etiket (web `CATEGORY_LABEL`).
  String get label => switch (this) {
    SignCategory.tehlike => 'Tehlike Uyarı',
    SignCategory.yasak => 'Yasaklayıcı / Kısıtlayıcı',
    SignCategory.mecburiyet => 'Mecburiyet',
    SignCategory.bilgi => 'Bilgi',
    SignCategory.park => 'Duraklama & Park',
    SignCategory.otoyol => 'Otoyol & Yönlendirme',
    SignCategory.gecici => 'Geçici / Çalışma',
    SignCategory.oncelik => 'Öncelik (DUR / Yol Ver)',
  };
}

/// Trafik işareti şekli (kabuk) — web `SignShape`.
@JsonEnum()
enum SignShape {
  @JsonValue('triangle')
  triangle,
  @JsonValue('inv-triangle')
  invTriangle,
  @JsonValue('ring')
  ring,
  @JsonValue('disc')
  disc,
  @JsonValue('rect-blue')
  rectBlue,
  @JsonValue('rect-green')
  rectGreen,
  @JsonValue('octagon')
  octagon,
  @JsonValue('diamond')
  diamond,
}

/// Sınav önemi (web `ExamImportance`).
@JsonEnum()
enum ExamImportance {
  @JsonValue('çok yüksek')
  cokYuksek,
  @JsonValue('yüksek')
  yuksek,
  @JsonValue('orta')
  orta;

  /// Türkçe etiket (kaynaktaki değerle aynı, ilk harf büyük).
  String get label => switch (this) {
    ExamImportance.cokYuksek => 'Çok yüksek',
    ExamImportance.yuksek => 'Yüksek',
    ExamImportance.orta => 'Orta',
  };
}

/// Araç sistemi (web `VehicleSystem`).
@JsonEnum()
enum VehicleSystem {
  @JsonValue('motor-bolmesi')
  motorBolmesi,
  @JsonValue('kabin')
  kabin,
  @JsonValue('dis')
  dis,
  @JsonValue('muayene')
  muayene;

  /// Türkçe etiket (web `SYSTEM_LABEL`).
  String get label => switch (this) {
    VehicleSystem.motorBolmesi => 'Motor Bölmesi',
    VehicleSystem.kabin => 'Kabin & Kumandalar',
    VehicleSystem.dis => 'Dış & Lastikler',
    VehicleSystem.muayene => 'Muayene & Park',
  };
}

/// Vurgu kutusu tonu (web `Callout.tone`).
@JsonEnum()
enum CalloutTone {
  @JsonValue('info')
  info,
  @JsonValue('success')
  success,
  @JsonValue('warning')
  warning,
  @JsonValue('danger')
  danger,
}
