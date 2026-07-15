/**
 * E-posta platformu (Sprint 4 / ADR-009). Sağlayıcı-agnostik arayüz + üretim şablonları.
 * Varsayılan: ConsoleEmailProvider (RESEND_API_KEY yoksa — geliştirme/mock; e-posta gitmez,
 * loglanır). ENV geldiğinde ResendEmailProvider devreye girer — uygulama kodu değişmez.
 */
import { withRetry } from '../retry';
import { logger } from './logger';

export interface EmailTemplate {
  subject: string;
  html: string;
  text: string;
}
export interface EmailResult {
  ok: boolean;
  id?: string;
  provider: string;
}
export interface EmailProvider {
  readonly name: string;
  send(to: string, tpl: EmailTemplate): Promise<EmailResult>;
}

/** Geliştirme/mock: e-posta göndermez, güvenli biçimde loglar. */
class ConsoleEmailProvider implements EmailProvider {
  readonly name = 'console';
  async send(to: string, tpl: EmailTemplate): Promise<EmailResult> {
    logger.info('email (console)', { to, subject: tpl.subject });
    return { ok: true, provider: 'console' };
  }
}

/** Resend (ENV: RESEND_API_KEY, EMAIL_FROM). Yeniden denemeli (geçici hatalarda). */
class ResendEmailProvider implements EmailProvider {
  readonly name = 'resend';
  constructor(
    private apiKey: string,
    private from: string
  ) {}
  async send(to: string, tpl: EmailTemplate): Promise<EmailResult> {
    return withRetry(
      async () => {
        const res = await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: {
            authorization: `Bearer ${this.apiKey}`,
            'content-type': 'application/json',
          },
          body: JSON.stringify({
            from: this.from,
            to,
            subject: tpl.subject,
            html: tpl.html,
            text: tpl.text,
          }),
        });
        if (!res.ok) throw new Error(`resend ${res.status}`);
        const data = (await res.json().catch(() => ({}))) as { id?: string };
        return { ok: true, id: data.id, provider: 'resend' };
      },
      { retries: 2, baseMs: 250, shouldRetry: () => true }
    );
  }
}

export function emailConfigured(): boolean {
  return Boolean(process.env.RESEND_API_KEY);
}

export function getEmailProvider(): EmailProvider {
  const key = process.env.RESEND_API_KEY;
  const from = process.env.EMAIL_FROM ?? 'Ehliyet Akademi <bilgi@ehliyetakademi.app>';
  return key ? new ResendEmailProvider(key, from) : new ConsoleEmailProvider();
}

/* ---------- şablonlar (saf; test edilebilir) ---------- */

const BRAND = 'Ehliyet Akademi';

function shell(heading: string, bodyHtml: string): string {
  return `<!doctype html><html lang="tr"><body style="margin:0;background:#0f1720;font-family:system-ui,Segoe UI,Roboto,sans-serif">
<div style="max-width:520px;margin:0 auto;padding:28px 22px;color:#e6edf3">
  <div style="font-size:20px;font-weight:800;margin-bottom:18px">🚗 ${BRAND}</div>
  <h1 style="font-size:20px;margin:0 0 14px">${heading}</h1>
  ${bodyHtml}
  <hr style="border:none;border-top:1px solid #22303c;margin:24px 0"/>
  <p style="font-size:12px;color:#8b98a5">${BRAND} · Eğitim amaçlı hazırlık platformu. Resmî sınav ve kural için MEB/MTSK esastır.</p>
</div></body></html>`;
}
function btn(url: string, label: string): string {
  return `<a href="${url}" style="display:inline-block;background:#14b8a6;color:#04231f;font-weight:700;text-decoration:none;padding:11px 18px;border-radius:10px">${label}</a>`;
}

export function welcomeEmail(name: string): EmailTemplate {
  const hi = name ? `Merhaba ${name},` : 'Merhaba,';
  return {
    subject: `${BRAND}'ye hoş geldin 🚗`,
    html: shell(
      'Hoş geldin!',
      `<p>${hi}</p><p>Ehliyet Akademi'ye kaydoldun. Teorik e-Sınav ve direksiyon hazırlığına hemen başlayabilirsin: dersler, akıllı tekrar (SRS), deneme sınavı ve AI koç seni bekliyor.</p>`
    ),
    text: `${hi}\nEhliyet Akademi'ye kaydoldun. Derslere, deneme sınavına ve AI koça hemen başlayabilirsin.`,
  };
}

export function verificationEmail(link: string): EmailTemplate {
  return {
    subject: `${BRAND} — e-posta adresini doğrula`,
    html: shell(
      'E-postanı doğrula',
      `<p>Hesabını etkinleştirmek için e-posta adresini doğrula. Bağlantı 24 saat geçerlidir.</p><p style="margin:20px 0">${btn(link, 'E-postamı doğrula')}</p><p style="font-size:12px;color:#8b98a5">Bu isteği sen yapmadıysan bu e-postayı yok sayabilirsin.</p>`
    ),
    text: `E-postanı doğrulamak için: ${link}\nBağlantı 24 saat geçerlidir.`,
  };
}

export function passwordResetEmail(link: string): EmailTemplate {
  return {
    subject: `${BRAND} — parola sıfırlama`,
    html: shell(
      'Parolanı sıfırla',
      `<p>Parolanı sıfırlamak için aşağıdaki bağlantıya tıkla. Bağlantı 1 saat geçerlidir.</p><p style="margin:20px 0">${btn(link, 'Parolamı sıfırla')}</p><p style="font-size:12px;color:#8b98a5">Bu isteği sen yapmadıysan parolan değişmez; bu e-postayı yok sayabilirsin.</p>`
    ),
    text: `Parolanı sıfırlamak için: ${link}\nBağlantı 1 saat geçerlidir. İsteği sen yapmadıysan yok say.`,
  };
}

export function purchaseConfirmationEmail(productTitle: string, priceTRY: number): EmailTemplate {
  return {
    subject: `${BRAND} — satın alman onaylandı ✅`,
    html: shell(
      'Satın alman onaylandı',
      `<p><strong>${productTitle}</strong> hesabına tanımlandı — <strong>ömür boyu erişim</strong> (tek seferlik ödeme, abonelik yok).</p><p>Tutar: ${priceTRY} ₺.</p><p style="margin:20px 0">${btn('/panel', 'Uygulamayı aç')}</p><p style="font-size:12px;color:#8b98a5">Satın alımların her cihazda "Satın almaları geri yükle" ile geri gelir.</p>`
    ),
    text: `${productTitle} hesabına tanımlandı — ömür boyu erişim. Tutar: ${priceTRY} TRY. Tek seferlik ödeme, abonelik yok.`,
  };
}

function escapeHtml(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

export function supportRequestEmail(fromEmail: string, message: string): EmailTemplate {
  return {
    subject: `${BRAND} — destek talebi`,
    html: shell(
      'Yeni destek talebi',
      `<p><strong>Gönderen:</strong> ${escapeHtml(fromEmail)}</p><p><strong>Mesaj:</strong></p><p>${escapeHtml(message)}</p>`
    ),
    text: `Destek talebi\nGönderen: ${fromEmail}\nMesaj: ${message}`,
  };
}
