/**
 * Sürüş Akademisi — direksiyon (uygulama) dersleri (Sprint 3). ADR-005 şemasıyla doğrulanır.
 * ÖZGÜN içerik. Kaynak = MTSK direksiyon eğitimi + MEB direksiyon sınavı uygulaması.
 */
import type { LessonInput } from '@ea/content-schema';

export const DRIVING_LESSONS: LessonInput[] = [
  {
    id: 'arac-hazirlik',
    slug: 'arac-hazirlik',
    no: 15,
    subject: 'pratik',
    title: 'Araç Kontrolü ve Sürüşe Hazırlık',
    summary:
      'Direğe geçmeden önce koltuk, ayna, kemer ayarı ve gösterge kontrolü ile aracı güvenle hareket ettirmenin doğru sırası.',
    minutes: 8,
    objectives: [
      'Koltuk, ayna ve kemeri doğru sırayla ayarlamak',
      'Motoru çalıştırmadan önce vitesi boşta ve debriyajı basılı tutmak',
      'Gösterge panelindeki ikaz lambalarını okumak',
      'Araç çevresini kontrol ederek güvenli hareket etmek',
    ],
    sections: [
      {
        heading: 'Ayar sırası: önce koltuk, sonra ayna',
        badge: 'instructor',
        body: 'Hazırlığın ilk adımı **koltuğu ayarlamaktır**. Debriyaja tam basabildiğinizde dizinizde hafif kırış kalmalı, sırtınız koltuğa yaslıyken kollarınızı düz uzattığınızda bilekleriniz direksiyonun üst kenarına değmeli. Aynalar mutlaka koltuktan sonra ayarlanır; çünkü koltuğun konumu değişince aynaların açısı da kayar ve tekrar kurmanız gerekir.',
      },
      {
        heading: 'Kemer ve gösterge kontrolü',
        badge: 'safety',
        body: 'Emniyet kemeri hem yasal zorunluluk hem de ilk güvenlik adımıdır; kemer göğüs ve kalça kemiğinden geçmeli, boyna veya karına gelmemelidir. Kontağı açtığınızda gösterge panelinde ikaz lambaları kısa süre yanıp söner: **kırmızı ikazlar acil ve ciddi** (yağ basıncı, fren, akü şarj), **sarı ikazlar dikkat/kontrol** anlamı taşır. Kalıcı yanan kırmızı bir ikazla yola çıkılmaz.',
      },
      {
        heading: 'Motoru çalıştırmadan önce',
        badge: 'instructor',
        body: 'Kontağı çevirmeden önce vitesin **boşta** olduğunu doğrulayın, **debriyaja tam basın** ve el freninin çekili olduğunu kontrol edin. Vites takılıyken çalıştırmak aracın öne veya arkaya fırlamasına yol açabilir; debriyaja basmak ise marşın motoru daha kolay döndürmesini sağlar ve olası bir vites hatasında aracı yerinde tutar.',
      },
      {
        heading: 'Çevre kontrolü ve hareket',
        badge: 'safety',
        body: 'Araç hareket etmeden önce iç ve dış aynaları, ardından **kör noktayı omuz üstünden** kontrol edin ve gideceğiniz yöne sinyal verin. Bu sıra (ayna - sinyal - kör nokta - manevra) hem arkadan gelen trafiği görmenizi hem de niyetinizi diğer sürücülere bildirmenizi sağlar. Kaldırımdan ayrılırken yayaları da tarayın.',
      },
    ],
    mistakes: [
      {
        text: 'Aynaları, koltuğu ayarlamadan önce kurmak.',
        fix: 'Önce koltuk, sonra ayna; koltuk konumu değişince ayna açısı da kayar.',
      },
      {
        text: 'Motoru vites takılıyken çalıştırmaya çalışmak.',
        fix: 'Kontaktan önce vitesi boşa alın ve debriyaja tam basın.',
      },
    ],
    tips: [
      'Bilek testi: kollarınızı düz uzatın, bilekleriniz direksiyonun üst kenarına değmeli; bu mesafe idealdir.',
    ],
    memoryTips: ['Hazırlık sırası: Koltuk - Ayna - Kemer - Kontak.'],
    examStrategy: [
      'Araca biner binmez acele etmeyin; hakem kemer ve ayna gibi hazırlık adımlarını sessizce izler, atlarsanız araç daha hareket etmeden puan kaybedersiniz.',
    ],
    keyTakeaways: [
      'Önce koltuk, sonra aynalar ayarlanır.',
      'Motor çalışmadan vites boşta ve debriyaj basılı olmalı.',
      'Kemer, ilk ve vazgeçilmez güvenlik adımıdır.',
      'Hareketten önce ayna, sinyal ve kör nokta kontrolü yapılır.',
    ],
    reviewCards: [
      {
        front: 'Aynaları ne zaman ayarlarız?',
        back: 'Koltuk ayarı bittikten sonra; koltuk konumu değişince ayna açısı da değiştiği için önce koltuk kurulur.',
      },
      {
        front: 'Motoru çalıştırmadan önce vites nerede olmalı?',
        back: 'Boşta olmalı; ayrıca debriyaja tam basılı ve el freni çekili olmalıdır.',
      },
    ],
    quizQuestionIds: ['pratik-101', 'pratik-102', 'pratik-124'],
    practiceQuestionIds: ['pratik-101', 'pratik-102', 'pratik-124', 'pratik-110', 'pratik-112'],
    references: [
      'MTSK direksiyon eğitimi — sürüşe hazırlık',
      'Karayolları Trafik Yönetmeliği — emniyet kemeri kullanımı',
    ],
    figureId: 'vehicle',
  },
  {
    id: 'debriyaj-rampa',
    slug: 'debriyaj-rampa',
    no: 16,
    subject: 'pratik',
    title: 'Debriyaj Kontrolü ve Rampada Kalkış',
    summary:
      'Kavrama noktasını hissederek yumuşak kalkış yapmanın ve rampada geri kaymadan hareket etmenin adım adım tekniği.',
    minutes: 10,
    objectives: [
      'Kavrama (buluşma) noktasını hissederek bulmak',
      'Yarım debriyajla sarsıntısız kalkış yapmak',
      'Rampada el freni desteğiyle geri kaymadan kalkmak',
    ],
    sections: [
      {
        heading: 'Kavrama noktası nedir?',
        badge: 'instructor',
        body: 'Kavrama noktası, debriyaj pedalını yavaşça bırakırken motor gücünün tekerleklere **geçmeye başladığı andır**. Bu noktada motorun sesi hafif kalınlaşır, aracın burnu biraz kalkar ve gövdede küçük bir titreşim hissedilir. **Yarım debriyaj**, pedalı tam bırakmadan bu buluşma bölgesinde tutarak gücü kademeli aktarmaktır; kalkışın kalbi burasıdır.',
      },
      {
        heading: 'Düz zeminde yumuşak kalkış',
        badge: 'instructor',
        body: 'Birinci vitese takın, hafifçe gaza basın ve debriyajı **kavrama noktasına kadar yavaşça** bırakın. Araç hareketlenmeye başlayınca gazı biraz artırıp debriyajı kademeli olarak tam bırakın. Debriyajı bir anda bırakmak motoru boğar ve araç **stop** eder; asıl beceri, pedalı kavrama noktasında bir an bekletebilmektir.',
      },
      {
        heading: 'Rampada kalkış: üç ayağın dengesi',
        badge: 'instructor',
        body: 'Yokuşta el freni çekiliyken debriyajı kavrama noktasına getirin ve aynı anda hafif gaz verin. Aracın öne asıldığını (ses ve titreşim) hissettiğiniz anda **el frenini yavaşça indirin**. Bu üçlü denge (el freni - gaz - debriyaj) sayesinde araç geri kaymadan öne doğru hareket eder.',
      },
      {
        heading: 'Geri kaymanın tehlikesi',
        badge: 'safety',
        body: 'Rampada geri kayma, hemen arkanızdaki araca çarpma riski taşıdığı için ciddi bir güvenlik hatasıdır ve sınavda güvenliği tehlikeye atan bir hareket olarak değerlendirilebilir. El freni yöntemi bu riski ortadan kaldırdığı için en güvenli ve en çok önerilen tekniktir.',
      },
    ],
    mistakes: [
      {
        text: 'Rampada el freni desteği olmadan debriyajı hızlı bırakıp geri kaymak.',
        fix: 'El freni çekiliyken kavrama noktası ve gaz dengesini kurun; araç öne asıldığında el frenini indirin.',
      },
      {
        text: 'Kalkışta debriyajı bir anda bırakıp motoru boğmak.',
        fix: 'Kavrama noktasında bir an bekleyin ve debriyajı kademeli bırakın.',
      },
    ],
    tips: [
      'Kavrama noktasını tanımak için düz zeminde gaz vermeden yalnızca debriyajla aracı yürütmeyi deneyin.',
    ],
    memoryTips: ['Rampa dengesi: El freni - Gaz - Debriyaj - Bırak.'],
    examStrategy: [
      'Rampa istasyonunda acele etmeyin; geri kaymamak hızlı kalkmaktan daha önemlidir ve el freni yöntemi en güvenli yoldur.',
    ],
    keyTakeaways: [
      'Kavrama noktası, gücün tekerleğe geçmeye başladığı andır.',
      'Yarım debriyaj ve hafif gaz sarsıntısız kalkış sağlar.',
      'Rampada el freni geri kaymayı önler.',
      'Debriyajı ani bırakmak motoru durdurur.',
    ],
    reviewCards: [
      {
        front: 'Rampada geri kaymamak için ne yaparız?',
        back: 'El freni çekiliyken kavrama noktası ve gaz dengesini kurar, araç öne asıldığında el frenini yavaşça indiririz.',
      },
      {
        front: 'Yarım debriyaj ne demektir?',
        back: 'Debriyaj pedalını tam bırakmadan, gücün kademeli aktarıldığı kavrama noktası civarında tutmaktır.',
      },
    ],
    quizQuestionIds: ['pratik-104', 'pratik-105', 'pratik-111'],
    practiceQuestionIds: ['pratik-104', 'pratik-105', 'pratik-111', 'pratik-119', 'pratik-103'],
    references: ['MTSK direksiyon eğitimi — kavrama kontrolü ve rampada kalkış'],
    figureId: 'hill-start',
  },
  {
    id: 'park-manevra',
    slug: 'park-manevra',
    premium: true,
    no: 17,
    subject: 'pratik',
    title: 'Park Manevraları: Paralel ve Geri Park',
    summary:
      'Referans noktaları, ayna ve kör nokta kullanımıyla paralel ve geri parkı yavaş ve kontrollü yapmanın yöntemi.',
    minutes: 11,
    objectives: [
      'Paralel parkı referans noktalarıyla yapmak',
      'Geri manevrada ayna ve kör noktayı birlikte kullanmak',
      'Direksiyonu yavaş ve kontrollü çevirmek',
    ],
    sections: [
      {
        heading: 'Referans noktaları neden önemli?',
        badge: 'instructor',
        body: 'Referans noktası, aracın belirli bir parçasının (yan ayna, cam kenarı, kaput köşesi) dışarıdaki bir çizgiyle hizalandığı andır. Bu noktaları kullanmak, aracın nerede olduğunu **tahmin etmek yerine öngörmenizi** sağlar. Her araçta ölçüler farklıdır; bu yüzden kendi aracınızda tutarlı noktalar belirleyip her manevrada aynılarını kullanın.',
      },
      {
        heading: 'Paralel park adımları',
        badge: 'instructor',
        body: 'Aracı park boşluğunun yanındaki araçla yaklaşık aynı hizaya getirin. Geri gelirken direksiyonu boşluğa doğru kırın; arka tekerlek bordür hizasına yaklaşınca direksiyonu düzeltip sonra ters yöne kırarak aracın önünü içeri alın. Her aşamada **dur, bak, sonra devam et**; manevra tek hamlede değil, kontrollü parçalarla tamamlanır.',
      },
      {
        heading: 'Geri park ve kör nokta',
        badge: 'safety',
        body: 'Geri manevrada yalnızca aynalara güvenmek yeterli değildir; arka ve yan aynalara ek olarak **omuz üstünden kör noktayı** ve arka camı kontrol edin. Aynaların göremediği alandan aniden bir yaya, çocuk ya da bisikletli çıkabilir. Görüş kısıtlıysa yavaşlayın, gerekiyorsa tamamen durun.',
      },
      {
        heading: 'Yavaş araç, kontrollü direksiyon',
        badge: 'instructor',
        body: 'Manevrada aracı debriyajla rölantiye yakın bir hızda yürütün ve direksiyonu **kararlı ama kontrollü** çevirin. Araç yavaş olduğunda pozisyon hatasını fark edip düzeltmek kolaydır; hız arttıkça hem hata büyür hem de düzeltme şansı azalır. Hızda değil, kontrolde başarı vardır.',
      },
    ],
    mistakes: [
      {
        text: 'Geri parkta yalnızca aynalara güvenip kör noktayı kontrol etmemek.',
        fix: 'Aynaların görmediği alanı omuz üstünden bizzat kontrol edin.',
      },
      {
        text: 'Manevrada araca fazla hız verip pozisyonu kaçırmak.',
        fix: 'Debriyajla yavaş yürüyün; düşük hızda hata düzeltmek kolaydır.',
      },
    ],
    tips: [
      'Emin olmadığınızda durun, çevreyi tarayın ve manevraya öyle devam edin; manevra ortasında durmak hata değildir.',
    ],
    memoryTips: ['Manevra kuralı: Yavaş git, çok bak, erken kırma.'],
    examStrategy: [
      'Park istasyonunda hız değil kontrol puan kazandırır; her yön değişiminde durup ayna ve kör nokta kontrolü yapmak hem güvenli hem de hakem gözünde olumludur.',
    ],
    keyTakeaways: [
      'Referans noktaları tahmini azaltır, tekrarlanabilir park sağlar.',
      'Geri manevrada ayna, kör nokta ve arka cam birlikte kullanılır.',
      'Manevra yavaş araç ve kontrollü direksiyonla yapılır.',
      'Şüphede durmak her zaman güvenlidir.',
    ],
    reviewCards: [
      {
        front: 'Geri parkta kör nokta nasıl kontrol edilir?',
        back: 'Aynalara ek olarak omuz üstünden dönüp aynaların göremediği alan bizzat kontrol edilerek.',
      },
      {
        front: 'Manevrada aracın hızı nasıl olmalı?',
        back: 'Debriyajla yürüyecek kadar yavaş, rölantiye yakın; böylece direksiyon hataları kolay düzeltilir.',
      },
    ],
    quizQuestionIds: ['pratik-106', 'pratik-107', 'pratik-109'],
    practiceQuestionIds: ['pratik-106', 'pratik-107', 'pratik-109', 'pratik-116', 'pratik-118'],
    references: ['MTSK direksiyon eğitimi — park ve manevra teknikleri'],
    figureId: 'parking',
  },
  {
    id: 'kavsak-uygulama',
    slug: 'kavsak-uygulama',
    premium: true,
    no: 18,
    subject: 'pratik',
    title: 'Kavşak ve Dönel Kavşak Uygulaması',
    summary:
      'Kavşağa yaklaşırken tarama, erken sinyal ve dönel kavşakta yol verme ile çıkış sinyalinin doğru zamanlaması.',
    minutes: 9,
    objectives: [
      'Kavşağa yaklaşırken erken tarama ve sinyal vermek',
      'Dönel kavşakta içerideki araca yol vermek',
      'Çıkışta sinyal vererek güvenli ayrılmak',
    ],
    sections: [
      {
        heading: 'Yaklaşırken tara ve erken sinyal ver',
        badge: 'instructor',
        body: 'Kavşağa yaklaşırken önce hızınızı azaltın, ardından **sol - ileri - sağ** yönünde tarama yapın ve gideceğiniz yöne göre sinyali erken verin. Sinyalin amacı niyetinizi diğer sürücülere önceden bildirmektir; dönüşün tam üstünde verilen geç bir sinyal işe yaramaz. Doğru şeridi de kavşağa girmeden seçin.',
      },
      {
        heading: 'Dönel kavşakta yol verme',
        badge: 'official',
        body: 'İşaretlerle aksi belirtilmedikçe dönel kavşakta **halkanın içindeki (soldan gelen) araç önceliklidir**. Girişte yavaşlayın, halkadaki trafiğe yol verin ve ancak uygun bir boşluk oluştuğunda içeri girin. Zorlayarak girmek çarpışma riski yaratır; beklemek her zaman daha güvenlidir.',
      },
      {
        heading: 'Çıkışta sinyal ver',
        badge: 'instructor',
        body: 'Dönel kavşaktan ayrılırken, çıkacağınız koldan **hemen önce sağ sinyal verin** ve ayna kontrolüyle halkayı terk edin. Böylece arkanızdaki ve girişte bekleyen sürücüler niyetinizi anlar. Çıkışı kaçırırsanız zorlanmadan bir tur daha atın; ani ve son anda dönüş yapmayın.',
      },
      {
        heading: 'Kavşakta yayaya öncelik',
        badge: 'safety',
        body: 'Dönüş yaparken yaya geçidini kullanan yayaya yol vermek zorunludur. Ayrıca çıkışı dolu bir kavşağa, yolunuz açık olsa bile girmeyin; kavşak ortasında sıkışıp kalmak trafiği kilitler ve tehlike yaratır. Emin olamadığınız her durumda yavaşlayıp öncelik verin.',
      },
    ],
    mistakes: [
      {
        text: 'Dönel kavşağa, içerideki araca yol vermeden girmek.',
        fix: 'Girişte yavaşlayın, halkadaki araca yol verin ve uygun boşlukta girin.',
      },
      {
        text: 'Çıkışta sağ sinyal vermeyi unutmak.',
        fix: 'Çıkacağınız koldan hemen önce sağ sinyal verin ki arkadaki sürücü niyetinizi anlasın.',
      },
    ],
    tips: [
      'Sinyal bir rica değil, bir bilgilendirmedir; niyetinizi erken, açık ve zamanında bildirin.',
    ],
    memoryTips: ['Kavşak sırası: Tara - Sinyal - Yol ver - Gir - Çıkışta yine sinyal.'],
    examStrategy: [
      'Hakem sinyal zamanlamasını yakından izler; hiç verilmeyen ya da geç verilen sinyal puan kaybettirir, dönüş bitince sinyali kapatmayı da unutmayın.',
    ],
    keyTakeaways: [
      'Kavşağa yaklaşırken önce tara, sonra erken sinyal ver.',
      'Dönel kavşakta içerideki araç önceliklidir.',
      'Çıkıştan hemen önce sağ sinyal verilir.',
      'Yayaya ve geçiş hakkı olana yol verilir.',
    ],
    reviewCards: [
      {
        front: 'Dönel kavşakta kim önceliklidir?',
        back: 'İşaretlerle aksi belirtilmedikçe halkanın içindeki (soldan gelen) araç önceliklidir; giren araç yol verir.',
      },
      {
        front: 'Dönel kavşaktan çıkarken ne yaparız?',
        back: 'Çıkacağımız koldan hemen önce sağ sinyal verir, ayna kontrolü yapıp halkayı terk ederiz.',
      },
    ],
    quizQuestionIds: ['pratik-108', 'pratik-113', 'pratik-117'],
    practiceQuestionIds: ['pratik-108', 'pratik-113', 'pratik-117', 'pratik-123', 'pratik-109'],
    references: [
      'Karayolları Trafik Yönetmeliği — dönel kavşak ve geçiş hakkı',
      'MTSK direksiyon eğitimi — kavşak uygulaması',
    ],
    figureId: 'roundabout',
  },
  {
    id: 'sinav-strateji',
    slug: 'sinav-strateji',
    no: 19,
    subject: 'pratik',
    title: 'Direksiyon Sınavı: Hatalar, Değerlendirme ve Psikoloji',
    summary:
      'Sınavı bitiren ağır hatalarla puan kıran hataların mantığını ve sınav kaygısıyla başa çıkma yöntemlerini kavramak.',
    minutes: 10,
    objectives: [
      'Ağır (elemeli) hata ile puan kıran hatayı ayırt etmek',
      'Sık atlanan adımları (kemer, ayna, sinyal) fark etmek',
      'Sınav kaygısıyla nefes ve odak teknikleriyle başa çıkmak',
    ],
    sections: [
      {
        heading: 'İki tür hata: kaldıran ve kıran',
        badge: 'examiner',
        body: 'Direksiyon sınavında hatalar aynı ağırlıkta değildir. **Bazı hatalar güvenliği doğrudan tehlikeye attığı için sınavı anında bitirir** ya da hakemin müdahalesini (frene veya direksiyona el atması) gerektirir. **Bazı hatalar ise güvenliği yıkmaz ama puan kırar**; ayna kontrolünü atlamak, geç sinyal vermek ya da sarsıntılı kalkış gibi. Kesin bir puan tablosu ezberlemeye çalışmak yerine bu mantığı kavramak daha değerlidir: hangi hata güvenliği bozuyorsa o ağırdır.',
      },
      {
        heading: 'Sık atlanan küçük ama pahalı adımlar',
        badge: 'examiner',
        body: 'Adayların en sık kaçırdığı adımlar aslında en basitleridir: kemeri takmamak ya da geç takmak, harekete geçmeden ayna ve kör nokta kontrolü yapmamak, sinyal vermemek veya geç vermek, el frenini indirmeyi unutmak. Tek başına küçük görünen bu eksikler hem birbiriyle birikir hem de güvenliğe dokundukları anda sonucu belirleyecek kadar pahalıya mal olur.',
      },
      {
        heading: 'Güvenliği tehlikeye atan hareket',
        badge: 'safety',
        body: 'Hakemin ayağının frene gitmesi, yayaya veya geçiş hakkı olan araca yol vermemek, kavşakta hatalı geçiş yapmak en ağır hatalardır; çünkü bunlar gerçek bir kaza riski taşır. Bu yüzden emin olamadığınız her durumda ilkeniz nettir: **yavaşlayın ve yol verin**. Fazla temkinli olmak nadiren, aceleci olmak ise sık kaybettirir.',
      },
      {
        heading: 'Sınav kaygısıyla başa çıkma',
        badge: 'instructor',
        body: 'Gerginlik doğaldır ama yönetilebilir. Sınavdan önce yavaş ve derin nefes alın (yaklaşık dört saniye al, dört saniye ver); bu, kalp atışını ve titremeyi yatıştırır. Adımlarınızı içinizden ya da alçak sesle **sesli düşünmek** (ayna - sinyal - manevra) hem odağı korur hem adım atlamayı önler. Bir hata yaptığınızda paniğe kapılıp zincirleme hataya sürüklenmeyin; o hatayı bırakıp bir sonraki harekete odaklanın.',
      },
    ],
    mistakes: [
      {
        text: 'Küçük bir hatadan sonra paniğe kapılıp arka arkaya yeni hatalar yapmak.',
        fix: 'Hatayı geride bırakın, bir nefes alın ve bir sonraki adıma sakince odaklanın.',
      },
      {
        text: 'Kesin bir puan tablosu ezberlemeye çalışıp asıl mantığı kaçırmak.',
        fix: 'Hangi hatanın güvenliği bozduğunu düşünün; güvenliği bozan hata her zaman ağırdır.',
      },
    ],
    tips: [
      'Adımları alçak sesle düşünmek (ayna - sinyal - manevra) hem sizi sakinleştirir hem de adım atlamayı engeller.',
    ],
    memoryTips: [
      'Ağır hata = güvenlik tehlikesi (kaldırır); hafif hata = eksik veya dikkatsizlik (kırar).',
    ],
    examStrategy: [
      'Emin olmadığınız her durumda yavaşlayıp yol verin; sınavda fazla temkinli olmak nadiren, aceleci olmak sık kaybettirir.',
      'Sınavdan önce koltuk-ayna-kemer rutinini otomatikleştirin; gerginken bile ezberlenmiş adımlar sizi taşır.',
    ],
    keyTakeaways: [
      'Bazı hatalar sınavı doğrudan bitirir, bazıları yalnızca puan kırar.',
      'Güvenliği tehlikeye atan hareket en ağır hatadır.',
      'Kemer, ayna ve sinyal en sık atlanan pahalı adımlardır.',
      'Nefes ve odak, kaygıyı yönetmenin en pratik araçlarıdır.',
    ],
    reviewCards: [
      {
        front: 'Hangi hata sınavı doğrudan bitirir?',
        back: 'Güvenliği tehlikeye atan, hakemin müdahalesini gerektiren hareketler; örneğin geçiş hakkı ihlali veya çarpma riski.',
      },
      {
        front: 'Sınav kaygısını azaltmanın pratik yolu nedir?',
        back: 'Yavaş ve derin nefes almak, adımları (ayna - sinyal - manevra) içinden düşünmek ve odağı bir sonraki harekete vermek.',
      },
    ],
    quizQuestionIds: ['pratik-114', 'pratik-115', 'pratik-120'],
    practiceQuestionIds: ['pratik-114', 'pratik-115', 'pratik-120', 'pratik-125', 'pratik-113'],
    references: [
      'MEB direksiyon sınavı uygulaması — değerlendirme mantığı',
      'MTSK direksiyon eğitimi — sınav hazırlığı',
    ],
  },
];
