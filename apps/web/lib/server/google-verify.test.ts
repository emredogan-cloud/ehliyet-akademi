import { describe, it, expect } from 'vitest';
import {
  decodeJwtUnsafe,
  displayNameFrom,
  failureMessage,
  verifyGoogleClaims,
  type GoogleIdTokenClaims,
} from './google-verify';

/**
 * Beta Faz 2 — Google ID token doğrulaması.
 *
 * Bu testler güvenlik sınırını koruyor: doğrulamanın hangi durumlarda **reddetmek zorunda**
 * olduğunu tek tek sabitliyor. Bir kontrolün sessizce kaldırılması testi kırar.
 */

const AUD = 'server-client-id.apps.googleusercontent.com';
const NOW = 1_800_000_000;

function claims(over: Partial<GoogleIdTokenClaims> = {}): GoogleIdTokenClaims {
  return {
    iss: 'https://accounts.google.com',
    aud: AUD,
    sub: '1234567890',
    exp: NOW + 3600,
    email: 'aday@example.com',
    email_verified: true,
    name: 'Ayşe Kandemir',
    ...over,
  };
}

const okArgs = { audience: AUD, signatureValid: true, nowSeconds: NOW };

describe('geçerli token', () => {
  it('kabul edilir ve e-posta küçük harfe indirilir', () => {
    const r = verifyGoogleClaims({ ...okArgs, claims: claims({ email: 'Aday@Example.COM' }) });
    expect(r.ok).toBe(true);
    if (r.ok) expect(r.claims.email).toBe('aday@example.com');
  });

  it('iki geçerli issuer da kabul edilir', () => {
    for (const iss of ['accounts.google.com', 'https://accounts.google.com']) {
      expect(verifyGoogleClaims({ ...okArgs, claims: claims({ iss }) }).ok).toBe(true);
    }
  });

  it('email_verified DİZGİ "true" olarak gelse de kabul edilir', () => {
    // Google bu alanı bazen dizgi gönderir; katı `=== true` kontrolü girişleri kırardı.
    expect(verifyGoogleClaims({ ...okArgs, claims: claims({ email_verified: 'true' }) }).ok).toBe(
      true
    );
  });
});

describe('REDDEDİLMESİ ZORUNLU durumlar', () => {
  it('imza geçersizse reddedilir', () => {
    const r = verifyGoogleClaims({ ...okArgs, signatureValid: false, claims: claims() });
    expect(r).toEqual({ ok: false, reason: 'bad-signature' });
  });

  it('BAŞKA bir uygulamanın token’ı reddedilir (aud uyuşmuyor)', () => {
    // En kritik kontrol: başka bir Google uygulamasının kullanıcısı bizim hesabımıza giremez.
    const r = verifyGoogleClaims({
      ...okArgs,
      claims: claims({ aud: 'baska-uygulama.apps.googleusercontent.com' }),
    });
    expect(r).toEqual({ ok: false, reason: 'bad-audience' });
  });

  it('sahte issuer reddedilir', () => {
    const r = verifyGoogleClaims({ ...okArgs, claims: claims({ iss: 'https://evil.example' }) });
    expect(r).toEqual({ ok: false, reason: 'bad-issuer' });
  });

  it('süresi dolmuş token reddedilir', () => {
    const r = verifyGoogleClaims({ ...okArgs, claims: claims({ exp: NOW - 3600 }) });
    expect(r).toEqual({ ok: false, reason: 'expired' });
  });

  it('exp sayı değilse reddedilir', () => {
    const r = verifyGoogleClaims({
      ...okArgs,
      claims: claims({ exp: 'yakında' as unknown as number }),
    });
    expect(r).toEqual({ ok: false, reason: 'expired' });
  });

  it('e-posta yoksa reddedilir', () => {
    const r = verifyGoogleClaims({ ...okArgs, claims: claims({ email: undefined }) });
    expect(r).toEqual({ ok: false, reason: 'email-missing' });
  });

  it('DOĞRULANMAMIŞ e-posta reddedilir', () => {
    // Doğrulanmamış e-posta kabul edilseydi, başkasının adresiyle hesap açılabilirdi.
    const r = verifyGoogleClaims({ ...okArgs, claims: claims({ email_verified: false }) });
    expect(r).toEqual({ ok: false, reason: 'email-unverified' });
  });
});

describe('saat kayması', () => {
  it('yeni dolmuş token pay içinde kabul edilir', () => {
    const r = verifyGoogleClaims({ ...okArgs, claims: claims({ exp: NOW - 30 }) });
    expect(r.ok).toBe(true);
  });

  it('payın dışına çıkınca reddedilir', () => {
    const r = verifyGoogleClaims({ ...okArgs, claims: claims({ exp: NOW - 120 }) });
    expect(r.ok).toBe(false);
  });
});

describe('hata mesajları durum SIZDIRMAZ', () => {
  it('imza/aud/issuer/biçim hataları AYNI mesajı verir', () => {
    const shared = [
      failureMessage('bad-signature'),
      failureMessage('bad-audience'),
      failureMessage('bad-issuer'),
      failureMessage('malformed'),
      failureMessage('email-missing'),
    ];
    expect(new Set(shared).size).toBe(1);
  });

  it('kullanıcının düzeltebileceği iki durum ayrı mesaj alır', () => {
    expect(failureMessage('email-unverified')).not.toBe(failureMessage('bad-signature'));
    expect(failureMessage('expired')).not.toBe(failureMessage('bad-signature'));
  });
});

describe('JWT çözümleme (doğrulamasız)', () => {
  function makeJwt(header: object, body: object): string {
    const b64 = (o: object) => Buffer.from(JSON.stringify(o)).toString('base64url');
    return `${b64(header)}.${b64(body)}.imza`;
  }

  it('başlık ve gövdeyi okur', () => {
    const token = makeJwt({ alg: 'RS256', kid: 'abc123' }, claims());
    const d = decodeJwtUnsafe(token);
    expect(d?.header.kid).toBe('abc123');
    expect(d?.claims.email).toBe('aday@example.com');
  });

  it('bozuk girdilerde null', () => {
    expect(decodeJwtUnsafe('tek-parca')).toBeNull();
    expect(decodeJwtUnsafe('a.b')).toBeNull();
    expect(decodeJwtUnsafe('!!!.!!!.!!!')).toBeNull();
    expect(decodeJwtUnsafe('')).toBeNull();
  });

  it('aud/iss taşımayan gövde reddedilir', () => {
    expect(decodeJwtUnsafe(makeJwt({ alg: 'RS256' }, { sub: '1' }))).toBeNull();
  });
});

describe('görünen ad türetme', () => {
  it('addan alınır', () => {
    expect(displayNameFrom(claims())).toBe('Ayşe Kandemir');
  });

  it('ad yoksa e-postanın yerel kısmından üretilir', () => {
    expect(displayNameFrom(claims({ name: undefined, email: 'burak@example.com' }))).toBe('burak');
  });

  it('hiçbiri yoksa güvenli varsayılana düşer — boş ad kaydedilmez', () => {
    expect(displayNameFrom(claims({ name: '   ', email: '' }))).toBe('Sürücü adayı');
  });

  it('aşırı uzun ad kırpılır', () => {
    expect(displayNameFrom(claims({ name: 'a'.repeat(200) })).length).toBe(80);
  });
});
