import { describe, expect, it } from 'vitest';
import {
  AVATAR_MAX_BYTES,
  AVATAR_MIMES,
  avatarUrlFor,
  base64Bytes,
  isAvatarMime,
  validateAvatarUpload,
} from './community';

/**
 * Beta Faz 7 — profil fotoğrafı yükleme kuralları (SAF katman).
 *
 * E8'de "fotoğraf yükleme YOK" bilinçli bir moderasyon/PII kararıydı. Faz 7 onu değiştiriyor,
 * dolayısıyla ortadan kalkmış olan saldırı yüzeyi geri geliyor. Bu testler, o yüzeyin
 * sınırlarını **kod düzeyinde sabitler**.
 */

/** `bytes` uzunluğunda geçerli bir base64 gövdesi üretir. */
function b64(bytes: number): string {
  return Buffer.alloc(bytes, 0x41).toString('base64');
}

describe('kabul edilen görsel türleri', () => {
  it('yalnız JPEG, PNG ve WebP kabul edilir', () => {
    expect([...AVATAR_MIMES]).toEqual(['image/jpeg', 'image/png', 'image/webp']);
  });

  it('SVG REDDEDİLİR — gömülü script taşıyabilir', () => {
    expect(isAvatarMime('image/svg+xml')).toBe(false);
    const r = validateAvatarUpload({ mime: 'image/svg+xml', dataBase64: b64(100) });
    expect(r.ok).toBe(false);
  });

  it('Lottie/JSON REDDEDİLİR — avatar değildir', () => {
    expect(isAvatarMime('application/json')).toBe(false);
  });

  it('rastgele/uydurma türler reddedilir', () => {
    for (const m of ['text/html', 'image/gif', 'application/octet-stream', '', null, 42]) {
      expect(isAvatarMime(m)).toBe(false);
    }
  });
});

describe('boyut sınırı', () => {
  it('base64 bayt hesabı padding’i doğru sayar', () => {
    expect(base64Bytes(Buffer.from('a').toString('base64'))).toBe(1); // 'YQ=='
    expect(base64Bytes(Buffer.from('ab').toString('base64'))).toBe(2); // 'YWI='
    expect(base64Bytes(Buffer.from('abc').toString('base64'))).toBe(3); // 'YWJj'
    expect(base64Bytes('')).toBe(0);
  });

  it('CMS’in genel 2MB sınırından belirgin biçimde SIKIDIR', () => {
    expect(AVATAR_MAX_BYTES).toBe(512 * 1024);
    expect(AVATAR_MAX_BYTES).toBeLessThan(2 * 1024 * 1024);
  });

  it('sınırın altındaki görsel kabul, üstündeki RED', () => {
    const ok = validateAvatarUpload({ mime: 'image/jpeg', dataBase64: b64(AVATAR_MAX_BYTES - 10) });
    expect(ok.ok).toBe(true);

    const big = validateAvatarUpload({ mime: 'image/jpeg', dataBase64: b64(AVATAR_MAX_BYTES + 1) });
    expect(big.ok).toBe(false);
    if (!big.ok) expect(big.error).toContain('çok büyük');
  });
});

describe('gövde biçimi', () => {
  it('boş veri reddedilir', () => {
    expect(validateAvatarUpload({ mime: 'image/png', dataBase64: '' }).ok).toBe(false);
    expect(validateAvatarUpload({ mime: 'image/png' }).ok).toBe(false);
  });

  it('base64 olmayan gövde reddedilir (boşluk/satır sonu dâhil)', () => {
    for (const bad of ['not base64!', 'AAAA AAAA', 'AAAA\nAAAA', 'data:image/png;base64,AAAA']) {
      expect(validateAvatarUpload({ mime: 'image/png', dataBase64: bad }).ok).toBe(false);
    }
  });

  it('geçerli gövde çözülmüş bayt sayısını döndürür', () => {
    const r = validateAvatarUpload({ mime: 'image/webp', dataBase64: b64(1234) });
    expect(r.ok).toBe(true);
    if (r.ok) {
      expect(r.bytes).toBe(1234);
      expect(r.mime).toBe('image/webp');
    }
  });
});

describe('maskota geri dönüş — E8 ilkesi korunur', () => {
  it('fotoğraf yoksa URL null olur (istemci maskota düşer)', () => {
    expect(avatarUrlFor(null)).toBeNull();
    expect(avatarUrlFor(undefined)).toBeNull();
    expect(avatarUrlFor('')).toBeNull();
  });

  it('fotoğraf varsa medya servisinin URL’si döner', () => {
    expect(avatarUrlFor('m123')).toBe('/api/media/m123');
  });
});
