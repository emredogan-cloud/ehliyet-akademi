import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../domain/community/community_models.dart';

/// Evolution Faz E8 — topluluk API'si.
///
/// TASARIM: arayüz + dio uygulaması ayrıdır (auth/coach/entitlements ile aynı desen) → widget
/// testleri sahte uygulamayla çalışır, ağ/platform kanalı gerekmez.
///
/// ÇEVRİMDIŞI: topluluk gerçekten paylaşılan durumdur; çevrimdışı üretilemez. Hatalar sessizce
/// yutulmaz — depo hata durumunu taşır ve arayüz dürüst bir "bağlanılamadı" durumu gösterir.
abstract class CommunityApi {
  Future<({CommunityProfile? profile, CommunityStats? stats})> fetchMe();
  Future<CommunityProfile> saveProfile({
    required String displayName,
    required String avatarId,
    required String licence,
    required bool public,
  });
  Future<void> leave();
  Future<CommunityStats> submitStats({
    required int xp,
    required int streak,
    required int lessons,
    required int exams,
    required int answered,
    required int accuracy,
    required List<String> achievements,
  });
  Future<LeaderboardPage> fetchLeaderboard({String? licence, int limit, int offset});
  Future<CommunityUser?> fetchUser(String userId);
  Future<void> report({required String userId, required ReportReason reason, String note});
  Future<void> block(String userId);
  Future<void> unblock(String userId);

  /// Faz E9 — engellenenler listesi (engel kaldırma yüzeyi için).
  Future<List<BlockedUser>> fetchBlocked();
}

class DioCommunityApi implements CommunityApi {
  DioCommunityApi(this._dio);
  final Dio _dio;

  Options get _opts =>
      Options(responseType: ResponseType.json, validateStatus: (s) => s != null && s < 500);

