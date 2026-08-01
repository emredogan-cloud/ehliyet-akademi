/**
 * ÖZGÜN soru bankası (seed). ROADMAP C.4/E.6:
 * Kaynak = resmî MEB/ODSGM müfredatı + Karayolları mevzuatı + resmî ilk yardım bilgisi.
 * Sorular KENDİ İFADEMİZLE yazılmıştır; hiçbir uygulama/site sorusu kopyalanmamıştır.
 * `review: 'draft'` — yayından önce alan uzmanı (MTSK eğitmeni / ilk yardım eğitmeni) onayı gerekir.
 *
 * Not: Bu seed, motorun çalıştığını kanıtlayan başlangıç kümesidir; ROADMAP Faz 11
 * üretim hattı ile konu başına 100+'a genişletilir.
 */
import type { QuestionInput } from '@ea/content-schema';

const SRC = 'Resmî MEB/ODSGM müfredatı ve Karayolları Trafik mevzuatı (özgün ifade)';
const SRC_FA = 'Resmî temel ilk yardım bilgisi (özgün ifade) — uzman onayı bekliyor';

export const SEED_QUESTIONS: QuestionInput[] = [
  // ——— TRAFİK VE ÇEVRE BİLGİSİ ———
  {
    id: 'trafik-001',
    subject: 'trafik',
    topic: 'isaretler',
    difficulty: 'kolay',
    stem: 'Kırmızı zeminli sekizgen "DUR" levhasının bulunduğu yerde sürücü ne yapmalıdır?',
    options: [
      'Yalnızca yavaşlayıp kavşağa girer',
      'Korna çalarak diğerlerini uyarıp geçer',
      'Kavşak boş görünüyorsa durmadan yavaşlayıp geçer',
      'Tam durur ve geçiş hakkı olana yol verir',
    ],
    answerIndex: 3,
    explanation:
      'DUR levhasında araç, durma çizgisinden önce TAM olarak durmalı ve geçiş üstünlüğü olan trafiğe yol vermelidir. Yavaşlayıp geçmek kural ihlalidir.',
    badge: 'official',
    review: 'draft',
    sourceRef: SRC,
  },
  {
    id: 'trafik-002',
    subject: 'trafik',
    topic: 'hiz',
    difficulty: 'kolay',
    stem: 'Yerleşim yeri içinde otomobiller için genel azami hız sınırı kaç km/saattir?',
    options: ['30', '50', '70', '90'],
    answerIndex: 1,
    explanation:
      'Yerleşim yeri içinde otomobil için genel hız sınırı 50 km/saattir. Levha farklı bir değer gösteriyorsa levha geçerlidir.',
    badge: 'official',
    review: 'draft',
    sourceRef: SRC,
  },
  {
    id: 'trafik-003',
    subject: 'trafik',
    topic: 'oncelik',
    difficulty: 'orta',
    stem: 'Işıklı işaret veya trafik görevlisi bulunmayan, eşit yolların kesiştiği kavşakta geçiş önceliği kimindir?',
    options: ['Soldaki araç', 'Sağdaki araç', 'Büyük olan araç', 'Hızlı gelen araç'],
    answerIndex: 1,
    explanation:
      'Eşit yolların kesiştiği, ışıksız kavşakta sağdan gelen araç önceliklidir ("sağ geçer" kuralı).',
    badge: 'official',
    review: 'draft',
    sourceRef: SRC,
  },
  {
    id: 'trafik-004',
    subject: 'trafik',
    topic: 'takip-mesafesi',
    difficulty: 'orta',
    stem: 'Kuru zeminde, normal koşullarda öndeki araçla güvenli takip mesafesi için pratik kural nedir?',
    options: [
      'En az yarım saniyelik mesafe',
      'Aracın hemen arkasına yaklaşmak',
      'Öndeki aracın plakasını okuyabildiği kadar mesafe',
      'En az iki saniyelik mesafe',
    ],
    answerIndex: 3,
    explanation:
      'Kuru zeminde en az "iki saniye kuralı" önerilir: öndeki araç bir noktayı geçtikten sonra siz aynı noktaya en az iki saniyede ulaşmalısınız. Islak/kaygan zeminde mesafe artırılır.',
    badge: 'safety',
    review: 'draft',
    sourceRef: SRC,
  },
  {
    id: 'trafik-005',
    subject: 'trafik',
    topic: 'donel-kavsak',
    difficulty: 'orta',
    stem: 'Dönel kavşaktan (göbekli kavşak) çıkarken sürücü hangi işareti vermelidir?',
    options: ['Sol sinyal', 'Sağ sinyal', 'Dörtlü flaşör', 'İşaret gerekmez'],
    answerIndex: 1,
    explanation:
      'Dönel kavşaktan çıkmadan hemen önce sağ sinyal verilerek çıkış niyeti bildirilir.',
    badge: 'official',
    review: 'draft',
    sourceRef: SRC,
  },
  {
    id: 'trafik-006',
    subject: 'trafik',
    topic: 'cevre',
    difficulty: 'kolay',
    stem: 'Aşağıdakilerden hangisi yakıt tüketimini ve çevreye verilen zararı azaltır?',
    options: [
      'Düzenli bakım ve uygun viteste, sabit hızla sürmek',
      'Ani hızlanma ve ani frenlerle sürmek',
      'Motoru gereksiz yere rölantide uzun süre çalıştırmak',
      'Lastik basıncını önerilenin çok altında tutmak',
    ],
    answerIndex: 0,
    explanation:
      'Düzenli bakım, uygun vites ve sabit/öngörülü sürüş yakıt tüketimini ve emisyonu düşürür. Ani manevralar ve gereksiz rölanti tüketimi artırır.',
    badge: 'best',
    review: 'draft',
    sourceRef: SRC,
  },

  // ——— İLK YARDIM BİLGİSİ ———
  {
    id: 'ilkyardim-001',
    subject: 'ilkyardim',
    topic: 'temel',
    difficulty: 'kolay',
    stem: 'Bir trafik kazasında ilk yardımın ilk adımı ne olmalıdır?',
    options: [
      'Hemen yaralıyı araçtan çıkarmak',
      'Olay yerinin ve kendinin güvenliğini sağlamak',
      'Yaralıya su vermek',
      "Hemen 112'yi arayıp yaralılara hiç yaklaşmadan beklemek",
    ],
    answerIndex: 1,
    explanation:
      'İlk yardımda önce olay yeri güvenliği sağlanır (kendini ve yaralıyı ikincil kazalardan korumak). Zorunlu olmadıkça yaralı hareket ettirilmez.',
    badge: 'safety',
    review: 'draft',
    sourceRef: SRC_FA,
  },
  {
    id: 'ilkyardim-002',
    subject: 'ilkyardim',
    topic: 'tyd',
    difficulty: 'orta',
    stem: 'Yetişkinde temel yaşam desteğinde göğüs (kalp) masajı dakikada kaç bası hızında yapılmalıdır?',
    options: ['40–60', '60–80', '100–120', '160–180'],
    answerIndex: 2,
    explanation:
      'Yetişkinde kalp masajı dakikada 100–120 bası hızında ve yaklaşık 5 cm derinliğinde uygulanır.',
    badge: 'official',
    review: 'draft',
    sourceRef: SRC_FA,
  },
  {
    id: 'ilkyardim-003',
    subject: 'ilkyardim',
    topic: 'pozisyon',
    difficulty: 'orta',
    stem: 'Bilinci kapalı ancak solunumu ve nabzı olan bir kazazedeye hangi pozisyon verilir?',
    options: [
      'Sırtüstü düz yatış',
      'Yan yatış (koma) pozisyonu',
      'Oturma pozisyonu',
      'Bacaklar yükseltilmiş sırtüstü (şok) pozisyonu',
    ],
    answerIndex: 1,
    explanation:
      'Solunumu olan bilinçsiz kazazedeye, dil kökünün solunum yolunu tıkamasını ve kusmukla boğulmayı önlemek için yan yatış (koma/derlenme) pozisyonu verilir.',
    badge: 'official',
    review: 'draft',
    sourceRef: SRC_FA,
  },
  {
    id: 'ilkyardim-004',
    subject: 'ilkyardim',
    topic: 'kanama',
    difficulty: 'kolay',
    stem: 'Dış kanamalarda uygulanacak ilk ve en temel yöntem hangisidir?',
    options: [
      'Hemen turnike takmak',
      'Bölgeyi soğuk suyla yıkamak',
      'Kanayan bölgeyi kalp seviyesinin altında tutmak',
      'Kanayan bölgeye doğrudan baskı uygulamak',
    ],
    answerIndex: 3,
    explanation:
      'Dış kanamada ilk yöntem, temiz bir bezle kanayan bölgeye doğrudan baskı uygulamak ve mümkünse bölgeyi kalp seviyesinin üstüne kaldırmaktır. Turnike yalnız durdurulamayan, hayatı tehdit eden uzuv kanamalarında son çaredir.',
    badge: 'safety',
    review: 'draft',
    sourceRef: SRC_FA,
  },
  {
    id: 'ilkyardim-005',
    subject: 'ilkyardim',
    topic: 'temel',
    difficulty: 'orta',
    stem: 'İlk yardımın öncelikli değerlendirme sırası olan "ABC" neyi ifade eder?',
    options: [
      'Ağrı - Bilinç - Ciğer kontrolü',
      'Ateş - Baygınlık - Cilt rengi',
      'Acil - Bilinç - Can güvenliği',
      'Hava yolu - Solunum - Dolaşım',
    ],
    answerIndex: 3,
    explanation:
      'ABC; Hava yolu (Airway) açıklığı, Solunum (Breathing) ve Dolaşım (Circulation) değerlendirmesidir — yaşamsal işlevlerin öncelik sırasıdır.',
    badge: 'official',
    review: 'draft',
    sourceRef: SRC_FA,
  },

  // ——— ARAÇ TEKNİĞİ (MOTOR) ———
  {
    id: 'motor-001',
    subject: 'motor',
    topic: 'yaglama',
    difficulty: 'kolay',
    stem: 'Motor yağının temel görevi aşağıdakilerden hangisidir?',
    options: [
      'Silindire giren yakıt-hava karışımını kıvılcımla ateşleyerek yakmak',
      'Hareketli parçaları yağlayarak sürtünme ve aşınmayı azaltmak',
      'Ön camdaki kir ve böcek kalıntılarını temizleyip görüşü açmak',
      'Yakıtın oktan değerini yükseltip vuruntuyu önlemek',
    ],
    answerIndex: 1,
    explanation:
      'Motor yağı; hareketli parçaları yağlar, sürtünme ve aşınmayı azaltır, ayrıca soğutmaya ve temizlemeye yardımcı olur.',
    badge: 'official',
    review: 'draft',
    sourceRef: SRC,
  },
  {
    id: 'motor-002',
    subject: 'motor',
    topic: 'fren',
    difficulty: 'orta',
    stem: 'ABS (kilitlenmeyi önleyici fren sistemi) ani ve sert frenlemede ne sağlar?',
    options: [
      'Tekerleklerin kilitlenmesini önleyerek yönlendirme kontrolünü korur',
      'Ani frende motor devrini düşürüp aracın kendiliğinden durmasını sağlar',
      'Yakıt tüketimini azaltarak deponun daha uzun süre dayanmasını sağlar',
      'Fren balatalarının ömrünü iki katına çıkarıp bakım maliyetini düşürür',
    ],
    answerIndex: 0,
    explanation:
      'ABS, sert frenlemede tekerleklerin kilitlenip kaymasını önler; böylece sürücü fren yaparken direksiyon hakimiyetini korur.',
    badge: 'official',
    review: 'draft',
    sourceRef: SRC,
  },
  {
    id: 'motor-003',
    subject: 'motor',
    topic: 'aku',
    difficulty: 'kolay',
    stem: 'Aracın aküsünün (akümülatör) temel görevi nedir?',
    options: [
      'Motorun ürettiği ısıyı dışarı atarak çalışma sıcaklığını dengelemek',
      'Elektrik enerjisi depolayıp aracın elektrik sistemini beslemek',
      'Yakıttaki tortu ve suyu süzerek motora temiz yakıt göndermek',
      'Motorun devrini sınırlayıp aşırı hıza çıkmasını engellemek',
    ],
    answerIndex: 1,
    explanation:
      'Akü, elektrik enerjisini depolar; marş anında ve elektrikli sistemlerin çalışmasında bu enerjiyi sağlar.',
    badge: 'official',
    review: 'draft',
    sourceRef: SRC,
  },
  {
    id: 'motor-004',
    subject: 'motor',
    topic: 'aktarma',
    difficulty: 'orta',
    stem: 'Motorda üretilen gücü tekerleklere ileten sistem hangisidir?',
    options: ['Fren sistemi', 'Yakıt sistemi', 'Aydınlatma sistemi', 'Aktarma organları'],
    answerIndex: 3,
    explanation:
      'Aktarma organları (debriyaj, vites kutusu, şaft ve diferansiyel) motor gücünü tekerleklere iletir.',
    badge: 'official',
    review: 'draft',
    sourceRef: SRC,
  },
  {
    id: 'motor-005',
    subject: 'motor',
    topic: 'hararet',
    difficulty: 'orta',
    stem: 'Gösterge panelinde motor ısı (hararet) ikazı kırmızı bölgeye geldiğinde ne yapılmalıdır?',
    options: [
      'Hız artırılıp hava akımıyla soğuması sağlanır',
      'Güvenli bir yerde durulup motorun soğuması beklenir',
      'Klima açılıp motor yükü azaltılarak yola devam edilir',
      'Radyatör kapağı hemen açılıp içine soğuk su doldurulur',
    ],
    answerIndex: 1,
    explanation:
      'Motor hararet yapıyorsa güvenli bir yerde durulmalı ve motor soğutulmalıdır; sıcak motorda radyatör/soğutma kapağı açılmaz.',
    badge: 'safety',
    review: 'draft',
    sourceRef: SRC,
  },

  // ——— TRAFİK ADABI ———
  {
    id: 'adab-001',
    subject: 'adab',
    topic: 'oncelik-yaya',
    difficulty: 'kolay',
    stem: 'Yaya geçidine yaklaşan bir sürücünün trafik adabına uygun davranışı nedir?',
    options: [
      'Korna çalarak yayanın adımlarını hızlandırmasını beklemek',
      'Yavaşlayıp gerekiyorsa durarak yayaya yol vermek',
      'Yayadan önce hızlanıp geçidi boşaltmaya çalışmak',
      'Yayaya el işareti yapıp aynı hızda geçmek',
    ],
    answerIndex: 1,
    explanation:
      'Yaya geçidinde öncelik yayanındır. Saygılı ve güvenli davranış, yavaşlayıp gerektiğinde durarak yol vermektir.',
    badge: 'official',
    review: 'draft',
    sourceRef: SRC,
  },
  {
    id: 'adab-002',
    subject: 'adab',
    topic: 'ofke',
    difficulty: 'orta',
    stem: 'Trafikte öfke ve stresle başa çıkmanın en uygun yolu hangisidir?',
    options: [
      'Karşı sürücüye tepki gösterip hakkını sonuna kadar aramak',
      'Hızlanarak biriken öfkeyi üzerinden atmaya çalışmak',
      'Müziği açıp diğer sürücüleri tümüyle görmezden gelmek',
      'Sakin kalıp empati kurmak ve güvenliği önceliklendirmek',
    ],
    answerIndex: 3,
    explanation:
      'Trafik adabının temeli; sakinlik, empati ve hoşgörüdür. Öfkeli tepkiler kaza riskini artırır; can güvenliği her zaman önce gelir.',
    badge: 'instructor',
    review: 'draft',
    sourceRef: SRC,
  },
  {
    id: 'adab-003',
    subject: 'adab',
    topic: 'gecis-ustunlugu',
    difficulty: 'orta',
    stem: 'Arkadan siren ve tepe lambasıyla gelen bir ambulans için sürücü ne yapmalıdır?',
    options: [
      'Şeridi kapatıp ambulansın kendi yolunu bulmasını beklemek',
      'Güvenli şekilde sağa yanaşıp geçiş kolaylığı sağlamak',
      'Hızlanıp ambulansın önünden gitmeyi sürdürmek',
      'Kırmızı ışıkta bile hemen kavşağa girip yol açmak',
    ],
    answerIndex: 1,
    explanation:
      'Geçiş üstünlüğüne sahip araçlara (ambulans, itfaiye vb.) güvenli biçimde yol verilmeli, geçiş kolaylığı sağlanmalıdır.',
    badge: 'official',
    review: 'draft',
    sourceRef: SRC,
  },
  {
    id: 'adab-004',
    subject: 'adab',
    topic: 'sorumluluk',
    difficulty: 'kolay',
    stem: 'Trafikte "değerli olan can güvenliğidir" ilkesi neyi vurgular?',
    options: [
      'Bir an önce varış noktasına ulaşmanın önceliğini',
      'Trafikte en deneyimli sürücünün haklı sayılmasını',
      'Pahalı ve büyük araçların geçiş üstünlüğünü',
      'Kurallara ve diğer yol kullanıcılarına saygıyı',
    ],
    answerIndex: 3,
    explanation:
      'Trafik adabı; kurallara ve tüm yol kullanıcılarına (yaya, bisikletli, sürücü) saygıyı ve can güvenliğini her şeyin üstünde tutmayı vurgular.',
    badge: 'best',
    review: 'draft',
    sourceRef: SRC,
  },

  // ——— PRATİK (DİREKSİYON) — v1 ile tutarlı ———
  {
    id: 'pratik-001',
    subject: 'pratik',
    topic: 'puanlama',
    difficulty: 'kolay',
    stem: 'Direksiyon uygulama sınavında araca binince emniyet kemerini takmamak hangi hata sınıfındadır?',
    options: ['Mavi (küçük) hata', 'Sarı (tali) hata', 'Yeşil (uyarı) hata', 'Kırmızı (asli)'],
    answerIndex: 3,
    explanation:
      'Emniyet kemerini takmamak asli (kırmızı) kusurdur ve tek başına sınavdan elenmeye yol açar. Hata — anında elenme.',
    badge: 'official',
    review: 'draft',
    sourceRef: 'MTSK direksiyon değerlendirme çizelgesi (özgün ifade)',
  },
  {
    id: 'pratik-002',
    subject: 'pratik',
    topic: 'puanlama',
    difficulty: 'orta',
    stem: 'Direksiyon sınavında kaç mavi (küçük) hata elenme sebebidir?',
    options: ['2', '3', '5', '10'],
    answerIndex: 2,
    explanation:
      '5 mavi hata elenme sebebidir; en fazla 4 mavi hataya kadar sınav devam eder. (1 kırmızı veya 2 sarı da elenmedir.)',
    badge: 'official',
    review: 'draft',
    sourceRef: 'MTSK direksiyon değerlendirme çizelgesi (özgün ifade)',
  },
  {
    id: 'pratik-003',
    subject: 'pratik',
    topic: 'rampa',
    difficulty: 'orta',
    stem: 'Rampada (yokuşta) kalkışta aracın kaç cm’den fazla geri kayması sarı hata sayılır?',
    options: ['5 cm', '10 cm', '30 cm', '1 metre'],
    answerIndex: 2,
    explanation:
      '30 cm’den fazla geri kayma tali (sarı) hata olarak değerlendirilir. El freni yöntemiyle geri kayma önlenir.',
    badge: 'official',
    review: 'draft',
    sourceRef: 'MTSK direksiyon değerlendirme çizelgesi (özgün ifade)',
  },
];
