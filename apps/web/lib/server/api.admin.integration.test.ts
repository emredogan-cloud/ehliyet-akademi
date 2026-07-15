/**
 * Admin/CMS entegrasyon testleri — RBAC + içerik hattı + medya + denetim (PGlite bellek-içi).
 */
import { describe, it, expect } from 'vitest';
import { POST as register } from '@/app/api/auth/register/route';
import { GET as contentList, POST as contentCreate } from '@/app/api/admin/content/route';
import {
  GET as contentGet,
  PUT as contentUpdate,
  PATCH as contentTransition,
} from '@/app/api/admin/content/[id]/route';
import { GET as mediaList, POST as mediaUpload } from '@/app/api/admin/media/route';
import { GET as mediaServe } from '@/app/api/media/[id]/route';
import { GET as usersList, PUT as usersRole } from '@/app/api/admin/users/route';
import { GET as auditList } from '@/app/api/admin/audit/route';
import { GET as statsGet } from '@/app/api/admin/stats/route';

const BASE = 'http://test.local';
const j = (b: unknown) => JSON.stringify(b);
function post(path: string, body: unknown, cookie?: string): Request {
  return new Request(BASE + path, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...(cookie ? { cookie } : {}) },
    body: j(body),
  });
}
function put(path: string, body: unknown, cookie?: string): Request {
  return new Request(BASE + path, {
    method: 'PUT',
    headers: { 'content-type': 'application/json', ...(cookie ? { cookie } : {}) },
    body: j(body),
  });
}
function patch(path: string, body: unknown, cookie?: string): Request {
  return new Request(BASE + path, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json', ...(cookie ? { cookie } : {}) },
    body: j(body),
  });
}
function get(path: string, cookie?: string): Request {
  return new Request(BASE + path, { headers: cookie ? { cookie } : {} });
}
const cookieOf = (r: Response) => (r.headers.get('set-cookie') ?? '').split(';')[0] ?? '';

const T = Date.now();
let adminCookie = '';
let userCookie = '';
let contentId = '';
let mediaId = '';
let normalUserId = '';

const ARTICLE = {
  type: 'article',
  slug: `sinav-rehberi-${T}`,
  title: 'e-Sınav Başvuru Rehberi',
  payload: {
    title: 'e-Sınav Başvuru Rehberi',
    summary: 'Başvurudan sınav gününe adım adım süreç.',
    body: 'Bu rehber; başvuru, randevu, sınav merkezi ve sonuç adımlarını tek tek anlatır.',
  },
};

describe('RBAC bootstrap', () => {
  it('ilk kullanıcı otomatik admin; ikincisi normal user', async () => {
    const r1 = await register(
      post('/api/auth/register', {
        email: `adm-${T}@ea.dev`,
        password: 'parola-123',
        name: 'Admin',
      })
    );
    expect(r1.status).toBe(201);
    expect(((await r1.json()) as { user: { role: string } }).user.role).toBe('admin');
    adminCookie = cookieOf(r1);

    const r2 = await register(
      post('/api/auth/register', { email: `usr-${T}@ea.dev`, password: 'parola-123', name: 'Aday' })
    );
    const u2 = (await r2.json()) as { user: { role: string; id: string } };
    expect(u2.user.role).toBe('user');
    normalUserId = u2.user.id;
    userCookie = cookieOf(r2);
  });

  it('normal kullanıcı admin uçlarında 403; oturumsuz 401', async () => {
    expect((await contentList(get('/api/admin/content', userCookie))).status).toBe(403);
    expect((await contentList(get('/api/admin/content'))).status).toBe(401);
    expect((await usersList(get('/api/admin/users', userCookie))).status).toBe(403);
  });
});

