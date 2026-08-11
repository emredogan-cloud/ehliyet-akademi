import { describe, it, expect } from 'vitest';
import {
  LEGAL_ENV_KEYS,
  REQUIRED_LEGAL_FIELDS,
  SUB_PROCESSORS,
  isLegalIdentityConfigured,
  missingLegalEnvKeys,
  readLegalEntity,
  taxIdLabel,
} from './legal-entity';

const FULL: Record<string, string> = {
  LEGAL_COMPANY_NAME: 'Örnek Eğitim Teknolojileri A.Ş.',
  LEGAL_TAX_ID: '1234567890',
  LEGAL_ADDRESS: 'Örnek Mah. Test Cad. No:1, Çankaya/Ankara',
  LEGAL_KEP_ADDRESS: 'ornek@hs01.kep.tr',
  LEGAL_SUPPORT_EMAIL: 'destek@ehliyetegitim.com',
};

describe('yasal kimlik (veri sorumlusu)', () => {
  it('tüm alanlar doluyken kimliği okur', () => {
    const e = readLegalEntity(FULL);
    expect(e).not.toBeNull();
    expect(e?.companyName).toBe('Örnek Eğitim Teknolojileri A.Ş.');
    expect(e?.taxId).toBe('1234567890');
    expect(e?.kepAddress).toBe('ornek@hs01.kep.tr');
    expect(isLegalIdentityConfigured(FULL)).toBe(true);
    expect(missingLegalEnvKeys(FULL)).toEqual([]);
  });

  it('ZORUNLU alanlardan biri eksikse kısmi kimlik YAYIMLANMAZ — null döner', () => {
    for (const field of REQUIRED_LEGAL_FIELDS) {
      const key = LEGAL_ENV_KEYS[field];
      const partial = { ...FULL, [key]: '' };
      expect(readLegalEntity(partial), `${key} boşken kimlik dönmemeli`).toBeNull();
      expect(isLegalIdentityConfigured(partial)).toBe(false);
      expect(missingLegalEnvKeys(partial)).toEqual([key]);
    }
  });

  /**
   * KEP zorunluluğu TTK m.18/3 uyarınca SERMAYE ŞİRKETLERİNE özgüdür. Veri sorumlusu bir gerçek
   * kişiyse KEP tutmak zorunda değildir. Alan bir dönem zorunluydu ve tam da bu durumu
   * kilitliyordu: kurucu diğer dört alanı doğru doldurduğu hâlde sayfa "henüz yayımlanmadı"
   * demeye devam ediyordu. Uydurma bir KEP adresi ise sahte tescil bilgisi yayımlamak olurdu.
   */
  describe('KEP isteğe bağlıdır', () => {
    const noKep = { ...FULL, LEGAL_KEP_ADDRESS: '' };

    it('KEP boşken kimlik YİNE DE yayımlanır', () => {
      const e = readLegalEntity(noKep);
      expect(e).not.toBeNull();
      expect(e?.kepAddress).toBeNull();
      expect(isLegalIdentityConfigured(noKep)).toBe(true);
    });

    it('KEP hiç tanımlı değilken de kimlik yayımlanır', () => {
      const { LEGAL_KEP_ADDRESS: _omit, ...withoutKey } = FULL;
      expect(isLegalIdentityConfigured(withoutKey)).toBe(true);
      expect(readLegalEntity(withoutKey)?.kepAddress).toBeNull();
    });

    it('eksik KEP bir EKSİKLİK olarak raporlanmaz', () => {
      expect(missingLegalEnvKeys(noKep)).toEqual([]);
      expect(missingLegalEnvKeys({})).not.toContain(LEGAL_ENV_KEYS.kepAddress);
    });

    it('KEP varsa aynen okunur', () => {
      expect(readLegalEntity(FULL)?.kepAddress).toBe('ornek@hs01.kep.tr');
    });
  });

  /**
   * Sayfa bir dönem her numarayı `VKN:` diye basıyordu. 11 hane T.C. kimlik numarasıdır; bunu
   * VKN diye etiketlemek yayımlanmış bir yasal metinde yanlış beyandır.
   */
  describe('kimlik numarası etiketi', () => {
    it('11 hane T.C. Kimlik No olarak etiketlenir', () => {
      expect(taxIdLabel('10351358422')).toBe('T.C. Kimlik No');
    });
    it('10 hane VKN olarak etiketlenir', () => {
      expect(taxIdLabel('1234567890')).toBe('VKN');
    });
    it('tanınmayan uzunlukta nötr etiket kullanılır', () => {
      expect(taxIdLabel('12345')).toBe('Kimlik No');
    });
    it('ayraçlar sayımı bozmaz', () => {
      expect(taxIdLabel('103 513 584 22')).toBe('T.C. Kimlik No');
    });
  });

  it('yalnız boşluk içeren değer DOLU sayılmaz', () => {
    expect(isLegalIdentityConfigured({ ...FULL, LEGAL_TAX_ID: '   ' })).toBe(false);
  });

  it('değerlerin baş/son boşlukları temizlenir', () => {
    const e = readLegalEntity({ ...FULL, LEGAL_COMPANY_NAME: '  Örnek A.Ş.  ' });
    expect(e?.companyName).toBe('Örnek A.Ş.');
  });

  it('hiçbir şey yapılandırılmamışken tüm ZORUNLU anahtarlar eksik listelenir', () => {
    expect(missingLegalEnvKeys({})).toEqual(REQUIRED_LEGAL_FIELDS.map((f) => LEGAL_ENV_KEYS[f]));
    expect(isLegalIdentityConfigured({})).toBe(false);
  });

  it('alt işleyici listesi koddaki gerçek üçüncü tarafları taşır', () => {
    const names = SUB_PROCESSORS.map((s) => s.name);
    // Bu beşi koddan doğrulanmıştır; biri kaldırılırsa gizlilik politikası da güncellenmelidir.
    expect(names).toContain('Vercel Inc.');
    expect(names).toContain('Neon Inc.');
    expect(names).toContain('Anthropic PBC');
    expect(names).toContain('Resend Inc.');
    expect(names).toContain('Google LLC');
    for (const s of SUB_PROCESSORS) {
      expect(s.purpose.length).toBeGreaterThan(0);
      expect(s.dataShared.length).toBeGreaterThan(0);
    }
  });
});

