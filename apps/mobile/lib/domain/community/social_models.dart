import 'community_models.dart';

/// Evolution Faz E9 — sosyal grafik modelleri (saf, ağdan bağımsız).
///
/// GİZLİLİK (E8'den devam): e-posta/gerçek ad ALANI YOKTUR. Sunucu da göndermez.
///
/// SORU PAYLAŞIMI: `questionRef` yalnız bankadaki soru KİMLİĞİDİR. Soru metni sunucudan GELMEZ;
/// istemci kimliği kendi yerel (çevrimdışı) bankasından çözer. Bu, "referansla paylaşım" kuralının
/// istemci tarafındaki karşılığıdır — banka bir tartışma akışına kopyalanamaz.

/// Bakan kişiye göre arkadaşlık durumu (sunucudaki `FriendState` ile birebir).
enum FriendState {
  none('none'),
  outgoing('outgoing'),
  incoming('incoming'),
  friends('friends');

  const FriendState(this.wire);
  final String wire;

  static FriendState fromWire(String? w) =>
      FriendState.values.firstWhere((e) => e.wire == w, orElse: () => FriendState.none);
}

/// Arkadaş / istek satırı.
class FriendEntry {
  const FriendEntry({
    required this.userId,
    required this.displayName,
    required this.avatarId,
    required this.licence,
    required this.state,
  });

  final String userId;
  final String displayName;
  final String avatarId;
  final String licence;
  final FriendState state;

  CommunityAvatar get avatar => CommunityAvatar.fromId(avatarId);

  factory FriendEntry.fromJson(Map<String, dynamic> j) => FriendEntry(
    userId: (j['userId'] ?? '').toString(),
    displayName: (j['displayName'] ?? '').toString(),
    avatarId: (j['avatarId'] ?? 'owl-wave').toString(),
    licence: (j['licence'] ?? 'b').toString(),
    state: FriendState.fromWire(j['state']?.toString()),
  );
}

/// Arkadaş listesi + bekleyen istekler.
class FriendsPage {
  const FriendsPage({required this.friends, required this.incoming, required this.outgoing});

  final List<FriendEntry> friends;
  final List<FriendEntry> incoming;
  final List<FriendEntry> outgoing;

  static const empty = FriendsPage(friends: [], incoming: [], outgoing: []);

  bool get isEmpty => friends.isEmpty && incoming.isEmpty && outgoing.isEmpty;

  static List<FriendEntry> _list(Object? v) => ((v as List?) ?? const [])
      .map((e) => FriendEntry.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();

  factory FriendsPage.fromJson(Map<String, dynamic> j) => FriendsPage(
    friends: _list(j['friends']),
    incoming: _list(j['incoming']),
    outgoing: _list(j['outgoing']),
  );
}

/// Konuşma listesi satırı (son mesajla birlikte).
class MessageThread {
  const MessageThread({
    required this.userId,
    required this.displayName,
    required this.avatarId,
    required this.lastMessage,
    required this.lastAt,
    required this.unread,
  });

  final String userId;
  final String displayName;
  final String avatarId;
  final String lastMessage;
  final DateTime? lastAt;
  final bool unread;

  CommunityAvatar get avatar => CommunityAvatar.fromId(avatarId);

  factory MessageThread.fromJson(Map<String, dynamic> j) => MessageThread(
    userId: (j['userId'] ?? '').toString(),
    displayName: (j['displayName'] ?? '').toString(),
    avatarId: (j['avatarId'] ?? 'owl-wave').toString(),
    lastMessage: (j['lastMessage'] ?? '').toString(),
    lastAt: DateTime.tryParse('${j['lastAt'] ?? ''}'),
    unread: j['unread'] == true,
  );
}

/// Tek mesaj.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.createdAt,
    required this.mine,
  });

  final String id;
  final String senderId;
  final String body;
  final DateTime? createdAt;
  final bool mine;

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: (j['id'] ?? '').toString(),
    senderId: (j['senderId'] ?? '').toString(),
    body: (j['body'] ?? '').toString(),
    createdAt: DateTime.tryParse('${j['createdAt'] ?? ''}'),
    mine: j['mine'] == true,
  );
}

