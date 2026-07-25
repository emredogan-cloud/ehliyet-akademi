import '../../core/assets.dart';

/// Evolution Faz E8 — topluluk modelleri (saf, ağdan bağımsız).
///
/// GİZLİLİK: burada e-posta, gerçek ad veya konum ALANI YOKTUR. Sunucu da döndürmez; model bunu
/// yapısal olarak imkânsız kılar.

/// Avatar, kullanıcı fotoğrafı DEĞİL — uygulamayla gelen sabit maskot varlıklarından biridir.
/// (Fotoğraf yükleme yokluğu, bütün bir moderasyon/PII sınıfını baştan ortadan kaldırır.)
enum CommunityAvatar {
  owlWave('owl-wave', 'Selam veren', AppImages.owlWave),
  owlReading('owl-reading', 'Okuyan', AppImages.owlReading),
  owlTeacher('owl-teacher', 'Öğretmen', AppImages.owlTeacher),
  owlWheel('owl-wheel', 'Direksiyon', AppImages.owlWheel),
  owlClipboard('owl-clipboard', 'Not tutan', AppImages.owlClipboard),
  owlShield('owl-shield', 'Koruyan', AppImages.owlShield);

  const CommunityAvatar(this.id, this.label, this.asset);
  final String id;
  final String label;
  final String asset;

  static CommunityAvatar fromId(String? id) =>
      CommunityAvatar.values.firstWhere((a) => a.id == id, orElse: () => CommunityAvatar.owlWave);
}

/// Şikâyet sebepleri — sunucudaki kümeyle birebir aynı.
enum ReportReason {
  isim('isim', 'Uygunsuz görünen ad'),
  avatar('avatar', 'Uygunsuz avatar'),
  taciz('taciz', 'Taciz veya hakaret'),
  spam('spam', 'Spam'),
  diger('diger', 'Diğer');

  const ReportReason(this.wire, this.label);
  final String wire;
  final String label;
}

/// Kendi topluluk profilim. `visibility` OPT-IN'dir: varsayılan gizlidir.
class CommunityProfile {
  const CommunityProfile({
    required this.displayName,
    required this.avatarId,
    required this.licence,
    required this.visibility,
  });

  final String displayName;
  final String avatarId;
  final String licence;
  final String visibility; // private | public

  bool get isPublic => visibility == 'public';
  CommunityAvatar get avatar => CommunityAvatar.fromId(avatarId);

  factory CommunityProfile.fromJson(Map<String, dynamic> json) => CommunityProfile(
    displayName: (json['displayName'] ?? '').toString(),
    avatarId: (json['avatarId'] ?? 'owl-wave').toString(),
    licence: (json['licence'] ?? 'b').toString(),
    visibility: (json['visibility'] ?? 'private').toString(),
  );
}

/// Sunucunun sahip olduğu istatistikler (istemci bildirir, sunucu sınırlar).
class CommunityStats {
  const CommunityStats({
    required this.xp,
    required this.streak,
    required this.lessons,
    required this.exams,
    required this.answered,
    required this.accuracy,
  });

  final int xp;
  final int streak;
  final int lessons;
  final int exams;
  final int answered;
  final int accuracy;

  static const empty = CommunityStats(
    xp: 0,
    streak: 0,
    lessons: 0,
    exams: 0,
    answered: 0,
    accuracy: 0,
  );

  factory CommunityStats.fromJson(Map<String, dynamic> json) => CommunityStats(
    xp: _int(json['xp']),
    streak: _int(json['streak']),
    lessons: _int(json['lessons']),
    exams: _int(json['exams']),
    answered: _int(json['answered']),
    accuracy: _int(json['accuracy']),
  );
}

/// Sıralama satırı — yalnız görünen ad + avatar + sayısal göstergeler.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.avatarId,
    required this.licence,
    required this.xp,
    required this.streak,
    required this.rank,
  });

  final String userId;
  final String displayName;
  final String avatarId;
  final String licence;
  final int xp;
  final int streak;
  final int rank;

  CommunityAvatar get avatar => CommunityAvatar.fromId(avatarId);

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
    userId: (json['userId'] ?? '').toString(),
    displayName: (json['displayName'] ?? '').toString(),
    avatarId: (json['avatarId'] ?? 'owl-wave').toString(),
    licence: (json['licence'] ?? 'b').toString(),
    xp: _int(json['xp']),
    streak: _int(json['streak']),
    rank: _int(json['rank']),
  );
}

