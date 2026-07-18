/**
 * PROGRAM SEO — halka açık rota manifesti (audit + dokümantasyon için tek kaynak).
 * `hasTitle`/`selfCanonical`: sayfanın kendi metadata/canonical'ını verip vermediği.
 * Dinamik rotalar (`dynamic:true`) içerik koleksiyonundan üretilir; sayıları audit'te açılır.
 */
export interface RouteDef {
  path: string;
  indexable: boolean;
  dynamic?: boolean;
  hasTitle: boolean;
  selfCanonical: boolean;
  title?: string;
  description?: string;
}

/** Statik + dinamik-şablon halka açık rotalar. Kişisel/oturum/admin rotaları indexable:false. */
export const PUBLIC_ROUTES: RouteDef[] = [
  {
    path: '/',
    indexable: true,
    hasTitle: true,
    selfCanonical: true,
    title: 'B Sınıfı Ehliyet Sınavına Akıllı Hazırlık',
  },
  {
    path: '/dersler',
    indexable: true,
    hasTitle: true,
    selfCanonical: true,
    title: 'Dersler',
  },
  {
    path: '/isaretler',
    indexable: true,
    hasTitle: true,
    selfCanonical: true,
    title: 'Trafik İşaretleri — Anlamları ve Açıklamaları',
  },
  {
    path: '/arac',
    indexable: true,
    hasTitle: true,
    selfCanonical: true,
    title: 'Araç Tanıma',
  },
  {
    path: '/e-sinav',
    indexable: true,
    hasTitle: true,
    selfCanonical: true,
    title: 'e-Sınav Hazırlık',
  },
  {
    path: '/deneme-sinavi',
    indexable: true,
    hasTitle: true,
    selfCanonical: true,
    title: 'Deneme Sınavı (e-Sınav Simülatörü)',
  },
  {
    path: '/gorsel-quiz',
    indexable: true,
    hasTitle: true,
    selfCanonical: true,
    title: 'Görsel Trafik İşareti Quizi',
  },
  {
    path: '/senaryolar',
    indexable: true,
    hasTitle: true,
    selfCanonical: true,
    title: 'Trafik Senaryoları — İnteraktif Karar',
  },
  {
    path: '/videolar',
    indexable: true,
    hasTitle: true,
    selfCanonical: true,
    title: 'Video Dersler',
  },
  { path: '/tani', indexable: true, hasTitle: true, selfCanonical: true, title: 'Tanı Denemesi' },
  {
    path: '/calis',
    indexable: true,
    hasTitle: true,
    selfCanonical: true,
    title: 'Akıllı Çalışma (SRS)',
  },
  {
    path: '/hazirlik-skorum',
    indexable: true,
    hasTitle: true,
    selfCanonical: true,
    title: 'Hazırlık Skorum',
  },
  { path: '/ai-koc', indexable: true, hasTitle: true, selfCanonical: true, title: 'AI Koç' },
  {
    path: '/fiyatlandirma',
    indexable: true,
    hasTitle: true,
    selfCanonical: true,
    title: 'Fiyatlandırma — Bir Kez Öde, Ömür Boyu',
  },
  {
    path: '/gizlilik',
    indexable: true,
    hasTitle: true,
    selfCanonical: true,
    title: 'Gizlilik Politikası',
  },
  {
    path: '/kvkk',
    indexable: true,
    hasTitle: true,
    selfCanonical: true,
    title: 'KVKK Aydınlatma Metni',
  },
  {
    path: '/cerez-politikasi',
    indexable: true,
    hasTitle: true,
    selfCanonical: true,
    title: 'Çerez Politikası',
  },
  {
    path: '/kullanim-kosullari',
    indexable: true,
    hasTitle: true,
    selfCanonical: true,
    title: 'Kullanım Koşulları',
  },
  // Dinamik şablonlar (içerikten üretilir).
  { path: '/dersler/[slug]', indexable: true, dynamic: true, hasTitle: true, selfCanonical: true },
  { path: '/isaretler/[id]', indexable: true, dynamic: true, hasTitle: true, selfCanonical: true },
  { path: '/arac/[id]', indexable: true, dynamic: true, hasTitle: true, selfCanonical: true },
  // İndekslenmeyen (kişisel/oturum/admin) — sitemap dışı, robots disallow.
  { path: '/panel', indexable: false, hasTitle: true, selfCanonical: true },
  { path: '/profil', indexable: false, hasTitle: false, selfCanonical: false },
  { path: '/ayarlar', indexable: false, hasTitle: false, selfCanonical: false },
  { path: '/ilerleme', indexable: false, hasTitle: false, selfCanonical: false },
  { path: '/basarilar', indexable: false, hasTitle: false, selfCanonical: false },
  { path: '/calisma-plani', indexable: false, hasTitle: false, selfCanonical: false },
  { path: '/arama', indexable: false, hasTitle: true, selfCanonical: true },
  { path: '/giris', indexable: false, hasTitle: false, selfCanonical: false },
  { path: '/dogrula', indexable: false, hasTitle: false, selfCanonical: false },
  { path: '/sifirla', indexable: false, hasTitle: false, selfCanonical: false },
];
