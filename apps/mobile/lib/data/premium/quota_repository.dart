import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/premium/products.dart';

/// Ücretsiz kademe kotaları — web `lib/payments.ts` limanı. Günlük 5 AI sorusu, 1 deneme sınavı.
/// `{day, count}` olarak `ea:aiQuota:v1` / `ea:examQuota:v1`'de saklanır. Premium yetenek → sınırsız.

const int freeAiDaily = 5;
const int freeExamDaily = 1;
const _kAi = 'ea:aiQuota:v1';
const _kExam = 'ea:examQuota:v1';

String _today() {
  final d = DateTime.now();
  String p(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${p(d.month)}-${p(d.day)}';
}

class QuotaRepository {
  QuotaRepository(this._prefs);
  final SharedPreferences _prefs;

  int _countToday(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return 0;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return m['day'] == _today() ? ((m['count'] as num?)?.toInt() ?? 0) : 0;
  }

  Future<void> _bump(String key) async {
    await _prefs.setString(key, jsonEncode({'day': _today(), 'count': _countToday(key) + 1}));
  }

  // ——— AI ———
  int remainingAi(List<String> owned) {
    if (hasCapability(owned, 'ai-sinirsiz')) return -1; // sınırsız
    return (freeAiDaily - _countToday(_kAi)).clamp(0, freeAiDaily);
  }

  bool canAskAi(List<String> owned) => remainingAi(owned) != 0;

  Future<void> consumeAi(List<String> owned) async {
    if (!hasCapability(owned, 'ai-sinirsiz')) await _bump(_kAi);
  }

  // ——— Deneme sınavı ———
  bool canStartExam(List<String> owned) {
    if (hasCapability(owned, 'sinirsiz-deneme')) return true;
    return _countToday(_kExam) < freeExamDaily;
  }

  int remainingExam(List<String> owned) {
    if (hasCapability(owned, 'sinirsiz-deneme')) return -1;
    return (freeExamDaily - _countToday(_kExam)).clamp(0, freeExamDaily);
  }

  Future<void> consumeExam(List<String> owned) async {
    if (!hasCapability(owned, 'sinirsiz-deneme')) await _bump(_kExam);
  }
}

final quotaRepositoryProvider = FutureProvider<QuotaRepository>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return QuotaRepository(prefs);
});
