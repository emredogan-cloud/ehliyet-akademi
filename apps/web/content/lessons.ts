/**
 * Teorik akademi dersleri (ROADMAP Faz 9/10). İçerik ADR-005 şemasıyla doğrulanır.
 * Özgün içerik (ROADMAP E.6). Başlangıç kümesi; Faz 9 ile 4 dersin tümüne genişletilir.
 */
import { parseLesson, type Lesson } from '@ea/content-schema';

const raw: Lesson[] = [
  {
    id: 'trafik-isaretleri',
    slug: 'trafik-isaretleri',
    no: 1,
    subject: 'trafik',
    title: 'Trafik İşaretlerine Giriş',
    summary:
      'Tehlike uyarı, trafik tanzim ve bilgi işaretlerinin mantığı: renk ve şekil neyi anlatır?',
    minutes: 8,
    objectives: [
      'İşaret gruplarını (tehlike / tanzim / bilgi) ayırt etmek',
      'Renk ve şeklin anlamını okumak',
      'DUR ve "yol ver" işaretlerinde doğru davranmak',
    ],
    sections: [
      {
        heading: 'İşaretlerin dili: renk ve şekil',
        badge: 'official',
        body: 'Trafik işaretleri renk ve şekilleriyle anlam taşır. Üçgen ve kırmızı kenarlı işaretler genellikle **tehlike uyarısı**; kırmızı daire içindeki işaretler **yasak/tanzim**; mavi işaretler **mecburiyet veya bilgi** anlatır. İşareti önce grubundan tanımak, tek tek ezberlemekten daha güçlüdür.',
      },
      {
        heading: 'DUR ve Yol Ver',
        badge: 'official',
        body: 'Sekizgen kırmızı **DUR** işaretinde araç tam durur ve geçiş hakkı olana yol verir. Ters üçgen **Yol Ver** işaretinde gerekirse durarak öncelik verilir. İkisinde de amaç kavşak güvenliğidir.',
      },
      {
        heading: 'Neden önemli?',
        badge: 'safety',
        body: 'İşaretleri erken görüp doğru yorumlamak, ani fren ve kavşak kazalarını önler. Sınavda da gerçek trafikte de en sık hatalar öncelik ve işaret ihlalleridir.',
      },
    ],
    mistakes: [
      {
        text: 'DUR levhasında yavaşlayıp durmadan geçmek.',
        fix: 'Araç **tam durmalı**; sonra öncelik verilir.',
      },
      {
        text: 'İşareti son anda fark etmek.',
        fix: 'Bakışı ileriye yayın; işaretleri erkenden tarayın.',
      },
    ],
    tips: ['Renk-şekil grubunu öğrenin: yeni bir işareti bile grubundan tahmin edebilirsiniz.'],
    quizQuestionIds: ['trafik-001', 'trafik-003'],
    references: ['Karayolları Trafik Yönetmeliği — işaretler'],
  },
  {
    id: 'ilk-yardim-temel',
    slug: 'ilk-yardim-temel',
    no: 2,
    subject: 'ilkyardim',
    title: 'İlk Yardımın Temel İlkeleri',
    summary:
      'Olay yeri güvenliği, ABC değerlendirmesi ve bilinci kapalı kazazedede doğru pozisyon.',
    minutes: 9,
    objectives: [
      'İlk yardımın önceliklerini (güvenlik → ABC) sıralamak',
      'Bilinci kapalı, solunumu olan kazazedeye doğru pozisyonu vermek',
      'Dış kanamada ilk yöntemi uygulamak',
    ],
    sections: [
      {
        heading: 'Önce güvenlik, sonra ABC',
        badge: 'safety',
        body: 'İlk yardımın ilk adımı **olay yeri ve kendi güvenliğini** sağlamaktır. Sonra ABC değerlendirilir: **Hava yolu** açıklığı, **Solunum**, **Dolaşım**. Zorunlu olmadıkça yaralı hareket ettirilmez.',
      },
      {
        heading: 'Koma (yan yatış) pozisyonu',
        badge: 'official',
        body: 'Bilinci kapalı ama **solunumu olan** kazazedeye yan yatış (koma) pozisyonu verilir. Böylece dil kökünün hava yolunu tıkaması ve kusmukla boğulma önlenir.',
      },
      {
        heading: 'Dış kanama',
        badge: 'safety',
        body: 'Dış kanamada ilk yöntem, temiz bezle **doğrudan baskı** ve bölgeyi kalp seviyesinin üstüne kaldırmaktır. Turnike yalnız durdurulamayan, hayatı tehdit eden uzuv kanamalarında son çaredir.',
      },
    ],
    mistakes: [
      {
        text: 'Yaralıyı gereksiz yere hemen hareket ettirmek.',
        fix: 'Zorunlu değilse **kımıldatmayın**; ikincil yaralanma riski.',
      },
    ],
    tips: ['ABC sırasını bir cümle olarak ezberleyin: "Hava - Soluk - Dolaşım".'],
    quizQuestionIds: ['ilkyardim-001', 'ilkyardim-003', 'ilkyardim-005'],
    references: ['Resmî temel ilk yardım rehberleri — uzman onayı gereklidir'],
  },
  {
    id: 'motor-temel',
    slug: 'motor-temel',
    no: 3,
    subject: 'motor',
    title: 'Araç Tekniğine Giriş',
    summary: 'Motor yağı, fren/ABS ve akünün görevleri; hararet ikazında ne yapılır?',
    minutes: 8,
    objectives: [
      'Temel sistemlerin görevini açıklamak (yağlama, fren, elektrik)',
      'ABS’nin ani frende ne sağladığını bilmek',
      'Hararet ikazında doğru davranmak',
    ],
    sections: [
      {
        heading: 'Yağlama, fren, elektrik',
        badge: 'official',
        body: 'Motor yağı hareketli parçaları **yağlar**, sürtünmeyi azaltır. Fren sistemi aracı **yavaşlatır/durdurur**. Akü elektrik enerjisi **depolar** ve sistemleri besler.',
      },
      {
        heading: 'ABS ne işe yarar?',
        badge: 'official',
        body: 'ABS, ani ve sert frenlemede tekerleklerin **kilitlenmesini önler**; böylece fren yaparken direksiyon hakimiyeti korunur.',
      },
      {
        heading: 'Hararet (kırmızı ısı) ikazı',
        badge: 'safety',
        body: 'Isı göstergesi kırmızıya gelirse **güvenli yerde durup** motoru soğutun. Sıcak motorda radyatör/soğutma suyu kapağı **açılmaz** (yanma riski).',
      },
    ],
    mistakes: [
      {
        text: 'Motor sıcakken soğutma suyu kapağını açmak.',
        fix: 'Motorun soğumasını bekleyin; sıcakta **açmayın**.',
      },
    ],
    tips: ['Gösterge panelinde kırmızı ikaz = ciddi/acil; sarı ikaz = dikkat/kontrol.'],
    quizQuestionIds: ['motor-001', 'motor-002', 'motor-005'],
    references: ['Araç tekniği temel bilgisi'],
  },
];

/** Şema doğrulaması modül yüklenirken çalışır — bozuk içerik build’i kırar. */
export const LESSONS: Lesson[] = raw.map(parseLesson);

export function lessonBySlug(slug: string): Lesson | undefined {
  return LESSONS.find((l) => l.slug === slug);
}
