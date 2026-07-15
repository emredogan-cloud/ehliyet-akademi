/* Ehliyet Akademi — Service Worker (ROADMAP Faz 18).
   Strateji: statik varlıklar cache-first; sayfalar network-first + offline fallback.
   Yalnız üretimde kaydedilir (RegisterSW). */
'use strict';

const CACHE = 'ea-v1';
const PRECACHE = ['/', '/dersler', '/e-sinav', '/fiyatlandirma', '/icon.svg'];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches
      .open(CACHE)
      .then((c) => c.addAll(PRECACHE))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.map((k) => (k !== CACHE ? caches.delete(k) : null))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;

  // Next statik varlıkları: cache-first (içerik-hash'li, güvenli)
  if (url.pathname.startsWith('/_next/static/') || url.pathname === '/icon.svg') {
    e.respondWith(
      caches.match(req).then(
        (hit) =>
          hit ||
          fetch(req).then((res) => {
            const copy = res.clone();
            caches.open(CACHE).then((c) => c.put(req, copy));
            return res;
          })
      )
    );
    return;
  }

  // Sayfalar: network-first, düşerse cache, o da yoksa ana sayfa
  if (req.mode === 'navigate') {
    e.respondWith(
      fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE).then((c) => c.put(req, copy));
          return res;
        })
        .catch(() => caches.match(req).then((hit) => hit || caches.match('/')))
    );
  }
});