/**
 * Derleme önbelleği ile yayımlanan metnin ayrışmaması için koruma.
 *
 * `/gizlilik`, `/kvkk` ve `/hesap-silme` **statik olarak ön-üretiliyor**: veri sorumlusu bilgisi
 * ve saklama süreleri derleme anında HTML'e gömülüyor. Bu değişkenler `turbo.json` içinde
 * bildirilmezse turbo onları önbellek anahtarına katmaz; değeri değiştirip yeniden derlemek
 * ESKİ çıktının geri yüklenmesiyle sonuçlanır — hiçbir hata vermeden, eski yasal metinle.
 *
 * Bu tam olarak bu oturumda yaşandı: dört yasal değişken ayarlandı, `pnpm build` "FULL TURBO"
 * deyip 15 ms'de bitti ve sayfa hâlâ "henüz yayımlanmadı" gösterdi.
 */
describe('derleme önbelleği', () => {
  it('render zamanı okunan tüm ortam anahtarları turbo.json build.env içinde bildirilmiş', async () => {
    const { readFileSync } = await import('node:fs');
    const { fileURLToPath } = await import('node:url');
    const turbo = JSON.parse(
      readFileSync(fileURLToPath(new URL('../../../turbo.json', import.meta.url)), 'utf8')
    ) as { tasks: { build: { env?: string[] } } };
    const declared = new Set(turbo.tasks.build.env ?? []);

    const mustBeDeclared = [
      ...Object.values(LEGAL_ENV_KEYS),
      'RETENTION_ANALYTICS_DAYS',
      'RETENTION_ERROR_REPORTS_DAYS',
      'RETENTION_MODERATION_DAYS',
    ];
    for (const key of mustBeDeclared) {
      expect(
        declared.has(key),
        `${key} turbo.json → tasks.build.env içinde bildirilmemiş; önbellek eski yasal metni geri yükleyebilir`
      ).toBe(true);
    }
  });
});
