/**
 * Video sahneleri — TEK KAYNAK (Evolution Faz E12).
 *
 * Buradaki her sahne hem **görüntüyü** (svg + css) hem **bölümleri** hem de **altyazıyı** taşır.
 * `render-video.mjs` bu dosyadan mp4/webm/poster/VTT üretir ve `content/videos.generated.ts`
 * dosyasını yazar; `content/videos.ts` de o üretilmiş veriyi kullanır.
 *
 * NEDEN TEK KAYNAK: roadmap'in E12 için işaretlediği risk "render hattının sahne kaynağından
 * SAPMASI"ydı. Bölüm/altyazı verisi elle ayrı yerlerde tutulursa er geç videoyla uyuşmaz. Burada
 * uyuşmazlık YAPISAL OLARAK imkânsız — üçü de aynı nesneden türetiliyor.
 *
 * DÜRÜSTLÜK: bunlar ÖZGÜN ANİMASYONLARDIR, gerçek çekim değildir. Gerçek çekim gerektiren
 * konular katalogda `planned` kalır ve öyle etiketlenir.
 */

/** Tasarım token'ları (globals.css ile birebir) — sahneler markadan kopmasın. */
export const T = {
  grass: '#16241f',
  road: '#39414a',
  roadDark: '#2f363e',
  kerb: '#5b6570',
  line: 'rgba(255,255,255,0.78)',
  ego: '#14b8a6',
  other: '#d97706',
  danger: '#ef4444',
  ok: '#22c55e',
  guide: 'rgba(255,255,255,0.62)',
  label: '#e8eef7',
  labelBg: 'rgba(5,11,22,0.82)',
};

/** Araç gövdesi — tekerlek ve cam ayrıntısıyla (önceki sürümde düz dikdörtgendi). */
export const CAR = (body, opts = {}) => {
  const { wheel = '#11161d', glass = 'rgba(255,255,255,0.42)' } = opts;
  return `<g>
    <rect x="-13" y="-16" width="4" height="9" rx="1.6" fill="${wheel}"/>
    <rect x="9" y="-16" width="4" height="9" rx="1.6" fill="${wheel}"/>
    <rect x="-13" y="8" width="4" height="9" rx="1.6" fill="${wheel}"/>
    <rect x="9" y="8" width="4" height="9" rx="1.6" fill="${wheel}"/>
    <rect x="-11" y="-22" width="22" height="44" rx="6.5" fill="${body}"/>
    <rect x="-8.5" y="-13" width="17" height="11" rx="3" fill="${glass}"/>
    <rect x="-8.5" y="3" width="17" height="9" rx="3" fill="${glass}" opacity="0.72"/>
    <rect x="-9" y="-21.5" width="5" height="3" rx="1.2" fill="rgba(255,255,255,0.85)"/>
    <rect x="4" y="-21.5" width="5" height="3" rx="1.2" fill="rgba(255,255,255,0.85)"/>
  </g>`;
};

/** Trafik konisi — manevra alanlarını işaretler (sınav pistlerindeki gibi). */
export const CONE = `<g><ellipse cx="0" cy="3" rx="6" ry="2.4" fill="rgba(0,0,0,0.35)"/>
  <path d="M0 -10 L5 4 L-5 4 Z" fill="#e2570f"/>
  <rect x="-3.4" y="-2.5" width="6.8" height="2.6" fill="#fff" opacity="0.9"/></g>`;

/** Kesikli yol çizgisi üretici. */
const dashes = (xs, y, w = 30, h = 4) =>
  xs
    .map(
      (x) =>
        `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="2" fill="${T.line}" opacity="0.5"/>`
    )
    .join('');

/**
 * Adım etiketi. Bölümle AYNI zamanlarda görünür/kaybolur — böylece izleyici o anda hangi adımda
 * olduğunu videonun İÇİNDE de görür (roadmap: "labelled steps").
 */
