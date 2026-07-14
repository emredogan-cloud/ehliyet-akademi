/**
 * @ea/srs-engine — Öğrenme bilimi çekirdeği (ROADMAP Faz 9/35).
 * 1) SM-2 tabanlı aralıklı tekrar (spaced repetition)
 * 2) Adaptif soru seçimi (zayıf konu + vadesi gelen kart ağırlıklı)
 * 3) Hazırlık skoru + "trafik ışığı" (Führerschein "Exam Traffic Light" muadili)
 *
 * Saf, yan-etkisiz fonksiyonlar; her `now` dışarıdan verilir (deterministik test).
 */
import { EXAM_BLUEPRINT, type Subject } from '@ea/content-schema';

// Tüketicilerin (web, storage) rahat kullanması için yeniden dışa aktar.
export type { Subject } from '@ea/content-schema';

export const DAY_MS = 86_400_000;

/** Bir sorunun kullanıcıdaki tekrar kartı. */
export interface SrsCard {
  questionId: string;
  /** SM-2 kolaylık faktörü (>= 1.3). */
  ease: number;
  /** Gün cinsinden aralık. */
  intervalDays: number;
  /** Ardışık doğru sayısı. */
  repetitions: number;
  /** Sonraki tekrarın zamanı (epoch ms). */
  dueAt: number;
  /** Toplam görülme. */
  reviews: number;
  lapses: number;
}

/** Kullanıcı cevabının kalitesi (SM-2 0..5). Uygulamada 4 kademeye eşlenir. */
export type Grade = 0 | 1 | 2 | 3 | 4 | 5;

export const MIN_EASE = 1.3;

/** Yeni bir kart oluştur (henüz çalışılmamış soru). */
export function newCard(questionId: string, now: number): SrsCard {
  return {
    questionId,
    ease: 2.5,
    intervalDays: 0,
    repetitions: 0,
    dueAt: now,
    reviews: 0,
    lapses: 0,
  };
}

/**
 * SM-2 tekrar adımı. grade < 3 => başarısız (aralık sıfırlanır, ceza).
 * Referans: SuperMemo-2 algoritması (kamuya açık); parametreler ehliyet çalışmasına uyarlandı.
 */
export function review(card: SrsCard, grade: Grade, now: number): SrsCard {
  const reviews = card.reviews + 1;
  let { ease, intervalDays, repetitions, lapses } = card;

  if (grade < 3) {
    // Başarısız: tekrar sıfırla, kısa süre sonra tekrar sor, kolaylığı düşür.
    repetitions = 0;
    intervalDays = 0; // aynı oturumda/kısa süre içinde
    lapses += 1;
    ease = Math.max(MIN_EASE, ease - 0.2);
  } else {
    repetitions += 1;
    // SM-2 ease güncellemesi
    ease = Math.max(MIN_EASE, ease + (0.1 - (5 - grade) * (0.08 + (5 - grade) * 0.02)));
    if (repetitions === 1) intervalDays = 1;
    else if (repetitions === 2) intervalDays = 6;
    else intervalDays = Math.round(card.intervalDays * ease);
    // Emniyet: en az 1 gün, sınav odaklı üst sınır
    intervalDays = Math.min(Math.max(intervalDays, 1), 180);
  }

  const dueDelta = grade < 3 ? Math.round(0.007 * DAY_MS) : intervalDays * DAY_MS; // fail => ~10 dk
  return { ...card, ease, intervalDays, repetitions, reviews, lapses, dueAt: now + dueDelta };
}

/** Ham 4-kademeli UI cevabını SM-2 grade'ine çevir. */
export function toGrade(outcome: 'again' | 'hard' | 'good' | 'easy'): Grade {
  switch (outcome) {
    case 'again':
      return 1;
    case 'hard':
      return 3;
    case 'good':
      return 4;
    case 'easy':
      return 5;
  }
}

export function isDue(card: SrsCard, now: number): boolean {
  return card.dueAt <= now;
}

/**
 * Adaptif seçim: vadesi gelen kartlar + hiç görülmemiş sorular arasından,
 * zayıf konulara ağırlık vererek `limit` adet soru id'si seç.
 */
export interface SelectableQuestion {
  id: string;
  subject: Subject;
  topic: string;
}
export function selectNext(
  pool: SelectableQuestion[],
  cards: Map<string, SrsCard>,
  topicMastery: Map<string, number>, // topic -> 0..1
  now: number,
  limit: number
): string[] {
  const scored = pool.map((q) => {
    const card = cards.get(q.id);
    const mastery = topicMastery.get(q.topic) ?? 0;
    let score = 0;
    if (card) {
      // vadesi geçmiş kartlara yüksek öncelik (gecikme kadar)
      score += isDue(card, now) ? 100 + (now - card.dueAt) / DAY_MS : -50;
      score += card.lapses * 10; // sık unutulan
    } else {
      score += 40; // yeni içerik öğrenme değeri
    }
    score += (1 - mastery) * 60; // zayıf konu ağırlığı
    return { id: q.id, score };
  });
  scored.sort((a, b) => b.score - a.score);
  return scored.slice(0, limit).map((s) => s.id);
}

