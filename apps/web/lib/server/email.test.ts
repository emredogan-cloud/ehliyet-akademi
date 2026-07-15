import { describe, it, expect } from 'vitest';
import {
  getEmailProvider,
  emailConfigured,
  welcomeEmail,
  verificationEmail,
  passwordResetEmail,
  purchaseConfirmationEmail,
  supportRequestEmail,
} from './email';

describe('email şablonları', () => {
  it('welcome/verification/reset subject + html + text taşır', () => {
    for (const tpl of [
      welcomeEmail('Ada'),
      verificationEmail('https://x/dogrula?token=abc'),
      passwordResetEmail('https://x/sifirla?token=abc'),
    ]) {
      expect(tpl.subject.length).toBeGreaterThan(4);
      expect(tpl.html).toContain('Ehliyet Akademi');
      expect(tpl.text.length).toBeGreaterThan(4);
    }
  });

  it('doğrulama/sıfırlama şablonu bağlantıyı içerir', () => {
    expect(verificationEmail('https://x/dogrula?token=T').html).toContain('token=T');
    expect(passwordResetEmail('https://x/sifirla?token=T').text).toContain('token=T');
  });

  it('satın alma onayı ürün + fiyat + ömür boyu vurgusu içerir', () => {
    const tpl = purchaseConfirmationEmail('Komple B Ehliyet Paketi', 449);
    expect(tpl.html).toContain('Komple B Ehliyet Paketi');
    expect(tpl.html).toContain('449');
    expect(tpl.text.toLowerCase()).toContain('ömür boyu');
  });

  it('destek şablonu HTML enjeksiyonunu kaçırır', () => {
    const tpl = supportRequestEmail('a@b.com', '<script>alert(1)</script>');
    expect(tpl.html).not.toContain('<script>');
    expect(tpl.html).toContain('&lt;script&gt;');
  });
});

describe('email sağlayıcı seçimi', () => {
  it('RESEND_API_KEY yokken console sağlayıcı', () => {
    expect(emailConfigured()).toBe(false);
    expect(getEmailProvider().name).toBe('console');
  });

  it('console sağlayıcı gönderimi ok döner (e-posta gitmez)', async () => {
    const r = await getEmailProvider().send('a@b.com', welcomeEmail('X'));
    expect(r.ok).toBe(true);
    expect(r.provider).toBe('console');
  });
});
