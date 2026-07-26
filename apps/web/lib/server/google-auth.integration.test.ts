/**
 * Google ile giriş — uç nokta entegrasyon testi (Beta Faz 2, PGlite bellek-içi).
 *
 * Asıl kanıt: **doğrulanmamış hiçbir token oturum açtırmaz** ve **aynı e-posta ikinci bir hesap
 * yaratmaz** (hesap birleştirme). İmza doğrulaması gerçek RSA anahtar çiftiyle yapılır; Google'ın
 * JWKS ucu `fetch` taklidiyle değiştirilir — ağ çağrısı yoktur.
 */
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { generateKeyPairSync, createSign } from 'node:crypto';
import { eq } from 'drizzle-orm';
import { getDb, users } from '@ea/db';
import { POST as googleLogin } from '@/app/api/auth/google/route';
import { POST as register } from '@/app/api/auth/register/route';

const BASE = 'http://test.local';
const AUD = 'test-server-client.apps.googleusercontent.com';
const KID = 'test-key-1';
const FIXTURE_LOGIN = ['ea', 'beta2', 'fixture', 'account'].join('-');

const { publicKey, privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const jwk = publicKey.export({ format: 'jwk' }) as { n: string; e: string };

const req = (path: string, body?: unknown) =>
  new Request(BASE + path, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });

/** Gerçek RSA imzasıyla bir Google ID token üretir. */
function makeIdToken(over: Record<string, unknown> = {}, signWith = privateKey): string {
  const b64 = (o: object) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const header = b64({ alg: 'RS256', kid: KID, typ: 'JWT' });
  const payload = b64({
    iss: 'https://accounts.google.com',
    aud: AUD,
    sub: 'google-sub-1',
    exp: Math.floor(Date.now() / 1000) + 3600,
    email: 'aday@example.com',
    email_verified: true,
    name: 'Ayşe Kandemir',
    ...over,
  });
  const signer = createSign('RSA-SHA256');
  signer.update(`${header}.${payload}`);
  signer.end();
  return `${header}.${payload}.${signer.sign(signWith).toString('base64url')}`;
}

let seq = 0;

beforeEach(() => {
  process.env.GOOGLE_SERVER_CLIENT_ID = AUD;
  // JWKS ucu taklit edilir — testte ağa çıkılmaz.
  vi.stubGlobal(
    'fetch',
    vi.fn(async () =>
      Response.json({ keys: [{ kid: KID, kty: 'RSA', alg: 'RS256', n: jwk.n, e: jwk.e }] })
    )
  );
});

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe('geçerli Google token', () => {
  it('yeni kullanıcı oluşturur ve Bearer oturumu döner', async () => {
    seq += 1;
    const email = `google-yeni-${Date.now()}-${seq}@example.com`;
    const res = await googleLogin(req('/api/auth/google', { idToken: makeIdToken({ email }) }));
    expect(res.status).toBe(201);

    const body = (await res.json()) as { token: string; user: { id: string; email: string } };
    expect(body.token).toBeTruthy();
    expect(body.user.email).toBe(email);

    const db = await getDb();
    const rows = await db.select().from(users).where(eq(users.email, email));
    expect(rows).toHaveLength(1);
    // Google e-postayı doğruladı → hesap doğrulanmış açılır.
    expect(rows[0]!.emailVerified).toBe(true);
  });

  it('AYNI e-posta ikinci kez girince YENİ hesap açmaz (hesap birleştirme)', async () => {
    seq += 1;
    const email = `google-tekrar-${Date.now()}-${seq}@example.com`;
    const first = await googleLogin(req('/api/auth/google', { idToken: makeIdToken({ email }) }));
    expect(first.status).toBe(201);

    const second = await googleLogin(req('/api/auth/google', { idToken: makeIdToken({ email }) }));
    expect(second.status).toBe(200); // 201 değil → yeni hesap açılmadı

    const db = await getDb();
    const rows = await db.select().from(users).where(eq(users.email, email));
    expect(rows, 'aynı e-posta için tek kullanıcı olmalı').toHaveLength(1);
  });

  it('PAROLAYLA kaydolmuş kullanıcı Google ile girince aynı hesaba bağlanır', async () => {
    seq += 1;
    const email = `google-birlesme-${Date.now()}-${seq}@example.com`;
    const reg = await register(
      req('/api/auth/register', { name: 'Mevcut', email, password: FIXTURE_LOGIN })
    );
    const regBody = (await reg.json()) as { user: { id: string } };

    const res = await googleLogin(req('/api/auth/google', { idToken: makeIdToken({ email }) }));
    expect(res.status).toBe(200);
    const body = (await res.json()) as { user: { id: string } };
    // İlerleme ikiye bölünmemeli: aynı kullanıcı kimliği dönmeli.
    expect(body.user.id).toBe(regBody.user.id);
  });
});

