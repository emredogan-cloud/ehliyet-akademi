import 'community_models.dart';

/// Evolution Faz E10 — çalışma grubu ve meydan okuma modelleri (saf, ağdan bağımsız).
///
/// GİZLİLİK (E8'den devam): burada e-posta, gerçek ad veya konum ALANI YOKTUR.

/// Katılım kodu alfabesi — sunucudakiyle BİREBİR aynı. Karışan karakterler (0/O, 1/I/L) yoktur.
const String kJoinCodeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const int kJoinCodeLength = 6;
const int kGroupNameMin = 3;
const int kGroupNameMax = 40;

/// Sunucudaki `normalizeJoinCode` ile aynı kural: büyük harf, boşluk/tire atılır, alfabe dışı
/// karakter REDDEDİLİR (sessizce eşlenmez — yanlış gruba düşmemek için).
String? normalizeJoinCode(String raw) {
  final cleaned = raw.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
  if (cleaned.length != kJoinCodeLength) return null;
  for (final ch in cleaned.split('')) {
    if (!kJoinCodeAlphabet.contains(ch)) return null;
  }
  return cleaned;
}

/// Anında geri bildirim için — sunucu yine son sözü söyler.
String? validateGroupName(String raw) {
  final value = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (value.length < kGroupNameMin) return 'Grup adı en az $kGroupNameMin karakter olmalı.';
  if (value.length > kGroupNameMax) return 'Grup adı en fazla $kGroupNameMax karakter olabilir.';
  if (!RegExp(r'^[\p{L}\p{N} _-]+$', unicode: true).hasMatch(value)) {
    return 'Yalnız harf, rakam, boşluk, _ ve - kullanılabilir.';
  }
  return null;
}

/// Üyesi olduğum bir grup (liste satırı).
class StudyGroup {
  const StudyGroup({
    required this.id,
    required this.name,
    required this.licence,
    required this.joinCode,
    required this.isOwner,
    required this.memberCount,
    required this.totalXp,
    required this.totalAnswered,
  });

  final String id;
  final String name;
  final String licence;

  /// Yalnız ÜYEYE döner — davet etmek için gerekli.
  final String joinCode;
  final bool isOwner;
  final int memberCount;
  final int totalXp;
  final int totalAnswered;

  factory StudyGroup.fromJson(Map<String, dynamic> j) => StudyGroup(
    id: (j['id'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    licence: (j['licence'] ?? 'b').toString(),
    joinCode: (j['joinCode'] ?? '').toString(),
    isOwner: j['isOwner'] == true,
    memberCount: _int(j['memberCount']),
    totalXp: _int(j['totalXp']),
    totalAnswered: _int(j['totalAnswered']),
  );
}

/// Grup üyesi satırı.
class GroupMember {
  const GroupMember({
    required this.userId,
    required this.displayName,
    required this.avatarId,
    required this.role,
    required this.xp,
    required this.streak,
    required this.rank,
    required this.isSelf,
  });

  final String userId;
  final String displayName;
  final String avatarId;
  final String role; // owner | member
  final int xp;
  final int streak;
  final int rank;
  final bool isSelf;

  bool get isOwner => role == 'owner';
  CommunityAvatar get avatar => CommunityAvatar.fromId(avatarId);

  factory GroupMember.fromJson(Map<String, dynamic> j) => GroupMember(
    userId: (j['userId'] ?? '').toString(),
    displayName: (j['displayName'] ?? '').toString(),
    avatarId: (j['avatarId'] ?? 'owl-wave').toString(),
    role: (j['role'] ?? 'member').toString(),
    xp: _int(j['xp']),
    streak: _int(j['streak']),
    rank: _int(j['rank']),
    isSelf: j['isSelf'] == true,
  );
}

/// Grup ayrıntısı = grup + görünen üyeler.
class GroupDetail {
  const GroupDetail({required this.group, required this.members});
  final StudyGroup group;
  final List<GroupMember> members;

  factory GroupDetail.fromJson(Map<String, dynamic> j) => GroupDetail(
    group: StudyGroup.fromJson(Map<String, dynamic>.from(j['group'] as Map)),
    members: ((j['members'] as List?) ?? const [])
        .map((e) => GroupMember.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

/// Sunucu tanımlı meydan okuma + benim ilerlemem.
///
/// İLERLEME İSTEMCİDEN BİLDİRİLMEZ: sunucu, kırpılmış istatistiklerden türetir. Bu model yalnız
/// sonucu taşır — istemcinin ilerlemeyi "ayarlayabileceği" bir alan yoktur.
class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.metric,
    required this.target,
    required this.joined,
    required this.value,
    required this.percent,
    required this.done,
    required this.endsAt,
  });

  final String id;
  final String title;
  final String description;
  final String metric; // xp | answered | lessons | exams
  final int target;
  final bool joined;
  final int value;
  final int percent;
  final bool done;
  final DateTime? endsAt;

  String get metricLabel => switch (metric) {
    'xp' => 'XP',
    'answered' => 'soru',
    'lessons' => 'ders',
    'exams' => 'deneme',
    _ => '',
  };

  factory Challenge.fromJson(Map<String, dynamic> j) => Challenge(
    id: (j['id'] ?? '').toString(),
    title: (j['title'] ?? '').toString(),
    description: (j['description'] ?? '').toString(),
    metric: (j['metric'] ?? 'xp').toString(),
    target: _int(j['target']),
    joined: j['joined'] == true,
    value: _int(j['value']),
    percent: _int(j['percent']),
    done: j['done'] == true,
    endsAt: DateTime.tryParse((j['endsAt'] ?? '').toString()),
  );
}

int _int(Object? v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
