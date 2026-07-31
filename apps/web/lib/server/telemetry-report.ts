/**
 * Beta Faz 8 — toplanan telemetriyi OKUNABİLİR hâle getiren toplama katmanı.
 *
 * ## Neden gerekliydi
 *
 * Faz 3 ve 4 veri TOPLUYORDU ama okuyacak hiçbir yüzey yoktu. Yazılıp okunmayan telemetri en kötü
 * durumdur: maliyeti (istemci karmaşıklığı, ağ, depolama, KVKK yükümlülüğü) ödenir, faydası
 * alınmaz. Üstelik bozulduğunda fark edilmez — kimse bakmadığı için sayıların durduğu bile
 * görülmez.
 *
 * ## Neden SQL değil Drizzle + bellek toplama
 *
 * Sayılar küçük (beta ölçeği) ve iki sürücü var: PGlite (yerel/test) ve Postgres (üretim). Lehçeye
 * özgü SQL (`date_trunc`, `filter`) ikisinde de aynı davranmıyor ve testte doğrulanamıyor. Satırları
 * çekip Dart/TS tarafında toplamak, ölçek büyüyene kadar doğru karardır — büyüdüğünde bu dosya
 * SQL'e taşınır, çağıranlar değişmez.
 */
import { and, gte, sql } from 'drizzle-orm';
import { getDb, analyticsEvents, errorReports, referrals, referralVisits } from '@ea/db';
import { KNOWN_EVENTS } from '@/lib/server/telemetry';

/** Kaç günlük pencereye bakılıyor. */
export const DEFAULT_WINDOW_DAYS = 30;

export interface EventCount {
  name: string;
  total: number;
  /** Kaç FARKLI cihaz/kullanıcı. Toplam sayı, tek bir kullanıcının tekrarıyla şişebilir. */
  uniqueActors: number;
}

export interface FunnelStep {
  label: string;
  value: number;
  /** Bir önceki basamağa göre dönüşüm (ilk basamakta null). */
  conversion: number | null;
}

export interface ErrorGroup {
  fingerprint: string;
  kind: string;
  message: string;
  route: string;
  count: number;
  affectedActors: number;
  lastSeen: Date;
  appVersions: string[];
}

/** Olay adı → toplam ve tekil aktör sayısı. */
export async function eventCounts(windowDays = DEFAULT_WINDOW_DAYS): Promise<EventCount[]> {
  const db = await getDb();
  const since = new Date(Date.now() - windowDays * 86400_000);
  const rows = await db
    .select({
      name: analyticsEvents.name,
      userId: analyticsEvents.userId,
      anonId: analyticsEvents.anonId,
    })
    .from(analyticsEvents)
    .where(gte(analyticsEvents.at, since));

  const byName = new Map<string, { total: number; actors: Set<string> }>();
  for (const r of rows) {
    const entry = byName.get(r.name) ?? { total: 0, actors: new Set<string>() };
    entry.total++;
    // Oturum açmış kullanıcı `userId` ile, misafir `anonId` ile sayılır. İkisi karışırsa aynı kişi
    // iki kez sayılır — giriş yapan bir kullanıcı hem misafirken hem sonra olay göndermiştir.
    entry.actors.add(r.userId ?? `anon:${r.anonId}`);
    byName.set(r.name, entry);
  }

  // Sözlükteki AMA HİÇ GELMEYEN olaylar da sıfırla listelenir. Listede olmaması ile sıfır olması
  // farklı şeylerdir: birincisi "ölçüm kopmuş olabilir", ikincisi "kimse yapmıyor".
  const out: EventCount[] = KNOWN_EVENTS.map((name) => ({
    name,
    total: byName.get(name)?.total ?? 0,
    uniqueActors: byName.get(name)?.actors.size ?? 0,
  }));
  out.sort((a, b) => b.total - a.total);
  return out;
}

/**
 * Ürün hunisi — kurulumdan satın almaya.
 *
 * Basamaklar TEKİL AKTÖR sayar, toplam olay değil: "kaç kişi" sorusunun cevabı budur. Toplam olayla
 * hesaplansa, sınavı beş kez çözen bir kullanıcı huniyi beş kişi gibi genişletirdi.
 */
export async function productFunnel(windowDays = DEFAULT_WINDOW_DAYS): Promise<FunnelStep[]> {
  const counts = new Map((await eventCounts(windowDays)).map((c) => [c.name, c.uniqueActors]));
  const steps: Array<{ label: string; event: string }> = [
    { label: 'Uygulamayı açtı', event: 'app_opened' },
    { label: 'İlk sınavını çözdü', event: 'first_exam' },
    { label: 'Kayıt oldu', event: 'registration' },
    { label: 'Ödeme ekranını gördü', event: 'premium_screen_viewed' },
    { label: 'Satın almayı başlattı', event: 'purchase_started' },
    { label: 'Satın almayı tamamladı', event: 'purchase_completed' },
  ];

  return steps.map((s, i) => {
    const value = counts.get(s.event) ?? 0;
    const prev = i === 0 ? null : (counts.get(steps[i - 1]!.event) ?? 0);
    return {
      label: s.label,
      value,
      conversion: prev === null || prev === 0 ? null : value / prev,
    };
  });
}

