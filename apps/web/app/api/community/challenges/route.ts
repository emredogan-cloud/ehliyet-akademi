import { and, eq } from 'drizzle-orm';
import { getDb, challenges, challengeProgress, communityStats } from '@ea/db';
import { getSessionUser, json, guarded } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import {
  challengeProgressValue,
  isChallengeActive,
  type ChallengeMetric,
} from '@/lib/server/groups';
import { hasCommunityProfile } from '@/lib/server/social-guards';

/**
 * Meydan okumalar (Evolution Faz E10).
 *
 * SUNUCU TANIMLIDIR: istemci meydan okuma OLUŞTURAMAZ, yalnız katılır. İlerleme istemciden
 * BİLDİRİLMEZ — E8'de kırpılmış `community_stats` sayaçlarından türetilir. Böylece meydan okuma
 * yeni bir hile yüzeyi açmaz; mevcut anti-hile tavanı olduğu gibi geçerlidir.
 *
 * TABAN (`baseline`): katılım anındaki sayaç. İlerleme `güncel − taban` → geçmişte kazanılmış XP
 * meydan okumayı anında bitiremez.
 */

function counterFor(
  stats: { xp: number; answered: number; lessons: number; exams: number } | undefined,
  metric: string
): number {
  if (!stats) return 0;
  const m = metric as ChallengeMetric;
  return m === 'xp'
    ? stats.xp
    : m === 'answered'
      ? stats.answered
      : m === 'lessons'
        ? stats.lessons
        : m === 'exams'
          ? stats.exams
          : 0;
}

/** Etkin meydan okumalar + benim ilerlemem. */
export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const db = await getDb();
  const now = new Date();
  const all = await db.select().from(challenges);
  const active = all.filter((c) => isChallengeActive(c, now));

  const [stats] = await db
    .select()
    .from(communityStats)
    .where(eq(communityStats.userId, user.id))
    .limit(1);
  const mine = await db
    .select()
    .from(challengeProgress)
    .where(eq(challengeProgress.userId, user.id));
  const byChallenge = new Map(mine.map((p) => [p.challengeId, p]));

  return json({
    challenges: active
      .map((c) => {
        const p = byChallenge.get(c.id);
        const current = counterFor(stats, c.metric);
        const progress = p
          ? challengeProgressValue(current, p.baseline, c.target)
          : { value: 0, percent: 0, done: false };
        return {
          id: c.id,
          slug: c.slug,
          title: c.title,
          description: c.description,
          metric: c.metric,
          target: c.target,
          licence: c.licence,
          endsAt: c.endsAt,
          joined: Boolean(p),
          value: progress.value,
          percent: progress.percent,
          done: progress.done,
        };
      })
      .sort((a, b) => a.endsAt.getTime() - b.endsAt.getTime()),
  });
});

/** Meydan okumaya katıl — katılım anındaki sayaç TABAN olarak yazılır. */
export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, {
    bucket: 'community-challenges',
    limit: 20,
    windowMs: 60_000,
  });
  if (limited) return limited;

  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });
  if (!(await hasCommunityProfile(user.id))) {
    return json({ error: 'Önce topluluğa katılmalısın.' }, { status: 409 });
  }

  let body: { challengeId?: unknown };
  try {
    body = (await req.json()) as typeof body;
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const challengeId = typeof body.challengeId === 'string' ? body.challengeId : '';
  if (!challengeId) return json({ error: 'Meydan okuma gerekli.' }, { status: 400 });

  const db = await getDb();
  const [c] = await db.select().from(challenges).where(eq(challenges.id, challengeId)).limit(1);
  if (!c) return json({ error: 'Meydan okuma bulunamadı.' }, { status: 404 });
  if (!isChallengeActive(c, new Date())) {
    return json({ error: 'Bu meydan okuma etkin değil.' }, { status: 409 });
  }

  const [existing] = await db
    .select()
    .from(challengeProgress)
    .where(
      and(eq(challengeProgress.challengeId, challengeId), eq(challengeProgress.userId, user.id))
    )
    .limit(1);
  if (existing) return json({ error: 'Zaten katıldın.', joined: true }, { status: 409 });

  const [stats] = await db
    .select()
    .from(communityStats)
    .where(eq(communityStats.userId, user.id))
    .limit(1);
  const baseline = counterFor(stats, c.metric);

  await db
    .insert(challengeProgress)
    .values({ challengeId, userId: user.id, baseline })
    .onConflictDoNothing();

  return json({ joined: true, baseline, target: c.target }, { status: 201 });
});
