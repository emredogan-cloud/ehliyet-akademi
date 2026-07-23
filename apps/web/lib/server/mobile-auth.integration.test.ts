/**
 * Mobil Bearer-token auth entegrasyon testi (QIP mobile Faz 2). Aynı opak oturum token'ı hem çerez
 * hem `Authorization: Bearer` ile çalışır (PGlite bellek-içi).
 */
import { describe, it, expect } from 'vitest';
import { POST as register } from '@/app/api/auth/register/route';
import { POST as login } from '@/app/api/auth/login/route';
import { GET as me } from '@/app/api/auth/me/route';

const BASE = 'http://test.local';
const post = (path: string, body: unknown) =>
  new Request(BASE + path, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
const bearer = (path: string, token: string) =>
  new Request(BASE + path, { headers: { authorization: `Bearer ${token}` } });

describe('mobil Bearer token auth', () => {
  const email = `mobile-${Date.now()}@ea.dev`;
  const password = 'mobil-parola-123';

  it('register token döner + Bearer ile /me çalışır (çerezsiz)', async () => {
    const reg = await register(post('/api/auth/register', { name: 'Mobil', email, password }));
    expect(reg.status).toBe(201);
    const rb = (await reg.json()) as { token: string; user: { email: string } };
    expect(rb.token).toMatch(/^[a-f0-9]{64}$/);

    const meRes = await me(bearer('/api/auth/me', rb.token));
    expect(meRes.status).toBe(200);
    const mb = (await meRes.json()) as { user: { email: string } | null };
    expect(mb.user?.email).toBe(email);
  });

  it('login token döner + Bearer ile /me çalışır', async () => {
    const lg = await login(post('/api/auth/login', { email, password }));
    expect(lg.status).toBe(200);
    const lb = (await lg.json()) as { token: string };
    expect(lb.token).toMatch(/^[a-f0-9]{64}$/);
    const meRes = await me(bearer('/api/auth/me', lb.token));
    expect(meRes.status).toBe(200);
  });

  it('geçersiz Bearer → 401', async () => {
    const meRes = await me(bearer('/api/auth/me', 'a'.repeat(64)));
    expect(meRes.status).toBe(401);
    expect(((await meRes.json()) as { user: null }).user).toBeNull();
  });

  it('Bearer başlığı yoksa → 401', async () => {
    const meRes = await me(new Request(`${BASE}/api/auth/me`));
    expect(meRes.status).toBe(401);
  });
});
