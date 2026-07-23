import { createHash } from 'node:crypto';
import { json } from '@/lib/server/auth';
import { allQuestions } from '@ea/question-bank';
import { EXAM_BLUEPRINT, type Question } from '@ea/content-schema';

/**
 * Mobil soru bankası anlık görüntüsü (Mobile Phase 4 · Practice & Exams).
 *
 * Soru bankası statik ve kullanıcıya özel değildir → tek, halka açık, önbelleğe alınabilir uç nokta.
 * Flutter istemcisi bir kez indirir, `version` ile yerelde (drift) saklar ve pratik + sınav + SRS'i
 * TAMAMEN çevrimdışı çalıştırır (SM-2, buildExam, scoreExam Dart'a taşındı). Yalnız pratik/sınav için
 * gereken alanlar döner (yalın projeksiyon → ~1.3 MB, gzip ile ~250 KB).
 */

type LeanQuestion = {
  id: string;
  subject: Question['subject'];
  topic: string;
  difficulty: Question['difficulty'];
  stem: string;
  options: string[];
  answerIndex: number;
  explanation: string;
  badge?: Question['badge'];
  whyWrong: string[];
};

function lean(q: Question): LeanQuestion {
  return {
    id: q.id,
    subject: q.subject,
    topic: q.topic,
    difficulty: q.difficulty,
    stem: q.stem,
    options: q.options,
    answerIndex: q.answerIndex,
    explanation: q.explanation,
    badge: q.badge,
    whyWrong: q.whyWrong,
  };
}

let cached: { version: string; questions: LeanQuestion[] } | null = null;

function bank(): { version: string; questions: LeanQuestion[] } {
  if (cached) return cached;
  const questions = allQuestions().map(lean);
  const version = createHash('sha256').update(JSON.stringify(questions)).digest('hex').slice(0, 16);
  cached = { version, questions };
  return cached;
}

export function GET(req: Request): Response {
  const { version, questions } = bank();
  const etag = `"${version}"`;

  const inm = req.headers.get('if-none-match');
  if (inm && inm === etag) {
    return new Response(null, {
      status: 304,
      headers: { etag, 'cache-control': 'public, max-age=300, stale-while-revalidate=86400' },
    });
  }

  return json(
    {
      version,
      generatedAt: new Date().toISOString(),
      count: questions.length,
      blueprint: EXAM_BLUEPRINT,
      questions,
    },
    { headers: { etag, 'cache-control': 'public, max-age=300, stale-while-revalidate=86400' } }
  );
}
