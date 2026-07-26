import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Evolution Faz E11 — video ilerlemesi ve yer imleri (cihazda kalıcı).
///
/// NEDEN SUNUCUDA DEĞİL: izleme konumu kişisel ve düşük değerli bir veridir; sunucuya taşımak
/// topluluk katmanının gizlilik yükünü (E8) gereksiz yere büyütürdü. Cihazda kalır.
///
/// Depolama, uygulamadaki diğer tercihlerle AYNI desen: `SharedPreferences` + tek JSON anahtarı.

const _kVideoState = 'ea:videoState:v1';

/// Tek bir videonun durumu.
class VideoState {
  const VideoState({
    this.positionMs = 0,
    this.durationMs = 0,
    this.watched = false,
    this.bookmarks = const [],
  });

  final int positionMs;
  final int durationMs;
  final bool watched;

  /// Yer imleri — milisaniye cinsinden, SIRALI ve tekrarsız tutulur.
  final List<int> bookmarks;

  Duration get position => Duration(milliseconds: positionMs);

  VideoState copyWith({int? positionMs, int? durationMs, bool? watched, List<int>? bookmarks}) =>
      VideoState(
        positionMs: positionMs ?? this.positionMs,
        durationMs: durationMs ?? this.durationMs,
        watched: watched ?? this.watched,
        bookmarks: bookmarks ?? this.bookmarks,
      );

  Map<String, Object?> toJson() => {
    'p': positionMs,
    'd': durationMs,
    'w': watched,
    'b': bookmarks,
  };

  factory VideoState.fromJson(Map<String, Object?> j) => VideoState(
    positionMs: (j['p'] as num?)?.toInt() ?? 0,
    durationMs: (j['d'] as num?)?.toInt() ?? 0,
    watched: j['w'] == true,
    bookmarks: ((j['b'] as List?) ?? const [])
        .map((e) => (e as num).toInt())
        .toList(growable: false),
  );
}

/// Bütün videoların durumu (videoId → durum).
class VideoStates {
  const VideoStates(this.byId);
  final Map<String, VideoState> byId;

  static const empty = VideoStates({});

  VideoState of(String id) => byId[id] ?? const VideoState();

  /// Çalışma planına beslenen sayaç.
  int get watchedCount => byId.values.where((v) => v.watched).length;
}

/// Yer imi ekler/çıkarır — aynı saniyeye iki kez imlenmesin diye 1 sn'lik tolerans uygulanır.
///
/// Kullanıcı ilerleme çubuğunu tam aynı milisaniyeye getiremez; tolerans olmadan liste
/// neredeyse-aynı imlerle dolardı.
List<int> toggleBookmark(List<int> current, int atMs, {int toleranceMs = 1000}) {
  final existing = current.where((b) => (b - atMs).abs() <= toleranceMs).toList();
  if (existing.isNotEmpty) {
    return current.where((b) => !existing.contains(b)).toList(growable: false);
  }
  return ([...current, atMs]..sort()).toList(growable: false);
}

class VideoProgressController extends Notifier<VideoStates> {
  VideoProgressController([this._initial = VideoStates.empty]);
  final VideoStates _initial;

  @override
  VideoStates build() => _initial;

  Future<void> _persist(VideoStates next) async {
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = next.byId.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString(_kVideoState, jsonEncode(map));
    } catch (_) {
      // Kalıcılık başarısız olsa bile oturum içi durum doğru kalır.
    }
  }

  /// Konumu kaydet. Sık çağrılır (saniyede bir) — çağıran taraf kısar.
  Future<void> savePosition(String id, {required Duration position, required Duration duration}) {
    final prev = state.of(id);
    final next = prev.copyWith(
      positionMs: position.inMilliseconds,
      durationMs: duration.inMilliseconds,
    );
    return _persist(VideoStates({...state.byId, id: next}));
  }

  Future<void> markWatched(String id) {
    final prev = state.of(id);
    if (prev.watched) return Future.value();
    return _persist(VideoStates({...state.byId, id: prev.copyWith(watched: true)}));
  }

  Future<void> toggleBookmarkAt(String id, Duration at) {
    final prev = state.of(id);
    final next = prev.copyWith(bookmarks: toggleBookmark(prev.bookmarks, at.inMilliseconds));
    return _persist(VideoStates({...state.byId, id: next}));
  }

  Future<void> clear(String id) {
    final copy = {...state.byId}..remove(id);
    return _persist(VideoStates(copy));
  }
}

final videoProgressProvider = NotifierProvider<VideoProgressController, VideoStates>(
  () => VideoProgressController(),
);

/// main()'de bir kez okunur (diğer tercihlerle aynı desen).
Future<VideoStates> readVideoStates() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kVideoState);
    if (raw == null || raw.isEmpty) return VideoStates.empty;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return VideoStates.empty;
    final out = <String, VideoState>{};
    decoded.forEach((k, v) {
      if (v is Map) out['$k'] = VideoState.fromJson(Map<String, Object?>.from(v));
    });
    return VideoStates(out);
  } catch (_) {
    // Bozuk kayıt kullanıcıyı kilitlemesin — boş durumla devam.
    return VideoStates.empty;
  }
}
