import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gamification.dart';

/// Faz 10 — YENİ açılan rozetin bulunması.
///
/// Rozetler saf bir fonksiyondan (`computeAchievements`) türetilir; kalıcı bir "açıldı" kaydı
/// YOKTUR ve olmamalıdır — kayıt tutmak, aynı gerçeği iki yerde saklamak olurdu ve ikisi
/// birbirinden ayrı düşebilirdi.
///
/// Kutlamanın ihtiyacı olan tek şey farklı: "kullanıcı bu rozeti DAHA ÖNCE gördü mü?" Bu, rozetin
/// kendisi değil, KUTLAMANIN durumudur ve ayrı saklanır (`ea:celebratedBadges:v1`).
///
/// İlk kurulumda (ya da uygulamayı silip yeniden kuranda) kullanıcının zaten hak ettiği rozetler
/// için arka arkaya beş pencere açmak saçma olurdu; bu yüzden [firstSyncSilently] vardır: ilk
/// senkronda açık rozetler kutlanmadan işaretlenir.

/// Kutlanacak rozet(ler)i bul.
///
/// [alreadyCelebrated] daha önce gösterilmiş rozet kimlikleri. Dönüş, sırayla gösterilecek
/// YENİ rozetlerdir.
List<Achievement> newlyUnlocked({
  required List<Achievement> achievements,
  required Set<String> alreadyCelebrated,
}) => [
  for (final a in achievements)
    if (a.unlocked && !alreadyCelebrated.contains(a.id)) a,
];

const _kCelebrated = 'ea:celebratedBadges:v1';

/// Kutlanmış rozet kimlikleri.
class CelebratedBadgesController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    Future.microtask(_load);
    return const {};
  }

  /// İlk okuma tamamlandı mı? Tamamlanmadan kutlama yapılmaz — aksi hâlde boş küme yüzünden
  /// TÜM açık rozetler "yeni" sanılırdı.
  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCelebrated);
      if (raw != null) {
        state = (jsonDecode(raw) as List).map((e) => e.toString()).toSet();
      }
    } catch (_) {}
    _loaded = true;
  }

  /// Rozeti kutlanmış olarak işaretle.
  Future<void> markCelebrated(Iterable<String> ids) async {
    if (ids.isEmpty) return;
    state = {...state, ...ids};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCelebrated, jsonEncode(state.toList()));
    } catch (_) {}
  }

  /// İLK senkron: zaten açık olan rozetleri kutlamadan işaretle.
  ///
  /// Uygulamayı yeni kuran ama ilerlemesi sunucudan gelen bir kullanıcıya arka arkaya beş
  /// kutlama penceresi açmak, kutlamayı gürültüye çevirirdi.
  Future<void> firstSyncSilently(List<Achievement> achievements) => markCelebrated([
    for (final a in achievements)
      if (a.unlocked) a.id,
  ]);
}

final celebratedBadgesProvider = NotifierProvider<CelebratedBadgesController, Set<String>>(
  CelebratedBadgesController.new,
);
