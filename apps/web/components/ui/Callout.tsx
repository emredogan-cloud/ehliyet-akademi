/**
 * Callout — ders içi vurgu kutusu (Program 1 · Bölüm D · görsel dönüşüm).
 * Metin-ağırlıklı gövdeyi kırar; tona göre renk + ikon. Tema-uyumlu, telifsiz.
 */
import type { Callout as CalloutData } from '@ea/content-schema';

const TONE: Record<CalloutData['tone'], { icon: string; color: string; label: string }> = {
  info: { icon: '💡', color: 'var(--blue)', label: 'Bilgi' },
  success: { icon: '✅', color: 'var(--green)', label: 'İpucu' },
  warning: { icon: '⚠️', color: 'var(--yellow)', label: 'Dikkat' },
  danger: { icon: '🚫', color: 'var(--red)', label: 'Tehlike' },
};

/** Basit **kalın** işaretlemesini <strong>'a çevirir (içerik markdown-hafif). */
function mdBold(s: string): string {
  const escaped = s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  return escaped.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
}

export function Callout({ tone, title, text }: CalloutData) {
  const t = TONE[tone];
  return (
    <div className="callout" style={{ ['--callout-c' as string]: t.color }} role="note">
      <span className="callout__icon" aria-hidden>
        {t.icon}
      </span>
      <div>
        <strong className="callout__title">{title ?? t.label}</strong>
        <p
          className="callout__text"
          dangerouslySetInnerHTML={{ __html: mdBold(text) }}
        />
      </div>
    </div>
  );
}
