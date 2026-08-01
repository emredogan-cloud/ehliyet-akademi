import 'package:freezed_annotation/freezed_annotation.dart';

import '../content/content_enums.dart';

part 'question.freezed.dart';
part 'question.g.dart';

/// Soru zorluğu (web `Difficulty`).
@JsonEnum()
enum Difficulty {
  @JsonValue('kolay')
  kolay,
  @JsonValue('orta')
  orta,
  @JsonValue('zor')
  zor;

  String get label => switch (this) {
    Difficulty.kolay => 'Kolay',
    Difficulty.orta => 'Orta',
    Difficulty.zor => 'Zor',
  };
}

/// QIP v3 · Faz 1 — soru TÜRÜ (web `QuestionKind` karşılığı).
///
/// Görsel taşıyıp taşımadığı `media`'dan da anlaşılırdı; tür bundan fazlasını söyler: bir levha
/// sorusu kare ve küçük çizilir, bir kavşak sorusu geniş ve şematik. Arayüz, üreteç ve kalite
/// motoru üçü de bu ayrımı kullanıyor.
@JsonEnum()
enum QuestionKind {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('scenario')
  scenario,
  @JsonValue('diagram')
  diagram,
  @JsonValue('intersection')
  intersection,
  @JsonValue('sign')
  sign,
  @JsonValue('mechanic')
  mechanic,
  @JsonValue('dashboard')
  dashboard;

  /// Bu tür görsel gerektirir mi?
  bool get needsMedia => this != QuestionKind.text && this != QuestionKind.scenario;
}

/// Görsel üstünde ilgi alanı. **Bugün çizilmiyor** — şemayla aynı hizada durması için var
/// (ileride "araca dokun" tipi sorular geldiğinde yük biçimi değişmesin).
@freezed
abstract class ImageHotspot with _$ImageHotspot {
  const factory ImageHotspot({
    required String id,
    required double x,
    required double y,
    required double w,
    required double h,
    required String label,
  }) = _ImageHotspot;
  factory ImageHotspot.fromJson(Map<String, Object?> json) => _$ImageHotspotFromJson(json);
}

/// Soruya bağlı tek görsel.
@freezed
abstract class QuestionImage with _$QuestionImage {
  const factory QuestionImage({
    /// Varlık kimliği — paketteki yola `AssetCatalog` sözleşmesiyle çözülür.
    required String assetId,

    /// ZORUNLU. Görsel çizilemezse soru bu metinle yine cevaplanabilir olmalı; ekran okuyucu
    /// kullanan biri için de tek kaynak budur.
    required String alt,
    String? caption,
    @Default([]) List<ImageHotspot> hotspots,
  }) = _QuestionImage;
  factory QuestionImage.fromJson(Map<String, Object?> json) => _$QuestionImageFromJson(json);
}

/// Görsel yerleşimi — tek, ızgara ya da karşılaştırma.
@JsonEnum()
enum MediaLayout {
  @JsonValue('single')
  single,
  @JsonValue('grid')
  grid,
  @JsonValue('compare')
  compare,
}

/// Sorunun görsel yükü. Çoklu görsel baştan destekli.
@freezed
abstract class QuestionMedia with _$QuestionMedia {
  const factory QuestionMedia({
    required List<QuestionImage> images,
    @Default(MediaLayout.single) MediaLayout layout,
  }) = _QuestionMedia;
  factory QuestionMedia.fromJson(Map<String, Object?> json) => _$QuestionMediaFromJson(json);
}

/// e-Sınav sorusu (web `Question` yalın projeksiyonu — `/api/mobile/question-bank`).
@freezed
abstract class Question with _$Question {
  const factory Question({
    required String id,
    required Subject subject,
    required String topic,
    @Default(Difficulty.orta) Difficulty difficulty,
    required String stem,
    required List<String> options,
    required int answerIndex,
    required String explanation,
    Badge? badge,
    @Default([]) List<String> whyWrong,

    /// QIP v3 · Faz 1 — tür + görsel. İkisi de VARSAYILANLI/OPSİYONEL: sunucudan gelen eski
    /// yükte bu alanlar yoktur ve soru aynen çalışmaya devam eder.
    @Default(QuestionKind.text) QuestionKind kind,
    QuestionMedia? media,

    /// Öğrenme kazanımı — görsel sorularda zorunlu değil ama üreteç her zaman dolduruyor.
    String? objective,
  }) = _Question;
  factory Question.fromJson(Map<String, Object?> json) => _$QuestionFromJson(json);
}

/// Faz 11 — her soru TAM DÖRT seçenek taşır: A, B, C, D.
///
/// Gerçek e-Sınav dört şıklıdır. Uygulama bir dönem şık harfini `options.length`'ten türetiyordu
/// ve bankaya sızmış üç şıklı sorularda kullanıcı A-B-C görüyordu. Kural artık üç yerde birden
/// duruyor: şemada (`z.array(...).length(4)`), veri kümesinde ve burada.
const int kOptionCount = 4;

/// Bu soru A/B/C/D biçimine uyuyor mu?
///
/// Sunucudan gelen banka istemcinin kontrolü DIŞINDADIR: eski bir dağıtım ya da elle düzenlenmiş
/// bir kayıt yine üç şıklı gelebilir. Uygulamanın buna karşı bir tutumu olmalı — sessizce yanlış
/// harflendirmektense o soruyu hiç göstermemek dürüsttür.
bool isWellFormedQuestion(Question q) =>
    q.options.length == kOptionCount && q.answerIndex >= 0 && q.answerIndex < kOptionCount;
