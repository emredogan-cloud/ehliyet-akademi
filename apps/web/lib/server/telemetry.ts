/**
 * Beta Faz 3/4 — istemciden gelen telemetrinin (analitik olayları + hata raporları) DOĞRULAMA ve
 * yazma katmanı.
 *
 * Bu uç noktalar **oturum gerektirmez**: misafir kullanım gerçek bir kitledir ve ölçülmesi
 * gerekir; ilk çöken açılışta henüz oturum da yoktur. Oturum yoksa kayıt anonim (`anonId`) gider.
 *
 * Oturum gerektirmeyen bir yazma ucu, kötüye kullanılabilir bir yüzeydir. Savunma üç katmanlı:
 * 1. **Hız sınırı** (uç noktada) — IP başına dakikada kaç istek.
 * 2. **Boyut sınırı** — parti başına kayıt, alan başına karakter, `props` anahtar sayısı.
 * 3. **Sözlük dışı olay reddi** — bilinmeyen bir olay adı sessizce ATILIR (400 değil): eski bir
 *    uygulama sürümü artık kullanılmayan bir olayı gönderirse istemciyi sonsuz yeniden denemeye
 *    sokmak istemeyiz.
 */
import { getDb, analyticsEvents, errorReports } from '@ea/db';
import { getSessionUser } from '@/lib/server/auth';
import { logger } from '@/lib/server/logger';

/** Tek istekte kabul edilen kayıt sayısı (istemcinin parti boyutuyla aynı). */
export const MAX_BATCH = 50;
const MAX_NAME = 64;
const MAX_ID = 64;
const MAX_TEXT = 400;
const MAX_STACK = 8000;
const MAX_PROPS_KEYS = 24;

/**
 * İSTEMCİDEKİ sözlükle aynı olmak ZORUNDA: `apps/mobile/lib/core/analytics/analytics_event.dart`.
 *
 * Beyaz liste, "kim ne gönderirse yazılır" durumunu kapatır: sözlük dışı bir ad ile tabloyu
 * şişirmek mümkün olmaz ve pano yalnız anlamı bilinen olayları sayar.
 */
export const KNOWN_EVENTS: readonly string[] = [
  'app_installed',
  'first_launch',
  'app_opened',
  'coach_marks_started',
  'coach_marks_completed',
  'coach_marks_skipped',
  'registration',
  'login',
  'google_login',
  'guest_session',
  'logout',
  'account_deleted',
  'first_exam',
  'exam_completed',
  'exam_passed',
  'exam_failed',
  'ai_coach_started',
  'ai_coach_session_length',
  'progress_screen',
  'premium_screen_viewed',
  'purchase_started',
  'purchase_completed',
  'purchase_abandoned',
  'restore_purchases',
  'referral_created',
  'referral_link_opened',
  'referral_accepted',
  'badge_earned',
  'badge_shared',
  'app_rated',
];

const KNOWN_EVENT_SET = new Set(KNOWN_EVENTS);

/** Hata raporu türleri — istemcideki `ErrorKind` ile aynı. */
export const KNOWN_ERROR_KINDS: readonly string[] = [
  'flutter',
  'async',
  'platform',
  'network',
  'store',
  'google-signin',
  'isolate',
  'rendering',
];
const KNOWN_ERROR_KIND_SET = new Set(KNOWN_ERROR_KINDS);

function str(v: unknown, max: number): string {
  return typeof v === 'string' ? v.slice(0, max) : '';
}

/** Zamanı ayıkla. Gelecekteki ya da çok eski tarihler ŞİMDİYE çekilir (cihaz saati yanlış olabilir). */
export function safeAt(raw: unknown, now: Date): Date {
  const parsed = typeof raw === 'string' ? new Date(raw) : null;
  if (!parsed || Number.isNaN(parsed.getTime())) return now;
  const ms = parsed.getTime();
  const thirtyDays = 30 * 24 * 3600_000;
  if (ms > now.getTime() + 3600_000) return now; // ileri saatli cihaz
  if (ms < now.getTime() - thirtyDays) return new Date(now.getTime() - thirtyDays);
  return parsed;
}

/**
 * `props` sanitizasyonu — yalnız ilkel değerler, sınırlı anahtar sayısı, kısaltılmış dizeler.
 *
 * İç içe nesne/dizi REDDEDİLİR: hem panoda anlamı yoktur hem de sınırsız derinlik bir saldırı
 * yüzeyidir. Serbest metin de reddedilir çünkü kişisel veri oraya sızar (`MAX_TEXT` yine sınırlar).
 */