const stepLabel = (i, text, from, to, duration) => {
  const pct = (s) => ((s / duration) * 100).toFixed(3);
  const a = pct(from);
  const b = pct(Math.min(from + 0.25, to));
  const c = pct(Math.max(to - 0.25, from + 0.3));
  const d = pct(to);
  return {
    svg: `<g class="step step-${i}" transform="translate(24 40)">
      <rect x="0" y="-21" width="${Math.min(560, 17 + text.length * 10.2)}" height="30" rx="8" fill="${T.labelBg}"/>
      <text x="13" y="0" font-family="Inter,Segoe UI,sans-serif" font-size="16" font-weight="700" fill="${T.label}">${text}</text>
    </g>`,
    css: `@keyframes kf-step-${i} {
      0%, ${a}% { opacity: 0; }
      ${b}% { opacity: 1; }
      ${c}% { opacity: 1; }
      ${d}%, 100% { opacity: 0; }
    }
    .step-${i} { opacity: 0; animation: kf-step-${i} ${duration}s linear infinite; }`,
  };
};

/** Sahneyi, bölümlerinden türetilen adım etiketleriyle birlikte kurar. */
function withSteps(scene) {
  const { duration, chapters } = scene;
  const labels = chapters.map((c, i) => {
    const next = chapters[i + 1];
    return stepLabel(i, `${i + 1}. ${c.title}`, c.t, next ? next.t : duration, duration);
  });
  return {
    ...scene,
    svgExtra: labels.map((l) => l.svg).join(''),
    cssExtra: labels.map((l) => l.css).join('\n'),
  };
}

const road = (w, h) => `<rect width="${w}" height="${h}" fill="${T.grass}"/>`;

// ─────────────────────────────────────────────────────────────────────────────
// Sahneler
// ─────────────────────────────────────────────────────────────────────────────

