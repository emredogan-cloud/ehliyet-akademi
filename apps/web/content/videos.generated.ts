/**
 * ÜRETİLMİŞ DOSYA — elle düzenlemeyin.
 * Kaynak: `scripts/video-scenes.mjs` · Üretici: `node scripts/render-video.mjs`
 *
 * Bölüm ve transkript verisi videoyu çizen sahneyle AYNI nesneden türetilir; böylece video ile
 * katalog arasında sapma olamaz (Evolution Faz E12).
 */
import type { VideoChapter, TranscriptCue } from './videos';

export type GeneratedVideoData = {
  duration: number;
  chapters: VideoChapter[];
  transcript: TranscriptCue[];
};

export const GENERATED_VIDEOS: Record<string, GeneratedVideoData> = {
  'parallel-park': {
    duration: 12,
    chapters: [
      { t: 0, title: "Boşluğu geç, hizalan" },
      { t: 3, title: "Geri al, direksiyonu sağa kır" },
      { t: 6.5, title: "45° olunca sola çevir" },
      { t: 9.5, title: "Düzelt ve ortala" },
    ],
    transcript: [
      { t: 0, text: "Park edeceğin boşluğun yanından geç ve öndeki araçla yan yana hizalan." },
      { t: 3, text: "Geri viteste yavaşça geri al; direksiyonu tam sağa kır." },
      { t: 6.5, text: "Araç kaldırıma yaklaşık 45 derece olunca direksiyonu sola çevirmeye başla." },
      { t: 9.5, text: "Tekerlekleri düzelt, iki araç arasında ortala ve kaldırım mesafeni koru." },
    ],
  },
  'right-of-way': {
    duration: 10,
    chapters: [
      { t: 0, title: "Yaklaş ve tara" },
      { t: 2.6, title: "Çizgide dur" },
      { t: 5.2, title: "Önceliği sağdakine ver" },
      { t: 7.6, title: "Kontrollü geç" },
    ],
    transcript: [
      { t: 0, text: "Işıksız eşit kavşağa yaklaşırken yavaşla; sol, ileri ve sağı tara." },
      { t: 2.6, text: "Sağdan gelen araç var — kavşak çizgisinde dur." },
      { t: 5.2, text: "Işıksız eşit kavşakta öncelik sağdan gelenindir; geçmesini bekle." },
      { t: 7.6, text: "Yol boşaldığında kavşağa kontrollü şekilde gir ve geç." },
    ],
  },
  'l-park': {
    duration: 13,
    chapters: [
      { t: 0, title: "Yanaş ve referansı yakala" },
      { t: 3.2, title: "Dur, geri vitese al" },
      { t: 5.4, title: "Direksiyonu tam kır" },
      { t: 9.2, title: "Düzelt, boşluğa otur" },
    ],
    transcript: [
      { t: 0, text: "Park cebinin yanından yavaşça geç; cebin köşesini referans al." },
      { t: 3.2, text: "Aracını cebe dik gelecek konumda durdur ve geri vitese al." },
      { t: 5.4, text: "Direksiyonu cep yönüne tam kır ve yavaşça geri gel; arkanı kontrol et." },
      { t: 9.2, text: "Araç cebe girince direksiyonu düzelt ve çizgilerin arasına ortala." },
    ],
  },
  'u-turn': {
    duration: 12,
    chapters: [
      { t: 0, title: "Sağa yanaş, kontrol et" },
      { t: 2.8, title: "Sinyal ver, yavaşla" },
      { t: 5, title: "Direksiyonu tam sola kır" },
      { t: 9, title: "Şeride yerleş" },
    ],
    transcript: [
      { t: 0, text: "Dönüş öncesi sağa yanaş; aynalardan ve omuz üstünden arkanı kontrol et." },
      { t: 2.8, text: "Sol sinyali ver ve dönüşe girecek kadar yavaşla." },
      { t: 5, text: "Yol boşken direksiyonu tam sola kır; karşı şeride geniş bir yay çizerek dön." },
      { t: 9, text: "Dönüş bitince direksiyonu düzelt ve karşı şeride düzgün yerleş." },
    ],
  },
  'reverse-25m': {
    duration: 12,
    chapters: [
      { t: 0, title: "Başlangıç çizgisinde dur" },
      { t: 2.4, title: "Geri vites, arkanı kontrol et" },
      { t: 4.6, title: "Şeridi koruyarak geri git" },
      { t: 9.6, title: "Bitiş çizgisinde durdur" },
    ],
    transcript: [
      { t: 0, text: "Aracını başlangıç çizgisinde, şeridin ortasında durdur." },
      { t: 2.4, text: "Geri vitese al; omuz üstünden ve aynalardan arkanı kontrol et." },
      { t: 4.6, text: "Yavaş ve sabit hızla geri git; direksiyonla küçük düzeltmeler yaparak şeritte kal." },
      { t: 9.6, text: "Bitiş çizgisini geçmeden, tekerlekler düz hâldeyken aracı durdur." },
    ],
  },
  'hill-start': {
    duration: 12,
    chapters: [
      { t: 0, title: "Yokuşta dur, el frenini çek" },
      { t: 3, title: "Debriyajı kavrama noktasına getir" },
      { t: 6.2, title: "Gazı ver, el frenini indir" },
      { t: 9, title: "Geri kaymadan kalk" },
    ],
    transcript: [
      { t: 0, text: "Yokuşta durduğunda el frenini çek; araç geri kaymasın." },
      { t: 3, text: "Debriyajı yavaşça bırakıp kavrama noktasını bul — araç hafifçe titrer." },
      { t: 6.2, text: "Aynı anda gazı ver ve el frenini kademeli indir." },
      { t: 9, text: "Araç geri kaymadan ileri hareket eder; debriyajı tamamen bırak." },
    ],
  },
  'common-mistakes': {
    duration: 14,
    chapters: [
      { t: 0, title: "Çizgiyi aşarak durmak" },
      { t: 4.6, title: "Dönüşte fazla geniş almak" },
      { t: 9.4, title: "Aynaya bakmadan geri gitmek" },
    ],
    transcript: [
      { t: 0, text: "Hata: kavşak çizgisini aşarak durmak — yayaların geçiş alanını kapatır." },
      { t: 2.4, text: "Doğrusu: çizginin gerisinde, yaya geçidini kapatmadan dur." },
      { t: 4.6, text: "Hata: dönüşü fazla geniş almak — karşı şeride taşarsın." },
      { t: 7, text: "Doğrusu: dönüşe yavaşlayarak gir ve kendi şeridinde kal." },
      { t: 9.4, text: "Hata: aynalara ve arkana bakmadan geri gitmek." },
      { t: 11.8, text: "Doğrusu: geri gitmeden önce aynaları ve omuz üstünü kontrol et." },
    ],
  },
};