/**
 * Davet hunisi — bağlantı açılışından nitelikli davete.
 *
 * Faz 1'de eklenen `referral_visits` olmadan bu hunini ilk basamağı görünmüyordu; "kaç kişi
 * bağlantıyı açıp vazgeçti" sorusu cevapsızdı.
 */
export async function referralFunnel(windowDays = DEFAULT_WINDOW_DAYS): Promise<FunnelStep[]> {
  const db = await getDb();
  const since = new Date(Date.now() - windowDays * 86400_000);

  const visits = await db
    .select({ id: referralVisits.id })
    .from(referralVisits)
    .where(gte(referralVisits.at, since));
  const all = await db
    .select({ status: referrals.status })
    .from(referrals)
    .where(gte(referrals.createdAt, since));

  const signed = all.length;
  const qualified = all.filter((r) => r.status === 'qualified').length;

  const step = (label: string, value: number, prev: number | null): FunnelStep => ({
    label,
    value,
    conversion: prev === null || prev === 0 ? null : value / prev,
  });

  return [
    step('Davet bağlantısı açıldı', visits.length, null),
    step('Kayıt oldu', signed, visits.length),
    step('E-postasını doğruladı (nitelikli)', qualified, signed),
  ];
}

/**
 * Hata raporlarını PARMAK İZİNE göre grupla.
 *
 * Ham liste işe yaramaz: bir çökme döngüsü listeyi tek başına doldurur ve altındaki nadir ama
 * ciddi hata görünmez. Gruplama, "kaç FARKLI hatamız var" ve "hangisi kaç kişiyi etkiliyor"
 * sorularını cevaplar — öncelik sırası bu ikincisinden çıkar.
 */
export async function errorGroups(
  windowDays = DEFAULT_WINDOW_DAYS,
  limit = 50
): Promise<ErrorGroup[]> {
  const db = await getDb();
  const since = new Date(Date.now() - windowDays * 86400_000);
  const rows = await db
    .select({
      fingerprint: errorReports.fingerprint,
      kind: errorReports.kind,
      message: errorReports.message,
      route: errorReports.route,
      userId: errorReports.userId,
      anonId: errorReports.anonId,
      appVersion: errorReports.appVersion,
      at: errorReports.at,
    })
    .from(errorReports)
    .where(gte(errorReports.at, since));

  const groups = new Map<
    string,
    {
      kind: string;
      message: string;
      route: string;
      count: number;
      actors: Set<string>;
      lastSeen: Date;
      versions: Set<string>;
    }
  >();

  for (const r of rows) {
    const g = groups.get(r.fingerprint) ?? {
      kind: r.kind,
      message: r.message,
      route: r.route,
      count: 0,
      actors: new Set<string>(),
      lastSeen: r.at,
      versions: new Set<string>(),
    };
    g.count++;
    g.actors.add(r.userId ?? `anon:${r.anonId}`);
    if (r.at > g.lastSeen) {
      g.lastSeen = r.at;
      // En SON görülen mesaj tutulur: aynı parmak izinin mesajı sürümle değişebilir ve eski
      // metni göstermek yanlış yere baktırır.
      g.message = r.message;
      g.route = r.route;
    }
    if (r.appVersion) g.versions.add(r.appVersion);
    groups.set(r.fingerprint, g);
  }

  return (
    [...groups.entries()]
      .map(([fingerprint, g]) => ({
        fingerprint,
        kind: g.kind,
        message: g.message,
        route: g.route,
        count: g.count,
        affectedActors: g.actors.size,
        lastSeen: g.lastSeen,
        appVersions: [...g.versions].sort(),
      }))
      // ETKİLENEN KİŞİ sayısına göre sırala, toplam sayıya göre değil. Tek bir cihazın döngüye
      // girip bin rapor üretmesi, o hatayı en önemli hata yapmaz.
      .sort((a, b) => b.affectedActors - a.affectedActors || b.count - a.count)
      .slice(0, limit)
  );
}

/** Günlük etkin cihaz/kullanıcı (son [windowDays] gün). */
export async function dailyActive(
  windowDays = 14
): Promise<Array<{ day: string; actors: number }>> {
  const db = await getDb();
  const since = new Date(Date.now() - windowDays * 86400_000);
  const rows = await db
    .select({
      at: analyticsEvents.at,
      userId: analyticsEvents.userId,
      anonId: analyticsEvents.anonId,
    })
    .from(analyticsEvents)
    .where(and(gte(analyticsEvents.at, since), sql`1 = 1`));

  const byDay = new Map<string, Set<string>>();
  for (const r of rows) {
    const day = r.at.toISOString().slice(0, 10);
    const set = byDay.get(day) ?? new Set<string>();
    set.add(r.userId ?? `anon:${r.anonId}`);
    byDay.set(day, set);
  }
  return [...byDay.entries()]
    .map(([day, actors]) => ({ day, actors: actors.size }))
    .sort((a, b) => a.day.localeCompare(b.day));
}