export const SCENES = {
  'parallel-park': withSteps({
    duration: 12,
    title: 'Paralel Park',
    chapters: [
      { t: 0, title: 'Boşluğu geç, hizalan' },
      { t: 3, title: 'Geri al, direksiyonu sağa kır' },
      { t: 6.5, title: '45° olunca sola çevir' },
      { t: 9.5, title: 'Düzelt ve ortala' },
    ],
    captions: [
      { t: 0, text: 'Park edeceğin boşluğun yanından geç ve öndeki araçla yan yana hizalan.' },
      { t: 3, text: 'Geri viteste yavaşça geri al; direksiyonu tam sağa kır.' },
      {
        t: 6.5,
        text: 'Araç kaldırıma yaklaşık 45 derece olunca direksiyonu sola çevirmeye başla.',
      },
      { t: 9.5, text: 'Tekerlekleri düzelt, iki araç arasında ortala ve kaldırım mesafeni koru.' },
    ],
    svg: `
      ${road(560, 320)}
      <rect y="78" width="560" height="196" fill="${T.road}"/>
      <rect y="270" width="560" height="12" fill="${T.kerb}"/>
      <rect y="70" width="560" height="8" fill="${T.kerb}"/>
      ${dashes([0, 80, 160, 240, 320, 400, 480], 170)}
      <g transform="translate(104 240) rotate(90)">${CAR('#8a939d')}</g>
      <g transform="translate(438 240) rotate(90)">${CAR('#8a939d')}</g>
      <rect x="188" y="218" width="162" height="44" rx="9" fill="none" stroke="${T.guide}" stroke-dasharray="7 7"/>
      <g class="anim-car anim-parallel">${CAR(T.ego)}</g>`,
    css: `@keyframes kf-parallel {
      0%   { transform: translate(-40px, 128px) rotate(90deg); }
      22%  { transform: translate(400px, 128px) rotate(90deg); }
      27%  { transform: translate(400px, 128px) rotate(90deg); }
      54%  { transform: translate(340px, 196px) rotate(62deg); }
      79%  { transform: translate(288px, 232px) rotate(84deg); }
      92%, 100% { transform: translate(272px, 240px) rotate(90deg); }
    }
    .anim-parallel { animation: kf-parallel 12s ease-in-out infinite; }`,
  }),

  'right-of-way': withSteps({
    duration: 10,
    title: 'Kavşakta Sağdan Gelen',
    chapters: [
      { t: 0, title: 'Yaklaş ve tara' },
      { t: 2.6, title: 'Çizgide dur' },
      { t: 5.2, title: 'Önceliği sağdakine ver' },
      { t: 7.6, title: 'Kontrollü geç' },
    ],
    captions: [
      { t: 0, text: 'Işıksız eşit kavşağa yaklaşırken yavaşla; sol, ileri ve sağı tara.' },
      { t: 2.6, text: 'Sağdan gelen araç var — kavşak çizgisinde dur.' },
      { t: 5.2, text: 'Işıksız eşit kavşakta öncelik sağdan gelenindir; geçmesini bekle.' },
      { t: 7.6, text: 'Yol boşaldığında kavşağa kontrollü şekilde gir ve geç.' },
    ],
    svg: `
      ${road(560, 320)}
      <rect y="112" width="560" height="96" fill="${T.road}"/>
      <rect x="232" width="96" height="320" fill="${T.road}"/>
      ${dashes([12, 80, 148, 400, 468], 158, 34)}
      ${[10, 62, 250, 302].map((y) => `<rect x="278" y="${y}" width="4" height="28" rx="2" fill="${T.line}" opacity="0.5"/>`).join('')}
      <rect x="200" y="118" width="6" height="84" fill="${T.line}" opacity="0.85"/>
      <g class="anim-car anim-row-other">${CAR(T.other, { glass: 'rgba(0,0,0,0.28)' })}</g>
      <g class="anim-car anim-row-ego">${CAR(T.ego)}</g>`,
    css: `@keyframes kf-row-ego {
      0%   { transform: translate(-40px, 182px) rotate(90deg); }
      24%  { transform: translate(170px, 182px) rotate(90deg); }
      74%  { transform: translate(170px, 182px) rotate(90deg); }
      100% { transform: translate(600px, 182px) rotate(90deg); }
    }
    @keyframes kf-row-other {
      0%   { transform: translate(302px, 380px) rotate(0deg); }
      14%  { transform: translate(302px, 330px) rotate(0deg); }
      62%  { transform: translate(302px, -70px) rotate(0deg); }
      100% { transform: translate(302px, -70px) rotate(0deg); }
    }
    .anim-row-ego { animation: kf-row-ego 10s ease-in-out infinite; }
    .anim-row-other { animation: kf-row-other 10s ease-in-out infinite; }`,
  }),

  'l-park': withSteps({
    duration: 13,
    title: 'L Park (Dik Park)',
    chapters: [
      { t: 0, title: 'Yanaş ve referansı yakala' },
      { t: 3.2, title: 'Dur, geri vitese al' },
      { t: 5.4, title: 'Direksiyonu tam kır' },
      { t: 9.2, title: 'Düzelt, boşluğa otur' },
    ],
    captions: [
      { t: 0, text: 'Park cebinin yanından yavaşça geç; cebin köşesini referans al.' },
      { t: 3.2, text: 'Aracını cebe dik gelecek konumda durdur ve geri vitese al.' },
      { t: 5.4, text: 'Direksiyonu cep yönüne tam kır ve yavaşça geri gel; arkanı kontrol et.' },
      { t: 9.2, text: 'Araç cebe girince direksiyonu düzelt ve çizgilerin arasına ortala.' },
    ],
    svg: `
      ${road(560, 320)}
      <rect width="560" height="200" fill="${T.road}"/>
      <rect y="196" width="560" height="8" fill="${T.kerb}"/>
      ${dashes([0, 80, 160, 240, 320, 400, 480], 96)}
      <!-- Park alanı: kaldırımın altı GRASS değil, ASFALT olmalı; üç cep yan yana çizilir ki
           "boş cebe dik park" okunsun (ilk sürümde araçlar çim üstünde duruyordu). -->
      <rect y="204" width="560" height="116" fill="${T.roadDark}"/>
      ${[110, 200, 290, 380].map((x) => `<rect x="${x}" y="208" width="3" height="104" fill="${T.line}" opacity="0.8"/>`).join('')}
      <rect x="200" y="208" width="90" height="104" fill="${T.ego}" opacity="0.10"/>
      <g transform="translate(155 262)">${CAR('#8a939d')}</g>
      <g transform="translate(335 262)">${CAR('#8a939d')}</g>
      <g class="anim-car anim-lpark">${CAR(T.ego)}</g>`,
    css: `@keyframes kf-lpark {
      0%   { transform: translate(-40px, 120px) rotate(90deg); }
      24%  { transform: translate(330px, 120px) rotate(90deg); }
      41%  { transform: translate(330px, 120px) rotate(90deg); }
      70%  { transform: translate(292px, 200px) rotate(38deg); }
      88%  { transform: translate(250px, 246px) rotate(6deg); }
      96%, 100% { transform: translate(245px, 262px) rotate(0deg); }
    }
    .anim-lpark { animation: kf-lpark 13s ease-in-out infinite; }`,
  }),

  'u-turn': withSteps({
    duration: 12,
    title: 'U Dönüşü',
    chapters: [
      { t: 0, title: 'Sağa yanaş, kontrol et' },
      { t: 2.8, title: 'Sinyal ver, yavaşla' },
      { t: 5, title: 'Direksiyonu tam sola kır' },
      { t: 9, title: 'Şeride yerleş' },
    ],
    captions: [
      { t: 0, text: 'Dönüş öncesi sağa yanaş; aynalardan ve omuz üstünden arkanı kontrol et.' },
      { t: 2.8, text: 'Sol sinyali ver ve dönüşe girecek kadar yavaşla.' },
      {
        t: 5,
        text: 'Yol boşken direksiyonu tam sola kır; karşı şeride geniş bir yay çizerek dön.',
      },
      { t: 9, text: 'Dönüş bitince direksiyonu düzelt ve karşı şeride düzgün yerleş.' },
    ],
    svg: `
      ${road(560, 320)}
      <rect y="46" width="560" height="228" fill="${T.road}"/>
      <rect y="38" width="560" height="8" fill="${T.kerb}"/>
      <rect y="270" width="560" height="10" fill="${T.kerb}"/>
      <rect y="156" width="560" height="4" fill="${T.line}" opacity="0.85"/>
      ${dashes([20, 100, 180, 260, 340, 420, 500], 98, 34, 3)}
      ${dashes([20, 100, 180, 260, 340, 420, 500], 216, 34, 3)}
      <path d="M120 232 C 120 232, 300 232, 300 190 C 300 148, 160 96, 120 96"
            fill="none" stroke="${T.guide}" stroke-width="2.5" stroke-dasharray="8 8"/>
      <g class="anim-car anim-uturn">${CAR(T.ego)}</g>`,
    css: `@keyframes kf-uturn {
      0%   { transform: translate(-40px, 232px) rotate(90deg); }
      22%  { transform: translate(190px, 232px) rotate(90deg); }
      36%  { transform: translate(268px, 230px) rotate(90deg); }
      52%  { transform: translate(300px, 196px) rotate(30deg); }
      64%  { transform: translate(292px, 150px) rotate(-30deg); }
      76%  { transform: translate(238px, 106px) rotate(-84deg); }
      86%  { transform: translate(170px, 96px) rotate(-90deg); }
      100% { transform: translate(-50px, 96px) rotate(-90deg); }
    }
    .anim-uturn { animation: kf-uturn 12s ease-in-out infinite; }`,
  }),

  'reverse-25m': withSteps({
    duration: 12,
    title: '25 Metre Geri Gidiş',
    chapters: [
      { t: 0, title: 'Başlangıç çizgisinde dur' },
      { t: 2.4, title: 'Geri vites, arkanı kontrol et' },
      { t: 4.6, title: 'Şeridi koruyarak geri git' },
      { t: 9.6, title: 'Bitiş çizgisinde durdur' },
    ],
    captions: [
      { t: 0, text: 'Aracını başlangıç çizgisinde, şeridin ortasında durdur.' },
      { t: 2.4, text: 'Geri vitese al; omuz üstünden ve aynalardan arkanı kontrol et.' },
      {
        t: 4.6,
        text: 'Yavaş ve sabit hızla geri git; direksiyonla küçük düzeltmeler yaparak şeritte kal.',
      },
      { t: 9.6, text: 'Bitiş çizgisini geçmeden, tekerlekler düz hâldeyken aracı durdur.' },
    ],
    svg: `
      ${road(560, 320)}
      <rect y="88" width="560" height="150" fill="${T.road}"/>
      <rect y="80" width="560" height="8" fill="${T.kerb}"/>
      <rect y="234" width="560" height="10" fill="${T.kerb}"/>
      ${dashes([0, 80, 160, 240, 320, 400, 480], 161, 34, 3)}
      <rect x="470" y="88" width="5" height="150" fill="${T.ok}" opacity="0.9"/>
      <rect x="86" y="88" width="5" height="150" fill="${T.danger}" opacity="0.85"/>
      <text x="482" y="82" font-family="Inter,sans-serif" font-size="14" font-weight="700" fill="${T.ok}">başlangıç</text>
      <text x="60" y="82" font-family="Inter,sans-serif" font-size="14" font-weight="700" fill="${T.danger}">bitiş</text>
      <g transform="translate(20 250)">${CONE}</g>
      <g transform="translate(280 250)">${CONE}</g>
      <g transform="translate(540 250)">${CONE}</g>
      <g class="anim-car anim-reverse">${CAR(T.ego)}</g>`,
    css: `@keyframes kf-reverse {
      0%, 18%  { transform: translate(430px, 163px) rotate(90deg); }
      36%      { transform: translate(430px, 163px) rotate(90deg); }
      44%      { transform: translate(392px, 161px) rotate(90deg); }
      60%      { transform: translate(300px, 165px) rotate(90deg); }
      76%      { transform: translate(206px, 161px) rotate(90deg); }
      88%, 100% { transform: translate(128px, 163px) rotate(90deg); }
    }
    .anim-reverse { animation: kf-reverse 12s linear infinite; }`,
  }),

  'hill-start': withSteps({
    duration: 12,
    title: 'Yokuşta Kalkış',
    chapters: [
      { t: 0, title: 'Yokuşta dur, el frenini çek' },
      { t: 3, title: 'Debriyajı kavrama noktasına getir' },
      { t: 6.2, title: 'Gazı ver, el frenini indir' },
      { t: 9, title: 'Geri kaymadan kalk' },
    ],
    captions: [
      { t: 0, text: 'Yokuşta durduğunda el frenini çek; araç geri kaymasın.' },
      { t: 3, text: 'Debriyajı yavaşça bırakıp kavrama noktasını bul — araç hafifçe titrer.' },
      { t: 6.2, text: 'Aynı anda gazı ver ve el frenini kademeli indir.' },
      { t: 9, text: 'Araç geri kaymadan ileri hareket eder; debriyajı tamamen bırak.' },
    ],
    svg: `
      ${road(560, 320)}
      <path d="M0 320 L0 250 L560 96 L560 320 Z" fill="${T.road}"/>
      <path d="M0 250 L560 96" stroke="${T.kerb}" stroke-width="9" fill="none"/>
      <g class="hill-arrow" transform="translate(430 210)">
        <path d="M0 0 L0 46" stroke="${T.danger}" stroke-width="4" opacity="0.9"/>
        <path d="M-8 38 L0 52 L8 38 Z" fill="${T.danger}" opacity="0.9"/>
        <text x="14" y="34" font-family="Inter,sans-serif" font-size="14" font-weight="700" fill="${T.danger}">geri kayma riski</text>
      </g>
      <g class="anim-car anim-hill">${CAR(T.ego)}</g>`,
    css: `@keyframes kf-hill {
      0%, 26%  { transform: translate(190px, 246px) rotate(105deg); }
      /* Kavrama noktası: araç sabit kalır, kaymaz. */
      52%      { transform: translate(190px, 246px) rotate(105deg); }
      /* El freni inerken minik bir salınım — gerçekte hissedilen an. */
      58%      { transform: translate(188px, 248px) rotate(105deg); }
      70%      { transform: translate(240px, 232px) rotate(105deg); }
      100%     { transform: translate(470px, 168px) rotate(105deg); }
    }
    @keyframes kf-hill-warn {
      0%, 44% { opacity: 0.95; }
      62%, 100% { opacity: 0; }
    }
    .anim-hill { animation: kf-hill 12s ease-in infinite; }
    .hill-arrow { animation: kf-hill-warn 12s linear infinite; }`,
  }),

  'common-mistakes': withSteps({
    duration: 14,
    title: 'Sık Yapılan Manevra Hataları',
    chapters: [
      { t: 0, title: 'Çizgiyi aşarak durmak' },
      { t: 4.6, title: 'Dönüşte fazla geniş almak' },
      { t: 9.4, title: 'Aynaya bakmadan geri gitmek' },
    ],
    captions: [
      { t: 0, text: 'Hata: kavşak çizgisini aşarak durmak — yayaların geçiş alanını kapatır.' },
      { t: 2.4, text: 'Doğrusu: çizginin gerisinde, yaya geçidini kapatmadan dur.' },
      { t: 4.6, text: 'Hata: dönüşü fazla geniş almak — karşı şeride taşarsın.' },
      { t: 7, text: 'Doğrusu: dönüşe yavaşlayarak gir ve kendi şeridinde kal.' },
      { t: 9.4, text: 'Hata: aynalara ve arkana bakmadan geri gitmek.' },
      { t: 11.8, text: 'Doğrusu: geri gitmeden önce aynaları ve omuz üstünü kontrol et.' },
    ],
    svg: `
      ${road(560, 320)}
      <rect y="104" width="560" height="120" fill="${T.road}"/>
      <rect x="252" y="0" width="96" height="320" fill="${T.road}" class="scene-2 scene-3"/>
      <rect x="196" y="108" width="6" height="112" fill="${T.line}" opacity="0.85"/>
      ${[210, 226, 242, 258, 274].map((y) => `<rect x="206" y="${y}" width="0" height="0" fill="none"/>`).join('')}
      ${[112, 132, 152, 172, 192].map((y) => `<rect x="150" y="${y}" width="40" height="10" rx="2" fill="${T.line}" opacity="0.45"/>`).join('')}
      <g class="mistake-mark" transform="translate(300 62)">
        <circle r="17" fill="${T.danger}" opacity="0.92"/>
        <path d="M-7 -7 L7 7 M7 -7 L-7 7" stroke="#fff" stroke-width="4" stroke-linecap="round"/>
      </g>
      <g class="fix-mark" transform="translate(300 62)">
        <circle r="17" fill="${T.ok}" opacity="0.92"/>
        <path d="M-8 0 L-2 7 L9 -7" stroke="#fff" stroke-width="4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
      </g>
      <g class="anim-car anim-mistake">${CAR(T.ego)}</g>`,
    css: `@keyframes kf-mistake {
      /* 1) Çizgiyi aşarak durmak → sonra doğrusu */
      0%   { transform: translate(-40px, 164px) rotate(90deg); }
      12%  { transform: translate(250px, 164px) rotate(90deg); }
      17%  { transform: translate(250px, 164px) rotate(90deg); }
      22%  { transform: translate(150px, 164px) rotate(90deg); }
      32%  { transform: translate(150px, 164px) rotate(90deg); }
      /* 2) Dönüşte fazla geniş almak → sonra doğrusu */
      38%  { transform: translate(268px, 164px) rotate(60deg); }
      45%  { transform: translate(322px, 96px) rotate(4deg); }
      50%  { transform: translate(322px, 96px) rotate(4deg); }
      58%  { transform: translate(298px, 130px) rotate(0deg); }
      64%  { transform: translate(298px, 60px) rotate(0deg); }
      /* 3) Aynaya bakmadan geri gitmek → sonra doğrusu */
      68%  { transform: translate(298px, 60px) rotate(180deg); }
      80%  { transform: translate(298px, 196px) rotate(180deg); }
      86%  { transform: translate(298px, 196px) rotate(180deg); }
      100% { transform: translate(298px, 120px) rotate(180deg); }
    }
    @keyframes kf-mistake-mark {
      0%, 2% { opacity: 0; }
      6%, 15% { opacity: 1; }
      19%, 34% { opacity: 0; }
      40%, 48% { opacity: 1; }
      52%, 68% { opacity: 0; }
      72%, 84% { opacity: 1; }
      88%, 100% { opacity: 0; }
    }
    @keyframes kf-fix-mark {
      0%, 21% { opacity: 0; }
      25%, 33% { opacity: 1; }
      37%, 56% { opacity: 0; }
      60%, 66% { opacity: 1; }
      70%, 87% { opacity: 0; }
      92%, 100% { opacity: 1; }
    }
    .anim-mistake { animation: kf-mistake 14s ease-in-out infinite; }
    .mistake-mark { opacity: 0; animation: kf-mistake-mark 14s linear infinite; }
    .fix-mark { opacity: 0; animation: kf-fix-mark 14s linear infinite; }`,
  }),
};