/// Sıralama sayfası + kullanıcının kendi sırası (sayfada olmasa bile).
class LeaderboardPage {
  const LeaderboardPage({
    required this.weekStart,
    required this.licence,
    required this.total,
    required this.rows,
    required this.me,
  });

  final String weekStart;
  final String licence;
  final int total;
  final List<LeaderboardEntry> rows;
  final LeaderboardEntry? me;

  static const empty = LeaderboardPage(
    weekStart: '',
    licence: 'all',
    total: 0,
    rows: [],
    me: null,
  );

  factory LeaderboardPage.fromJson(Map<String, dynamic> json) => LeaderboardPage(
    weekStart: (json['weekStart'] ?? '').toString(),
    licence: (json['licence'] ?? 'all').toString(),
    total: _int(json['total']),
    rows: ((json['rows'] as List?) ?? const [])
        .map((e) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    me: json['me'] == null
        ? null
        : LeaderboardEntry.fromJson(Map<String, dynamic>.from(json['me'] as Map)),
  );
}

/// Başka bir kullanıcının profili (rozetleriyle).
class CommunityUser {
  const CommunityUser({
    required this.userId,
    required this.displayName,
    required this.avatarId,
    required this.licence,
    required this.stats,
    required this.achievements,
    required this.isSelf,
  });

  final String userId;
  final String displayName;
  final String avatarId;
  final String licence;
  final CommunityStats stats;
  final List<String> achievements;
  final bool isSelf;

  CommunityAvatar get avatar => CommunityAvatar.fromId(avatarId);

  factory CommunityUser.fromJson(Map<String, dynamic> json) {
    final p = Map<String, dynamic>.from((json['profile'] ?? const {}) as Map);
    return CommunityUser(
      userId: (p['userId'] ?? '').toString(),
      displayName: (p['displayName'] ?? '').toString(),
      avatarId: (p['avatarId'] ?? 'owl-wave').toString(),
      licence: (p['licence'] ?? 'b').toString(),
      stats: json['stats'] == null
          ? CommunityStats.empty
          : CommunityStats.fromJson(Map<String, dynamic>.from(json['stats'] as Map)),
      achievements: ((json['achievements'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      isSelf: json['isSelf'] == true,
    );
  }
}

/// Engellenen kullanıcı satırı (Faz E9 — engel kaldırma yüzeyi).
class BlockedUser {
  const BlockedUser({required this.userId, required this.displayName, required this.avatarId});
  final String userId;
  final String displayName;
  final String avatarId;

  factory BlockedUser.fromJson(Map<String, dynamic> j) => BlockedUser(
    userId: (j['userId'] ?? '').toString(),
    displayName: (j['displayName'] ?? '').toString(),
    avatarId: (j['avatarId'] ?? 'owl-wave').toString(),
  );
}

/// Görünen ad kuralları — sunucudaki doğrulamanın aynısı, kullanıcıya ANINDA geri bildirim için.
/// (Sunucu yine de son sözü söyler; bu yalnız iyi bir kullanıcı deneyimi katmanıdır.)
const int kDisplayNameMin = 3;
const int kDisplayNameMax = 20;

String? validateDisplayName(String raw) {
  final value = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (value.length < kDisplayNameMin) return 'En az $kDisplayNameMin karakter olmalı.';
  if (value.length > kDisplayNameMax) return 'En fazla $kDisplayNameMax karakter olabilir.';
  if (value.contains('@')) return 'Görünen ad e-posta olamaz.';
  if (!RegExp(r'^[\p{L}\p{N} _-]+$', unicode: true).hasMatch(value)) {
    return 'Yalnız harf, rakam, boşluk, _ ve - kullanılabilir.';
  }
  return null;
}

int _int(Object? v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
