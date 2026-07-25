import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../domain/community/group_models.dart';
import 'community_repository.dart';

/// Evolution Faz E10 — çalışma grupları ve meydan okumalar API'si.
///
/// E8/E9'daki desenin aynısı: arayüz + dio uygulaması ayrı → widget testleri sahte uygulamayla
/// çalışır. Hatalar yutulmaz; arayüz dürüst bir hata durumu gösterir.
abstract class GroupsApi {
  Future<List<StudyGroup>> fetchGroups();
  Future<StudyGroup> createGroup({required String name, required String licence});
  Future<GroupDetail?> fetchGroup(String groupId);

  /// Kodla katıl. Kod geçersiz/bilinmiyorsa [CommunityException] atar.
  Future<StudyGroup> joinByCode(String code);

  /// Gruptan ayrıl. Sahibi ayrılırsa sunucu sahipliği devreder veya grubu siler.
  Future<void> leaveGroup(String groupId);

  /// Grubu sil — yalnız sahibi.
  Future<void> deleteGroup(String groupId);

  Future<List<Challenge>> fetchChallenges();
  Future<void> joinChallenge(String challengeId);
}

class DioGroupsApi implements GroupsApi {
  DioGroupsApi(this._dio);
  final Dio _dio;

  Options get _opts =>
      Options(responseType: ResponseType.json, validateStatus: (s) => s != null && s < 500);

  Never _fail(Response<Map<String, dynamic>> res, String fallback) =>
      throw CommunityException((res.data?['error'] ?? fallback).toString());

  @override
  Future<List<StudyGroup>> fetchGroups() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/community/groups', options: _opts);
    if (res.statusCode != 200) _fail(res, 'Gruplar alınamadı.');
    return ((res.data?['groups'] as List?) ?? const [])
        .map((e) => StudyGroup.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<StudyGroup> createGroup({required String name, required String licence}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/community/groups',
      data: {'name': name, 'licence': licence},
      options: _opts,
    );
    if (res.statusCode != 201) _fail(res, 'Grup kurulamadı.');
    return StudyGroup.fromJson({...res.data!, 'isOwner': true});
  }

  @override
  Future<GroupDetail?> fetchGroup(String groupId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/community/groups/$groupId',
      options: _opts,
    );
    // 404 = yok / üye değilim / engelli (ayrım sızdırılmaz).
    if (res.statusCode != 200) return null;
    return GroupDetail.fromJson(res.data!);
  }

  @override
  Future<StudyGroup> joinByCode(String code) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/community/groups/join',
      data: {'code': code},
      options: _opts,
    );
    if (res.statusCode != 201) _fail(res, 'Gruba katılınamadı.');
    return StudyGroup.fromJson({...res.data!, 'isOwner': false});
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    await _dio.delete<Map<String, dynamic>>(
      '/api/community/groups/join',
      queryParameters: {'groupId': groupId},
      options: _opts,
    );
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    final res = await _dio.delete<Map<String, dynamic>>(
      '/api/community/groups',
      queryParameters: {'groupId': groupId},
      options: _opts,
    );
    if (res.statusCode != 200) _fail(res, 'Grup silinemedi.');
  }

  @override
  Future<List<Challenge>> fetchChallenges() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/community/challenges', options: _opts);
    if (res.statusCode != 200) _fail(res, 'Meydan okumalar alınamadı.');
    return ((res.data?['challenges'] as List?) ?? const [])
        .map((e) => Challenge.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> joinChallenge(String challengeId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/community/challenges',
      data: {'challengeId': challengeId},
      options: _opts,
    );
    if (res.statusCode != 201) _fail(res, 'Meydan okumaya katılınamadı.');
  }
}

final groupsApiProvider = Provider<GroupsApi>((ref) => DioGroupsApi(ref.watch(dioProvider)));
