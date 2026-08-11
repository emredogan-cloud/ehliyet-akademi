import { describe, it, expect } from 'vitest';
import {
  LEGAL_ENV_KEYS,
  SUB_PROCESSORS,
  isLegalIdentityConfigured,
  missingLegalEnvKeys,
  readLegalEntity,
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

  it('TEK bir alan eksikse kısmi kimlik YAYIMLANMAZ — null döner', () => {
    for (const key of Object.values(LEGAL_ENV_KEYS)) {
      const partial = { ...FULL, [key]: '' };
      expect(readLegalEntity(partial), `${key} boşken kimlik dönmemeli`).toBeNull();
      expect(isLegalIdentityConfigured(partial)).toBe(false);
      expect(missingLegalEnvKeys(partial)).toEqual([key]);
    }
  });

  it('yalnız boşluk içeren değer DOLU sayılmaz', () => {
    expect(isLegalIdentityConfigured({ ...FULL, LEGAL_TAX_ID: '   ' })).toBe(false);
  });

  it('değerlerin baş/son boşlukları temizlenir', () => {
    const e = readLegalEntity({ ...FULL, LEGAL_COMPANY_NAME: '  Örnek A.Ş.  ' });
    expect(e?.companyName).toBe('Örnek A.Ş.');
  });

  it('hiçbir şey yapılandırılmamışken tüm anahtarlar eksik listelenir', () => {
    expect(missingLegalEnvKeys({})).toEqual(Object.values(LEGAL_ENV_KEYS));
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
