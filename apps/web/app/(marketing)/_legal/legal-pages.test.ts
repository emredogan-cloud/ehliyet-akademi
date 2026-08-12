import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

/**
 * Yasal sayfalar için GERİLEME KORUMASI.
 *
 * 10 Ağustos 2026'da yapılan denetim, `/gizlilik` ve `/kvkk` sayfalarının CANLIDA bir
 * "Taslak belge uyarısı" ve `[Şirket Ünvanı]` gibi köşeli parantezli yer tutucular taşıdığını
 * buldu. Bu, Play'in Kullanıcı Verisi politikası açısından yanlış beyandır ve tek başına bir
 * reddedilme sebebidir.
 *
 * Bu test o durumun geri gelmesini imkânsız kılar: yer tutucu bir kez daha sayfaya girerse test
 * kırılır ve CI kırmızıya döner. İnsan gözü bu tür bir metni kolayca kaçırır — bir kez kaçırdı.
 */

const here = (rel: string) => fileURLToPath(new URL(rel, import.meta.url));

const PAGES = {
  gizlilik: here('../gizlilik/page.tsx'),
  kvkk: here('../kvkk/page.tsx'),
  'hesap-silme': here('../hesap-silme/page.tsx'),
} as const;

/**
 * Blok yorumları çıkar.
 *
 * NEDEN: yasak dizeler KULLANICIYA GÖRÜNEN metinde aranır. Bu dosyaların başındaki geliştirici
 * yorumları, düzeltilen eski ifadeleri (ör. eski "localStorage" cümlesi) tarihe geçirmek için
 * bilerek alıntılar. Yorumları taramak, doğru yapılmış bir düzeltmeyi hata gibi gösterirdi.
 * `//` satır yorumları KASTEN çıkarılmaz: JSX içindeki `https://` bağlantılarını bozardı.
 */
function visibleSource(path: string): string {
  return readFileSync(path, 'utf8').replace(/\/\*[\s\S]*?\*\//g, '');
}

/** Sayfalarda ASLA bulunamayacak dizeler ve neden yasak oldukları. */
const FORBIDDEN: ReadonlyArray<{ needle: string; why: string }> = [
  { needle: 'Taslak belge', why: 'yayına hazır olmayan belge uyarısı' },
  { needle: 'taslaktır', why: 'yayına hazır olmayan belge uyarısı' },
  { needle: '[Şirket Ünvanı]', why: 'yer tutucu tüzel kişilik' },
  { needle: '[VKN]', why: 'yer tutucu vergi kimlik numarası' },
  { needle: '[Adres]', why: 'yer tutucu adres' },
  { needle: '[KEP adresi]', why: 'yer tutucu KEP adresi' },
  { needle: '[destek e-postası]', why: 'yer tutucu destek e-postası' },
  { needle: 'localStorage', why: 'yalnız web uygulamasını anlatan eski ifade' },
  {
    needle: 'yaklaşık konum',
    why: 'Veri Güvenliği formundaki "konum toplanmıyor" beyanıyla çelişir',
  },
];

describe('yasal sayfalar — yer tutucu ve taslak uyarısı içermez', () => {
  for (const [name, path] of Object.entries(PAGES)) {
    describe(`/${name}`, () => {
      const src = visibleSource(path);

      for (const { needle, why } of FORBIDDEN) {
        it(`"${needle}" içermez (${why})`, () => {
          expect(src, `/${name} sayfasında yasak dize bulundu: ${needle}`).not.toContain(needle);
        });
      }

      it('yasal kimliği koda gömmez — LegalIdentity bileşenini kullanır', () => {
        expect(src).toContain('LegalIdentity');
      });
    });
  }

  it('gizlilik politikası Android uygulamasının veri akışlarını kapsar', () => {
    const src = visibleSource(PAGES.gizlilik);
    // Denetimde eksik oldukları tespit edilen akışların her biri.
    for (const topic of [
      'Android',
      'analitik',
      'Hata ve çökme',
      'AI Koç',
      'Google ile giriş',
      'Google Play',
      'Topluluk',
      'Bildirimler',
      'Alt İşleyiciler',
    ]) {
      expect(src, `gizlilik politikasında eksik konu: ${topic}`).toContain(topic);
    }
  });

  it('gizlilik politikası konum toplamadığını açıkça söyler', () => {
    const src = visibleSource(PAGES.gizlilik);
    expect(src).toContain('konum izni istemez');
  });

  it('hesap silme sayfası Play için gereken bölümleri taşır', () => {
    const src = visibleSource(PAGES['hesap-silme']);
    for (const topic of [
      'Hesabımı sil',
      'Silinen veriler',
      'Saklama süreleri',
      'Uygulama kurulu değilse',
    ]) {
      expect(src, `hesap silme sayfasında eksik bölüm: ${topic}`).toContain(topic);
    }
  });

  /**
   * Denetim bulgusu: sayfa "satın alma kayıtları mevzuatın öngördüğü süre boyunca saklanır"
   * diyordu, oysa `purchases.user_id` şemada ON DELETE CASCADE taşır ve kayıt hesapla birlikte
   * SİLİNİR. Sayfa, sunucunun yapmadığı bir şeyi anlatıyordu.
   *
   * Bu test o cümlenin geri gelmesini engeller. Süreler artık `lib/retention.ts` üzerinden
   * render edildiği için sayfaya elle yazılmış bir saklama iddiası da olmamalıdır.
   */
  it('hiçbir yasal sayfa satın alma kaydının hesap silindikten sonra saklandığını iddia etmez', () => {
    for (const name of ['gizlilik', 'kvkk', 'hesap-silme'] as const) {
      const src = visibleSource(PAGES[name]);
      expect(src, `${name}: uydurulmuş yasal saklama iddiası`).not.toMatch(
        /mevzuatın öngördüğü süre boyunca/
      );
      expect(src, `${name}: satın alma kaydı için yanlış saklama iddiası`).not.toMatch(
        /vergi ve ticaret mevzuatı[^.]*saklanmasını zorunlu/i
      );
    }
  });

  it('saklama süreleri tek kaynaktan (lib/retention) render edilir', () => {
    for (const name of ['gizlilik', 'hesap-silme'] as const) {
      const src = visibleSource(PAGES[name]);
      expect(src, `${name}: saklama tablosu elle yazılmış olabilir`).toContain(
        "from '@/lib/retention'"
      );
      expect(src).toContain('retentionRules()');
    }
  });

  it('gizlilik ve KVKK sayfaları hesap silme sayfasına bağlanır', () => {
    for (const name of ['gizlilik', 'kvkk'] as const) {
      expect(visibleSource(PAGES[name])).toContain('/hesap-silme');
    }
  });
});
