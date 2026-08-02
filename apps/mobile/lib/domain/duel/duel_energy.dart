library;

/// Ürün Evrimi v1.1 · Faz 4 — düello enerjisi, günlük sınır ve çiftçilik önleme.
///
/// SAF (pure) tutuldu: hiçbir depolama, saat ya da sağlayıcı bilmez. Zaman dışarıdan verilir.
/// Böylece "gece yarısı sıfırlanma", "saat ileri alınırsa ne olur", "üst üste kaç düello"
/// sorularının hepsi testte cevaplanabiliyor.

/// Enerji durumu — kalıcılaştırılan tek şey budur.
class DuelEnergy {
  const DuelEnergy({required this.spent, required this.dayKey, required this.lastFinishedAtMs});

  /// Bugün harcanan enerji.
  final int spent;

  /// Hangi güne ait (`YYYY-MM-DD`). Gün değişince [spent] sıfırlanır.
  final String dayKey;

  /// Son BİTİRİLEN düellonun zamanı — çiftçilik önlemesi buna bakar.
  final int lastFinishedAtMs;

  static const empty = DuelEnergy(spent: 0, dayKey: '', lastFinishedAtMs: 0);

  DuelEnergy copyWith({int? spent, String? dayKey, int? lastFinishedAtMs}) => DuelEnergy(
    spent: spent ?? this.spent,
    dayKey: dayKey ?? this.dayKey,
    lastFinishedAtMs: lastFinishedAtMs ?? this.lastFinishedAtMs,
  );

  Map<String, Object?> toJson() => {
    'spent': spent,
    'dayKey': dayKey,
    'lastFinishedAtMs': lastFinishedAtMs,
  };

  /// Bozuk kayıt ÇÖKMEZ, varsayılana düşer.
  ///
  /// `as num?` yetmiyor: alan bir String'se cast atar. Kalıcı depoda ne bulunacağını
  /// garanti edemeyiz (eski sürüm, elle düzenleme, bozulmuş yazma) ve enerji kaydı yüzünden
  /// uygulamanın açılmaması kabul edilemez.
  static DuelEnergy fromJson(Map<String, Object?> j) {
    int asInt(Object? v) => v is num ? v.toInt() : 0;
    return DuelEnergy(
      spent: asInt(j['spent']),
      dayKey: j['dayKey'] is String ? j['dayKey']! as String : '',
      lastFinishedAtMs: asInt(j['lastFinishedAtMs']),
    );
  }
}

/// Ücretsiz kullanıcının günlük düello hakkı.
const int kFreeDailyDuels = 5;

/// Premium kullanıcının günlük hakkı.
///
/// SINIRSIZ DEĞİL — ve bu bilinçli. Sınırsız hak, sunucu tarafı sıralama geldiğinde en çok
/// oynayanın en tepede olduğu bir tablo üretir; sıralama beceriyi değil boş vakti ölçer.
/// 30 düello (~2 saat) hiçbir gerçek kullanıcıyı kısıtlamayacak kadar yüksek.
const int kPremiumDailyDuels = 30;

/// İki düello arasındaki en kısa süre.
///
/// ÇİFTÇİLİK ÖNLEME: düelloyu açıp hemen bırakıp yeniden başlatarak XP toplamayı engeller.
/// 20 saniye, gerçek bir kullanıcının sonucu okuyup yeni düello başlatma süresinden kısa —
/// yani meşru kullanımı hiç engellemez, otomatik tekrarı engeller.
const int kDuelCooldownMs = 20 * 1000;

/// `YYYY-MM-DD` — YEREL güne göre. Kullanıcının "bugün"ü kendi saatidir.
String duelDayKey(DateTime now) =>
    '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

int dailyLimit({required bool premium}) => premium ? kPremiumDailyDuels : kFreeDailyDuels;

/// Bugün kaç düello hakkı kaldı.
int remainingDuels(DuelEnergy e, DateTime now, {required bool premium}) {
  final today = duelDayKey(now);
  final spent = e.dayKey == today ? e.spent : 0;
  return (dailyLimit(premium: premium) - spent).clamp(0, dailyLimit(premium: premium));
}

/// Düello başlatılamama nedeni — yoksa null.
///
/// Enum yerine mesaj döndürmüyoruz: arayüz nedeni bilmeli ki uygun eylemi sunsun (premium'a
/// yönlendir / bekle).
enum DuelBlock {
  /// Günlük hak bitti.
  dailyLimit,

  /// Bir önceki düellodan bu yana yeterli süre geçmedi.
  cooldown,
}

DuelBlock? duelBlockReason(DuelEnergy e, DateTime now, {required bool premium}) {
  if (remainingDuels(e, now, premium: premium) <= 0) return DuelBlock.dailyLimit;
  final since = now.millisecondsSinceEpoch - e.lastFinishedAtMs;
  // `lastFinishedAtMs == 0` → hiç düello bitirilmemiş; bekleme uygulanmaz.
  if (e.lastFinishedAtMs > 0 && since < kDuelCooldownMs) return DuelBlock.cooldown;
  return null;
}

bool canStartDuel(DuelEnergy e, DateTime now, {required bool premium}) =>
    duelBlockReason(e, now, premium: premium) == null;

/// Bekleme bitene kadar kalan süre.
Duration cooldownLeft(DuelEnergy e, DateTime now) {
  if (e.lastFinishedAtMs <= 0) return Duration.zero;
  final left = kDuelCooldownMs - (now.millisecondsSinceEpoch - e.lastFinishedAtMs);
  return left <= 0 ? Duration.zero : Duration(milliseconds: left);
}

/// Düello BAŞLADIĞINDA enerji harca.
///
/// Harcama başlangıçta yapılır, bitişte değil: yarıda bırakarak bedava düello elde etmek
/// mümkün olmasın diye.
DuelEnergy spendForDuel(DuelEnergy e, DateTime now) {
  final today = duelDayKey(now);
  final spent = e.dayKey == today ? e.spent : 0;
  return e.copyWith(spent: spent + 1, dayKey: today);
}

/// Düello BİTTİĞİNDE bekleme sayacını başlat.
DuelEnergy markFinished(DuelEnergy e, DateTime now) =>
    e.copyWith(lastFinishedAtMs: now.millisecondsSinceEpoch);

/// Sıralama basamağı — XP'den türer.
///
/// Sunucu tarafı sıralama henüz YOK. Basamak yerel XP'den hesaplanıyor ve arayüz bunu
/// "senin basamağın" olarak gösteriyor; "dünya sıralamasında 43." gibi doğrulanamaz bir şey
/// SÖYLENMİYOR. Çevrimiçi sıralama geldiğinde bu fonksiyon sunucu değerine devreder.
enum DuelRank {
  cirak('Çırak', 0),
  kalfa('Kalfa', 500),
  usta('Usta', 1500),
  uzman('Uzman', 3500),
  sampiyon('Şampiyon', 7000);

  const DuelRank(this.label, this.minXp);
  final String label;
  final int minXp;
}

DuelRank rankForXp(int xp) {
  var out = DuelRank.cirak;
  for (final r in DuelRank.values) {
    if (xp >= r.minXp) out = r;
  }
  return out;
}

/// Bir sonraki basamağa kalan XP — yoksa null (en üstte).
int? xpToNextRank(int xp) {
  for (final r in DuelRank.values) {
    if (r.minXp > xp) return r.minXp - xp;
  }
  return null;
}
