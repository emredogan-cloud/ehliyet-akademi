import { describe, expect, it } from 'vitest';
import {
  DELETION_REQUEST_SLA_DAYS,
  RETENTION_DEFAULT_DAYS,
  RETENTION_ENV_KEYS,
  retentionDays,
  retentionRules,
  retentionText,
} from './retention';

/**
 * Saklama politikası testleri.
 *
 * Bu testlerin asıl işi bir regresyonu ÖNLEMEK: yayımlanan yasal sayfa ile temizleme işi aynı
 * listeden beslendiği için, listeyi bozan bir değişiklik sayfayı da sessizce yanlışlar.
 */
describe('retentionDays', () => {
  it('ortam değişkeni yoksa varsayılanı verir', () => {
    expect(retentionDays('analytics', {})).toBe(RETENTION_DEFAULT_DAYS.analytics);
    expect(retentionDays('errorReports', {})).toBe(RETENTION_DEFAULT_DAYS.errorReports);
    expect(retentionDays('moderation', {})).toBe(RETENTION_DEFAULT_DAYS.moderation);
  });

  it('geçerli ortam değerini kullanır', () => {
    expect(retentionDays('analytics', { [RETENTION_ENV_KEYS.analytics]: '90' })).toBe(90);
  });

  // Sessiz veri kaybı, fazladan saklamadan daha kötüdür: bozuk değer 0 gün gibi yorumlanmamalı.
  it.each(['abc', '', '   ', '0', '-5', '1.5', 'NaN', 'Infinity'])(
    'geçersiz değer %o varsayılana düşer',
    (raw) => {
      expect(retentionDays('analytics', { [RETENTION_ENV_KEYS.analytics]: raw })).toBe(
        RETENTION_DEFAULT_DAYS.analytics
      );
    }
  );
});

describe('retentionRules', () => {
  it('her kural doldurulmuş alanlar taşır', () => {
    for (const rule of retentionRules({})) {
      expect(rule.key).toBeTruthy();
      expect(rule.label).toBeTruthy();
      expect(rule.what).toBeTruthy();
      expect(rule.why).toBeTruthy();
      expect(rule.deletion).toBeTruthy();
    }
  });

  it('hiçbir kural süresiz saklama anlamına gelmez', () => {
    for (const rule of retentionRules({})) {
      // days === null → hesapla birlikte silinir (süresiz DEĞİL). Sayı ise sonlu ve pozitif olmalı.
      if (rule.days !== null) {
        expect(Number.isFinite(rule.days)).toBe(true);
        expect(rule.days).toBeGreaterThan(0);
      }
    }
  });

  // Denetimin bulduğu uyuşmazlık: sayfa "satın alma kayıtları saklanır" diyordu, şema CASCADE idi.
  it('satın alma kaydı hesapla birlikte silinir olarak işaretlidir', () => {
    const purchases = retentionRules({}).find((r) => r.key === 'purchases');
    expect(purchases?.days).toBeNull();
    expect(purchases?.deletion).toMatch(/Hesap silindiği anda silinir/);
  });

  it('yapılandırılabilir kuralların ortam anahtarı politikadaki adla aynıdır', () => {
    const rules = retentionRules({});
    const envKeyOf = (key: string) => rules.find((r) => r.key === key)?.envKey;
    expect(envKeyOf('analytics')).toBe(RETENTION_ENV_KEYS.analytics);
    expect(envKeyOf('errorReports')).toBe(RETENTION_ENV_KEYS.errorReports);
    expect(envKeyOf('moderation')).toBe(RETENTION_ENV_KEYS.moderation);
  });

  it('ortam değişkeni tabloya yansır', () => {
    const rules = retentionRules({ [RETENTION_ENV_KEYS.errorReports]: '30' });
    expect(rules.find((r) => r.key === 'errorReports')?.days).toBe(30);
  });
});

describe('retentionText', () => {
  it('hesapla silinen kuralı sayı olarak göstermez', () => {
    expect(retentionText({ days: null } as never)).toBe('Hesapla birlikte silinir');
  });

  it('tam yılı yıl olarak da yazar', () => {
    expect(retentionText({ days: 365 } as never)).toBe('365 gün (1 yıl)');
    expect(retentionText({ days: 90 } as never)).toBe('90 gün');
  });
});

describe('silme talebi SLA', () => {
  it('sayfa ile aynı kaynaktan gelir', () => {
    expect(DELETION_REQUEST_SLA_DAYS).toBe(30);
  });
});