  @override
  Future<({CommunityProfile? profile, CommunityStats? stats})> fetchMe() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/community/profile', options: _opts);
    if (res.statusCode != 200) return (profile: null, stats: null);
    final data = res.data ?? const {};
    return (
      profile: data['profile'] == null
          ? null
          : CommunityProfile.fromJson(Map<String, dynamic>.from(data['profile'] as Map)),
      stats: data['stats'] == null
          ? null
          : CommunityStats.fromJson(Map<String, dynamic>.from(data['stats'] as Map)),
    );
  }

  @override
  Future<CommunityProfile> saveProfile({
    required String displayName,
    required String avatarId,
    required String licence,
    required bool public,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/community/profile',
      data: {
        'displayName': displayName,
        'avatarId': avatarId,
        'licence': licence,
        'visibility': public ? 'public' : 'private',
      },
      options: _opts,
    );
    if (res.statusCode != 200) {
      throw CommunityException((res.data?['error'] ?? 'Profil kaydedilemedi.').toString());
    }
    return CommunityProfile.fromJson(Map<String, dynamic>.from(res.data!['profile'] as Map));
  }

  @override
  Future<void> leave() async {
    await _dio.delete<Map<String, dynamic>>('/api/community/profile', options: _opts);
  }

  @override
  Future<CommunityStats> submitStats({
    required int xp,
    required int streak,
    required int lessons,
    required int exams,
    required int answered,
    required int accuracy,
    required List<String> achievements,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/community/stats',
      data: {
        'xp': xp,
        'streak': streak,
        'lessons': lessons,
        'exams': exams,
        'answered': answered,
        'accuracy': accuracy,
        'achievements': achievements,
      },
      options: _opts,
    );
    if (res.statusCode != 200) {
      throw CommunityException((res.data?['error'] ?? 'İstatistik gönderilemedi.').toString());
    }
    return CommunityStats.fromJson(Map<String, dynamic>.from(res.data!['stats'] as Map));
  }

  @override
  Future<LeaderboardPage> fetchLeaderboard({String? licence, int limit = 25, int offset = 0}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/community/leaderboard',
      queryParameters: {'licence': ?licence, 'limit': limit, 'offset': offset},
      options: _opts,
    );
    if (res.statusCode != 200) {
      throw CommunityException((res.data?['error'] ?? 'Sıralama alınamadı.').toString());
    }
    return LeaderboardPage.fromJson(res.data!);
  }

  @override
  Future<CommunityUser?> fetchUser(String userId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/community/user/$userId',
      options: _opts,
    );
    if (res.statusCode != 200) return null; // 404 = yok / gizli / engelli (ayrım sızdırılmaz)
    return CommunityUser.fromJson(res.data!);
  }

  @override
  Future<void> report({
    required String userId,
    required ReportReason reason,
    String note = '',
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/community/report',
      data: {'targetUserId': userId, 'reason': reason.wire, 'note': note},
      options: _opts,
    );
    if (res.statusCode != 201) {
      throw CommunityException((res.data?['error'] ?? 'Bildirim gönderilemedi.').toString());
    }
  }

  @override
  Future<void> block(String userId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/community/block',
      data: {'targetUserId': userId},
      options: _opts,
    );
    if (res.statusCode != 201) {
      throw CommunityException((res.data?['error'] ?? 'Engellenemedi.').toString());
    }
  }

  @override
  Future<void> unblock(String userId) async {
    await _dio.delete<Map<String, dynamic>>(
      '/api/community/block',
      queryParameters: {'targetUserId': userId},
      options: _opts,
    );
  }

  @override
  Future<List<BlockedUser>> fetchBlocked() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/community/block', options: _opts);
    if (res.statusCode != 200) {
      throw CommunityException((res.data?['error'] ?? 'Liste alınamadı.').toString());
    }
    return ((res.data?['blocked'] as List?) ?? const [])
        .map((e) => BlockedUser.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

class CommunityException implements Exception {
  CommunityException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Kendi topluluk durumum: katılmadıysam `profile` null'dır.
class MyCommunityState {
  const MyCommunityState({this.profile, this.stats, this.loading = false, this.error});
  final CommunityProfile? profile;
  final CommunityStats? stats;
  final bool loading;
  final String? error;

  bool get joined => profile != null;

  MyCommunityState copyWith({
    CommunityProfile? profile,
    CommunityStats? stats,
    bool? loading,
    String? error,
    bool clearProfile = false,
    bool clearError = false,
  }) => MyCommunityState(
    profile: clearProfile ? null : (profile ?? this.profile),
    stats: clearProfile ? null : (stats ?? this.stats),
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
  );
}

class CommunityController extends Notifier<MyCommunityState> {
  @override
  MyCommunityState build() {
    Future.microtask(refresh);
    return const MyCommunityState();
  }

  CommunityApi get _api => ref.read(communityApiProvider);

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final me = await _api.fetchMe();
      state = MyCommunityState(profile: me.profile, stats: me.stats);
    } catch (_) {
      // Oturum yok / ağ yok → katılmamış gibi davran; arayüz dürüst durumu gösterir.
      state = const MyCommunityState();
    }
  }

  Future<void> join({
    required String displayName,
    required String avatarId,
    required String licence,
    required bool public,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final profile = await _api.saveProfile(
        displayName: displayName,
        avatarId: avatarId,
        licence: licence,
        public: public,
      );
      state = MyCommunityState(profile: profile, stats: state.stats);
    } on CommunityException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(loading: false, error: 'Bağlanılamadı. İnternetini kontrol et.');
    }
  }

  Future<void> leave() async {
    try {
      await _api.leave();
    } catch (_) {
      // en iyi çaba
    }
    state = const MyCommunityState();
  }

  /// Yerel ilerlemeyi sunucuya bildirir. Sunucu sınırlar; dönen değer yetkilidir.
  Future<void> pushStats({
    required int xp,
    required int streak,
    required int lessons,
    required int exams,
    required int answered,
    required int accuracy,
    required List<String> achievements,
  }) async {
    if (!state.joined) return;
    try {
      final stats = await _api.submitStats(
        xp: xp,
        streak: streak,
        lessons: lessons,
        exams: exams,
        answered: answered,
        accuracy: accuracy,
        achievements: achievements,
      );
      state = state.copyWith(stats: stats);
    } catch (_) {
      // sessiz: istatistik bildirimi en iyi çabadır, kullanıcıyı engellemez
    }
  }
}

final communityApiProvider = Provider<CommunityApi>(
  (ref) => DioCommunityApi(ref.watch(dioProvider)),
);

final communityProvider = NotifierProvider<CommunityController, MyCommunityState>(
  CommunityController.new,
);
