/**
 * PROGRAM SEO / AEO — ana sayfa SSS. AI aramalarında (Google AI Overviews, ChatGPT, Perplexity)
 * alıntılanabilir, DOĞRU, kısa soru-cevaplar. Uydurma yok: rakamlar resmî MEB e-Sınav formatı
 * (EXAM_BLUEPRINT: 50 soru / 45 dk / 35 doğru baraj) ve gerçek platform özellikleridir.
 */
import { EXAM_BLUEPRINT } from '@ea/content-schema';

const { totalQuestions, durationMinutes, passCorrect, distribution } = EXAM_BLUEPRINT;

export interface FaqItem {
  question: string;
  answer: string;
}

export const HOME_FAQ: FaqItem[] = [
  {
    question: 'B sınıfı ehliyet teorik sınavı kaç soru ve kaç dakika?',
    answer: `B sınıfı ehliyet teorik (e-Sınav) ${totalQuestions} sorudan oluşur ve süresi ${durationMinutes} dakikadır. Sorular trafik ve çevre bilgisi (${distribution.trafik}), ilk yardım (${distribution.ilkyardim}), araç tekniği (${distribution.motor}) ve trafik adabı (${distribution.adab}) konularına dağılır.`,
  },
  {
    question: 'Ehliyet teorik sınavında geçmek için kaç doğru gerekir?',
    answer: `Ehliyet teorik sınavında geçmek için ${totalQuestions} soruda en az ${passCorrect} doğru yapmanız gerekir; bu 100 puan üzerinden 70 puana karşılık gelir. Her soru eşit puandır ve yanlışlar doğruları götürmez.`,
  },
  {
    question: 'Ehliyet Akademi nedir?',
    answer:
      'Ehliyet Akademi, Türkiye B sınıfı ehliyet adayları için hazırlanmış bir dijital eğitim platformudur. Özgün soru bankası, konu anlatımlı dersler, trafik işaretleri rehberi, araç tanıma, deneme sınavları ve içeriğe dayalı (halüsinasyon üretmeyen) bir AI Koç sunar.',
  },
  {
    question: 'Ehliyet Akademi ücretsiz mi?',
    answer:
      'Ehliyet Akademi ücretsiz bir kademe sunar: tanı denemesi, günlük deneme sınavı ve aralıklı tekrar (SRS) pratiği ücretsizdir. Premium içerikler ise abonelik yerine tek seferlik satın alma ile ömür boyu erişilebilir.',
  },
  {
    question: 'Ehliyet sınavına nasıl çalışmalıyım?',
    answer:
      'Önce kısa bir tanı denemesiyle hazırlık skorunuzu ölçün; zayıf konularınızı belirleyip önce onlara çalışın. Konu derslerini okuyun, trafik işaretlerini tekrar edin, aralıklı tekrar (SRS) ile yanlışlarınızı pekiştirin ve gerçek sınav formatında deneme sınavlarıyla kendinizi ölçün.',
  },
  {
    question: 'Trafik işaretleri sınavda çıkar mı?',
    answer:
      'Evet. Trafik ve çevre bilgisi, e-Sınavdaki en yüksek ağırlıklı konudur ve trafik işaretleri bu bölümün önemli bir kısmını oluşturur. Ehliyet Akademi tehlike uyarı, yasaklayıcı, mecburiyet, bilgi ve öncelik levhalarını anlamları ve hafıza teknikleriyle birlikte sunar.',
  },
];
