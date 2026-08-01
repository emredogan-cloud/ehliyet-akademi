/**
 * A (motosiklet) ve D (otobüs) sınıfına ÖZGÜ dersler — Evolution Faz E5.
 *
 * NEDEN AYRI DOSYA: `LESSONS` web uygulamasının ders kütüphanesidir (sayfalar, site haritası, QIP
 * grafiği ondan türer) ve DEĞİŞMEZ. Buradaki dersler yalnız mobil içerik anlık görüntüsüne eklenir
 * (`ALL_LESSONS`) — `vehicle-licence.ts` / `MOBILE_PRODUCTS` ile aynı toplama deseni.
 *
 * KAPSAM İLKESİ: Türkiye'de e-Sınav teori soru bankası tüm sınıflar için ORTAKTIR. Bu dersler ayrı
 * bir sınav uydurmaz; ortak teoriye EK olarak, sınıfa özgü araç kullanma tekniği, mekanik ve mevzuat
 * farkını anlatır. Ortak dersler etiketsizdir ve her sınıfta görünmeye devam eder.
 *
 * KAYNAK DİSİPLİNİ: sayısal/hukuki iddialar yalnız birincil mevzuat metninden yazılmıştır —
 * 2918 sayılı Karayolları Trafik Kanunu (KTK) ve Karayolları Trafik Yönetmeliği (KTY). Kaynağı
 * doğrulanamayan hiçbir sayı yazılmamıştır (gerekçeler faz raporunda).
 */
import type { LessonInput } from '@ea/content-schema';

