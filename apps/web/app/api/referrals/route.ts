import { getSessionUser, json, guarded } from '@/lib/server/auth';
import { referralSummary } from '@/lib/server/referrals';
import { REFERRAL_MILESTONES, nextMilestone } from '@/lib/referrals';

/**
 * Faz 8 — kullanıcının davet özeti: kodu, davet bağlantısı, sayaçlar ve ödülleri.
 *
 * Kod İLK İSTEKTE ÜRETİLİR (varsa okunur): kayıt akışına ekstra bir adım eklemeye gerek yok ve
 * hiç davet etmeyecek kullanıcılar için satır açılmamış olur.
 */
export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const summary = await referralSummary(user.id);
  const base = process.env.PUBLIC_BASE_URL ?? 'https://www.ehliyetegitim.com';
  return json({
    ...summary,
    link: `${base}/davet/${summary.code}`,
    nextMilestone: nextMilestone(summary.qualified),
    milestones: REFERRAL_MILESTONES,
  });
});
