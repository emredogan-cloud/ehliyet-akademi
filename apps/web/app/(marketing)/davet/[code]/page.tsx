import type { Metadata } from 'next';
import { headers } from 'next/headers';
import { getDb } from '@ea/db';
import { Icon } from '@/components/ui/icons';
import { buildMetadata } from '@/lib/seo/metadata';
import {
  REFERRAL_MILESTONES,
  isValidReferralCodeFormat,
  normalizeReferralCode,
} from '@/lib/referrals';
import { clientIp, recordReferralVisit, referrerPublicInfoByCode } from '@/lib/server/referrals';
import { appInviteIntent, appInviteScheme, playStoreUrl } from '@/lib/app-links';
import { logger } from '@/lib/server/logger';
import { InviteActions } from './InviteActions';

/**
 * Beta Faz 1 — `/davet/<KOD>` davet karşılama sayfası.
 *
 * Bu sayfa OLMADAN davet sistemi yarımdı: uygulama bağlantıyı paylaşıyordu, bağlantı 404 veriyordu.
 * Kod elle de girilebildiği için akış "çalışıyordu", ama bağlantıya tıklayan kişi kırık bir ürün
 * görüyordu — davet edenin arkadaşına gönderdiği ilk izlenim buydu.
 *
 * Sayfanın üç işi var:
 * 1. **Uygulamaya götürmek.** Android'de tek dokunuş: kuruluysa uygulama, değilse Play Store.
 * 2. **Kodu kaybetmemek.** Uygulamaya derin bağlantıyla, web'e `?ref=` ile, en kötü hâlde panoya.
 * 3. **Ziyareti saymak.** Huninin ilk basamağı ölçülmezse "kaç davet işe yaradı" cevaplanamaz.
 *
 * `noindex` BİLİNÇLİ: bunlar kişisel davet bağlantıları. Dizinlemek hem anlamsız (her kod ayrı
 * sayfa) hem de davet edenin adını arama sonuçlarına düşürürdü.
 */
export const dynamic = 'force-dynamic';

export async function generateMetadata({
  params,
}: {
  params: Promise<{ code: string }>;
}): Promise<Metadata> {
  const { code } = await params;
  return buildMetadata({
    title: 'Davet bağlantısı',
    description:
      'Bir arkadaşın seni Ehliyet Akademi’ye davet etti. Uygulamayı indir, davet kodunu kullan.',
    path: `/davet/${normalizeReferralCode(code)}`,
    noindex: true,
  });
}

/** Ödül merdiveninin insan diline çevrilmiş hâli. */
function milestoneLabel(count: number, months: number): string {
  return `${count} arkadaş → ${months} ay premium`;
}