/** A sınıfı — motosiklet. */
export const MOTO_LESSONS: LessonInput[] = [
  {
    id: 'moto-koruyucu-donanim',
    slug: 'moto-koruyucu-donanim',
    no: 20,
    subject: 'trafik',
    licences: ['a'],
    title: 'Motosiklette Koruyucu Donanım',
    summary:
      'Koruma başlığı (kask) ve gözlüğün yasal zorunluluğu, "usulüne uygun kullanım" ne demek ve kaskın dışında ne giyilir?',
    minutes: 8,
    objectives: [
      'Koruma başlığı ve gözlüğün yasal dayanağını bilmek',
      '"Usulüne uygun kullanım" ölçütünü uygulamak',
      'Kask dışındaki koruyucu donanımı ve neyi koruduğunu saymak',
    ],
    sections: [
      {
        heading: 'Kask yasal bir zorunluluktur',
        badge: 'official',
        body: 'Karayolları Trafik Kanunu, araçların sürülmesi sırasında **koruma başlığı ve koruma gözlüğünün** usulüne uygun kullanılmasını zorunlu tutar. Bu zorunluluk yalnız sürücüyü değil, **yolcuyu** da kapsar. Kanun ayrıca çok net bir ölçüt koyar: **koruyucu sistemi usulüne uygun kullanmayan, hiç kullanmamış sayılır.** Yani başta duran ama kayışı bağlanmamış bir kask, hukuken de fiilen de kask değildir.',
        callout: {
          tone: 'danger',
          title: 'Bağlanmamış kask = kasksız',
          text: 'Kayışı bağlı değilse kask ilk darbede kafadan ayrılır. Mevzuat da bu durumu **kullanmamış** sayar; ceza ve koruma kaybı birlikte gelir.',
        },
      },
      {
        heading: 'Kaskın dışında ne giyilir?',
        badge: 'safety',
        body: 'Motosiklette karoser yoktur; **giydiğin şey karoserdir.** Düşmede ilk temas eden yerler el, diz ve omuzdur. Bu yüzden eldiven, korumalı mont/pantolon, bileği kapatan bot ve dizlik kaskın tamamlayıcısıdır — biri eksikse zincirin o halkası kopar.',
        compare: {
          caption: 'Her parça farklı bir yaralanmayı önler',
          headers: ['Donanım', 'Neyi korur', 'Kontrol'],
          rows: [
            [
              'Koruma başlığı (kask)',
              'Kafa travması — en ölümcül yaralanma',
              'Kayış bağlı, siperlik temiz, çatlak yok',
            ],
            [
              'Eldiven',
              'Düşerken refleksle yere basan eller',
              'Dikişler sağlam, avuç içi aşınmamış',
            ],
            [
              'Korumalı mont / pantolon',
              'Omuz, dirsek, kalça sıyrıkları',
              'Koruyucu pedler yerinde',
            ],
            [
              'Bilek üstü bot',
              'Ayak bileği burkulma ve ezilmesi',
              'Taban kaymaz, bilek desteği sert',
            ],
            ['Dizlik', 'Diz kapağı — düşüşte ikinci temas noktası', 'Kayışlar gevşemiyor'],
          ],
        },
      },
      {
        heading: 'Görünürlük de donanımın parçasıdır',
        badge: 'best',
        body: 'Motosiklet kazalarının büyük bölümünde diğer sürücünün ifadesi aynıdır: **"görmedim".** Motosiklet dar ve alçaktır; aynada kolayca kaybolur. Açık renkli kask, reflektif yelek ve gündüz de açık tutulan kısa far, seni "görülebilir bir nesne" hâline getirir. Bu bir stil tercihi değil, aktif güvenlik önlemidir.',
      },
    ],
    mistakes: [
      {
        text: 'Kaskı takıp kayışını bağlamamak veya gevşek bırakmak.',
        fix: 'Kayış çene altında **iki parmak** boşluk kalacak şekilde bağlanır; kask sağa-sola oynamamalı.',
      },
      {
        text: 'Kısa mesafe için "nasılsa yakın" deyip donanımsız binmek.',
        fix: 'Kazaların çoğu **yakın mesafede ve düşük hızda** olur; donanım mesafeye göre seçilmez.',
      },
    ],
    tips: [
      'Kaskı yere veya aynanın üstüne bırakma; görünmeyen bir çatlak koruma değerini bitirir.',
    ],
    memoryTips: [
      'Sıralamayı baştan aşağı kodla: **K**ask, **E**ldiven, **M**ont, **B**ot, **D**izlik.',
      '"Usulüne uygun" = **kayış bağlı**. Bağlı değilse yok sayılır.',
    ],
    examStrategy: [
      'Kask sorularında "sadece sürücü için zorunludur" diyen şık genelde yanlıştır; yolcu da kapsamdadır.',
      'Donanım sorularında "kısa mesafede gerekmez" içeren şıkkı ilk elemede at.',
    ],
    keyTakeaways: [
      'Koruma başlığı ve gözlüğün usulüne uygun kullanımı kanunen zorunludur.',
      'Usulüne uygun kullanmayan, kullanmamış sayılır.',
      'Kask tek başına yeterli değildir: eldiven, mont, bot, dizlik zincirin halkalarıdır.',
    ],
    reviewCards: [
      {
        front: 'Kask kayışı bağlanmamışsa mevzuat ne der?',
        back: 'Koruyucu sistemi usulüne uygun kullanmayan, kullanmamış sayılır.',
      },
      { front: 'Kask zorunluluğu kimleri kapsar?', back: 'Sürücüyü ve yolcuyu birlikte.' },
    ],
    references: [
      '2918 sayılı Karayolları Trafik Kanunu — madde 78 (koruma başlığı ve koruma gözlüğü)',
    ],
  },
  {
    id: 'moto-kumandalar-kalkis',
    slug: 'moto-kumandalar-kalkis',
    no: 21,
    subject: 'motor',
    licences: ['a'],
    title: 'Motosiklet Kumandaları ve Kalkış',
    summary:
      'Sağ ve sol gidonun görev dağılımı, kill anahtarı, vites şeması ve kavrama noktasıyla düzgün kalkış.',
    minutes: 9,
    objectives: [
      'Kumandaların hangi elde/ayakta olduğunu ezberden söylemek',
      'Motor çalışmıyorsa önce neye bakılacağını bilmek',
      'Kavrama noktasını kullanarak sarsıntısız kalkmak',
    ],
    sections: [
      {
        heading: 'Sağ el hız, sol el kavrama',
        badge: 'official',
        body: 'Motosiklette kumandalar **dört uzva** dağılmıştır ve bu dağılım neredeyse tüm motosikletlerde aynıdır. Sağ el gaz ve ön freni, sol el debriyajı, sağ ayak arka freni, sol ayak vitesi yönetir. Bu dört noktayı ezberlemek, panik anında doğru refleksin temelidir.',
        compare: {
          caption: 'Dört uzuv, dört görev',
          headers: ['Uzuv', 'Kumanda', 'İşlevi'],
          rows: [
            ['Sağ el', 'Gaz kolu + ön fren kolu', 'Hızlanma ve frenlemenin büyük bölümü'],
            ['Sol el', 'Debriyaj kolu', 'Motor gücünü tekerlekten ayırır'],
            ['Sağ ayak', 'Arka fren pedalı', 'Dengeyi bozmadan yavaşlatma'],
            ['Sol ayak', 'Vites kolu', 'Vites büyütme / küçültme'],
          ],
        },
      },
      {
        heading: 'Marş basmıyorsa önce kill anahtarına bak',
        badge: 'instructor',
        body: 'Sağ gidondaki kırmızı **motor durdurma (kill) anahtarı**, kontağa uzanmadan motoru anında kesmek içindir. Acil durumun kurtarıcısıdır ama en sık yaşanan "motor çalışmıyor" sorununun da sebebidir. Ayrıca çoğu motosiklette güvenlik kilidi vardır: **yan sehpa açıkken vitesteyse marş çalışmaz.**',
        callout: {
          tone: 'info',
          title: 'Çalışmama üçlüsü',
          text: 'Sırayla kontrol et: **kill anahtarı RUN mu**, **yan sehpa kalktı mı**, **vites boşta veya debriyaj çekili mi?**',
        },
      },
      {
        heading: 'Vites şeması ve kalkış',
        badge: 'best',
        body: 'Yaygın şema **1 aşağı, gerisi yukarı**dır; boş (N) birinci ile ikinci arasındadır. Kalkışta debriyaj yavaş bırakılır, gaz kademeli verilir. Kavrama noktası kolun ilk üçte birindedir: motorun sesi hafif değişip motosiklet öne yüklendiğinde nokta yakalanmış demektir. Ayaklar, motosiklet yürümeye başladıktan sonra basamaklara alınır.',
      },
    ],
    mistakes: [
      {
        text: 'Kalkışta debriyajı bir anda bırakmak.',
        fix: 'Kavrama noktasında **bekle**, gazı kademeli aç; motosiklet yürüyünce kolu tamamen bırak.',
      },
      {
        text: 'Sinyali dönüş bittikten sonra kapatmayı unutmak.',
        fix: 'Motosiklet sinyalleri çoğunlukla kendiliğinden sönmez; dönüş biter bitmez **elle iptal et**.',
      },
    ],
    tips: [
      'Kontağı açınca gösterge lambalarının yanıp sönmesini bekle — sistem kendini test eder.',
    ],
    memoryTips: [
      '"Sağ hızlandırır ve durdurur, sol ayırır ve vitesler" cümlesiyle dört uzvu sabitle.',
      'Vitesi "**bir aşağı, gerisi yukarı**" ritmiyle kodla; N ikisinin arasında.',
    ],
    examStrategy: [
      'Kumanda sorularında "ön fren sol eldedir" gibi yer değiştirmiş şıklar klasik çeldiricidir.',
      'Marş sorularında güvenlik kilidi (yan sehpa) geçen şıkkı ciddiye al.',
    ],
    keyTakeaways: [
      'Sağ el gaz + ön fren, sol el debriyaj, sağ ayak arka fren, sol ayak vites.',
      'Marş basmıyorsa önce kill anahtarı, yan sehpa ve vites kontrol edilir.',
      'Kavrama noktası kolun ilk üçte birindedir.',
    ],
    reviewCards: [
      { front: 'Ön fren hangi kumandadadır?', back: 'Sağ gidondaki fren kolu.' },
      {
        front: 'Yan sehpa açıkken vitese takılırsa ne olur?',
        back: 'Güvenlik kilidi devreye girer; motor çalışmaz veya stop eder.',
      },
    ],
    references: ['Motosiklet kullanma tekniği — temel kumanda düzeni'],
  },
  {
    id: 'moto-fren-viraj',
    slug: 'moto-fren-viraj',
    no: 22,
    subject: 'pratik',
    licences: ['a'],
    title: 'Frenleme, Motor Freni ve Viraj Tekniği',
    summary:
      'Ön–arka fren dağılımı, ağırlık transferi, motor freniyle yavaşlama ve virajda bakış–yatış düzeni.',
    minutes: 10,
    objectives: [
      'Ön ve arka freni birlikte ve doğru oranda kullanmak',
      'Motor freniyle yavaşlamayı frenle birleştirmek',
      'Virajı yavaşla–bak–yatır–gazla sırasıyla almak',
    ],
    sections: [
      {
        heading: 'Frenleme: ağırlık öne biner',
        badge: 'official',
        body: 'Frenlemede ağırlık öne aktarılır; ön lastiğin yere baskısı artar, arkanın azalır. Bu yüzden **frenleme gücünün büyük bölümü ön frenden** gelir, arka fren dengeyi ve yönü korur. İkisi birlikte, **kademeli** olarak sıkılır: önce hafif temas, sonra artan basınç. Ani ve tek noktadan yapılan frenleme tekerleği kilitler.',
        compare: {
          caption: 'Duruma göre fren dağılımı',
          headers: ['Durum', 'Fren kullanımı', 'Neden'],
          rows: [
            [
              'Düz yolda normal yavaşlama',
              'Ön ağırlıklı + arka destek',
              'En kısa mesafe, denge korunur',
            ],
            [
              'Islak / kaygan zemin',
              'Her ikisi de **yumuşak** ve erken',
              'Tutunma az; ani girdi kaymayı başlatır',
            ],
            [
              'Virajda yatarken',
              'Mümkünse fren yok — önce doğrul',
              'Yatıkken lastiğin fren payı kalmamıştır',
            ],
            [
              'Çok düşük hızda manevra',
              'Arka fren + debriyaj',
              'Ön fren düşük hızda dengeyi bozar',
            ],
          ],
        },
      },
      {
        heading: 'Motor freni: bedava yavaşlama',
        badge: 'best',
        body: 'Gaz kesildiğinde motor tekerleği yavaşlatır — buna **motor freni** denir. Uzun inişlerde vites küçülterek motor frenini artırmak, fren balatalarını ısınmaktan korur ve motosikleti daha kararlı tutar. Ancak vites çok sert düşürülürse arka tekerlek kilitlenip zıplayabilir; debriyaj kademeli bırakılır.',
        callout: {
          tone: 'warning',
          title: 'Uzun inişte tek başına fren yetmez',
          text: 'İnişte sürekli fren tutmak balatayı ısıtır ve etkisini düşürür. **Uygun vitese in, motor freni çalışsın**, servis frenini kısa aralıklarla kullan.',
        },
      },
      {
        heading: 'Viraj: yavaşla – bak – yatır – gazla',
        badge: 'instructor',
        body: 'Virajın hızı **girmeden önce** ayarlanır. Viraja doğru hızla girildikten sonra bakış virajın **çıkışına** çevrilir; motosiklet bakılan yere gider. Yatış başladıktan sonra gaz sabit tutulur veya hafifçe açılır — bu, aracı kararlı kılar. Viraj içinde gaz kesmek veya fren yapmak, dengeyi bozan en yaygın hatadır.',
        callout: {
          tone: 'danger',
          title: 'Virajda sert ön fren',
          text: 'Motosiklet yatıkken sert ön fren yapılırsa ön tekerlek tutunmasını kaybeder ve **kayma** başlar. Önce motosikleti dikleştir, sonra fren yap.',
        },
      },
    ],
    mistakes: [
      {
        text: 'Viraja fazla hızlı girip içeride fren yapmak.',
        fix: 'Hız **viraj öncesinde** ayarlanır; içeride sabit gaz ile geçilir.',
      },
      {
        text: 'Sadece arka freni kullanmak.',
        fix: 'Arka fren tek başına duruş mesafesini uzatır; **ön ve arka birlikte** kullanılır.',
      },
      {
        text: 'Bakışı virajın hemen önüne sabitlemek.',
        fix: 'Bakışı **çıkışa** çevir; motosiklet baktığın yere yönelir.',
      },
    ],
    tips: ['Islak zeminde her girdiyi yarı yarıya yumuşat: fren de gaz da yönlendirme de.'],
    memoryTips: [
      'Viraj ritmini dört kelimeyle sabitle: **Yavaşla – Bak – Yatır – Gazla.**',
      'Fren dağılımını "ağırlık nereye biniyorsa fren orada" diye hatırla.',
    ],
    examStrategy: [
      '"Virajda sert fren yapılır" yönündeki şıklar neredeyse her zaman yanlıştır.',
      'Islak zemin geçen sorularda "yumuşat ve mesafeyi artır" içeren şıkkı öne al.',
    ],
    keyTakeaways: [
      'Frenlemede ağırlık öne biner; asıl güç ön frendedir, arka fren dengeyi korur.',
      'Uzun inişte motor freni kullanılır, servis freni kısa aralıklarla.',
      'Virajın hızı girmeden ayarlanır; bakış çıkışa çevrilir.',
    ],
    reviewCards: [
      {
        front: 'Frenlemede ağırlık nereye aktarılır ve sonucu nedir?',
        back: 'Öne aktarılır; ön lastiğin baskısı artar, frenleme gücünün çoğu ön frendedir.',
      },
      { front: 'Virajda dört adımlı sıra nedir?', back: 'Yavaşla, bak, yatır, gazla.' },
    ],
    references: ['Motosiklet sürüş tekniği — frenleme ve viraj dinamiği'],
  },
  {
    id: 'moto-bakim-zincir',
    slug: 'moto-bakim-zincir',
    no: 23,
    subject: 'motor',
    licences: ['a'],
    title: 'Motosiklet Bakımı: Zincir, Lastik ve Yağ',
    summary:
      'Gücü tekerleğe taşıyan zincirin gerginlik ve yağlaması, lastik kontrolü ve yağ seviye camının okunması.',
    minutes: 9,
    objectives: [
      'Zincir gerginliğinin neden kritik olduğunu açıklamak',
      'Yola çıkmadan önceki lastik kontrolünü yapmak',
      'Yağ seviyesini seviye camından doğru okumak',
    ],
    sections: [
      {
        heading: 'Zincir: gücün tek taşıyıcısı',
        badge: 'official',
        body: 'Motosikletin çoğunda motor gücü arka tekerleğe **zincirle** aktarılır. Zincir tek yedeksiz bağdır: koparsa güç kesilir, arka tekerleği kilitleyebilir ve motoru hasara uğratabilir. Bu yüzden zincir hem **gerginlik** hem **yağlama** açısından düzenli kontrol edilir.',
        compare: {
          caption: 'Zincir gerginliği: iki uçtaki hata da tehlikelidir',
          headers: ['Durum', 'Belirti', 'Sonuç'],
          rows: [
            ['Çok gevşek', 'Sarkma fazla, hızlanınca takırtı', 'Dişliden atlama, kopma riski'],
            ['Çok gergin', 'Boşluk yok, sert his', 'Rulman ve dişli aşınması, kopma'],
            ['Kuru / paslı', 'Kızıl renk, gıcırtı', 'Hızlı aşınma, verim kaybı'],
          ],
        },
        callout: {
          tone: 'info',
          title: 'Doğru boşluk aracın kendi değeridir',
          text: 'Zincir sarkma miktarı modele göre değişir; **kendi motosikletinin kullanım kılavuzundaki değeri** esas al, genel bir sayıya güvenme.',
        },
      },
      {
        heading: 'Lastik: yere değen tek yüzey',
        badge: 'safety',
        body: 'Motosikletin yerle teması, iki avuç içi kadar bir alandır. Yola çıkmadan önce **basınç**, **diş derinliği** ve **yanak çatlağı** kontrol edilir. Basıncı düşük lastik virajda hantallaşır ve ısınır; aşırı şişik lastik ise tutunmayı azaltır. Lastik basıncı **soğukken** ölçülür.',
      },
      {
        heading: 'Yağ ve soğutma',
        badge: 'best',
        body: 'Motor yağı hareketli parçaları yağlar ve soğutur. Birçok motosiklette seviye, motorun yan tarafındaki **seviye camından** okunur: motosiklet düz ve dik dururken, motor kısa süre çalışıp durduktan sonra bakılır. Yan sehpa üzerinde eğik dururken bakılan seviye **yanıltıcıdır**.',
      },
    ],
    mistakes: [
      {
        text: 'Zinciri yalnız ses çıkarınca yağlamak.',
        fix: 'Yağlama **düzenli bakım** işidir; ses çıktığında aşınma çoktan başlamıştır.',
      },
      {
        text: 'Yağ seviyesine motosiklet yan sehpadayken bakmak.',
        fix: 'Motosiklet **düz ve dik** dururken bakılır; eğik konumda seviye yanlış görünür.',
      },
    ],
    tips: ['Lastik basıncını yolculuk öncesi soğukken ölç; ısınmış lastikte değer yüksek çıkar.'],
    memoryTips: [
      'Yola çıkmadan üçlüyü tara: **Z**incir – **L**astik – **Y**ağ.',
      '"Gevşek de gergin de kötü" — zincirde doğru olan **kılavuzdaki boşluktur**.',
    ],
    examStrategy: [
      'Bakım sorularında "arıza belirtisi çıkınca bakılır" diyen şık genelde yanlıştır; kontrol periyodiktir.',
      'Lastik sorularında "sıcakken ölç" içeren şıkkı ele.',
    ],
    keyTakeaways: [
      'Zincir gücün tek taşıyıcısıdır; hem gevşek hem aşırı gergin olması tehlikelidir.',
      'Lastik basıncı soğukken ölçülür.',
      'Yağ seviyesi motosiklet düz ve dik dururken okunur.',
    ],
    reviewCards: [
      {
        front: 'Zincir çok gergin olursa ne olur?',
        back: 'Rulman ve dişliler aşınır, kopma riski artar.',
      },
      { front: 'Lastik basıncı ne zaman ölçülür?', back: 'Lastik soğukken.' },
    ],
    references: ['Motosiklet periyodik bakım esasları'],
  },
  {
    id: 'moto-trafikte-guvenlik',
    slug: 'moto-trafikte-guvenlik',
    no: 24,
    subject: 'trafik',
    figureId: 'blind-spot',
    licences: ['a'],
    title: 'Motosikletle Trafikte Görünürlük ve Konum',
    summary:
      'Kör nokta, şerit içi doğru konum, kaygan yüzeyler ve kavşakta en sık yaşanan motosiklet kazası.',
    minutes: 9,
    objectives: [
      'Şerit içinde görünürlüğü artıran konumu seçmek',
      'Motosiklet için özel tehlike oluşturan yüzeyleri tanımak',
      'Kavşakta sola dönen aracın oluşturduğu riski öngörmek',
    ],
    sections: [
      {
        heading: 'Şerit içinde nerede durmalı?',
        badge: 'best',
        body: 'Motosiklet bir şeridi doldurmaz; şerit içinde **nereyi seçtiğin** görünürlüğünü belirler. Şeridin ortası, araçlardan damlayan yağ ve akışkanların biriktiği bölgedir — hem kaygandır hem seni öndeki aracın aynasında kör noktaya sokabilir. Genellikle şeridin sol veya sağ tekerlek izinde ilerlemek, hem daha temiz zemin hem daha geniş görüş açısı verir.',
        callout: {
          tone: 'info',
          title: 'Aynada görünmüyorsan yoksun',
          text: 'Öndeki aracın **aynasında kendini göremiyorsan**, o sürücü de seni görmüyordur. Konumunu değiştir veya mesafeyi aç.',
        },
      },
      {
        heading: 'Motosiklet için kaygan olan yüzeyler',
        badge: 'safety',
        body: 'Dört tekerlekli bir araç için sorun olmayan yüzeyler, iki tekerlekte kaymaya yol açar: **rögar kapakları, yol çizgileri ve yaya geçidi boyaları, tramvay/demiryolu rayları, gevşek malzeme (mıcır), ıslak yaprak ve buzlanma.** Bunların üzerinde fren, gaz ve yatış yapılmaz; **dik ve sabit hızla** geçilir.',
        compare: {
          caption: 'Tehlike – neden – önlem',
          headers: ['Yüzey', 'Neden riskli', 'Ne yapılır'],
          rows: [
            [
              'Rögar kapağı / metal ızgara',
              'Metal, özellikle ıslakken çok kaygan',
              'Üzerinden dik ve sabit hızla geç',
            ],
            [
              'Yol çizgisi / geçit boyası',
              'Boya asfalttan daha az tutar',
              'Fren ve yatışı boyanın dışında yap',
            ],
            [
              'Tramvay veya demiryolu rayı',
              'Tekerleği yakalayıp yönü çalar',
              'Raya mümkün olan en dik açıyla yaklaş',
            ],
            [
              'Gevşek malzeme (mıcır)',
              'Lastik ile zemin arasında bilye etkisi',
              'Hızı düşür, ani girdi verme',
            ],
          ],
        },
      },
      {
        heading: 'En sık kaza: kavşakta sola dönen araç',
        badge: 'safety',
        body: 'Motosiklet kazalarının klasik senaryosu şudur: karşıdan gelen araç **sola dönmek** için bekler, motosikletin hızını ve mesafesini yanlış tahmin eder ya da hiç görmez, ve tam önüne dönerek yol keser. Kavşağa yaklaşırken **sürücüyle göz teması kur**, hızını düşür ve o araç durana kadar dönmeyeceğini varsayma. Öndeki aracın tekerleklerinin dönmeye başlaması, niyetinin ilk işaretidir.',
      },
    ],
    mistakes: [
      {
        text: 'Araçların arasından, aynalarda görünmeyen bir hatta ilerlemek.',
        fix: 'Görünür bir konum seç; kör noktada uzun süre kalma.',
      },
      {
        text: 'Yağmurda ilk dakikalarda normal hızla devam etmek.',
        fix: 'Yağmurun ilk dakikalarında yol yüzeyi en kaygandır; **hızı düşür, mesafeyi aç**.',
      },
    ],
    tips: ['Kavşaklarda karşı yönden sola dönmek üzere bekleyen aracı daima "dönecek" varsay.'],
    memoryTips: [
      'Görünürlük kuralı: **"Aynada yoksan yoksun."**',
      'Kaygan yüzeyleri "**metal – boya – ray – mıcır**" dörtlüsüyle sayarak tara.',
    ],
    examStrategy: [
      'Motosiklet sorularında "diğer sürücü beni görür" varsayımına dayanan şıklar yanlıştır.',
      'Kaygan yüzey geçen sorularda "üzerinde fren yapılır" diyen şıkkı ele.',
    ],
    keyTakeaways: [
      'Şeridin ortası hem kaygan hem kör noktadır; tekerlek izlerinde ilerle.',
      'Metal, boya, ray ve mıcır üzerinde dik ve sabit hızla geçilir.',
      'Kavşakta sola dönen araç, motosiklet için en sık kaza sebebidir.',
    ],
    reviewCards: [
      {
        front: 'Neden şeridin tam ortasında ilerlemek sakıncalıdır?',
        back: 'Yağ/akışkan birikir (kaygan) ve öndeki aracın kör noktasına denk gelebilir.',
      },
      {
        front: 'Islak rögar kapağı üzerinden nasıl geçilir?',
        back: 'Dik konumda, sabit hızla; fren, gaz ve yatış yapmadan.',
      },
    ],
    references: ['Motosiklet güvenliği — görünürlük ve yol yüzeyi riskleri'],
  },
];

