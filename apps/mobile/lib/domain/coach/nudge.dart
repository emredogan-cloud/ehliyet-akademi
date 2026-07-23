import '../practice/srs.dart';

/// AI Koç dürtme (nudge) tonu.
enum NudgeTone { good, warn, info }

/// Tek bir proaktif koç kartı/dürtmesi (AI_MOBILE_BEHAVIOR Faz 5 kataloğunun mobil alt kümesi).
/// Kural-tabanlı, deterministik — LLM YOK. Öncelik sırasına göre üretilir.
class Nudge {
  const Nudge({
    required this.id,
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.tone,
  });
  final String id;
  final String icon;
  final String title;
  final String body;

  /// Deep-link rotası (ör. `/practice/study`).
  final String action;
  final NudgeTone tone;
}

String _dayKey(int nowMs) {
  final d = DateTime.fromMillisecondsSinceEpoch(nowMs);
  String p(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${p(d.month)}-${p(d.day)}';
}

/// Deterministik dürtme motoru — gerçek yerel sinyallerden (readiness, seri, vadesi gelen kart,
/// cevap sayısı) öncelikli koç kartları üretir. Saf → test edilebilir.
List<Nudge> computeNudges({
  required Readiness? readiness,
  required StreakState streak,
  required int dueCount,
  required int answered,
  required int nowMs,
}) {
  final today = _dayKey(nowMs);
  final yesterday = _dayKey(nowMs - dayMs);
  final studiedToday = streak.lastDay == today;
  final out = <Nudge>[];

  // 1) Hoş geldin — hiç cevap yok.
  if (answered == 0) {
    out.add(
      const Nudge(
        id: 'welcome',
        icon: '👋',
        title: 'Hoş geldin!',
        body: 'İlk 10 soruyla başlayalım — birkaç dakikada temeli at.',
        action: '/practice/study',
        tone: NudgeTone.info,
      ),
    );
    return out;
  }

  // 2) Seri koruması — 2+ günlük seri, dün çalışılmış, bugün değil (en yüksek öncelik).
  if (streak.current >= 2 && streak.lastDay == yesterday) {
    out.add(
      Nudge(
        id: 'streak-protection',
        icon: '🔥',
        title: '${streak.current} günlük serini koru!',
        body: 'Bugün de kısa bir çalışmayla serini sürdür.',
        action: '/practice/study',
        tone: NudgeTone.warn,
      ),
    );
  }

  // 3) Vadesi gelen tekrar kartları.
  if (dueCount > 0) {
    out.add(
      Nudge(
        id: 'due-cards',
        icon: '🔁',
        title: 'Tekrar zamanı geldi',
        body: 'Vadesi gelen $dueCount kart var — hafızanı tazele.',
        action: '/practice/study',
        tone: NudgeTone.info,
      ),
    );
  }

  // 4) Hazırlık / zayıf konu.
  if (readiness != null) {
    if (readiness.light == TrafficLight.kirmizi) {
      out.add(
        Nudge(
          id: 'exam-readiness-low',
          icon: '⚠️',
          title: 'Hazırlık %${readiness.overall}',
          body: 'Şu an girsen risk yüksek. Temel konulara odaklanarak çalışmaya devam et.',
          action: '/practice/study',
          tone: NudgeTone.warn,
        ),
      );
    } else if (readiness.light == TrafficLight.yesil) {
      out.add(
        Nudge(
          id: 'exam-ready',
          icon: '✅',
          title: 'Sınava hazır görünüyorsun!',
          body: 'Hazırlık %${readiness.overall}. Bir deneme sınavıyla pekiştir.',
          action: '/practice/exam',
          tone: NudgeTone.good,
        ),
      );
    }
    // En zayıf ders (sarı/kırmızı olanlar arasından en düşük ustalık).
    final weak = [...readiness.perSubject]..sort((a, b) => a.mastery.compareTo(b.mastery));
    if (weak.isNotEmpty && weak.first.light != TrafficLight.yesil) {
      final w = weak.first;
      out.add(
        Nudge(
          id: 'weak-topic-${w.subject.name}',
          icon: '📉',
          title: 'En zayıf dersin: ${w.subject.label}',
          body: '%${(w.mastery * 100).round()} ustalık. Bu derse biraz daha çalışalım mı?',
          action: '/practice/study',
          tone: NudgeTone.warn,
        ),
      );
    }
  }

  // 5) Günlük motivasyon — bugün çalışılmış, başka acil dürtme yoksa.
  if (studiedToday && out.isEmpty) {
    out.add(
      const Nudge(
        id: 'daily-motivation',
        icon: '🎯',
        title: 'Bugün de harikasın!',
        body: 'Çalışmaya devam et — istikrar sınavı kazandırır.',
        action: '/practice/study',
        tone: NudgeTone.good,
      ),
    );
  }

  // 6) Bugün henüz çalışılmadıysa nazik hatırlatma (en sonda).
  if (!studiedToday && out.every((n) => n.id != 'streak-protection')) {
    out.add(
      const Nudge(
        id: 'start-today',
        icon: '📚',
        title: 'Bugünkü çalışma',
        body: '10 soruluk kısa bir oturumla güne başla.',
        action: '/practice/study',
        tone: NudgeTone.info,
      ),
    );
  }

  return out;
}
