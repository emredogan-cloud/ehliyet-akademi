import { describe, it, expect } from 'vitest';
import { ACCENT_VAR, type Accent } from './primitives';

/**
 * Faz B primitiflerinin aksan sözleşmesi: her aksan bir CSS token'ına eşlenir.
 * StatCard/IconBadge/Badge/Button hepsi bu haritayı kullanır — sabit kalmalı.
 */
describe('primitives · ACCENT_VAR', () => {
  const accents: Accent[] = ['teal', 'amber', 'blue', 'purple', 'red', 'green'];

  it('altı aksanın tümünü kapsar', () => {
    expect(Object.keys(ACCENT_VAR).sort()).toEqual([...accents].sort());
  });

  it('her aksan bir CSS değişkenine (var(--accent-*)) eşlenir', () => {
    for (const a of accents) {
      expect(ACCENT_VAR[a]).toBe(`var(--accent-${a})`);
    }
  });
});
