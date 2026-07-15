/**
 * EmptyState — premium boş durum bileşeni (Program 1 · Bölüm D).
 * Metin yerine görsel + yön veren eylem; "hiçbir şey yok" hissini fırsata çevirir.
 */
import type { ReactNode } from 'react';

export function EmptyState({
  icon = '🔍',
  title,
  hint,
  action,
  testId,
}: {
  icon?: string;
  title: string;
  hint?: string;
  action?: ReactNode;
  testId?: string;
}) {
  return (
    <div className="empty-state" data-testid={testId} role="status">
      <span className="empty-state__icon" aria-hidden>
        {icon}
      </span>
      <strong className="empty-state__title">{title}</strong>
      {hint && <p className="empty-state__hint">{hint}</p>}
      {action && <div className="empty-state__action">{action}</div>}
    </div>
  );
}