describe('içerik hattı (Epic 2)', () => {
  it('geçersiz payload 400 + hata listesi; geçerli taslak 201', async () => {
    const bad = await contentCreate(
      post('/api/admin/content', { ...ARTICLE, payload: { title: 'x' } }, adminCookie)
    );
    expect(bad.status).toBe(400);
    expect(((await bad.json()) as { errors: string[] }).errors.length).toBeGreaterThan(0);

    const ok = await contentCreate(post('/api/admin/content', ARTICLE, adminCookie));
    expect(ok.status).toBe(201);
    contentId = ((await ok.json()) as { id: string }).id;
  });

  it('güncelleme yeni sürüm üretir', async () => {
    const r = await contentUpdate(
      put(`/api/admin/content/${contentId}`, { title: 'e-Sınav Rehberi (v2)' }, adminCookie)
    );
    expect(((await r.json()) as { version: number }).version).toBe(2);
  });

  it('onaysız yayın REDDEDİLİR; doğru akış draft→in_review→approved→published', async () => {
    const skip = await contentTransition(
      patch(`/api/admin/content/${contentId}`, { to: 'published' }, adminCookie)
    );
    expect(skip.status).toBe(400);

    for (const to of ['in_review', 'approved', 'published']) {
      const r = await contentTransition(
        patch(`/api/admin/content/${contentId}`, { to }, adminCookie)
      );
      expect(r.status, to).toBe(200);
    }
    const item = (await (
      await contentGet(get(`/api/admin/content/${contentId}`, adminCookie))
    ).json()) as {
      item: { status: string; versions: unknown[] };
    };
    expect(item.item.status).toBe('published');
    expect(item.item.versions.length).toBeGreaterThanOrEqual(4); // create + update + 3 geçiş
  });
});

describe('medya (Epic 4)', () => {
  it('SVG yükle → listede → halka açık uçtan doğru mime ile servis edilir', async () => {
    const svg =
      '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><rect width="10" height="10" fill="teal"/></svg>';
    const up = await mediaUpload(
      post(
        '/api/admin/media',
        {
          filename: 'isaret.svg',
          mime: 'image/svg+xml',
          dataBase64: Buffer.from(svg).toString('base64'),
          alt: 'Deneme işareti',
        },
        adminCookie
      )
    );
    expect(up.status).toBe(201);
    mediaId = ((await up.json()) as { id: string }).id;

    const list = (await (await mediaList(get('/api/admin/media', adminCookie))).json()) as {
      items: Array<{ id: string }>;
    };
    expect(list.items.some((m) => m.id === mediaId)).toBe(true);

    const served = await mediaServe(get(`/api/media/${mediaId}`));
    expect(served.status).toBe(200);
    expect(served.headers.get('content-type')).toBe('image/svg+xml');
    expect(await served.text()).toContain('<svg');
  });

  it('desteklenmeyen mime reddedilir', async () => {
    const bad = await mediaUpload(
      post(
        '/api/admin/media',
        { filename: 'a.exe', mime: 'application/x-msdownload', dataBase64: 'aaaa' },
        adminCookie
      )
    );
    expect(bad.status).toBe(400);
  });
});

describe('kullanıcılar + denetim + istatistik (Epic 3)', () => {
  it('admin rol atar (editor); kendi adminliğini düşüremez', async () => {
    const ok = await usersRole(
      put('/api/admin/users', { userId: normalUserId, role: 'editor' }, adminCookie)
    );
    expect(ok.status).toBe(200);
    // editor artık içerik listeleyebilir
    expect((await contentList(get('/api/admin/content', userCookie))).status).toBe(200);

    const meRow = (await (await usersList(get('/api/admin/users', adminCookie))).json()) as {
      items: Array<{ role: string; email: string; id: string }>;
    };
    const self = meRow.items.find((u) => u.email.startsWith('adm-'))!;
    const deny = await usersRole(
      put('/api/admin/users', { userId: self.id, role: 'user' }, adminCookie)
    );
    expect(deny.status).toBe(400);
  });

  it('denetim kaydı yazılmış; istatistikler tutarlı', async () => {
    const audit = (await (await auditList(get('/api/admin/audit', adminCookie))).json()) as {
      items: Array<{ action: string }>;
    };
    const actions = audit.items.map((a) => a.action);
    expect(actions).toContain('content.create');
    expect(actions).toContain('content.published');
    expect(actions).toContain('media.upload');
    expect(actions).toContain('user.role');

    const stats = (await (await statsGet(get('/api/admin/stats', adminCookie))).json()) as {
      stats: { content: number; published: number; media: number; users: number };
    };
    expect(stats.stats.content).toBeGreaterThanOrEqual(1);
    expect(stats.stats.published).toBeGreaterThanOrEqual(1);
    expect(stats.stats.media).toBeGreaterThanOrEqual(1);
    expect(stats.stats.users).toBeGreaterThanOrEqual(2);
  });
});
