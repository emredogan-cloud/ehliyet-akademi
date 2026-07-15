import { describe, it, expect } from 'vitest';
import { VEHICLE_PARTS, partsBySystem, vehiclePartById } from './vehicle';
import { VEHICLE_PART_IDS } from '@/components/vehicle/VehicleFigure';

describe('araç bileşen kütüphanesi', () => {
  it('yeterli bileşen + benzersiz id', () => {
    expect(VEHICLE_PARTS.length).toBeGreaterThanOrEqual(18);
    const ids = new Set(VEHICLE_PARTS.map((p) => p.id));
    expect(ids.size).toBe(VEHICLE_PARTS.length);
  });

  it('her bileşenin görseli VehicleFigure kaydında var', () => {
    const known = new Set(VEHICLE_PART_IDS);
    for (const p of VEHICLE_PARTS) {
      expect(known.has(p.id), p.id).toBe(true);
    }
  });

  it('her bileşen görev + ipucu taşır', () => {
    for (const p of VEHICLE_PARTS) {
      expect(p.desc.length).toBeGreaterThan(10);
      expect(p.tip.length).toBeGreaterThan(10);
    }
  });

  it('sistemlere göre gruplama tüm bileşenleri kapsar', () => {
    const g = partsBySystem();
    const total = Object.values(g).reduce((n, arr) => n + arr.length, 0);
    expect(total).toBe(VEHICLE_PARTS.length);
    expect(g['motor-bolmesi'].length).toBeGreaterThan(0);
    expect(g['kabin'].length).toBeGreaterThan(0);
  });

  it('id ile erişim', () => {
    expect(vehiclePartById('battery')?.name).toBe('Akü');
    expect(vehiclePartById('yok')).toBeUndefined();
  });
});