/** D sınıfı — otobüs (ticari yolcu taşımacılığı). */
export const BUS_LESSONS: LessonInput[] = [
  {
    id: 'otobus-havali-fren',
    slug: 'otobus-havali-fren',
    no: 25,
    subject: 'motor',
    licences: ['d'],
    title: 'Otobüste Havalı Fren Sistemi',
    summary:
      'Basınçlı havanın üretimi ve depolanması, basınç göstergeleri, yay (park) freni ve günlük kontroller.',
    minutes: 10,
    objectives: [
      'Havalı frenin hidrolik frenden farkını açıklamak',
      'Yola çıkmadan önce basınç göstergesini doğru okumak',
      'Yay (park) freninin neden basınçla çalıştığını bilmek',
    ],
    sections: [
      {
        heading: 'Hava nereden gelir?',
        badge: 'official',
        body: 'Ağır araçlarda fren kuvveti, sürücünün ayak gücüyle değil **basınçlı havayla** üretilir. Motorun döndürdüğü kompresör havayı basar, kurutucudan geçen hava **hava tanklarında** depolanır. Pedala basıldığında valfler bu havayı fren körüklerine yollar. Bu yüzden havalı frenli bir araçta pedal hissi hidrolikten farklıdır: pedal bir "kumanda", asıl güç tanklardadır.',
        compare: {
          caption: 'Hidrolik fren ile havalı fren farkı',
          headers: ['Ölçüt', 'Hidrolik fren (binek)', 'Havalı fren (otobüs)'],
          rows: [
            ['Kuvvet kaynağı', 'Sürücünün ayak gücü + hidrolik', 'Depolanmış basınçlı hava'],
            ['Hazırlık', 'Kontak açınca hazır', 'Yeterli basınç oluşana kadar **beklenir**'],
            [
              'Basınç düşerse',
              'Pedal sertleşir / iner',
              'Yay freni devreye girer, araç kilitlenir',
            ],
            [
              'Günlük kontrol',
              'Hidrolik seviyesi',
              'Basınç göstergesi, kaçak sesi, tank tahliyesi',
            ],
          ],
        },
      },
      {
        heading: 'Göstergeler ve ikaz: basınç oluşmadan hareket edilmez',
        badge: 'safety',
        body: 'Kabindeki **basınç göstergeleri** ön ve arka devrelerin durumunu ayrı ayrı gösterir. Basınç güvenli seviyenin altındayken kırmızı ikaz ışığı ve çoğu araçta sesli uyarı devrededir. Motor çalıştırıldıktan sonra basınç normale çıkana kadar **araç hareket ettirilmez** — bu bir tercih değil, sistemin çalışma şartıdır.',
        callout: {
          tone: 'danger',
          title: 'Düşük basınçla yola çıkmak',
          text: 'Basınç yetersizken hareket edilirse birkaç fren uygulamasından sonra **fren kalmayabilir.** İkaz sönmeden kalkış yapılmaz.',
        },
      },
      {
        heading: 'Yay (park) freni ve günlük kontroller',
        badge: 'official',
        body: 'Park freni, ağır araçlarda **yay kuvvetiyle** frenleri uygulayan bir sistemdir; havayla frenler serbest bırakılır. Mantık güvenlik içindir: hava kaçarsa yaylar frenleri **kendiliğinden uygular** ve araç kaçmaz. Günlük kontrolde hava tanklarında biriken **su tahliye edilir**, valf ve hortumlarda kaçak sesi dinlenir, park freni tutma testi yapılır.',
        callout: {
          tone: 'info',
          title: 'Tankta neden su birikir?',
          text: 'Sıkıştırılan havanın nemi tankta yoğuşur. Tahliye edilmezse valfleri aşındırır ve soğukta **donarak** fren arızası yapar.',
        },
      },
    ],
    mistakes: [
      {
        text: 'Basınç ikazı sönmeden kalkış yapmak.',
        fix: 'Motor çalıştıktan sonra **basınç normale çıkana kadar bekle**; ikaz sönmeden hareket etme.',
      },
      {
        text: 'Uzun yokuşta havalı freni sürekli basılı tutmak.',
        fix: 'Sürekli kullanım hem balatayı ısıtır hem basıncı tüketir; **motor freni / retarder** kullan.',
      },
    ],
    tips: ['Kalkış öncesi park frenini çekili tutup hafif gazla tutma testi yap; araç kaçmamalı.'],
    memoryTips: [
      'Havalı freni "**hava serbest bırakır, yay frenler**" cümlesiyle kodla.',
      'Günlük kontrolü üç adımla tara: **B**asınç – **K**açak – **S**u tahliyesi.',
    ],
    examStrategy: [
      '"Basınç düşükse yavaş giderek devam edilir" tarzı şıklar yanlıştır.',
      'Park freni sorularında "hava ile frenler serbest kalır" ifadesi doğrudur.',
    ],
    keyTakeaways: [
      'Havalı frende kuvvet depolanmış basınçlı havadan gelir.',
      'Basınç normale çıkmadan araç hareket ettirilmez.',
      'Yay freni, hava kaçtığında frenleri kendiliğinden uygular.',
    ],
    reviewCards: [
      {
        front: 'Havalı frenli araçta basınç düşerse ne olur?',
        back: 'Yay (park) freni devreye girer ve araç frenlenir.',
      },
      {
        front: 'Hava tankındaki su neden boşaltılır?',
        back: 'Valfleri aşındırır ve soğukta donarak arıza yapar.',
      },
    ],
    references: ['Ağır araç fren sistemleri — havalı fren çalışma esasları'],
  },
  {
    id: 'otobus-yavaslama-retarder',
    slug: 'otobus-yavaslama-retarder',
    no: 26,
    subject: 'motor',
    licences: ['d'],
    title: 'Uzun İnişte Yavaşlama: Motor Freni ve Retarder',
    summary:
      'Fren ısınması (fade) neden ağır araçta kritiktir; egzoz freni, retarder ve doğru vitesle iniş.',
    minutes: 9,
    objectives: [
      'Fren aşırı ısınmasının sonucunu açıklamak',
      'Yavaşlatıcı sistemleri (motor freni, egzoz freni, retarder) ayırt etmek',
      'Uzun inişte doğru vites ve fren stratejisini uygulamak',
    ],
    sections: [
      {
        heading: 'Neden ağır araçta fren "biter"?',
        badge: 'safety',
        body: 'Frenler hareket enerjisini **ısıya** çevirerek çalışır. Dolu bir otobüsün kütlesi binek araçtan kat kat fazladır; uzun bir inişte servis freni sürekli kullanılırsa balata ve kampana aşırı ısınır ve **frenleme etkisi düşer**. Pedal aynı yere basar ama araç yavaşlamaz. Bu yüzden ağır araçta iniş, frenle değil **yavaşlatıcı sistemlerle** yönetilir.',
        callout: {
          tone: 'danger',
          title: 'Isınan fren uyarı vermez',
          text: 'Fren etkisinin azalması yavaş yavaş olur ve genellikle **en kötü anda** fark edilir. İnişe başlamadan önce doğru vitese geçmek tek gerçek önlemdir.',
        },
      },
      {
        heading: 'Yavaşlatıcı sistemler',
        badge: 'official',
        body: 'Ağır araçlarda servis freninin yükünü paylaşan birden çok sistem vardır. **Motor freni** gaz kesildiğinde motorun direncidir. **Egzoz freni**, egzoz yolunu kısarak bu direnci artırır ve genelde bir anahtarla açılır. **Retarder** ise aktarma organına bağlı, kademeli çalışan bir yavaşlatıcıdır ve direksiyon kolonundaki kolla kademe kademe kullanılır. Hiçbiri aracı durdurmaz — **hızı korur ve düşürür**; durdurma işi servis freninindir.',
        compare: {
          caption: 'Hangisi ne yapar',
          headers: ['Sistem', 'Nasıl çalışır', 'Ne zaman kullanılır'],
          rows: [
            ['Motor freni', 'Gaz kesilince motorun kendi direnci', 'Her yavaşlamada, doğal olarak'],
            ['Egzoz freni', 'Egzoz yolunu kısarak direnci artırır', 'İnişlerde, anahtar açıkken'],
            [
              'Retarder',
              'Aktarma organında kademeli yavaşlatma',
              'Uzun iniş ve yüksek hızda kontrollü yavaşlama',
            ],
            [
              'Servis freni (havalı)',
              'Balata/kampana ile durdurur',
              'Durmak ve kısa süreli hız düşürmek',
            ],
          ],
        },
      },
      {
        heading: 'İniş stratejisi',
        badge: 'instructor',
        body: 'Kural basittir: **İnişe çıkıştaki vitesle gir.** Yani tırmanırken kullandığın vites, indiğinde de uygun vitestir. Vites inişten **önce** küçültülür; hız arttıktan sonra vites küçültmek zorlaşır ve tehlikelidir. Retarder/egzoz freni açılır; servis freni yalnız **kısa ve aralıklı** basışlarla kullanılır, böylece soğuma fırsatı bulur.',
      },
    ],
    mistakes: [
      {
        text: 'İnişte vitesi boşa alıp frenle inmek.',
        fix: 'Boşta inmek motor frenini tamamen kaldırır ve **yasaktır**; uygun vitesle inilir.',
      },
      {
        text: 'Frene sürekli hafif basarak inmek.',
        fix: 'Sürekli temas balatayı ısıtır; **kısa ve aralıklı** basışlarla frenle.',
      },
    ],
    tips: ['İniş öncesi hızı düşür ve vitesi küçült; hız arttıktan sonra ikisi de zorlaşır.'],
    memoryTips: [
      '"**Çıktığın vitesle in**" cümlesi iniş vitesini seçmenin en kısa yoludur.',
      'Yavaşlatıcıları güçten sıraya koy: motor freni → egzoz freni → retarder → servis freni.',
    ],
    examStrategy: [
      '"Uzun inişte vites boşa alınır" diyen şık her zaman yanlıştır.',
      'Fren ısınması geçen sorularda "motor freni / retarder kullanılır" şıkkını öne al.',
    ],
    keyTakeaways: [
      'Ağır araçta sürekli fren kullanımı frenin etkisini düşürür.',
      'Motor freni, egzoz freni ve retarder aracı yavaşlatır; durdurma servis freninindir.',
      'İnişe çıkıştaki vitesle girilir; vites inişten önce küçültülür.',
    ],
    reviewCards: [
      {
        front: 'Uzun inişte sürekli fren kullanılırsa ne olur?',
        back: 'Balata ve kampana aşırı ısınır, frenleme etkisi azalır.',
      },
      {
        front: 'Retarder aracı durdurur mu?',
        back: 'Hayır; yavaşlatır. Durdurma işi servis freninindir.',
      },
    ],
    references: ['Ağır araç yavaşlatıcı sistemleri — motor freni, egzoz freni, retarder'],
  },
  {
    id: 'otobus-takograf-sureler',
    slug: 'otobus-takograf-sureler',
    no: 27,
    subject: 'trafik',
    licences: ['d'],
    title: 'Takograf ve Araç Kullanma – Dinlenme Süreleri',
    summary:
      'Ticari yolcu taşımacılığında yasal sürüş ve dinlenme sınırları, mola kuralı ve takografın rolü.',
    minutes: 11,
    objectives: [
      'Günlük sürekli ve toplam araç kullanma sınırlarını bilmek',
      'Mola ve günlük dinlenme kurallarını ayırt etmek',
      'Takografın hukuki işlevini ve sorumluluk paylaşımını açıklamak',
    ],
    sections: [
      {
        heading: 'Kimin için geçerli?',
        badge: 'official',
        body: 'Karayolları Trafik Yönetmeliği, araç kullanma ve dinlenme sürelerini iki grup için düzenler: ticari amaçla yük taşıyan ve azami ağırlığı **3,5 tonu geçen** araçların şoförleri ile ticari amaçla yolcu taşıyan ve taşıma kapasitesi **şoför dahil 9 kişiyi geçen** araçların şoförleri. Otobüs sürücüsü bu ikinci grubun tam merkezindedir — bu kurallar D sınıfı için mesleki hayatın çerçevesidir.',
      },
      {
        heading: 'Süre sınırları',
        badge: 'official',
        body: 'Yönetmeliğe göre bu şoförlerin **24 saatlik herhangi bir süre içinde toplam 9 saatten ve devamlı olarak 4,5 saatten fazla araç sürmeleri yasaktır.** Sürekli 4,5 saatlik kullanma süresi sonunda, istirahata çekilmiyorsa **en az 45 dakika mola** verilmesi mecburidir; bu mola, 4,5 saatlik süre içinde **en az 15 dakikalık** bölümler hâlinde de kullanılabilir. Mola süresince şoför başka bir işle meşgul olamaz ve **alınan molalar günlük dinlenme süresinden sayılmaz.**',
        compare: {
          caption: 'Yönetmelikte belirlenen sınırlar',
          headers: ['Sınır', 'Değer', 'Not'],
          rows: [
            ['Devamlı araç kullanma', '**4,5 saat**', 'Sonunda en az 45 dakika mola'],
            ['24 saatte toplam kullanma', '**9 saat**', 'Aşılması yasaktır'],
            ['Mola', '**45 dakika**', 'En az 15 dakikalık bölümler hâlinde kullanılabilir'],
            [
              'Günlük dinlenme',
              '**11 saat kesintisiz**',
              'Bölünürse biri en az 8 saat, toplam 12 saate çıkar',
            ],
            [
              'Hafta tatili',
              'En fazla 6 günlük kullanmadan sonra **en az 24 saat**',
              'Kullanılması zorunludur',
            ],
            ['Birleşik 2 hafta', '**En çok 90 saat**', 'Toplam araç kullanma süresi'],
          ],
        },
        callout: {
          tone: 'warning',
          title: 'Mola ≠ dinlenme',
          text: '45 dakikalık mola, 11 saatlik **günlük dinlenme** yerine geçmez. İkisi ayrı kurallardır ve ayrı ayrı denetlenir.',
        },
      },
      {
        heading: 'Günlük dinlenme ve çift şoför',
        badge: 'official',
        body: 'Şoförler her 24 saat içerisinde **11 saat kesintisiz** dinlenir. Bu süre, biri en az 8 saat kesintisiz olmak üzere iki veya üç ayrı bölüm hâlinde kullanılabilir; bu durumda günlük dinlenme süresi 1 saat eklenerek **12 saate** çıkar. 11 saatlik kesintisiz dinlenme, haftada **3 defadan fazla olmamak üzere** en az 9 saate indirilebilir. Aracın en az iki şoförle kullanılması durumunda her **30 saatlik** sürede her bir şoför en az **8 saat kesintisiz** dinlenir.',
      },
      {
        heading: 'Takograf: kuralın kanıtı',
        badge: 'official',
        body: 'Takograf, aracın hızını, kat ettiği yolu ve şoförün çalışma–dinlenme sürelerini kaydeden cihazdır. Karayolları Trafik Kanunu, takograf bulundurulması ve kullanılması zorunlu olan taşıtların **taşıt kullanma sürelerine aykırı kullanılmasını ve kullandırılmasını yasaklar.** Sorumluluk yalnız şoförde değildir: **işleten**, sürücünün kendisi olup olmadığına bakmaksızın gerekli tedbirleri almak ve denetimini yapmakla yükümlüdür. İhlallerde günlük sürekli kullanma, günlük toplam kullanma, haftalık kullanma ile günlük ve haftalık dinlenme süreleri **ayrı ayrı** idari para cezasına bağlanmıştır.',
        callout: {
          tone: 'info',
          title: 'Kayıt tutulur, beyan değil',
          text: 'Denetimde esas alınan şey sürücünün beyanı değil, **takograf kaydıdır**. Kuralı bilmek kadar kaydın doğru tutulması da mesleki sorumluluktur.',
        },
      },
    ],
    mistakes: [
      {
        text: '45 dakikalık molayı günlük dinlenmeden saymak.',
        fix: 'Mevzuat açıktır: **alınan molalar günlük dinlenme süresi olarak sayılmaz.**',
      },
      {
        text: 'Molada araçla ilgili başka bir iş yapmak (yükleme, temizlik, evrak).',
        fix: 'Mola süresince şoför **başka bir işle meşgul olamaz**; aksi hâlde mola geçersizdir.',
      },
    ],
    tips: [
      'Sürekli 4,5 saati doldurmadan molayı planla; 15 dakikalık bölümler hâlinde kullanmak da mevzuata uygundur.',
    ],
    memoryTips: [
      'Üç sayıyı birlikte kodla: **4,5 – 45 – 9** (devamlı saat, dakika mola, günlük toplam saat).',
      'Dinlenmeyi "**11 kesintisiz, bölünürse 12**" ikilisiyle hatırla.',
    ],
    examStrategy: [
      'Süre sorularında "devamlı" ile "24 saatlik toplam" karıştırılır; şıkta hangisinin sorulduğunu işaretle.',
      'Molanın dinlenmeden sayıldığını söyleyen şık yanlıştır.',
    ],
    keyTakeaways: [
      '24 saatte toplam 9 saat, devamlı 4,5 saatten fazla araç sürmek yasaktır.',
      '4,5 saat sonunda en az 45 dakika mola verilir; mola günlük dinlenmeden sayılmaz.',
      'Her 24 saatte 11 saat kesintisiz dinlenme esastır.',
      'Takograf kaydı esastır ve işleten de sorumludur.',
    ],
    reviewCards: [
      {
        front: 'Devamlı olarak en fazla kaç saat araç sürülebilir ve sonrasında ne gerekir?',
        back: '4,5 saat; sonunda en az 45 dakika mola verilir.',
      },
      {
        front: '24 saatlik sürede toplam araç kullanma sınırı nedir?',
        back: '9 saat.',
      },
      {
        front: 'Mola, günlük dinlenme süresinden sayılır mı?',
        back: 'Hayır; alınan molalar günlük dinlenme süresi olarak sayılmaz.',
      },
    ],
    references: [
      'Karayolları Trafik Yönetmeliği — madde 98/A (araç kullanma ve dinlenme sürelerine uyma mecburiyeti)',
      '2918 sayılı Karayolları Trafik Kanunu — madde 49 (taşıt kullanma sürelerine uyma zorunluluğu)',
    ],
  },
  {
    id: 'otobus-yolcu-guvenligi',
    slug: 'otobus-yolcu-guvenligi',
    no: 28,
    subject: 'trafik',
    figureId: 'load-placement',
    licences: ['d'],
    title: 'Yolcu Güvenliği ve Acil Durumlar',
    summary:
      'Emniyet kemeri uyarısı yükümlülüğü, acil çıkış donanımı, yangın söndürme cihazı ve tahliye sırası.',
    minutes: 10,
    objectives: [
      'Yolcuları emniyet kemeri konusunda uyarma yükümlülüğünü bilmek',
      'Otobüsteki acil durum donanımını ve yerini saymak',
      'Yangın ve tahliye durumunda doğru sırayı uygulamak',
    ],
    sections: [
      {
        heading: 'Yolcuyu uyarmak sürücünün yükümlülüğüdür',
        badge: 'official',
        body: 'Karayolları Trafik Kanunu, yönetmelikte cins ve sınıfları belirtilen araçlarda seyahat eden yolcuların, **araç hareket etmeden önce ve seyahat sırasında** emniyet kemerlerini bağlamaları konusunda **uyarılmalarını zorunlu** kılar. Yani yolcunun kemer takması yalnız yolcunun tercihi değildir; uyarının yapılması işletmenin ve sürücünün yükümlülüğüdür.',
        callout: {
          tone: 'info',
          title: 'Uyarı bir kez değil, seyahat boyunca',
          text: 'Kanun **hareket etmeden önce** ve **seyahat sırasında** uyarılmayı birlikte sayar; mola dönüşlerinde uyarıyı tekrarlamak bu yükümlülüğün doğal parçasıdır.',
        },
      },
      {
        heading: 'Acil durum donanımı',
        badge: 'official',
        body: 'Otobüste güvenlik donanımı, yeri bilinmediğinde işe yaramaz. **Acil kapı açma kolu**, **cam kırma çekici**, **yangın söndürme cihazı** ve **ilk yardım çantası** her seferden önce yerinde ve erişilebilir olmalıdır. Yönetmelik yangın söndürme cihazı için otobüslerde toplam doldurma kapasitesini **en az 6 kg kuru toz** olarak belirler; yolcu sayısı 26 kişiye kadar olan otobüslerde ise **2 kg kapasiteli en az iki adet** cihaz öngörülür. Cihazlar görülebilen ve erişilmesi kolay bir yerde bulundurulur ve **en az biri sürücünün hemen yanında** olur.',
        compare: {
          caption: 'Donanım – yeri – ne zaman',
          headers: ['Donanım', 'Nerede', 'Ne zaman kullanılır'],
          rows: [
            [
              'Acil kapı açma kolu',
              'Kapı üstü / yanı, işaretli',
              'Kapı normal kumandayla açılmadığında',
            ],
            [
              'Cam kırma çekici',
              'Camların yanında, sabit yuvasında',
              'Kapı ve acil çıkış kullanılamıyorsa',
            ],
            [
              'Yangın söndürme cihazı',
              'Görülebilir, erişilebilir; biri sürücünün yanında',
              'Yangının ilk anında',
            ],
            ['İlk yardım çantası', 'Belirlenmiş sabit yerinde', 'Yaralanma ve kaza sonrası'],
            [
              'Akü şalteri',
              'Motor bölmesi / şalter kutusu',
              'Yangında elektriği tamamen kesmek için',
            ],
          ],
        },
      },
      {
        heading: 'Tahliye sırası',
        badge: 'safety',
        body: 'Acil durumda sıra şaşarsa donanım işe yaramaz. Doğru sıra şudur: **aracı güvenli bir yere al ve durdur → kontağı kapat → park frenini uygula → akü şalterini indir → yolcuları trafiğe kapalı taraftan indir → yolcuları araçtan güvenli mesafeye uzaklaştır.** Yolcular her zaman **trafiğin geldiği taraftan değil**, yol dışına bakan taraftan indirilir; indikten sonra araç çevresinde beklemeleri engellenir.',
        callout: {
          tone: 'danger',
          title: 'En büyük risk indikten sonradır',
          text: 'Yolcuların araç çevresinde veya yolun üzerinde toplanması, ikinci bir kazaya davetiyedir. Güvenli mesafeye **yönlendirmek** tahliyenin son adımıdır.',
        },
      },
    ],
    mistakes: [
      {
        text: 'Yolcuları yolun trafik tarafından indirmek.',
        fix: 'İndirme **trafiğe kapalı taraftan** yapılır; yolcular yol dışına yönlendirilir.',
      },
      {
        text: 'Yangında elektriği kesmeden söndürmeye çalışmak.',
        fix: 'Mümkünse önce **kontağı kapat ve akü şalterini indir**; elektrik kaynağı beslemeye devam ederse yangın büyür.',
      },
    ],
    tips: ['Her sefer öncesi acil donanımın yerini ve erişilebilirliğini gözle kontrol et.'],
    memoryTips: [
      'Tahliye sırasını beş adımla kodla: **Dur – Kontak – Şalter – İndir – Uzaklaştır.**',
      'Yangın söndürücü kuralı: "**görülebilir, erişilebilir, biri şoförün yanında**".',
    ],
    examStrategy: [
      'Yolcu güvenliği sorularında "yolcunun kendi sorumluluğudur" diyen şıkkı temkinli karşıla; uyarı yükümlülüğü vardır.',
      'Tahliye sorularında "yolcular trafiğin olduğu taraftan indirilir" şıkkı yanlıştır.',
    ],
    keyTakeaways: [
      'Yolcuların kemer konusunda uyarılması kanunen zorunludur.',
      'Otobüste yangın söndürme cihazının en az biri sürücünün hemen yanında bulunur.',
      'Tahliye sırası: dur, kontağı kapat, akü şalterini indir, güvenli taraftan indir, uzaklaştır.',
    ],
    reviewCards: [
      {
        front: 'Yolcular kemer konusunda ne zaman uyarılır?',
        back: 'Araç hareket etmeden önce ve seyahat sırasında.',
      },
      {
        front: 'Yolcular hangi taraftan indirilir?',
        back: 'Trafiğe kapalı, yol dışına bakan taraftan.',
      },
    ],
    references: [
      '2918 sayılı Karayolları Trafik Kanunu — madde 78 (koruyucu sistemler ve yolcuların uyarılması)',
      'Karayolları Trafik Yönetmeliği — araçlarda bulundurulacak teçhizat (yangın söndürme cihazı)',
    ],
  },
  {
    id: 'otobus-manevra-olcu',
    slug: 'otobus-manevra-olcu',
    no: 29,
    subject: 'pratik',
    figureId: 'blind-spot',
    licences: ['d'],
    title: 'Büyük Araçla Manevra: Ölü Nokta ve Kuyruk Taşması',
    summary:
      'Uzun araçta dönüş yayı, arkanın dışa savrulması (kuyruk taşması), ayna kullanımı ve geri manevra.',
    minutes: 10,
    objectives: [
      'Uzun araçta dönüş sırasında arka tekerleklerin izlediği yolu öngörmek',
      'Kuyruk taşmasının komşu şeride etkisini hesaba katmak',
      'Ölü noktaları ayna ve gözcüyle yönetmek',
    ],
    sections: [
      {
        heading: 'Arka tekerlek öndekinin izini takip etmez',
        badge: 'official',
        body: 'Uzun bir araç dönerken arka tekerlekler, ön tekerleklerden **daha içeriden** geçer. Buna dönüş içi fark denir ve otobüste bu fark metrelerle ölçülür. Sonuç: dönüşü öndeki araç gibi alırsan arka tekerlek kaldırıma, refüje veya yayaya değer. Bu yüzden dönüşe **daha geniş bir yay** çizerek girilir ve dönüş **daha geç** başlatılır.',
        compare: {
          caption: 'Binek araç ile uzun araç farkı',
          headers: ['Ölçüt', 'Binek araç', 'Otobüs'],
          rows: [
            ['Arka tekerlek izi', 'Öne yakın', '**Belirgin şekilde içeriden** geçer'],
            ['Dönüşe giriş', 'Köşeye yakın', 'Daha geniş yay, daha geç dönüş'],
            ['Aracın arkası', 'Neredeyse yerinde kalır', '**Dışa savrulur** (kuyruk taşması)'],
            ['Kör nokta', 'Sınırlı', 'Sağ taraf ve arka çok geniş'],
          ],
        },
      },
      {
        heading: 'Kuyruk taşması: arkan komşu şeride girer',
        badge: 'safety',
        body: 'Arka dingilin gerisinde kalan bölüm, direksiyon çevrildiğinde **ters yöne doğru savrulur**. Durakta kalkarken, dar sokakta dönerken veya park yerinden çıkarken aracın arkası yan şeride veya kaldırıma taşabilir. Manevraya başlamadan önce **her iki aynadan** aracın arkasının nereye gideceği kontrol edilir; gerekiyorsa kalkış geciktirilir.',
        callout: {
          tone: 'warning',
          title: 'Duraktan kalkış klasik hasar noktasıdır',
          text: 'Durakta öne doğru direksiyon kırıldığında arka sol köşe komşu şeride girer. Kalkıştan önce sol aynayı ve kör noktayı kontrol et.',
        },
      },
      {
        heading: 'Ölü nokta ve geri manevra',
        badge: 'instructor',
        body: 'Otobüste kör nokta binek araçtakinden kat kat büyüktür; özellikle **sağ taraf ve tam arka** görülemez. Aynalar sefere çıkmadan önce ayarlanır ve manevrada **sürekli** taranır. Geri manevrada görüş yetersizse **gözcü** kullanılır; gözcüyle önceden anlaşılmış işaretler kullanılır ve gözcü aynada **görünmez** hâle geldiği anda manevra durdurulur.',
      },
    ],
    mistakes: [
      {
        text: 'Dönüşü binek araç refleksiyle erken başlatmak.',
        fix: 'Dönüşe **daha geç ve daha geniş** girilir; arka tekerleğin izi hesaba katılır.',
      },
      {
        text: 'Geri manevrada gözcüyü aynadan kaybedip devam etmek.',
        fix: 'Gözcü **görünmüyorsa dur**; görüş sağlanmadan geri gidilmez.',
      },
    ],
    tips: ['Manevradan önce aracın etrafını bir tur dolaş; alçak engeller aynadan görünmez.'],
    memoryTips: [
      '"**Ön içeri girer, arka dışarı savrulur**" cümlesi dönüş davranışını özetler.',
      'Geri manevra kuralı: **gözcü görünmüyorsa dur.**',
    ],
    examStrategy: [
      'Manevra sorularında "dönüşe erken girilir" diyen şık uzun araç için yanlıştır.',
      'Geri gitme sorularında gözcü/işaretçi geçen şıkkı ciddiye al.',
    ],
    keyTakeaways: [
      'Uzun araçta arka tekerlekler ön tekerleklerden içeriden geçer.',
      'Kuyruk taşması aracın arkasını komşu şeride sokabilir.',
      'Geri manevrada gözcü aynada görünmüyorsa manevra durdurulur.',
    ],
    reviewCards: [
      {
        front: 'Otobüs dönerken arka tekerlekler nereden geçer?',
        back: 'Ön tekerleklerden belirgin şekilde daha içeriden.',
      },
      {
        front: 'Kuyruk taşması nedir?',
        back: 'Direksiyon kırıldığında aracın arka bölümünün ters yöne savrulmasıdır.',
      },
    ],
    references: ['Ağır ve uzun araçlarla manevra esasları'],
  },
];

/** A + D sınıfına özgü tüm dersler (yalnız mobil anlık görüntüsüne eklenir). */
export const LICENCE_LESSONS: LessonInput[] = [...MOTO_LESSONS, ...BUS_LESSONS];