export function sanitizeProps(raw: unknown): Record<string, string | number | boolean> {
  const out: Record<string, string | number | boolean> = {};
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return out;
  let keys = 0;
  for (const [k, v] of Object.entries(raw as Record<string, unknown>)) {
    if (keys >= MAX_PROPS_KEYS) break;
    const key = k.slice(0, 40);
    if (typeof v === 'string') out[key] = v.slice(0, 120);
    else if (typeof v === 'number' && Number.isFinite(v)) out[key] = v;
    else if (typeof v === 'boolean') out[key] = v;
    else continue;
    keys++;
  }
  return out;
}

export interface IngestResult {
  /** Yazılan kayıt sayısı. */
  accepted: number;
  /** Sözlük dışı / biçimsiz olduğu için atılan kayıt sayısı. */
  rejected: number;
}

/**
 * Analitik olaylarını yaz.
 *
 * ÇİFT KAYIT: istemci kuyruğu bir partiyi ağ hatasından sonra tekrar gönderebilir. `id` tekil
 * olduğu için ikinci yazma çakışır; çakışma **hata değil beklenen durumdur** ve `onConflictDoNothing`
 * ile yutulur. Kayıp yerine tekrar seçildi (istemci tarafındaki gerekçe: `analytics_sink.dart`).
 */
export async function ingestAnalytics(req: Request, body: unknown): Promise<IngestResult> {
  const events = (body as { events?: unknown })?.events;
  if (!Array.isArray(events)) return { accepted: 0, rejected: 0 };

  const user = await getSessionUser(req).catch(() => null);
  const db = await getDb();
  const now = new Date();
  let accepted = 0;
  let rejected = 0;

  for (const raw of events.slice(0, MAX_BATCH)) {
    if (!raw || typeof raw !== 'object') {
      rejected++;
      continue;
    }
    const e = raw as Record<string, unknown>;
    const id = str(e.id, MAX_ID);
    const name = str(e.name, MAX_NAME);
    if (!id || !KNOWN_EVENT_SET.has(name)) {
      rejected++;
      continue;
    }
    try {
      await db
        .insert(analyticsEvents)
        .values({
          id,
          name,
          // Oturum varsa olay ona bağlanır; istemcinin gönderdiği `userId` GÜVENİLMEZ ve
          // KULLANILMAZ — aksi hâlde herhangi biri başkasının kimliğine olay yazabilirdi.
          userId: user?.id ?? null,
          anonId: str(e.anonId, MAX_ID),
          platform: str(e.platform, 16) || 'android',
          appVersion: str(e.appVersion, 32),
          props: sanitizeProps(e.props),
          at: safeAt(e.at, now),
        })
        .onConflictDoNothing();
      accepted++;
    } catch (err) {
      logger.warn('analytics_insert_failed', { err: String(err) });
      rejected++;
    }
  }
  return { accepted, rejected };
}

/** Hata raporlarını yaz. Aynı doğrulama disiplini; `stack` daha uzun tutulur (teşhis için gerekli). */
export async function ingestErrors(req: Request, body: unknown): Promise<IngestResult> {
  const reports = (body as { reports?: unknown })?.reports;
  if (!Array.isArray(reports)) return { accepted: 0, rejected: 0 };

  const user = await getSessionUser(req).catch(() => null);
  const db = await getDb();
  const now = new Date();
  let accepted = 0;
  let rejected = 0;

  for (const raw of reports.slice(0, MAX_BATCH)) {
    if (!raw || typeof raw !== 'object') {
      rejected++;
      continue;
    }
    const r = raw as Record<string, unknown>;
    const id = str(r.id, MAX_ID);
    const kind = str(r.kind, 32);
    const message = str(r.message, MAX_TEXT);
    if (!id || !KNOWN_ERROR_KIND_SET.has(kind) || !message) {
      rejected++;
      continue;
    }
    try {
      await db
        .insert(errorReports)
        .values({
          id,
          kind,
          fingerprint: str(r.fingerprint, MAX_NAME) || 'unknown',
          message,
          stack: str(r.stack, MAX_STACK),
          route: str(r.route, 120),
          userId: user?.id ?? null,
          anonId: str(r.anonId, MAX_ID),
          platform: str(r.platform, 16) || 'android',
          appVersion: str(r.appVersion, 32),
          context: sanitizeProps(r.context),
          fatal: r.fatal === true,
          at: safeAt(r.at, now),
        })
        .onConflictDoNothing();
      accepted++;
    } catch (err) {
      logger.warn('error_report_insert_failed', { err: String(err) });
      rejected++;
    }
  }
  return { accepted, rejected };
}
