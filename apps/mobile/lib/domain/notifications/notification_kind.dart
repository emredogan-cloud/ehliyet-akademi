/// Beta Faz 6 — bildirim TÜRLERİNİN merkezî kataloğu.
///
/// ## Neden bir katalog
///
/// `flutter_local_notifications` bildirimleri **tam sayı kimlikle** anar. Bu kimlikler kod içine
/// dağılmış sabitler olarak durursa (`1001`, `999` gibi) iki tür hata kaçınılmazdır:
///
/// 1. **Çakışma.** İki farklı bildirim aynı kimliği alır; ikincisi birincisini SESSİZCE ezer ve
///    kullanıcı bir hatırlatmayı hiç görmez. Hata hiçbir yere düşmez.
/// 2. **Sahipsiz bildirim.** Bir tür kaldırılır ama kimliği iptal edilmez; cihazda planlanmış
///    kalır ve haftalar sonra artık var olmayan bir özellik için bildirim gelir.
///
/// Katalog ikisini de kapatır: kimlik türün kendisine bağlıdır, tekilliği test edilir ve
/// "istenen küme" ile "planlı küme" karşılaştırılabilir hâle gelir.
///
/// ## Neden kopya (metin) burada
///
/// Bildirim metni ürünün en görünür ve en kolay bozulan yüzeyidir: kullanıcı uygulamayı açmadan
/// okur. Metinleri planlayıcının içine gömmek, onları gözden geçirilemez hâle getirirdi.
library;

/// Bir bildirim türü.
enum NotificationKind {
  /// Günlük çalışma hatırlatması — kullanıcının seçtiği saatte.
  studyReminder(
    id: 1001,
    channel: NotificationChannelKind.study,
    label: 'Çalışma hatırlatması',
    description: 'Seçtiğin saatte günlük hatırlatma',
    defaultEnabled: true,
  ),

  /// Kaçırılan çalışma günü — dün çalışıldı, bugün çalışılmadı.
  missedStudyDay(
    id: 1002,
    channel: NotificationChannelKind.study,
    label: 'Kaçırılan gün',
    description: 'Bir gün ara verdiğinde nazik bir hatırlatma',
    defaultEnabled: true,
  ),

  /// Seri korunuyor / kırılmak üzere.
  streak(
    id: 1003,
    channel: NotificationChannelKind.study,
    label: 'Çalışma serisi',
    description: 'Serin kırılmak üzereyken haber ver',
    defaultEnabled: true,
  ),

  /// Haftalık özet — geçen hafta ne yaptın.
  weeklySummary(
    id: 1004,
    channel: NotificationChannelKind.progress,
    label: 'Haftalık özet',
    description: 'Pazar akşamları haftanın özeti',
    defaultEnabled: true,
  ),

  /// Hedefe ulaşıldı (hazırlık eşiği geçildi).
  goalAchieved(
    id: 1005,
    channel: NotificationChannelKind.progress,
    label: 'Hedef tamamlandı',
    description: 'Bir hedefi tamamladığında kutlama',
    defaultEnabled: true,
  ),

  /// Yeni rozet açıldı.
  badgeUnlocked(
    id: 1006,
    channel: NotificationChannelKind.progress,
    label: 'Yeni rozet',
    description: 'Bir rozet kazandığında haber ver',
    defaultEnabled: true,
  ),

  /// Davet ödülü kazanıldı.
  referralReward(
    id: 1007,
    channel: NotificationChannelKind.account,
    label: 'Davet ödülü',
    description: 'Davetin ödüle dönüştüğünde haber ver',
    defaultEnabled: true,
  ),

  /// Premium süresi bitmek üzere (davet ödülü gibi SÜRELİ erişimler için).
  premiumExpiring(
    id: 1008,
    channel: NotificationChannelKind.account,
    label: 'Premium süresi',
    description: 'Süreli erişimin bitmeden önce hatırlat',
    defaultEnabled: true,
  );

  const NotificationKind({
    required this.id,
    required this.channel,
    required this.label,
    required this.description,
    required this.defaultEnabled,
  });

  /// Planlama kimliği — **asla değiştirilmez**. Değişirse cihazda planlanmış eski bildirim
  /// sahipsiz kalır ve iptal edilemez.
  final int id;

  final NotificationChannelKind channel;

  /// Ayarlar ekranındaki başlık.
  final String label;

  /// Ayarlar ekranındaki açıklama — kullanıcı NEYE izin verdiğini bilmeli.
  final String description;

  final bool defaultEnabled;

  /// Tercihlerde saklanan anahtar. Enum adı kullanılır; `id` değil — okunabilir kalsın diye.
  String get prefKey => name;
}

/// Android bildirim kanalı.
///
/// ## Neden tek kanal yetmiyor
///
/// Android'de kullanıcı kanalları **tek tek** susturabilir. Her şey tek kanaldan gelirse,
/// haftalık özetten rahatsız olan kullanıcının elindeki tek seçenek bildirimlerin TAMAMINI
/// kapatmaktır — çalışma hatırlatması da gider. Üç kanal, kullanıcıya gerçek bir seçim verir.
enum NotificationChannelKind {
  study(
    id: 'ea_study',
    name: 'Çalışma hatırlatmaları',
    description: 'Günlük hatırlatma, kaçırılan gün ve seri uyarıları',
  ),
  progress(
    id: 'ea_progress',
    name: 'İlerleme ve başarılar',
    description: 'Haftalık özet, rozetler ve hedefler',
  ),
  account(
    id: 'ea_account',
    name: 'Hesap ve premium',
    description: 'Davet ödülleri ve premium süresi',
  );

  const NotificationChannelKind({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}
