import 'dart:convert';

// ValueNotifier için — depo bir "ilerleme değişti" sinyali yayınlar (bkz. [ProgressRepository.revision]).
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/practice/srs.dart';
import 'state_sync.dart';

const _kCards = 'ea:cards:v1';
const _kAnswers = 'ea:answers:v1';
const _kStreak = 'ea:streak:v1';
const _kCounters = 'ea:counters:v1';
const _answersCap = 2000;

String _dayKey(int nowMs) {
  final d = DateTime.fromMillisecondsSinceEpoch(nowMs);
  String p(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${p(d.month)}-${p(d.day)}';
}

/// Yerel ilerleme deposu (SRS kartları, cevaplar, seri, sayaçlar). shared_preferences ile TAMAMEN
/// çevrimdışı; her yazımda best-effort olarak sunucuya (`/api/state`) push edilir.
class ProgressRepository {
  ProgressRepository(this._prefs, this._sync);
  final SharedPreferences _prefs;
  final StateSync? _sync;

  /// Yazma sayacı — "ilerleme değişti" sinyali.
  ///
  /// ## Neden gerekti (cihaz denetiminde bulundu, 11 Ağustos 2026)
  ///
  /// 90 soru çözüldükten sonra Ana Sayfa hâlâ **%0 hazırlık · 0 soru · Lv 1** gösteriyordu;
  /// İlerleme ekranı ise aynı anda doğru değerleri (90 soru · %71 · Seviye 4) gösteriyordu.
  /// Veri kaybı yoktu — ekran tazelenmiyordu.
  ///
  /// Sebep iki parçalıydı:
  /// 1. `progressRepositoryProvider` bir `FutureProvider`'dır ve **bir kez** çözülüp aynı
  ///    örneği döndürür. Depo içindeki veri değişse de sağlayıcı yeni bir değer YAYMAZ.
  /// 2. Gezinme `StatefulShellRoute.indexedStack` kullanır: Pratik sekmesinde çalışılırken
  ///    Ana Sayfa dalı **canlı kalır** ve yeniden inşa edilmez.
  ///
  /// İkisi birleşince Ana Sayfa, açıldığı andaki değerleri sonsuza kadar gösteriyordu; ancak
  /// uygulama yeniden başlatılınca düzeliyordu. Kullanıcı açısından bu "çalışmam kaydedilmedi"
  /// demektir — ilk izlenimi bozan, sessiz bir kusur.
  ///
  /// `ValueNotifier` seçildi çünkü depo saf bir shared_preferences sarmalayıcısıdır; onu
  /// `ChangeNotifier`'a çevirmek ya da Riverpod'a bağlamak, tek ihtiyaç "bir şey değişti"
  /// demekken gereğinden ağır olurdu.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Her YAZMA sonrası çağrılır. Okuma yollarında çağrılmaz — dinleyiciyi boşuna uyandırırdı.
  void _touch() => revision.value++;

  // ——— SRS kartları ———
  Map<String, SrsCard> loadCards() {
    final raw = _prefs.getString(_kCards);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, SrsCard.fromJson(v as Map<String, dynamic>)));
  }

  Future<void> saveCards(Map<String, SrsCard> cards) async {
    final obj = cards.map((k, v) => MapEntry(k, v.toJson()));
    await _prefs.setString(_kCards, jsonEncode(obj));
    _sync?.push(_kCards, obj);
    _touch();
  }

  // ——— Cevap kayıtları (son 2000) ———
  List<AnswerLog> loadAnswers() {
    final raw = _prefs.getString(_kAnswers);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => AnswerLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> appendAnswers(List<AnswerLog> more) async {
    final all = [...loadAnswers(), ...more];
    final capped = all.length > _answersCap ? all.sublist(all.length - _answersCap) : all;
    final obj = capped.map((a) => a.toJson()).toList();
    await _prefs.setString(_kAnswers, jsonEncode(obj));
    _sync?.push(_kAnswers, obj);
    _touch();
  }

  // ——— Seri (ardışık gün) ———
  StreakState loadStreak() {
    final raw = _prefs.getString(_kStreak);
    if (raw == null) return StreakState.empty;
    return StreakState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<StreakState> touchStreak(int nowMs) async {
    final today = _dayKey(nowMs);
    final s = loadStreak();
    if (s.lastDay == today) return s;
    final yesterday = _dayKey(nowMs - dayMs);
    final current = s.lastDay == yesterday ? s.current + 1 : 1;
    final next = StreakState(
      current: current,
      best: current > s.best ? current : s.best,
      lastDay: today,
    );
    await _prefs.setString(_kStreak, jsonEncode(next.toJson()));
    _sync?.push(_kStreak, next.toJson());
    _touch();
    return next;
  }

  // ——— Sayaçlar ———
  int examsFinished() {
    final raw = _prefs.getString(_kCounters);
    if (raw == null) return 0;
    return ((jsonDecode(raw) as Map)['examsFinished'] as num?)?.toInt() ?? 0;
  }

  Future<void> incrementExamsFinished() async {
    final obj = {'examsFinished': examsFinished() + 1};
    await _prefs.setString(_kCounters, jsonEncode(obj));
    _sync?.push(_kCounters, obj);
    _touch();
  }

  /// Oturum açıldığında sunucu durumunu yerelle birleştir (güvenli birleşim: kayıp yok).
  Future<void> mergeRemote(Map<String, dynamic> remote) async {
    // Kartlar: sunucu + yerel, daha çok gözden geçirilmiş olan kazanır.
    if (remote[_kCards] is Map) {
      final local = loadCards();
      final srv = (remote[_kCards] as Map).map(
        (k, v) => MapEntry(k as String, SrsCard.fromJson((v as Map).cast<String, dynamic>())),
      );
      final merged = {...srv};
      for (final e in local.entries) {
        final s = merged[e.key];
        if (s == null || e.value.reviews > s.reviews) merged[e.key] = e.value;
      }
      await saveCards(merged);
    }
    // Cevaplar: birleşim (questionId+at ile tekilleştir), zamana göre sırala, son 2000.
    if (remote[_kAnswers] is List) {
      final srv = (remote[_kAnswers] as List)
          .map((e) => AnswerLog.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      final seen = <String>{};
      final all = [...srv, ...loadAnswers()]..sort((a, b) => a.at.compareTo(b.at));
      final deduped = <AnswerLog>[];
      for (final a in all) {
        if (seen.add('${a.questionId}#${a.at}')) deduped.add(a);
      }
      final capped = deduped.length > _answersCap
          ? deduped.sublist(deduped.length - _answersCap)
          : deduped;
      await _prefs.setString(_kAnswers, jsonEncode(capped.map((a) => a.toJson()).toList()));
    }
    // Seri: en yüksek best; en güncel lastDay'in current'i.
    if (remote[_kStreak] is Map) {
      final srv = StreakState.fromJson((remote[_kStreak] as Map).cast<String, dynamic>());
      final local = loadStreak();
      final newer = srv.lastDay.compareTo(local.lastDay) >= 0 ? srv : local;
      final merged = StreakState(
        current: newer.current,
        best: srv.best > local.best ? srv.best : local.best,
        lastDay: newer.lastDay,
      );
      await _prefs.setString(_kStreak, jsonEncode(merged.toJson()));
    }
    // Sayaçlar: en yüksek.
    if (remote[_kCounters] is Map) {
      final srv = ((remote[_kCounters] as Map)['examsFinished'] as num?)?.toInt() ?? 0;
      if (srv > examsFinished()) {
        await _prefs.setString(_kCounters, jsonEncode({'examsFinished': srv}));
      }
    }
    // Birleştirme birden çok anahtarı değiştirebilir; tek bir sinyal yeter ve dinleyiciyi
    // gereksiz yere birden çok kez uyandırmaz.
    _touch();
  }

  /// Bir alt küme yardımcı: verilen cevap kayıtlarından readiness üret.
  Readiness readiness() => computeReadiness(statsFromAnswers(loadAnswers()).subjects);
}

/// SharedPreferences'ı bir kez açar (eklenti örneği önbelleğe alır).
final progressRepositoryProvider = FutureProvider<ProgressRepository>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return ProgressRepository(prefs, ref.watch(stateSyncProvider));
});
