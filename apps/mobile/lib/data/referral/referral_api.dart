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
String normalizeReferralCode(String raw) {
  final cleaned = raw
      .toUpperCase()
      .replaceAll(RegExp(r'[\s-]'), '')
      // Alfabede 0 ve 1 yok; kullanıcı yanlışlıkla yazdıysa niyeti açıktır.
      .replaceAll('0', 'O')
      .replaceAll('1', 'I');
  return cleaned.length <= kReferralCodeLength
      ? cleaned
      : cleaned.substring(0, kReferralCodeLength);
}

/// Kod biçimsel olarak geçerli mi?
bool isValidReferralCodeFormat(String code) =>
    code.length == kReferralCodeLength && code.split('').every(kReferralAlphabet.contains);

final referralApiProvider = Provider<ReferralApi>((ref) => DioReferralApi(ref.watch(dioProvider)));

/// Davet özeti (ekran bunu izler).
final referralSummaryProvider = FutureProvider<ReferralSummary?>(
  (ref) => ref.watch(referralApiProvider).fetch(),
);
