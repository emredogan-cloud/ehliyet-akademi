/** Premium içerik göstergesi (Sprint 4). */
export function PremiumBadge({ owned = false }: { owned?: boolean }) {
  return (
    <span
      className={`premium-badge ${owned ? 'premium-badge--owned' : ''}`}
      data-testid="premium-badge"
    >
      {owned ? '★ Premium' : '🔒 Premium'}
    </span>
  );
}
