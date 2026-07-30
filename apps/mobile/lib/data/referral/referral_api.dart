import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';

/// Faz 8 — davet (referral) ucu.
///
/// Kurallar SUNUCUDA yaşar (`apps/web/lib/referrals.ts`); istemci onları tekrar yazmaz, yalnız
/// gösterir. Tek istisna kodun BİÇİM kontrolüdür: kullanıcının yazdığı kodu göndermeden önce
/// elemek, boşuna ağ isteği yapmamak içindir.

/// Ödül basamağı (kaç davette kaç ay).
class ReferralMilestone {
  const ReferralMilestone({required this.count, required this.months});
  final int count;
  final int months;

  static ReferralMilestone fromJson(Map<String, dynamic> j) => ReferralMilestone(
    count: (j['count'] as num?)?.toInt() ?? 0,
    months: (j['months'] as num?)?.toInt() ?? 0,
  );
}

/// Kazanılmış bir ödül.
class ReferralReward {
  const ReferralReward({required this.milestone, required this.months, required this.expiresAt});
  final int milestone;
  final int months;
  final DateTime? expiresAt;

  static ReferralReward fromJson(Map<String, dynamic> j) => ReferralReward(
    milestone: (j['milestone'] as num?)?.toInt() ?? 0,
    months: (j['months'] as num?)?.toInt() ?? 0,
    expiresAt: DateTime.tryParse((j['expiresAt'] ?? '').toString()),
  );
}

/// Kullanıcının davet özeti.
class ReferralSummary {
  const ReferralSummary({
    required this.code,
    required this.link,
    required this.invited,
    required this.qualified,
    required this.pending,
    required this.rewards,
    required this.nextMilestone,
    required this.milestones,
  });

  final String code;
  final String link;

  /// Kaç kişi kodla kayıt oldu.
  final int invited;

  /// Kaç davet NİTELİKLİ (e-postası doğrulanmış) — ödüle sayılan budur.
  final int qualified;
  final int pending;
  final List<ReferralReward> rewards;

  /// Bir sonraki hedef; hepsi alındıysa null.
  final ReferralMilestone? nextMilestone;
  final List<ReferralMilestone> milestones;

  static ReferralSummary fromJson(Map<String, dynamic> j) => ReferralSummary(
    code: (j['code'] ?? '').toString(),
    link: (j['link'] ?? '').toString(),
    invited: (j['invited'] as num?)?.toInt() ?? 0,
    qualified: (j['qualified'] as num?)?.toInt() ?? 0,
    pending: (j['pending'] as num?)?.toInt() ?? 0,
    rewards: [
      for (final r in (j['rewards'] as List?) ?? const [])
        ReferralReward.fromJson((r as Map).cast<String, dynamic>()),
    ],
    nextMilestone: j['nextMilestone'] == null
        ? null
        : ReferralMilestone.fromJson((j['nextMilestone'] as Map).cast<String, dynamic>()),
    milestones: [
      for (final m in (j['milestones'] as List?) ?? const [])
        ReferralMilestone.fromJson((m as Map).cast<String, dynamic>()),
    ],
  );
}

abstract class ReferralApi {
  /// Davet özetini getir. Oturum yoksa `null`.
  Future<ReferralSummary?> fetch();
}

class DioReferralApi implements ReferralApi {
  DioReferralApi(this._dio);
  final Dio _dio;

  @override
  Future<ReferralSummary?> fetch() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/referrals',
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode != 200 || res.data == null) return null;
      return ReferralSummary.fromJson(res.data!);
    } on DioException catch (_) {
      return null;
    }
  }
}

/// Kod alfabesi ve uzunluğu — SUNUCUDAKİ ile aynı olmak ZORUNDA.
///
/// Karıştırılabilir harfler (0/O, 1/I/L) alfabede YOKTUR: kod telefonda okunup elle yazılıyor.
const String kReferralAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const int kReferralCodeLength = 8;

/// Kullanıcının yazdığı kodu kanonik biçime getir (sunucudaki `normalizeReferralCode` ile aynı).
///
/// ## Buradan KALDIRILAN şey ve nedeni (Beta Faz 1)
///
/// Bu fonksiyon eskiden `0`→`O` ve `1`→`I` çevirisi yapıyordu; gerekçesi "alfabede 0/1 yok, kullanıcı
/// yanlışlıkla yazdıysa niyeti açık" idi. **Gerekçe hatalıydı:** alfabede `O`, `I` ve `L` de yok
/// (karıştırılabilir çiftin İKİ üyesi de çıkarılmıştır). Çeviri, geçersiz bir karakteri başka bir
/// geçersiz karaktere dönüştürüyordu; kod yine doğrulamadan geçmiyordu.
///
/// Zararı kullanıcının gözüne çarpıyordu: `AB0DEF1H` → `ABODEFIH` (8 karakter, geçersiz) ve ekran
/// **"Davet kodu 8 karakter olmalı (şu an 8)."** diyordu — kendisiyle çelişen bir hata.
///
/// Kodun içinde ne `0` ne `O` bulunabileceği için, kullanıcı bunlardan birini yazdığında
/// kurtarılabilir bir niyet YOKTUR: kaynağı yanlış okumuştur. Karakter olduğu gibi bırakılır,
/// doğrulama reddeder ve arayüz sorunu ADIYLA söyler ([describeReferralCodeProblem]).
String normalizeReferralCode(String raw) {
  final cleaned = raw.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
  return cleaned.length <= kReferralCodeLength
      ? cleaned
      : cleaned.substring(0, kReferralCodeLength);
}

/// Kod biçimsel olarak geçerli mi?
bool isValidReferralCodeFormat(String code) =>
    code.length == kReferralCodeLength && code.split('').every(kReferralAlphabet.contains);

/// Kodun NEDEN geçersiz olduğunu insan diliyle söyle (geçerliyse ya da boşsa `null`).
///
/// Sunucudaki `describeReferralCodeProblem` ile AYNI kural. İki farklı sorun (alfabe dışı karakter
/// ve yanlış uzunluk) iki farklı cümle gerektirir; alfabe dışı karakter durumunda **hangi
/// karakterin** sorunlu olduğu söylenir, yoksa kullanıcı sekiz karakteri tek tek denemek zorunda
/// kalır.
String? describeReferralCodeProblem(String code) {
  if (code.isEmpty) return null;
  final offenders = <String>{
    for (final ch in code.split(''))
      if (!kReferralAlphabet.contains(ch)) ch,
  };
  if (offenders.isNotEmpty) {
    return 'Davet kodunda ${offenders.join(', ')} karakteri olamaz — kodu tekrar kontrol et.';
  }
  if (code.length != kReferralCodeLength) {
    return 'Davet kodu $kReferralCodeLength karakter olmalı (şu an ${code.length}).';
  }
  return null;
}

final referralApiProvider = Provider<ReferralApi>((ref) => DioReferralApi(ref.watch(dioProvider)));

/// Davet özeti (ekran bunu izler).
final referralSummaryProvider = FutureProvider<ReferralSummary?>(
  (ref) => ref.watch(referralApiProvider).fetch(),
);
