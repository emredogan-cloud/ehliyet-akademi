import { describe, it, expect } from 'vitest';
import { VEHICLE_PARTS, partsBySystem, vehiclePartById } from './vehicle';
import { VEHICLE_PART_IDS } from '@/components/vehicle/VehicleFigure';
import { visualAssetById } from './asset-manifest';

describe('araç bileşen kütüphanesi', () => {
  it('yeterli bileşen + benzersiz id (Faz 1: foto-öncelikli genişleme)', () => {
    expect(VEHICLE_PARTS.length).toBeGreaterThanOrEqual(30);
    const ids = new Set(VEHICLE_PARTS.map((p) => p.id));
    expect(ids.size).toBe(VEHICLE_PARTS.length);
  });

  it('her bileşenin görseli var: çizim şeması VEYA premium fotoğraf', () => {
    const known = new Set(VEHICLE_PART_IDS);
    for (const p of VEHICLE_PARTS) {
      const hasDiagram = known.has(p.id);
      const hasPhoto = Boolean(p.photo && visualAssetById(p.photo));
      expect(hasDiagram || hasPhoto, p.id).toBe(true);
    }
  });

  it('foto referansları manifest içinde çözülür', () => {
    for (const p of VEHICLE_PARTS) {
      if (p.photo) {
        expect(visualAssetById(p.photo), `${p.id} → ${p.photo}`).toBeDefined();
      }
    }
  });

  it('ilgili ders bağlantıları gerçek derslere çözülür (kırık link yok)', async () => {
    const { lessonBySlug } = await import('./lessons');
    for (const p of VEHICLE_PARTS) {
      if (p.relatedLessonSlug) {
        expect(lessonBySlug(p.relatedLessonSlug), `${p.id} → ${p.relatedLessonSlug}`).toBeDefined();
      }
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
