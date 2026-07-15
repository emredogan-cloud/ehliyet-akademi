/**
 * Teorik akademi — genişletilmiş dersler (Sprint 3). ADR-005 şemasıyla doğrulanır.
 * ÖZGÜN içerik (ROADMAP E.6). Kaynak = resmî MEB/ODSGM müfredatı + Karayolları mevzuatı.
 */
import type { LessonInput } from '@ea/content-schema';

export const THEORY_EXTRA_LESSONS: LessonInput[] = [
  {
    id: 'hiz-takip',
    slug: 'hiz-takip',
    no: 6,
    subject: 'trafik',
    title: 'Hız Sınırları ve Güvenli Takip Mesafesi',
    summary:
      'Yol türüne göre hız sınırları ve öndeki araçla aradaki güvenli mesafenin nasıl korunacağı.',
    minutes: 9,
    objectives: [
      'Yerleşim yeri içi, bölünmüş yol, bölünmemiş yol ve otoyol hız sınırlarını ayırt etmek',
      'İki saniye kuralıyla güvenli takip mesafesini hesaplamak',
      'Kötü hava ve ıslak zeminde mesafeyi neden artırmak gerektiğini açıklamak',
    ],
    sections: [
      {
        heading: 'Yol türüne göre hız sınırları',
        badge: 'official',
        body: 'Otomobil için azami hız, yolun türüne göre değişir: yerleşim yeri içinde **50 km/s**, yerleşim yeri dışındaki bölünmemiş yollarda **90 km/s**, bölünmüş yollarda **110 km/s** ve otoyolda **120 km/s**. Bu değerler tavan sınırdır; hava, görüş ve yol durumu kötüyse yasal sınırın altına inmek zorunludur. Levha varsa levhadaki düşük değer geçerlidir.',
        compare: {
          caption: 'Otomobil için yol türüne göre azami hız',
          headers: ['Yol türü', 'Azami hız'],
          rows: [
            ['Yerleşim yeri içi', '**50 km/s**'],
            ['Bölünmemiş şehirlerarası yol', '**90 km/s**'],
            ['Bölünmüş yol', '**110 km/s**'],
            ['Otoyol', '**120 km/s**'],
          ],
        },
      },
      {
        heading: 'İki saniye kuralı',
        badge: 'safety',
        body: 'Güvenli takip mesafesi metreyle değil, zamanla ölçülür. Öndeki araç sabit bir noktayı (levha, ağaç) geçtiğinde "bir-saniye, iki-saniye" diye sayın; siz aynı noktaya iki saniyeden önce ulaşıyorsanız **çok yakınsınız**. İki saniye, tepki süreniz artı frenleme için gereken en az boşluğu bırakır; hız arttıkça bu süre daha uzun bir mesafeye karşılık gelir.',
        callout: {
          tone: 'info',
          title: 'Aklında kalsın',
          text: 'Mesafeyi metreyle değil zamanla ölç: öndeki araç bir noktayı geçince **iki saniye** sayabiliyorsan mesafe güvenlidir.',
        },
      },
      {
        heading: 'Islak ve kötü havada mesafe',
        badge: 'safety',
        body: 'Yağmur, kar, buz veya sisde lastiklerin yola tutunması azalır ve fren mesafesi belirgin biçimde uzar. Bu koşullarda takip mesafesini **iki katına**, buzlanmada daha da fazlaya çıkarın. Görüşün düştüğü her durumda hızı da düşürmek, mesafeyi büyütmenin en kolay yoludur.',
        callout: {
          tone: 'warning',
          title: 'Islak zeminde dikkat',
          text: 'Yağmur, kar veya buzda fren mesafesi uzar; takip mesafeni **en az iki katına** çıkar ve hızını düşür.',
        },
      },
      {
        heading: 'Neden bu kadar önemli?',
        badge: 'instructor',
        body: 'Arkadan çarpmaların çoğu, hız yüksek olduğu için değil, takip mesafesi yetersiz olduğu için yaşanır. Yeterli boşluk, öndeki sürücünün ani frenine tepki verecek zamanı kazandırır. Mesafe bırakmak korkaklık değil, **hakimiyeti elde tutmaktır**.',
      },
    ],
    mistakes: [
      {
        text: 'Bölünmüş yol ile otoyolu karıştırıp hız sınırını yanlış hatırlamak.',
        fix: 'Bölünmüş yolda **110**, otoyolda **120** km/s; otoyol her zaman en yüksek sınırdır.',
      },
      {
        text: 'Yağmurda normal takip mesafesini korumak.',
        fix: 'Islak zeminde mesafeyi **en az iki katına** çıkarın; fren mesafesi uzar.',
      },
    ],
    tips: ['Soru "en yüksek hız hangisinde" diyorsa cevap neredeyse her zaman otoyoldur (120).'],
    memoryTips: [
      'Sırayı büyükten küçüğe kodla: Otoyol 120 > Bölünmüş 110 > Bölünmemiş 90 > Şehir içi 50.',
      'Mesafe için "iki nokta iki saniye" ikilemesini tekrarla.',
    ],
    examStrategy: [
      'Şıklarda hem yol türü hem hız verildiyse, ikisinin eşleşmesini kontrol et.',
      'Kötü hava geçen sorularda "hızı azalt / mesafeyi artır" yönündeki şık genelde doğrudur.',
    ],
    keyTakeaways: [
      'Şehir içi 50, bölünmemiş 90, bölünmüş 110, otoyol 120 km/s.',
      'Güvenli takip mesafesi iki saniye kuralıyla ölçülür.',
      'Islak/kötü havada mesafeyi en az iki katına çıkar.',
      'Levha varsa levhadaki düşük hız sınırı geçerlidir.',
    ],
    reviewCards: [
      { front: 'Otomobil için otoyolda azami hız?', back: '120 km/s.' },
      { front: 'Yerleşim yeri dışı bölünmemiş yolda azami hız?', back: '90 km/s.' },
      { front: 'Güvenli takip mesafesi nasıl ölçülür?', back: 'İki saniye kuralıyla.' },
    ],
    quizQuestionIds: ['trafik-101', 'trafik-102'],
    practiceQuestionIds: ['trafik-103', 'trafik-104', 'trafik-105'],
    references: ['Karayolları Trafik Yönetmeliği — hız kuralları ve takip mesafesi'],
    figureId: 'following-distance',
  },
  {
    id: 'sollama-serit',
    slug: 'sollama-serit',
    premium: true,
    no: 7,
    subject: 'trafik',
    title: 'Güvenli Sollama ve Şerit Kullanımı',
    summary:
      'Öndeki aracı ne zaman, nereden ve nasıl geçmek güvenlidir; şerit disiplininin kuralları.',
    minutes: 10,
    objectives: [
      'Sollamanın soldan yapılması kuralını ve istisnalarını bilmek',
      'Sollama için karşı yön görüşünün yeterli olup olmadığını değerlendirmek',
      'Sollamanın yasak olduğu yerleri tanımak',
    ],
    sections: [
      {
        heading: 'Sollama soldan yapılır',
        badge: 'official',
        body: 'Kural olarak öndeki araç **sol şeritten** geçilir; sağdan sollama yasaktır. Sollamadan önce ayna kontrolü yapılır, sol sinyal verilir ve arkadan hızlı bir aracın gelmediğinden emin olunur. Geçiş bittiğinde sağ sinyalle güvenli biçimde tekrar sağ şeride dönülür. İstisna: dönel kavşak ve trafiğin şeritlere ayrıldığı durumlar farklı işler.',
        callout: {
          tone: 'danger',
          title: 'Sağdan sollama yasak',
          text: 'Öndeki araç kural olarak **soldan** geçilir; sağdan sollamak kural ihlalidir ve kör noktada kaza riskini artırır.',
        },
      },
      {
        heading: 'Karşı yön görüşü şart',
        badge: 'safety',
        body: 'Sollama, karşı yönden gelen trafiğe ayrılmış alanı geçici olarak kullanmaktır. Bu yüzden **ileriyi ve karşı şeridi net görmeden** sollamaya başlanmaz. Görüş yeterli değilse, sollanan aracın hızını geçmeye elverişli bir hız farkınız yoksa beklemek en güvenlisidir. Tereddüt varsa sollamayın; geri dönüş her zaman mümkün olmayabilir.',
      },
      {
        heading: 'Sollamanın yasak olduğu yerler',
        badge: 'official',
        body: 'Tepe üstü, keskin viraj, yaya geçidi, kavşak, köprü ve tünel gibi görüşün kısıtlı veya çakışma riskinin yüksek olduğu yerlerde sollama **yasaktır**. Kesik çizginin devamlı (tek/çift düz) çizgiye döndüğü yerde de şerit değiştirilmez. Bu noktalar tam da kaza olasılığının en yüksek olduğu yerlerdir.',
        compare: {
          caption: 'Sollamanın yasak olduğu yerler ve nedeni',
          headers: ['Yer', 'Neden yasak'],
          rows: [
            ['Tepe üstü', 'Karşı yön görülemez'],
            ['Keskin viraj', 'Görüş kısıtlıdır'],
            ['Yaya geçidi', 'Yaya aniden çıkabilir'],
            ['Kavşak', 'Çakışma riski yüksektir'],
            ['Köprü ve tünel', 'Dar, kaçış alanı yoktur'],
          ],
        },
      },
      {
        heading: 'Şerit disiplini',
        badge: 'best',
        body: 'Normal koşullarda mümkün olan **en sağ şeritten** ilerlenir; sol şeritler sollama içindir. Sürekli sol şeritte gitmek arkadan gelen trafiği zorlar ve sağdan geçme baskısı yaratır. Şerit değiştirirken daima sinyal verin ve aynada göremediğiniz kör noktayı omuz hareketiyle kontrol edin.',
      },
    ],
    mistakes: [
      {
        text: 'Öndeki aracı sağ şeritten geçmeye çalışmak.',
        fix: 'Sollama **soldan** yapılır; sağdan geçmek kural ihlalidir ve tehlikelidir.',
      },
      {
        text: 'Tepe veya virajda "nasıl olsa gelen yok" diyerek sollamak.',
        fix: 'Görüşün kısıtlı olduğu yerde sollama **yasaktır**; karşıdan araç ansızın çıkabilir.',
      },
    ],
    tips: [
      'Sollamada doğru cevap hemen her zaman "önce görüşün ve mesafenin uygun olması" şartını içerir.',
    ],
    memoryTips: [
      'Sollama yasağı yerlerini "T-V-K-K-T" ile hatırla: Tepe, Viraj, Kavşak, Köprü, Tünel.',
      '"Soldan sol, sağa dön" ritmiyle sinyal sırasını kodla.',
    ],
    examStrategy: [
      'Sağdan sollamayı öneren şık genelde yanlıştır; ilk elemeyi buradan yap.',
      'Görüşün kapalı olduğu bir yer geçiyorsa "sollama yapılmaz" şıkkını öne al.',
    ],
    keyTakeaways: [
      'Sollama kural olarak soldan yapılır.',
      'Karşı yön net görülmeden sollamaya başlanmaz.',
      'Tepe, viraj, kavşak, köprü ve tünelde sollama yasaktır.',
      'Normalde en sağ şeritte gidilir; sol şerit sollama içindir.',
    ],
    reviewCards: [
      { front: 'Öndeki araç hangi taraftan geçilir?', back: 'Kural olarak soldan.' },
      {
        front: 'Sollama nerelerde yasaktır?',
        back: 'Tepe, viraj, kavşak, köprü, tünel ve yaya geçidi gibi görüşün kısıtlı yerlerde.',
      },
      { front: 'Normal seyirde hangi şerit kullanılır?', back: 'Mümkün olan en sağ şerit.' },
    ],
    quizQuestionIds: ['trafik-106', 'trafik-107'],
    practiceQuestionIds: ['trafik-108', 'trafik-109', 'trafik-110'],
    references: ['Karayolları Trafik Yönetmeliği — geçme (sollama) ve şerit kuralları'],
    figureId: 'overtaking',
  },
  {
    id: 'isik-gece',
    slug: 'isik-gece',
    no: 8,
    subject: 'trafik',
    title: 'Farlar ve Gece Sürüşü',
    summary: 'Kısa ve uzun farın ne zaman kullanılacağı, sisde doğru davranış ve gece görünürlüğü.',
    minutes: 8,
    objectives: [
      'Kısa far ile uzun farın kullanım yerlerini ayırt etmek',
      'Sisde hangi ışıkların kullanılacağını bilmek',
      'Karşı araca uzun far yakmanın neden tehlikeli olduğunu açıklamak',
    ],
    sections: [
      {
        heading: 'Kısa far mı, uzun far mı?',
        badge: 'official',
        body: 'Uzun far, önü aydınlatarak uzağı görmenizi sağlar; ancak karşıdan araç geldiğinde veya öndeki aracı yakından takip ederken sürücüyü **kör eder**. Bu yüzden karşılaşmalarda ve şehir içi aydınlatılmış yollarda **kısa far** (yakın huzme) kullanılır. Boş, karanlık kırsal yolda uzun fardan yararlanabilir, karşıdan araç görünce hemen kısaya dönersiniz.',
        compare: {
          caption: 'Hangi durumda hangi far?',
          headers: ['Durum', 'Kullanılacak far'],
          rows: [
            ['Karşıdan araç gelirken', 'Kısa (yakın) far'],
            ['Şehir içi aydınlatılmış yol', 'Kısa far'],
            ['Öndeki aracı yakından takip', 'Kısa far'],
            ['Boş, karanlık kırsal yol', 'Uzun far'],
          ],
        },
      },
      {
        heading: 'Sisde ne yapılır?',
        badge: 'safety',
        body: 'Sisde uzun far, su damlacıklarından yansıyarak önünüzü **beyaz bir perdeye** çevirir ve görüşü azaltır. Bu nedenle sisde **kısa far** ve varsa **sis farları** kullanılır, hız düşürülür, takip mesafesi artırılır. Sis arka lambası aracın arkadan görünmesini sağlar; sis dağılınca göz almaması için kapatılır.',
        callout: {
          tone: 'warning',
          title: 'Siste doğru davranış',
          text: 'Uzun far siste görüşü perde gibi kapatır. Siste **kısa far + sis farı** kullan, hızını düşür, mesafeni artır.',
        },
      },
      {
        heading: 'Karşı araca uzun far yakmayın',
        badge: 'safety',
        body: 'Karşıdan gelen sürücünün gözü uzun farla bir an için kamaşırsa, o kişi birkaç saniye adeta kör sürüş yapar. Bu, gecenin en tehlikeli hatalarından biridir. Karşı araç size uzun far yakarsa ışığa değil, **kendi şeridinizin sağ kenarına** bakarak yolda kalın ve yavaşlayın.',
        callout: {
          tone: 'danger',
          title: 'Karşı araca uzun far yakma',
          text: 'Karşıdan gelenin gözü bir an kamaşırsa birkaç saniye kör sürer. Bu gecenin en tehlikeli hatalarından biridir.',
        },
      },
    ],
    mistakes: [
      {
        text: 'Sisde daha iyi göreceğini sanıp uzun far yakmak.',
        fix: 'Sisde uzun far görüşü bozar; **kısa far ve sis farı** kullanın, yavaşlayın.',
      },
      {
        text: 'Şehir içinde sürekli uzun farla seyretmek.',
        fix: 'Aydınlatılmış yolda ve karşılaşmalarda **kısa fara** geçin.',
      },
    ],
    tips: [
      'Gece sorularında "karşı sürücüyü rahatsız etmeyen / göz kamaştırmayan" seçenek genellikle doğrudur.',
    ],
    memoryTips: [
      'Kural: "Karşılaşma = kısa far" eşlemesini tek cümle olarak sabitle.',
      '"Sis = kısa + yavaş + mesafe" üçlüsünü birlikte ezberle.',
    ],
    examStrategy: [
      'Uzun farı öven şıklara temkinli yaklaş; çoğu senaryoda kısa far istenir.',
      'Görüş azalması geçen her soruda "hızı düşür" içeren şıkkı ciddiye al.',
    ],
    keyTakeaways: [
      'Karşılaşmalarda ve aydınlatılmış yolda kısa far kullanılır.',
      'Uzun far yalnızca boş, karanlık yolda; karşı araç görünce kısaya geçilir.',
      'Sisde kısa far ve sis farı kullanılır, hız düşürülür.',
      'Karşı araca uzun far yakmak sürücüyü kör eder, kaza riskini artırır.',
    ],
    reviewCards: [
      { front: 'Karşıdan araç gelince hangi far kullanılır?', back: 'Kısa (yakın) far.' },
      {
        front: 'Sisde uzun far neden kullanılmaz?',
        back: 'Su damlacıklarından yansıyıp görüşü perde gibi kapatır.',
      },
      {
        front: 'Karşı araç uzun far yakınca nereye bakılır?',
        back: 'Kendi şeridinin sağ kenarına.',
      },
    ],
    quizQuestionIds: ['trafik-111', 'trafik-112'],
    practiceQuestionIds: ['trafik-113', 'trafik-114', 'trafik-115'],
    references: ['Karayolları Trafik Yönetmeliği — ışıkların kullanımı ve gece sürüşü'],
  },
  {
    id: 'yaya-gecidi',
    slug: 'yaya-gecidi',
    no: 9,
    subject: 'trafik',
    title: 'Yayalar ve Geçit Önceliği',
    summary:
      'Yaya geçidinde yayaya öncelik, okul geçidi ve çocuk, yaşlı, engelli yayalara karşı sorumluluk.',
    minutes: 8,
    objectives: [
      'Yaya geçidinde geçiş önceliğinin yayada olduğunu bilmek',
      'Okul geçidi ve okul çevresinde nasıl davranılacağını açıklamak',
      'Çocuk, yaşlı ve engelli yayalara karşı ek özeni uygulamak',
    ],
    sections: [
      {
        heading: 'Yaya geçidinde öncelik yayanındır',
        badge: 'official',
        body: 'Işıkla yönetilmeyen yaya geçitlerinde geçiş önceliği **yayaya** aittir. Geçide yaklaşan sürücü hızını azaltır, gerekirse durur ve yayanın karşıya güvenle geçmesini bekler. Geçitte veya geçide adım atmış yayanın önünden geçmeye çalışmak hem kural ihlalidir hem de en ağır sonuçlu kazalara yol açar.',
        callout: {
          tone: 'danger',
          title: 'Öncelik yayanındır',
          text: 'Işıksız yaya geçidinde geçiş önceliği **yayaya** aittir. Geçide yaklaşırken yavaşla, gerekirse tamamen dur.',
        },
      },
      {
        heading: 'Okul geçidi ve okul çevresi',
        badge: 'safety',
        body: 'Okul geçidi, çocukların yoğun olduğu yerlerde ekstra dikkat isteyen özel bir geçittir. Okul giriş-çıkış saatlerinde ve okul çevresinde hız **iyice düşürülür**, görevli veya geçit görevlisi varsa işaretlerine uyulur. Çocuklar aniden yola çıkabileceği için tahmin edilemez davranışa hazır olmak gerekir.',
      },
      {
        heading: 'Çocuk, yaşlı ve engelliye ek özen',
        badge: 'safety',
        body: 'Çocuk mesafe ve hızı ölçemez, yaşlı yavaş hareket eder, görme engelli beyaz baston veya rehber köpekle yol alır. Bu yayalar için sürücü **her zaman ek önlem** almak, gerektiğinde tamamen durmak zorundadır. Trafikte önceliği güçlünün değil, korunması gerekenin lehine kullanmak temel ilkedir.',
        compare: {
          caption: 'Ek özen gerektiren yayalar',
          headers: ['Yaya', 'Neden ek özen gerekir'],
          rows: [
            ['Çocuk', 'Mesafe ve hızı ölçemez, aniden çıkar'],
            ['Yaşlı', 'Yavaş hareket eder'],
            ['Görme engelli', 'Beyaz baston veya rehber köpekle yürür'],
          ],
        },
      },
    ],
    mistakes: [
      {
        text: 'Yaya geçidine yaklaşırken hız kesmeden geçmeye çalışmak.',
        fix: 'Geçide yaklaşınca **yavaşla, gerekirse dur**; öncelik yayanındır.',
      },
      {
        text: 'Okul çevresinde normal hızla ilerlemek.',
        fix: 'Okul geçidi ve çevresinde hızı **iyice düşür**, ani çıkışa hazır ol.',
      },
    ],
    tips: [
      'Yaya, okul veya çocuk geçen sorularda "yavaşla / dur / yol ver" içeren şık neredeyse her zaman doğrudur.',
    ],
    memoryTips: [
      'Kısaca kodla: "Geçitte yaya kraldır."',
      'Korunması gerekenleri "3Ç-Y-E" ile hatırla: Çocuk, Çevre (okul), Yaşlı, Engelli.',
    ],
    examStrategy: [
      'Sürücünün önceliği kendine aldığı şıkları ele; yaya lehine olan şıkkı seç.',
      'Okul geçidi görselinde beklenen davranış her zaman "hızı azalt ve dikkatli ol"dur.',
    ],
    keyTakeaways: [
      'Işıksız yaya geçidinde öncelik yayanındır.',
      'Okul geçidi ve okul çevresinde hız iyice düşürülür.',
      'Çocuk, yaşlı ve engelli yaya için ek önlem alınır.',
      'Gerektiğinde tam durarak yayanın geçmesi beklenir.',
    ],
    reviewCards: [
      { front: 'Işıksız yaya geçidinde öncelik kimindir?', back: 'Yayanın.' },
      {
        front: 'Okul çevresinde nasıl sürülür?',
        back: 'Hız iyice düşürülür, ani çıkışlara hazır olunur.',
      },
      { front: 'Görme engelli yaya neyle tanınır?', back: 'Beyaz baston veya rehber köpekle.' },
    ],
    quizQuestionIds: ['trafik-116', 'trafik-117'],
    practiceQuestionIds: ['trafik-118', 'trafik-119', 'trafik-120'],
    references: ['Karayolları Trafik Yönetmeliği — yayalara ilişkin kurallar ve geçiş üstünlüğü'],
    figureId: 'pedestrian',
  },
  {
    id: 'cevre-yakit',
    slug: 'cevre-yakit',
    no: 10,
    subject: 'trafik',
    title: 'Çevre ve Ekonomik Sürüş',
    summary:
      'Yakıtı verimli kullanma, gereksiz rölanti ve ani manevralardan kaçınma, egzoz emisyonunu azaltma.',
    minutes: 7,
    objectives: [
      'Ekonomik sürüş alışkanlıklarının yakıt ve çevreye etkisini açıklamak',
      'Gereksiz rölanti ve ani hızlanma/frenin zararlarını bilmek',
      'Egzoz emisyonu ve çevre bilinci arasındaki bağı kurmak',
    ],
    sections: [
      {
        heading: 'Neden ekonomik sürüş?',
        badge: 'best',
        body: 'Yakıtın bir kısmı, sürüş tarzından dolayı boşa gider. Sabit ve öngörülü sürüş; trafiği ileriden okuyarak yumuşak hızlanmak ve zamanında yavaşlamak, hem **yakıt tüketimini** hem de egzozdan çıkan zararlı gazları azaltır. Ekonomik sürüş aynı zamanda daha az fren-lastik aşınması ve daha güvenli bir sürüş demektir.',
        callout: {
          tone: 'success',
          title: 'Ekonomik sürüşün özeti',
          text: 'Yumuşak kalkış ve erken yavaşlama; hem yakıtı hem emisyonu düşürür, üstelik daha güvenlidir.',
        },
      },
      {
        heading: 'Gereksiz rölantiden kaçının',
        badge: 'official',
        body: 'Uzun süre duracaksanız (tren geçişi, uzun kırmızı ışık, beklemeler) motoru rölantide çalışır bırakmak yakıt yakar ve gereksiz emisyon üretir. Motoru boşa çalıştırmak yerine uygun durumlarda durdurmak hem çevreyi hem cebinizi korur. Kısa yol için aracı gereksiz ısıtmak da savurganlıktır.',
      },
      {
        heading: 'Ani hızlanma ve frenden kaçının',
        badge: 'safety',
        body: 'Sert gaz ve ani fren, yakıtı en çok harcatan iki davranıştır ve arkadan gelenler için de risk yaratır. Uygun viteste, motoru zorlamadan ve düşük devirde gitmek; kavşağa yaklaşırken gazı erken bırakıp aracın kendiliğinden yavaşlamasını sağlamak **verimi artırır**. Düzgün bakımlı araç, doğru lastik basıncı da tüketimi düşürür.',
        compare: {
          caption: 'Savurgan davranış yerine ekonomik alternatif',
          headers: ['Savurgan davranış', 'Ekonomik alternatif'],
          rows: [
            ['Uzun süre rölanti', 'Uzun beklemede motoru durdur'],
            ['Sert gaz / ani kalkış', 'Yumuşak hızlan'],
            ['Ani fren', 'Gazı erken bırak, kendiliğinden yavaşla'],
            ['Düşük lastik basıncı', 'Doğru basınç ve düzenli bakım'],
          ],
        },
      },
      {
        heading: 'Egzoz emisyonu ve çevre bilinci',
        badge: 'safety',
        body: 'Egzozdan çıkan gazlar hava kirliliğine ve sağlık sorunlarına yol açar. Düzenli **egzoz emisyon ölçümü**, zamanında bakım ve verimli sürüş bu etkiyi azaltır. Trafikte çevre bilinci; sadece yakıt tasarrufu değil, soluduğumuz havayı ve gelecek nesilleri korumakla ilgili bir sorumluluktur.',
      },
    ],
    mistakes: [
      {
        text: 'Beklerken motoru sürekli rölantide çalışır bırakmak.',
        fix: 'Uzun beklemelerde motoru **gereksiz çalıştırmayın**; yakıt ve emisyon boşa gider.',
      },
      {
        text: 'Her kalkışta sert gaz, her durakta ani fren yapmak.',
        fix: 'Yumuşak hızlan, **erken yavaşla**; tüketim ve risk birlikte düşer.',
      },
    ],
    tips: [
      'Çevre sorularında "yakıt tasarrufu / emisyon azaltma / yumuşak sürüş" içeren şık genellikle doğrudur.',
    ],
    memoryTips: [
      '"Yumuşak kalkış, erken yavaşlama" ikilisini ekonomik sürüşün özeti olarak aklında tut.',
      'Zararlı üçlüyü sil: "rölanti, sert gaz, ani fren".',
    ],
    examStrategy: [
      'Yakıt/çevre sorularında en "sakin ve öngörülü" davranışı öneren şıkkı seç.',
      'Emisyonu artıran davranışı işaretlemeni isteyen sorularda ani/sert olanı ara.',
    ],
    keyTakeaways: [
      'Yumuşak ve öngörülü sürüş yakıtı ve emisyonu azaltır.',
      'Gereksiz rölanti yakıt yakar ve çevreyi kirletir.',
      'Ani hızlanma ve fren tüketimi ve riski artırır.',
      'Düzenli emisyon ölçümü ve bakım çevre bilincinin parçasıdır.',
    ],
    reviewCards: [
      { front: 'Yakıtı en çok harcatan iki davranış?', back: 'Ani hızlanma ve ani fren.' },
      { front: 'Uzun beklemede motor ne yapılmalı?', back: 'Gereksiz rölantide çalıştırılmamalı.' },
      {
        front: 'Egzoz emisyonunu neyle düşürürüz?',
        back: 'Verimli sürüş, düzenli bakım ve emisyon ölçümüyle.',
      },
    ],
    quizQuestionIds: ['trafik-121', 'trafik-122'],
    practiceQuestionIds: ['trafik-123', 'trafik-124', 'trafik-125'],
    references: ['MEB Trafik ve Çevre Bilgisi müfredatı — çevre ve ekonomik sürüş'],
  },
  {
    id: 'yasal-sorumluluk',
    slug: 'yasal-sorumluluk',
    no: 11,
    subject: 'trafik',
    title: 'Yasal Sorumluluklar',
    summary:
      'Sürücü belgesi, zorunlu trafik sigortası, alkol sınırı, emniyet kemeri ve kaza sonrası yükümlülükler.',
    minutes: 10,
    objectives: [
      'Sürücü belgesi ve zorunlu trafik sigortasının neden gerekli olduğunu bilmek',
      'Özel otomobil için alkol sınırını ve emniyet kemeri zorunluluğunu açıklamak',
      'Kaza sonrası sürücünün yasal yükümlülüklerini sıralamak',
    ],
    sections: [
      {
        heading: 'Sürücü belgesi ve zorunlu sigorta',
        badge: 'official',
        body: 'Araç kullanmak için o sınıfa uygun **sürücü belgesine** sahip olmak zorunludur; belgesiz veya uygun olmayan sınıfla sürüş yaptırımı olan bir ihlaldir. Ayrıca her motorlu araç için **Zorunlu Mali Sorumluluk (trafik) Sigortası** yaptırılmalıdır. Bu sigorta, kazada karşı tarafın (üçüncü kişilerin) zararını güvence altına alır; kasko ise isteğe bağlıdır ve kendi aracınızı kapsar.',
        compare: {
          caption: 'Zorunlu trafik sigortası ve kasko farkı',
          headers: ['Özellik', 'Zorunlu trafik sigortası', 'Kasko'],
          rows: [
            ['Yaptırma', '**Zorunlu**', 'İsteğe bağlı'],
            ['Kapsam', 'Karşı tarafın (3. kişi) zararı', 'Kendi aracınız'],
          ],
        },
      },
      {
        heading: 'Alkol sınırı ve emniyet kemeri',
        badge: 'official',
        body: 'Özel otomobil sürücüleri için kandaki alkol sınırı **0,50 promildir**; bu değerin üzerinde araç kullanmak yasaktır. Ticari araç ve bazı sürücüler için sınır sıfır kabul edilir; en güvenlisi alkollüyken hiç direksiyona geçmemektir. Emniyet kemeri ise araçta ilgili koltuklarda **takılması zorunludur**; kaza anında savrulmayı ve ağır yaralanmayı önlediği için hayat kurtarır.',
        callout: {
          tone: 'info',
          title: 'Alkol sınırı',
          text: 'Özel otomobilde kandaki alkol sınırı **0,50 promildir**; ticari araçta sıfır kabul edilir. En doğrusu alkollüyken hiç sürmemektir.',
        },
      },
      {
        heading: 'Kaza sonrası yükümlülükler',
        badge: 'safety',
        body: 'Kazaya karışan sürücü **olay yerinde durmak**, gerekli önlemleri almak (ikaz üçgeni, dörtlü flaşör) ve yaralı varsa yardım sağlayıp ilgili birimlere haber vermek zorundadır. Yaralanmalı kazada araçların yeri işaretlenmeden gereksiz oynatılmaz; ölüm/yaralanma varsa kolluğa (polis/jandarma) haber verilir. Olay yerinden kaçmak ağır sonuçları olan bir suçtur.',
        callout: {
          tone: 'danger',
          title: 'Kaza sonrası sıra: Dur - Önlem - Yardım - Haber',
          text: 'Olay yerinde dur, ikaz üçgeni ve dörtlü flaşörle önlem al, yaralıya yardım et ve gerekiyorsa kolluğa haber ver. **Olay yerinden kaçmak suçtur.**',
        },
      },
      {
        heading: 'Neden hepsi zorunlu?',
        badge: 'instructor',
        body: 'Bu kurallar bürokrasi için değil; belge ehliyeti, sigorta mağduriyeti, alkol sınırı can güvenliğini, kemer ise darbede hayatta kalmayı korur. Yasal sorumluluklar, trafiği herkes için **öngörülebilir ve adil** kılan ortak bir güvenlik sözleşmesidir.',
      },
    ],
    mistakes: [
      {
        text: 'Zorunlu trafik sigortası ile kaskoyu aynı sanmak.',
        fix: 'Zorunlu sigorta karşı tarafın zararını, **kasko** kendi aracınızı kapsar; kasko isteğe bağlıdır.',
      },
      {
        text: '"Bir kadeh bir şey olmaz" diyerek alkollü sürmek.',
        fix: 'Özel otomobilde sınır **0,50 promil**; en doğrusu alkollüyken hiç sürmemektir.',
      },
      {
        text: 'Hafif kazada durmadan yoluna devam etmek.',
        fix: 'Kazada **durmak, önlem almak ve gerekiyorsa bildirmek** yasal zorunluluktur.',
      },
    ],
    tips: [
      'Sigorta sorularında "karşı tarafın zararı" geçiyorsa cevap zorunlu trafik sigortasıdır.',
    ],
    memoryTips: [
      'Alkol sınırını "sıfır virgül elli" olarak sesli tekrarla; özel otomobil için sabittir.',
      'Kaza sonrası sırayı kodla: "Dur - Önlem - Yardım - Haber".',
    ],
    examStrategy: [
      'Rakam soran alkol sorularında 0,50 promili doğrudan işaretle.',
      'Kaza sonrası davranış sorularında "kaçmak / oynatmak" içeren şıkları hemen ele.',
    ],
    keyTakeaways: [
      'Uygun sürücü belgesi ve zorunlu trafik sigortası şarttır.',
      'Özel otomobilde alkol sınırı 0,50 promildir.',
      'Emniyet kemeri ilgili koltuklarda takılması zorunludur.',
      'Kazada dur, önlem al, yardım et ve gerekiyorsa kolluğa haber ver.',
    ],
    reviewCards: [
      { front: 'Özel otomobil sürücüsü için alkol sınırı?', back: '0,50 promil.' },
      {
        front: 'Zorunlu trafik sigortası neyi karşılar?',
        back: 'Karşı tarafın (üçüncü kişilerin) zararını.',
      },
      {
        front: 'Kazaya karışan sürücünün ilk yükümlülüğü?',
        back: 'Olay yerinde durup gerekli önlemleri almak.',
      },
    ],
    quizQuestionIds: ['trafik-126', 'trafik-127'],
    practiceQuestionIds: ['trafik-128', 'trafik-129', 'trafik-130'],
    references: [
      'Karayolları Trafik Kanunu — sürücü belgesi, sigorta ve alkol sınırı',
      'Karayolları Trafik Yönetmeliği — kaza sonrası yükümlülükler',
    ],
  },
  {
    id: 'kanama-sok',
    slug: 'kanama-sok',
    no: 12,
    subject: 'ilkyardim',
    title: 'Dış Kanama ve Şok',
    summary:
      'Dış kanamada doğrudan baskı ve yükseltme, turnikenin son çare oluşu ve şok pozisyonu.',
    minutes: 9,
    objectives: [
      'Dış kanamayı doğrudan baskı ve yükseltmeyle durdurmayı bilmek',
      'Turnikenin yalnızca son çare olduğunu ve saat yazılması gerektiğini açıklamak',
      'Şok belirtilerini tanıyıp doğru pozisyonu vermek',
    ],
    sections: [
      {
        heading: 'Önce doğrudan baskı ve yükseltme',
        badge: 'official',
        body: 'Dış kanamada ilk ve en etkili yöntem, temiz bir bez veya gazlı bezle yara üzerine **doğrudan baskı** uygulamak ve mümkünse kanayan bölgeyi **kalp seviyesinin üstüne kaldırmaktır**. Baskıyı bırakmadan sürdürün; bez kana doyarsa çıkarmadan üzerine yenisini ekleyin. Bu iki basit hareket, kanamaların büyük çoğunluğunu durdurur.',
        compare: {
          caption: 'Dış kanama kontrolünde yöntem sırası',
          headers: ['Yöntem', 'Ne zaman'],
          rows: [
            ['Doğrudan baskı + yükseltme', 'İlk ve en etkili yöntem'],
            ['Bezi çıkarmadan üzerine ekleme', 'Bez kana doyduğunda'],
            ['Turnike', 'Durdurulamayan uzuv kanamasında son çare'],
          ],
        },
      },
      {
        heading: 'Turnike son çaredir',
        badge: 'safety',
        body: 'Turnike ancak baskıyla **durdurulamayan**, hayatı tehdit eden uzuv kanamalarında (örneğin kopma) uygulanır; çünkü uzun süre kan akışını tümden keser ve doku zarar görebilir. Turnike uygulandıysa üzerine **uygulama saati** yazılır ve turnike gevşetilmeden hızla sağlık ekibine ulaşılır. Boyun, gövde gibi turnike konamayan yerlerde yalnızca baskı sürdürülür.',
        callout: {
          tone: 'warning',
          title: 'Turnike son çaredir',
          text: 'Turnike yalnız baskıyla durdurulamayan uzuv kanamasında uygulanır ve üzerine mutlaka **uygulama saati** yazılır.',
        },
      },
      {
        heading: 'Şok ve pozisyonu',
        badge: 'official',
        body: 'Ciddi kanama, sıvı kaybı veya ağır yaralanmada dolaşım bozulur ve **şok** gelişebilir: soluk ve soğuk-nemli deri, hızlı-zayıf nabız, hızlı solunum, huzursuzluk. Bilinci yerinde ve tersini gerektiren bir yaralanma yoksa kazazede sırtüstü yatırılır, **ayakları yaklaşık 30 cm yukarı** kaldırılır (şok pozisyonu) ve üzeri örtülerek **üşümesi önlenir**.',
        callout: {
          tone: 'info',
          title: 'Şok pozisyonu',
          text: 'Sırtüstü yatır, **ayakları ~30 cm yükselt** ve üzerini örterek sıcak tut. Şok belirtisi: soluk, soğuk-nemli deri ve hızlı-zayıf nabız.',
        },
      },
    ],
    mistakes: [
      {
        text: 'Küçük kanamada hemen turnike uygulamak.',
        fix: 'Önce **doğrudan baskı ve yükseltme**; turnike yalnız durdurulamayan uzuv kanamasında son çaredir.',
      },
      {
        text: 'Şoktaki kazazedeyi oturtup üşümesine aldırmamak.',
        fix: 'Sırtüstü yatır, **ayakları yükselt** ve üzerini örterek sıcak tut.',
      },
    ],
    tips: ['Kanama sorularında "doğrudan baskı" içeren şık, aksi belirtilmedikçe ilk tercih olur.'],
    memoryTips: [
      'Kanama sırasını "Baskı - Yükselt - (gerekirse) Turnike" olarak kodla.',
      'Şok pozisyonu için "ayaklar yukarı, üzeri örtülü" ikilisini hatırla.',
    ],
    examStrategy: [
      'Turnikeyi ilk seçenek yapan şıkları çoğu soruda ele; baskı önceliklidir.',
      'Turnike geçen soruda "saatini yaz" ayrıntısı çıkarsa doğru şıkkın işaretidir.',
    ],
    keyTakeaways: [
      'Dış kanamada önce doğrudan baskı ve yükseltme uygulanır.',
      'Turnike sadece durdurulamayan uzuv kanamasında son çaredir; saati yazılır.',
      'Şok belirtisi soluk, soğuk-nemli deri ve hızlı-zayıf nabızdır.',
      'Şok pozisyonunda ayaklar yükseltilir ve kazazede üşütülmez.',
    ],
    reviewCards: [
      {
        front: 'Dış kanamada ilk yöntem nedir?',
        back: 'Doğrudan baskı ve bölgeyi kalp seviyesinin üstüne kaldırmak.',
      },
      {
        front: 'Turnike ne zaman uygulanır?',
        back: 'Baskıyla durdurulamayan, hayatı tehdit eden uzuv kanamasında son çare olarak; saati yazılır.',
      },
      {
        front: 'Şok pozisyonu nasıl verilir?',
        back: 'Sırtüstü yatırılır, ayaklar ~30 cm yükseltilir, üzeri örtülür.',
      },
    ],
    quizQuestionIds: ['ilkyardim-101', 'ilkyardim-102'],
    practiceQuestionIds: ['ilkyardim-103', 'ilkyardim-104', 'ilkyardim-105'],
    references: ['Temel İlk Yardım rehberi — kanama kontrolü ve şok (uzman onayı gereklidir)'],
  },
  {
    id: 'tyd-kalp-masaji',
    slug: 'tyd-kalp-masaji',
    no: 13,
    subject: 'ilkyardim',
    title: 'Temel Yaşam Desteği',
    summary: 'Bilinç ve solunum kontrolü, 112 çağrısı ve doğru kalp masajı ile suni solunum oranı.',
    minutes: 10,
    objectives: [
      'Bilinç ve solunum kontrolünü doğru sırayla yapmak',
      '112 çağrısının ne zaman yapılacağını bilmek',
      'Kalp masajının hız, derinlik ve 30:2 oranını uygulamak',
    ],
    sections: [
      {
        heading: 'Bilinç ve solunum kontrolü',
        badge: 'official',
        body: 'Önce olay yeri güvenliği sağlanır. Kazazedenin omzuna hafifçe dokunup seslenerek **bilinci** kontrol edilir. Yanıt yoksa hava yolunu açmak için **baş geriye, çene yukarı** pozisyonu verilir ve bak-dinle-hisset ile **solunum** 10 saniye kadar değerlendirilir. Bilinç kapalı ve solunum yoksa vakit kaybetmeden temel yaşam desteğine başlanır.',
        callout: {
          tone: 'info',
          title: 'Sıra: Bak - Ara - Bas',
          text: 'Önce bilinci ve solunumu **bak-dinle-hisset** ile kontrol et, sonra 112, sonra kalp masajı.',
        },
      },
      {
        heading: '112 hemen aranır',
        badge: 'safety',
        body: 'Kazazedede bilinç ve solunum yoksa, kalp masajına başlamadan hemen **112 acil çağrı** aranır veya çevredeki birine aratılır. Mümkünse **hoparlör** açılarak yönlendirme alınır ve varsa **OED (otomatik defibrilatör)** istenir. Erken haber vermek, profesyonel ekibin en kısa sürede ulaşması için hayati önemdedir.',
        callout: {
          tone: 'danger',
          title: 'Vakit kaybetme',
          text: 'Bilinç ve solunum yoksa masaja başlamadan hemen **112** aranır veya çevredeki birine aratılır. Gecikme hayat kaybettirir.',
        },
      },
      {
        heading: 'Kalp masajı: hız, derinlik, oran',
        badge: 'official',
        body: 'Eller göğüs kemiğinin ortasına, dirsekler gergin şekilde yerleştirilir. Bası hızı **dakikada 100-120**, derinlik yetişkinde **yaklaşık 5 cm** olmalı ve her basıdan sonra göğsün tam yükselmesine izin verilmelidir. Uygulama **30 kalp masajı + 2 suni solunum** (30:2) döngüsü hâlinde, ekip gelene ya da kazazede canlanma belirtisi gösterene kadar aralıksız sürdürülür.',
        compare: {
          caption: 'Yetişkinde kalp masajı ölçütleri',
          headers: ['Ölçüt', 'Değer'],
          rows: [
            ['Bası hızı', 'Dakikada **100-120**'],
            ['Bası derinliği', 'Yaklaşık **5 cm**'],
            ['Masaj : suni solunum', '**30 : 2**'],
          ],
        },
      },
      {
        heading: 'Hava yolu ve suni solunum',
        badge: 'safety',
        body: 'Suni solunum öncesi hava yolunun açık olması için **baş-çene pozisyonu** korunur; burun kapatılır, ağızdan ağıza göğsü hafifçe kaldıracak kadar nefes verilir. Fazla ve sert üfleme mideye hava kaçırır. Masajı olabildiğince az kesmek, kanın dolaşımını sürdürmek açısından kritiktir.',
      },
    ],
    mistakes: [
      {
        text: 'Kalp masajını çok yavaş veya çok yüzeysel yapmak.',
        fix: 'Hız **100-120/dk**, derinlik **~5 cm**; her basıdan sonra göğüs tam yükselmeli.',
      },
      {
        text: 'Masaja başlamadan uzun uzun ne yapacağına karar vermeye çalışmak.',
        fix: 'Bilinç ve solunum yoksa **112**yi aratıp hemen masaja başla; gecikme hayat kaybettirir.',
      },
    ],
    tips: [
      'TYD sorularında oran her zaman 30:2, hız 100-120/dk, derinlik yaklaşık 5 cm olarak sorulur.',
    ],
    memoryTips: [
      'Sayıları birlikte kodla: "30-2, 100-120, 5 cm".',
      'Sırayı hatırla: "Bak - Ara (112) - Bas".',
    ],
    examStrategy: [
      'Oran soran şıklarda 30:2 dışındaki değerleri ele.',
      'Hava yolu geçen soruda "baş geriye, çene yukarı" içeren şıkkı öne al.',
    ],
    keyTakeaways: [
      'Önce bilinç, sonra solunum kontrol edilir.',
      'Bilinç ve solunum yoksa hemen 112 aranır.',
      'Kalp masajı 100-120/dk hız ve ~5 cm derinlikte yapılır.',
      'Uygulama 30 masaj + 2 solunum (30:2) oranıyla sürdürülür.',
    ],
    reviewCards: [
      {
        front: 'Kalp masajı hızı ve derinliği?',
        back: 'Dakikada 100-120 bası, yaklaşık 5 cm derinlik.',
      },
      { front: 'Masaj/suni solunum oranı?', back: '30 masaj, 2 suni solunum (30:2).' },
      {
        front: 'Hava yolunu açmak için hangi pozisyon?',
        back: 'Baş geriye, çene yukarı pozisyonu.',
      },
    ],
    quizQuestionIds: ['ilkyardim-106', 'ilkyardim-107'],
    practiceQuestionIds: ['ilkyardim-108', 'ilkyardim-109', 'ilkyardim-110'],
    references: ['Temel Yaşam Desteği rehberi — yetişkinde TYD (uzman onayı gereklidir)'],
    figureId: 'cpr',
  },
  {
    id: 'gosterge-ikaz',
    slug: 'gosterge-ikaz',
    no: 14,
    subject: 'motor',
    title: 'Gösterge Paneli İkazları',
    summary:
      'İkaz ışıklarının renk mantığı: kırmızı dur ve acil kontrol demek, sarı en kısa sürede kontrol demektir.',
    minutes: 8,
    objectives: [
      'İkaz ışıklarının renk mantığını (kırmızı/sarı) ayırt etmek',
      'Kırmızı ikazlarda aracı hemen güvenli durdurmayı bilmek',
      'Hararet, yağ basıncı ve şarj ikazlarına doğru tepki vermek',
    ],
    sections: [
      {
        heading: 'İkaz renklerinin anlamı',
        badge: 'official',
        body: 'Gösterge panelindeki ışıklar renk koduyla aciliyet bildirir. **Kırmızı** ikaz "dur / acil" anlamına gelir; ciddi bir arıza veya güvenlik sorunu vardır, araç en kısa sürede güvenli biçimde durdurulmalıdır. **Sarı (turuncu)** ikaz "dikkat, en kısa sürede kontrol ettir" der; yola devam edilebilir ama sorun ihmal edilmemelidir. Yeşil ve mavi ışıklar ise arıza değil, bir sistemin çalıştığını (sinyal, far vb.) gösterir.',
        compare: {
          caption: 'İkaz ışığı renginin anlamı',
          headers: ['Renk', 'Anlam', 'Ne yapmalı'],
          rows: [
            ['Kırmızı', 'Dur / acil', 'Güvenli yerde hemen dur'],
            ['Sarı (turuncu)', 'Dikkat', 'En kısa sürede kontrol ettir'],
            ['Yeşil / Mavi', 'Sistem çalışıyor', 'Arıza değil, bilgilendirir'],
          ],
        },
      },
      {
        heading: 'Kırmızı ikazlar: hemen dur',
        badge: 'safety',
        body: 'Kırmızı yanan **hararet (motor ısısı)**, **yağ basıncı** ve **şarj (akü)** ikazları en kritik olanlardır. Bu ışıklardan biri yolda yanarsa güvenli bir yere çekip motoru durdurmak gerekir; yola devam etmek motora kalıcı ve pahalı hasar verebilir. Kırmızı ikazı "sonra bakarım" diye görmezden gelmek en sık yapılan ve en pahalıya mal olan hatadır.',
        callout: {
          tone: 'danger',
          title: 'Kırmızı acil üçlüsü: Hararet - Yağ - Şarj',
          text: 'Bu ikazlardan biri yolda yanarsa güvenli yere çekip **motoru durdur**; devam etmek motora kalıcı hasar verir.',
        },
      },
      {
        heading: 'Hararet, yağ basıncı, şarj',
        badge: 'official',
        body: 'Hararet ikazı motorun aşırı ısındığını gösterir; durup soğumasını bekleyin, **sıcak motorda radyatör kapağını açmayın**. Yağ basıncı ikazı yağlamanın yetersizliğine işaret eder; motoru derhâl durdurmazsanız parçalar kuru sürtünmeyle zarar görür. Şarj ikazı akünün şarj edilmediğini (genelde alternatör/kayış) gösterir; araç bir süre aküyle gider ama en kısa sürede kontrol ettirilmelidir.',
        callout: {
          tone: 'warning',
          title: 'Sıcak motorda dikkat',
          text: 'Hararet ikazında durup motoru soğut; **sıcak motorda radyatör kapağını açma**, fışkıran sıcak sıvı ağır yanık yapabilir.',
        },
      },
      {
        heading: 'Sarı ikazlar: en kısa sürede kontrol',
        badge: 'instructor',
        body: 'Motor arıza (check), ABS veya lastik basıncı gibi **sarı** ikazlar aracı hemen durdurmayı gerektirmez ama sürüşü etkileyebilir. En yakın uygun yerde veya serviste **en kısa sürede** kontrol ettirmek gerekir. Sarı ikazı erken ele almak, çoğu zaman küçük bir sorunun kırmızı ikaza dönüşmesini önler.',
      },
    ],
    mistakes: [
      {
        text: 'Kırmızı yağ basıncı/hararet ikazıyla yola devam etmek.',
        fix: 'Kırmızı ikazda **güvenli yerde dur ve motoru durdur**; devam motora zarar verir.',
      },
      {
        text: 'Sıcak motorda hemen radyatör kapağını açmak.',
        fix: 'Motorun **soğumasını bekle**; sıcakken kapak açmak yanma riski taşır.',
      },
    ],
    tips: [
      'Gösterge sorularında kırmızı ikaz "dur/acil", sarı ikaz "en kısa sürede kontrol" olarak eşleşir.',
    ],
    memoryTips: [
      'Trafik ışığı mantığıyla eşle: kırmızı = dur, sarı = dikkat/hazırlan.',
      'Kırmızı acil üçlüsünü hatırla: "Hararet, Yağ, Şarj".',
    ],
    examStrategy: [
      'İkaz sorusunda önce ışığın rengini belirle; renk aciliyeti verir.',
      'Kırmızı ikazda "yola devam et" diyen şıkları hemen ele.',
    ],
    keyTakeaways: [
      'Kırmızı ikaz dur/acil, sarı ikaz en kısa sürede kontrol demektir.',
      'Hararet, yağ basıncı ve şarj kırmızı ise araç hemen durdurulur.',
      'Sıcak motorda radyatör kapağı açılmaz.',
      'Sarı ikazlar ihmal edilmeden ilk fırsatta kontrol ettirilir.',
    ],
    reviewCards: [
      {
        front: 'Kırmızı ikaz ışığı ne anlatır?',
        back: 'Dur / acil; araç en kısa sürede güvenle durdurulmalı.',
      },
      { front: 'Sarı (turuncu) ikaz ne anlatır?', back: 'Dikkat; en kısa sürede kontrol ettir.' },
      { front: 'En kritik üç kırmızı ikaz?', back: 'Hararet, yağ basıncı ve şarj (akü).' },
    ],
    quizQuestionIds: ['motor-101', 'motor-102'],
    practiceQuestionIds: ['motor-103', 'motor-104', 'motor-105'],
    references: ['Araç Tekniği — gösterge paneli ikaz ışıkları ve anlamları'],
    figureId: 'dashboard',
  },
];