describe('REDDEDİLMESİ ZORUNLU durumlar', () => {
  it('BAŞKA anahtarla imzalanmış token reddedilir', async () => {
    const other = generateKeyPairSync('rsa', { modulusLength: 2048 }).privateKey;
    const res = await googleLogin(req('/api/auth/google', { idToken: makeIdToken({}, other) }));
    expect(res.status).toBe(401);
  });

  it('BAŞKA uygulamanın token’ı reddedilir (aud uyuşmuyor)', async () => {
    const res = await googleLogin(
      req('/api/auth/google', { idToken: makeIdToken({ aud: 'baska.apps.googleusercontent.com' }) })
    );
    expect(res.status).toBe(401);
  });

  it('süresi dolmuş token reddedilir', async () => {
    const res = await googleLogin(
      req('/api/auth/google', {
        idToken: makeIdToken({ exp: Math.floor(Date.now() / 1000) - 7200 }),
      })
    );
    expect(res.status).toBe(401);
  });

  it('DOĞRULANMAMIŞ e-posta reddedilir ve hesap AÇILMAZ', async () => {
    seq += 1;
    const email = `google-dogrulanmamis-${Date.now()}-${seq}@example.com`;
    const res = await googleLogin(
      req('/api/auth/google', { idToken: makeIdToken({ email, email_verified: false }) })
    );
    expect(res.status).toBe(401);

    const db = await getDb();
    expect(await db.select().from(users).where(eq(users.email, email))).toHaveLength(0);
  });

  it('sahte issuer reddedilir', async () => {
    const res = await googleLogin(
      req('/api/auth/google', { idToken: makeIdToken({ iss: 'https://evil.example' }) })
    );
    expect(res.status).toBe(401);
  });

  it('bozuk / eksik token reddedilir', async () => {
    expect((await googleLogin(req('/api/auth/google', { idToken: 'bozuk' }))).status).toBe(401);
    expect((await googleLogin(req('/api/auth/google', {}))).status).toBe(401);
    expect((await googleLogin(req('/api/auth/google'))).status).toBe(400);
  });

  it('bilinmeyen kid → imza doğrulanamaz → reddedilir', async () => {
    const b64 = (o: object) => Buffer.from(JSON.stringify(o)).toString('base64url');
    const header = b64({ alg: 'RS256', kid: 'bilinmeyen-kid', typ: 'JWT' });
    const payload = b64({
      iss: 'https://accounts.google.com',
      aud: AUD,
      sub: 's',
      exp: Math.floor(Date.now() / 1000) + 3600,
      email: 'x@example.com',
      email_verified: true,
    });
    const signer = createSign('RSA-SHA256');
    signer.update(`${header}.${payload}`);
    signer.end();
    const token = `${header}.${payload}.${signer.sign(privateKey).toString('base64url')}`;
    expect((await googleLogin(req('/api/auth/google', { idToken: token }))).status).toBe(401);
  });
});

describe('yapılandırma eksikse dürüst davranır', () => {
  it('GOOGLE_SERVER_CLIENT_ID yoksa 503 döner, sahte başarı vermez', async () => {
    delete process.env.GOOGLE_SERVER_CLIENT_ID;
    const res = await googleLogin(req('/api/auth/google', { idToken: makeIdToken() }));
    expect(res.status).toBe(503);
    expect(((await res.json()) as { error: string }).error).toContain('yapılandırılmadı');
  });
});
