import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../domain/community/community_models.dart';
import '../../domain/community/social_models.dart';
import 'community_repository.dart';

/// Evolution Faz E9 — sosyal grafik API'si (arkadaşlık, mesajlaşma, tartışma).
///
/// E8'deki `CommunityApi` ile aynı desen: arayüz + dio uygulaması ayrı → widget testleri sahte
/// uygulamayla çalışır, ağ/platform kanalı gerekmez.
///
/// ÇEVRİMDIŞI: sosyal veri gerçekten paylaşılan durumdur, çevrimdışı üretilemez. Hatalar
/// yutulmaz; arayüz dürüst bir "bağlanılamadı" durumu gösterir.
abstract class SocialApi {
  Future<FriendsPage> fetchFriends();
  Future<void> sendFriendRequest(String userId);
  Future<void> acceptFriendRequest(String userId);

  /// Reddet / isteği geri al / arkadaşlıktan çıkar — sunucuda hepsi satırı siler.
  Future<void> removeFriend(String userId);

  Future<List<MessageThread>> fetchThreads();
  Future<List<ChatMessage>> fetchConversation(String userId);
  Future<ChatMessage> sendMessage({required String userId, required String body});

  Future<List<DiscussionSummary>> fetchDiscussions({String? licence});
  Future<DiscussionSummary> createDiscussion({
    required String title,
    required String licence,
    String? questionRef,
  });
  Future<DiscussionDetail?> fetchDiscussion(String threadId);
  Future<void> addPost({required String threadId, required String body, String? questionRef});

  /// İçerik (mesaj/ileti) veya kullanıcı şikâyeti.
  Future<void> reportContent({
    required String userId,
    required ReportReason reason,
    String? targetType,
    String? targetRef,
  });
}

class DioSocialApi implements SocialApi {
  DioSocialApi(this._dio);
  final Dio _dio;

  Options get _opts =>
      Options(responseType: ResponseType.json, validateStatus: (s) => s != null && s < 500);

  Never _fail(Response<Map<String, dynamic>> res, String fallback) =>
      throw CommunityException((res.data?['error'] ?? fallback).toString());

  @override
  Future<FriendsPage> fetchFriends() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/community/friends', options: _opts);
    if (res.statusCode != 200) _fail(res, 'Arkadaşlar alınamadı.');
    return FriendsPage.fromJson(res.data!);
  }

  @override
  Future<void> sendFriendRequest(String userId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/community/friends',
      data: {'targetUserId': userId, 'action': 'request'},
      options: _opts,
    );
    if (res.statusCode != 201) _fail(res, 'İstek gönderilemedi.');
  }

  @override
  Future<void> acceptFriendRequest(String userId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/community/friends',
      data: {'targetUserId': userId, 'action': 'accept'},
      options: _opts,
    );
    if (res.statusCode != 200) _fail(res, 'İstek kabul edilemedi.');
  }

  @override
  Future<void> removeFriend(String userId) async {
    await _dio.delete<Map<String, dynamic>>(
      '/api/community/friends',
      queryParameters: {'targetUserId': userId},
      options: _opts,
    );
  }

  @override
  Future<List<MessageThread>> fetchThreads() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/community/messages', options: _opts);
    if (res.statusCode != 200) _fail(res, 'Konuşmalar alınamadı.');
    return ((res.data?['threads'] as List?) ?? const [])
        .map((e) => MessageThread.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<ChatMessage>> fetchConversation(String userId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/community/messages',
      queryParameters: {'with': userId},
      options: _opts,
    );
    // 404 = engellenmiş/erişilemez — ayrım sızdırılmaz, boş konuşma gibi davranılır.
    if (res.statusCode == 404) throw CommunityException('Konuşma açılamadı.');
    if (res.statusCode != 200) _fail(res, 'Mesajlar alınamadı.');
    return ((res.data?['messages'] as List?) ?? const [])
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<ChatMessage> sendMessage({required String userId, required String body}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/community/messages',
      data: {'targetUserId': userId, 'body': body},
      options: _opts,
    );
    if (res.statusCode != 201) _fail(res, 'Mesaj gönderilemedi.');
    return ChatMessage.fromJson({...res.data!, 'mine': true});
  }

  @override
  Future<List<DiscussionSummary>> fetchDiscussions({String? licence}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/community/discussions',
      queryParameters: {'licence': ?licence},
      options: _opts,
    );
    if (res.statusCode != 200) _fail(res, 'Tartışmalar alınamadı.');
    return ((res.data?['threads'] as List?) ?? const [])
        .map((e) => DiscussionSummary.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<DiscussionSummary> createDiscussion({
    required String title,
    required String licence,
    String? questionRef,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/community/discussions',
      data: {'title': title, 'licence': licence, 'questionRef': ?questionRef},
      options: _opts,
    );
    if (res.statusCode != 201) _fail(res, 'Başlık açılamadı.');
    return DiscussionSummary.fromJson({...res.data!, 'author': const {}});
  }

  @override
  Future<DiscussionDetail?> fetchDiscussion(String threadId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/community/discussions/$threadId',
      options: _opts,
    );
    if (res.statusCode != 200) return null; // 404 = yok / engelli (ayrım sızdırılmaz)
    return DiscussionDetail.fromJson(res.data!);
  }

  @override
  Future<void> addPost({
    required String threadId,
    required String body,
    String? questionRef,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/community/discussions/$threadId',
      data: {'body': body, 'questionRef': ?questionRef},
      options: _opts,
    );
    if (res.statusCode != 201) _fail(res, 'İleti gönderilemedi.');
  }

  @override
  Future<void> reportContent({
    required String userId,
    required ReportReason reason,
    String? targetType,
    String? targetRef,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/community/report',
      data: {
        'targetUserId': userId,
        'reason': reason.wire,
        'targetType': ?targetType,
        'targetRef': ?targetRef,
      },
      options: _opts,
    );
    if (res.statusCode != 201) _fail(res, 'Bildirim gönderilemedi.');
  }
}

final socialApiProvider = Provider<SocialApi>((ref) => DioSocialApi(ref.watch(dioProvider)));