export default async function DavetPage({ params }: { params: Promise<{ code: string }> }) {
  const raw = (await params).code;
  const code = normalizeReferralCode(raw);
  const validFormat = isValidReferralCodeFormat(code);

  // Kodun GERÇEKTEN var olup olmadığını sormak için veritabanı gerekir. Veritabanı yoksa (yerel
  // kurulum, geçici arıza) sayfa YİNE ÇALIŞIR: kod biçimsel olarak geçerliyse davet akışı sürer.
  // Davet sayfasını veritabanı arızasında 500'e düşürmek, davet edenin arkadaşını kaybetmesidir.
  let referrerName: string | null = null;
  let known = false;
  if (validFormat) {
    try {
      const db = await getDb();
      const info = await referrerPublicInfoByCode(db, code);
      referrerName = info.firstName;
      known = info.known;
      const hdrs = await headers();
      await recordReferralVisit({
        db,
        code,
        known,
        ip: clientIp(new Request('https://x/', { headers: hdrs })),
        platform: /android/i.test(hdrs.get('user-agent') ?? '') ? 'android' : 'web',
      });
    } catch (e) {
      logger.warn('referral_visit_unavailable', { err: String(e) });
    }
  }

  const storeUrl = playStoreUrl(validFormat ? `ref=${code}` : undefined);
  const schemeUrl = appInviteScheme(code);
  const intentUrl = appInviteIntent(code, storeUrl);

  if (!validFormat) {
    return (
      <section className="inv" data-testid="invite-invalid">
        <div className="mk-hero inv__hero">
          <div>
            <p className="mk-hero__eyebrow">DAVET BAĞLANTISI</p>
            <h1 className="mk-hero__title">Bu davet kodu okunamadı</h1>
            <p className="mk-hero__lead">
              Bağlantı kopyalanırken eksilmiş olabilir. Davet kodları <strong>8 karakterdir</strong>
              . Kodu sana gönderen kişiden bağlantıyı yeniden istersen, ya da kodu uygulamada kayıt
              olurken elle yazarsan davet işler.
            </p>
            <div className="mk-hero__cta">
              <a className="ui-btn ui-btn--primary ui-btn--lg" href={playStoreUrl()}>
                <Icon name="phone" size={18} /> Uygulamayı indir
              </a>
              <a className="ui-btn ui-btn--ghost ui-btn--lg" href="/">
                Ana sayfa
              </a>
            </div>
          </div>
        </div>
      </section>
    );
  }

  const inviter = referrerName ?? 'Bir arkadaşın';

  return (
    <section className="inv" data-testid="invite-page">
      <div className="mk-hero inv__hero">
        <div>
          <p className="mk-hero__eyebrow">DAVET BAĞLANTISI</p>
          <h1 className="mk-hero__title">
            {inviter} seni <span className="mk-hero__grad">Ehliyet Akademi</span>’ye davet etti
          </h1>
          <p className="mk-hero__lead">
            Sınava hazırlanırken yalnız olmak zorunda değilsin. Hesabını aç, kaldığın yerden devam
            eden bir çalışma planın olsun — davet kodun hazır.
          </p>

          <div className="inv__code" data-testid="invite-code">
            <span className="inv__code-cap">Davet kodu</span>
            <strong className="inv__code-val">{code}</strong>
          </div>

          <InviteActions
            code={code}
            intentUrl={intentUrl}
            storeUrl={storeUrl}
            schemeUrl={schemeUrl}
          />

          {!known && (
            <p className="inv__warn" data-testid="invite-unknown">
              <Icon name="shield" size={15} /> Bu kodu sistemde bulamadık. Kayıt olmana engel değil
              — ama ödül sayılması için kodun doğru olması gerekir.
            </p>
          )}
        </div>

        <aside className="inv__side mk-hero__art">
          <div className="ui-card ui-card--accent ui-card--glow">
            <h2 className="inv__side-title">
              <Icon name="crown" size={18} /> Davet eden de kazanır
            </h2>
            <p className="muted inv__side-lead">
              Seni davet eden kişi, sen <strong>e-postanı doğrulayınca</strong> ödüle bir adım
              yaklaşır. Merdiven şöyle:
            </p>
            <ul className="inv__ladder">
              {REFERRAL_MILESTONES.map((m) => (
                <li key={m.count}>
                  <Icon name="check-circle" size={16} />
                  <span>{milestoneLabel(m.count, m.months)}</span>
                </li>
              ))}
            </ul>
            <p className="muted inv__side-foot">
              Sana bir ücret çıkmaz; hesap açmak ücretsizdir. Premium olmadan da soru çözebilir,
              ders okuyabilir, işaretleri öğrenebilirsin.
            </p>
          </div>

          <div className="ui-card inv__side-what">
            <h2 className="inv__side-title">
              <Icon name="gradcap" size={18} /> Uygulamada ne var
            </h2>
            <ul className="inv__feats">
              <li>
                <Icon name="clipboard" size={16} /> Gerçek e-Sınav formatında denemeler
              </li>
              <li>
                <Icon name="brain" size={16} /> Yanlışlarını doğru zamanda tekrar eden akıllı
                çalışma
              </li>
              <li>
                <Icon name="sign" size={16} /> Trafik işaretleri, araç bilgisi, gösterge lambaları
              </li>
              <li>
                <Icon name="bot" size={16} /> Takıldığın soruyu açıklayan AI Koç
              </li>
            </ul>
          </div>
        </aside>
      </div>
    </section>
  );
}
