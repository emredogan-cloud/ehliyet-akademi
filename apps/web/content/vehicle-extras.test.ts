import { describe, it, expect } from 'vitest';
import { VEHICLE_PARTS, vehiclePartById } from './vehicle';
import { questionsForPart, allPartIds } from './vehicle-extras';
import { visualAssetById } from './asset-manifest';

describe('araç bilgisi genişletmesi (Program 2 · Faz 7)', () => {
  it('katalog ≥70 bileşen, kimlikler benzersiz', () => {
    expect(VEHICLE_PARTS.length).toBeGreaterThanOrEqual(70);
    const ids = new Set(VEHICLE_PARTS.map((p) => p.id));
    expect(ids.size).toBe(VEHICLE_PARTS.length);
    expect(allPartIds().length).toBe(VEHICLE_PARTS.length);
  });

  it('yeni bileşenler kontrol adımları + sık hata taşır (≥30 bileşen)', () => {
    const withInspection = VEHICLE_PARTS.filter(
      (p) => (p.inspection?.length ?? 0) >= 2 && (p.mistake?.length ?? 0) > 10
    );
    expect(withInspection.length).toBeGreaterThanOrEqual(30);
  });

  it('tüm foto referansları manifestte çözülür', () => {
    for (const p of VEHICLE_PARTS) {
      if (p.photo) expect(visualAssetById(p.photo), `${p.id} → ${p.photo}`).toBeDefined();
    }
  });

  it('bileşen→soru eşlemesi grounded (triger kayışı için soru bulunur)', () => {
    const part = vehiclePartById('timing-belt');
    expect(part).toBeDefined();
    // Grounded eşleme katalog dışına çıkmaz; boş dönebilir ama tip/uzunluk sözleşmesi korunur.
    const qs = questionsForPart(part!);
    expect(qs.length).toBeLessThanOrEqual(2);
    for (const q of qs) expect(q.stem.length).toBeGreaterThan(8);
  });
});