/** Ders/konu bazlı istatistik. */
export interface SubjectStat {
  subject: Subject;
  answered: number;
  correct: number;
  mastery: number; // 0..1
}

export type TrafficLight = 'kirmizi' | 'sari' | 'yesil';

export interface Readiness {
  overall: number; // 0..100 hazırlık skoru
  predictedPassProbability: number; // 0..1
  light: TrafficLight;
  perSubject: Array<{ subject: Subject; mastery: number; light: TrafficLight }>;
  message: string;
}

function lightFor(mastery: number): TrafficLight {
  if (mastery >= 0.8) return 'yesil';
  if (mastery >= 0.55) return 'sari';
  return 'kirmizi';
}

/**
 * Hazırlık skoru: e-Sınav dağılımına göre AĞIRLIKLI ders ustalığı.
 * Trafik %46, İlk Yardım %24, Motor %18, Adab %12 (23/12/9/6 → /50).
 * Geçme olasılığı, ağırlıklı ustalıktan kalibre edilmiş sigmoid ile tahmin edilir.
 */
export function computeReadiness(stats: SubjectStat[]): Readiness {
  const dist = EXAM_BLUEPRINT.distribution;
  const total = EXAM_BLUEPRINT.totalQuestions;
  const weights: Record<string, number> = {
    trafik: dist.trafik / total,
    ilkyardim: dist.ilkyardim / total,
    motor: dist.motor / total,
    adab: dist.adab / total,
  };

  let weighted = 0;
  let weightSum = 0;
  const perSubject = stats
    .filter((s) => s.subject !== 'pratik')
    .map((s) => {
      const w = weights[s.subject] ?? 0;
      // Az veri cezası: 5 sorudan az cevaplandıysa ustalık iskontolu.
      const confidence = Math.min(1, s.answered / 8);
      const adjusted = s.mastery * confidence;
      weighted += adjusted * w;
      weightSum += w;
      return { subject: s.subject, mastery: s.mastery, light: lightFor(adjusted) };
    });

  const overallFrac = weightSum > 0 ? weighted / weightSum : 0;
  const overall = Math.round(overallFrac * 100);

  // Geçme barajı %70 (35/50). Ağırlıklı ustalık %70 iken ~%50 geçme olasılığı veren sigmoid.
  const k = 12;
  const predictedPassProbability = 1 / (1 + Math.exp(-k * (overallFrac - 0.7)));

  const light = lightFor(overallFrac);
  const message =
    light === 'yesil'
      ? 'Sınava hazırsın. Zayıf kalan birkaç konuyu tazele, güvenle gir.'
      : light === 'sari'
        ? 'İyi yoldasın ama henüz garanti değil. Kırmızı/sarı konulara odaklan.'
        : 'Şu an girsen risk yüksek. Temel konulardan başlayarak çalışmaya devam et.';

  return {
    overall,
    predictedPassProbability: Math.round(predictedPassProbability * 100) / 100,
    light,
    perSubject,
    message,
  };
}

/** Basit yardımcı: cevap kayıtlarından ders istatistiği üret. */
export function statsFromAnswers(
  answers: Array<{ subject: Subject; topic: string; correct: boolean }>
): { subjects: SubjectStat[]; topicMastery: Map<string, number> } {
  const bySubject = new Map<Subject, { answered: number; correct: number }>();
  const byTopic = new Map<string, { answered: number; correct: number }>();
  for (const a of answers) {
    const s = bySubject.get(a.subject) ?? { answered: 0, correct: 0 };
    s.answered += 1;
    if (a.correct) s.correct += 1;
    bySubject.set(a.subject, s);
    const t = byTopic.get(a.topic) ?? { answered: 0, correct: 0 };
    t.answered += 1;
    if (a.correct) t.correct += 1;
    byTopic.set(a.topic, t);
  }
  const subjects: SubjectStat[] = [...bySubject.entries()].map(([subject, v]) => ({
    subject,
    answered: v.answered,
    correct: v.correct,
    mastery: v.answered ? v.correct / v.answered : 0,
  }));
  const topicMastery = new Map<string, number>();
  for (const [topic, v] of byTopic)
    topicMastery.set(topic, v.answered ? v.correct / v.answered : 0);
  return { subjects, topicMastery };
}
