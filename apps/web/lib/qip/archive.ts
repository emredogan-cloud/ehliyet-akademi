/**
 * QIP 2.0 — İçerik Genişletme · Tarihsel Sınav Oturum Dizini (referans katmanı).
 *
 * `sınav-soruları-pdf/` arşivindeki gerçek MEB e-Sınav oturumlarının TARİHLERİ — ki bunlar KAMUYA
 * AÇIK OLGULARDIR (sınavın ne zaman yapıldığı bilgisi telif konusu değildir). Bu dizin, kopyalanan
 * sınav sorularını DEĞİL; "geçmiş sınav FORMATLARINI" (Faz 6) ÖZGÜN deneme sınavlarıyla göstermek
 * için kullanılır. Hiçbir soru metni/görseli burada yoktur. Sınav yapısı `EXAM_BLUEPRINT`tir.
 *
 * Kaynak arşiv (21 PDF, 18 benzersiz oturum, 2015–2018) referans amaçlı incelendi; verbatim içe
 * aktarım YAPILMADI (bkz. PDF_ARCHIVE_ANALYSIS_REPORT.md).
 */
import { EXAM_BLUEPRINT } from '@ea/content-schema';

const MONTHS_TR = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

export interface HistoricalSession {
  /** Kararlı id = ISO tarih. */
  id: string;
  /** Sınav tarihi (YYYY-MM-DD) — kamuya açık olgu. */
  date: string;
  year: number;
  month: number;
  monthLabel: string;
  /** İnsan-okur etiket, ör. "10 Şubat 2018". */
  label: string;
}

/** Arşivden türetilen benzersiz gerçek oturum tarihleri (yalnız olgu — soru içeriği yok). */
const SESSION_DATES: string[] = [
  '2015-01-10',
  '2015-03-22',
  '2015-06-27',
  '2015-08-29',
  '2015-10-10',
  '2015-12-12',
  '2016-02-13',
  '2016-05-14',
  '2016-08-27',
  '2016-10-08',
  '2017-02-11',
  '2017-05-20',
  '2017-07-29',
  '2017-10-07',
  '2017-12-23',
  '2018-02-10',
  '2018-04-21',
  '2018-08-04',
];

function toSession(date: string): HistoricalSession {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  return {
    id: date,
    date,
    year: y,
    month: m,
    monthLabel: MONTHS_TR[m - 1]!,
    label: `${d} ${MONTHS_TR[m - 1]} ${y}`,
  };
}

/** Tüm tarihsel oturumlar (en yeni önce). */
export const HISTORICAL_SESSIONS: HistoricalSession[] = SESSION_DATES.map(toSession).sort((a, b) =>
  b.date.localeCompare(a.date)
);

/** Yıla göre gruplanmış oturumlar (en yeni yıl önce). */
export function sessionsByYear(): Array<{ year: number; sessions: HistoricalSession[] }> {
  const map = new Map<number, HistoricalSession[]>();
  for (const s of HISTORICAL_SESSIONS) {
    const arr = map.get(s.year) ?? [];
    arr.push(s);
    map.set(s.year, arr);
  }
  return [...map.entries()]
    .map(([year, sessions]) => ({ year, sessions }))
    .sort((a, b) => b.year - a.year);
}

export function historicalSessionById(id: string): HistoricalSession | undefined {
  return HISTORICAL_SESSIONS.find((s) => s.id === id);
}

/** Bu program tarafından referans alınan sınav yapısı (resmî MEB e-Sınav taslağı). */
export const HISTORICAL_EXAM_BLUEPRINT = EXAM_BLUEPRINT;