/// Tartışma başlığı özeti.
class DiscussionSummary {
  const DiscussionSummary({
    required this.id,
    required this.title,
    required this.licence,
    required this.questionRef,
    required this.postCount,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarId,
  });

  final String id;
  final String title;
  final String licence;

  /// Bankadaki soru kimliği (metin DEĞİL) — istemci yerelden çözer.
  final String? questionRef;
  final int postCount;
  final String authorId;
  final String authorName;
  final String authorAvatarId;

  CommunityAvatar get authorAvatar => CommunityAvatar.fromId(authorAvatarId);

  factory DiscussionSummary.fromJson(Map<String, dynamic> j) {
    final a = Map<String, dynamic>.from((j['author'] ?? const {}) as Map);
    return DiscussionSummary(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      licence: (j['licence'] ?? 'b').toString(),
      questionRef: j['questionRef']?.toString(),
      postCount: j['postCount'] is int ? j['postCount'] as int : 0,
      authorId: (a['userId'] ?? '').toString(),
      authorName: (a['displayName'] ?? '').toString(),
      authorAvatarId: (a['avatarId'] ?? 'owl-wave').toString(),
    );
  }
}

/// Tartışma iletisi.
class DiscussionPost {
  const DiscussionPost({
    required this.id,
    required this.body,
    required this.questionRef,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarId,
    required this.mine,
    required this.createdAt,
  });

  final String id;
  final String body;
  final String? questionRef;
  final String authorId;
  final String authorName;
  final String authorAvatarId;
  final bool mine;
  final DateTime? createdAt;

  CommunityAvatar get authorAvatar => CommunityAvatar.fromId(authorAvatarId);

  factory DiscussionPost.fromJson(Map<String, dynamic> j) {
    final a = Map<String, dynamic>.from((j['author'] ?? const {}) as Map);
    return DiscussionPost(
      id: (j['id'] ?? '').toString(),
      body: (j['body'] ?? '').toString(),
      questionRef: j['questionRef']?.toString(),
      authorId: (a['userId'] ?? '').toString(),
      authorName: (a['displayName'] ?? '').toString(),
      authorAvatarId: (a['avatarId'] ?? 'owl-wave').toString(),
      mine: j['mine'] == true,
      createdAt: DateTime.tryParse('${j['createdAt'] ?? ''}'),
    );
  }
}

/// Bir başlık + iletileri.
class DiscussionDetail {
  const DiscussionDetail({required this.thread, required this.posts});
  final DiscussionSummary thread;
  final List<DiscussionPost> posts;

  factory DiscussionDetail.fromJson(Map<String, dynamic> j) => DiscussionDetail(
    thread: DiscussionSummary.fromJson(Map<String, dynamic>.from(j['thread'] as Map)),
    posts: ((j['posts'] as List?) ?? const [])
        .map((e) => DiscussionPost.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// İstemci tarafı doğrulama — sunucudaki kurallarla birebir (anında geri bildirim).
// Sunucu yine son sözü söyler; bu yalnız kullanıcı deneyimi katmanıdır.
// ─────────────────────────────────────────────────────────────────────────────

const int kMessageMaxLength = 500;
const int kPostMaxLength = 1000;
const int kThreadTitleMin = 5;
const int kThreadTitleMax = 100;

String? validateMessageBody(String raw) {
  final v = raw.trim();
  if (v.isEmpty) return 'Mesaj boş olamaz.';
  if (v.length > kMessageMaxLength) return 'En fazla $kMessageMaxLength karakter.';
  return null;
}

String? validatePostBody(String raw) {
  final v = raw.trim();
  if (v.isEmpty) return 'İleti boş olamaz.';
  if (v.length > kPostMaxLength) return 'En fazla $kPostMaxLength karakter.';
  return null;
}

String? validateThreadTitle(String raw) {
  final v = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (v.length < kThreadTitleMin) return 'En az $kThreadTitleMin karakter olmalı.';
  if (v.length > kThreadTitleMax) return 'En fazla $kThreadTitleMax karakter olabilir.';
  return null;
}
