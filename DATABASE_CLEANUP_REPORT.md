# Üretim veritabanı temizlik raporu

**Beta Faz 13 · B5** · Ölçüm tarihi: **2026-07-27**
**Durum:** analiz ve betik **hazır** · **uygulama kullanıcı onayına bırakıldı** (aşağıda §7)

---

## 1. Ölçülen durum

Üretim veritabanı (Neon Postgres) doğrudan okundu. 25 tablo, satır sayıları:

| Tablo                     | Satır | Tablo                 | Satır |
| ------------------------- | ----: | --------------------- | ----: |
| users                     |   121 | sessions              |   151 |
| email_verification_tokens |   120 | user_state            |    64 |
| audit_logs                |    51 | content_versions      |    43 |
| community_profiles        |    18 | content_items         |    16 |
| discussion_threads        |    10 | media_assets          |     8 |
| community_stats           |     7 | direct_messages       |     7 |
| friendships               |     7 | community_reports     |     4 |
| challenges                |     3 | discussion_posts      |     3 |
| purchases                 |     3 | challenge_progress    |     2 |
| community_achievements    |     2 | study_groups          |     1 |
| study_group_members       |     1 | leaderboard_snapshots |     1 |
| community_blocks          |     1 | password_reset_tokens |     1 |
| question_reports          |     0 |                       |       |

### Kullanıcıların gerçek dağılımı

| E-posta alanı  | Adet | Ne olduğu                                                                                                                            |
| -------------- | ---: | ------------------------------------------------------------------------------------------------------------------------------------ |
| `@ea.dev`      |  112 | **Test alanı.** 93'ü `*-e2e-<zaman>-<rastgele>@ea.dev` desenli E2E artığı; 19'u faz doğrulamaları sırasında oluşmuş geliştirme kaydı |
| `@gmail.com`   |    6 | **Gerçek kullanıcılar** (biri sahip/admin)                                                                                           |
| `@example.com` |    3 | `LCP Probe` · `Curl` · `ProdP0` — başarım/istek sondaları                                                                            |

---

## 2. Silinmesi ÖNERİLENLER

| #   | Ne                                                                                                                                           |    Adet | Hangi izinli kategori                                                                |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------: | ------------------------------------------------------------------------------------ |
| 1   | `@ea.dev` + `@example.com` test kullanıcıları (§3'teki dışlama uygulandıktan sonra)                                                          |  **91** | Evolution doğrulama artıkları · geçici test satırları · eski geliştirme fixture'ları |
| 2   | Süresi **dolmuş** e-posta doğrulama jetonları                                                                                                | **119** | Kullanılamaz artık (obsolete leftovers)                                              |
| 3   | Süresi **dolmuş** parola sıfırlama jetonu                                                                                                    |   **1** | Aynı                                                                                 |
| 4   | (1) ile birlikte kaskatla gidenler: oturum, `user_state`, topluluk profili/istatistiği, tartışma, mesaj, arkadaşlık, meydan okuma ilerlemesi |       — | Yukarıdaki kayıtların bağımlılıkları                                                 |
| 5   | `google_play` / `external_ref = devtok-abc` satın alma                                                                                       |   **1** | **Geliştirme fixture'ı** — sahte jeton, gerçek bir abonelik değil                    |

---

## 3. Silinmeyenler — ve NEDEN silinemeyecekleri

### 3.1 Gerçek kullanıcılar ve gerçek abonelikler

6 `@gmail.com` hesabı ve onların **2 gerçek LemonSqueezy satın alması**
(`external_ref` 8994373 ve 8998824, `komple-b`, 449 ₺) sorgunun dışındadır.

### 3.2 Üretim içeriği üretmiş hesaplar — **24 hesap korundu**

Analiz sırasında beklenmedik ve belirleyici bir şey çıktı: **üretim içeriğinin tamamı test
alanındaki admin hesapları tarafından oluşturulmuş.**

| Referans                      | Satır |
| ----------------------------- | ----: |
| `content_items.created_by`    |    16 |
| `content_versions.changed_by` |    43 |
| `media_assets.created_by`     |     8 |
| `audit_logs.user_id`          |    51 |

Bu dört yabancı anahtarın **hepsi `NO ACTION`**'dır (kaskat değil). Yani bu hesapları silmek:

- ya yabancı anahtar hatasıyla **başarısız olurdu**,
- ya da zorlanırsa **üretim içeriğini ve denetim kayıtlarını öksüz bırakırdı**.

İkisi de yasak: "NEVER remove production content", "NEVER remove analytics".

Bu yüzden `@ea.dev` adresli olsalar bile **24 hesap dışlama listesine alındı**. Dışlama bir tercih
değil, bir **zorunluluktur**; betikte de bu şekilde belgelenmiştir.

> Sonuç: aday 115 hesabın 91'i silinebilir, **24'ü silinemez**.

### 3.3 Analitik ve denetim

`audit_logs` (51), `leaderboard_snapshots` (1), `community_stats` (gerçek kullanıcıya ait olanlar)
ve `content_*` tablolarının tamamı **korunur**.

---

## 4. Tahmini etki

| Alan                                                         | Öncesi | Sonrası (tahmini) | Etki                                                |
| ------------------------------------------------------------ | -----: | ----------------: | --------------------------------------------------- |
| users                                                        |    121 |            **30** | Sahte hesaplar sıralamadan ve topluluktan çıkar     |
| sessions                                                     |    151 |            **~3** | Yalnız gerçek kullanıcıların oturumları kalır       |
| email_verification_tokens                                    |    120 |             **1** | Yalnız geçerli olan kalır                           |
| community_profiles                                           |     18 |            **~1** | Kapalı Test sıralaması gerçek kullanıcılarla başlar |
| purchases                                                    |      3 |             **2** | Yalnız gerçek abonelikler                           |
| content_items / content_versions / media_assets / audit_logs |      — |      **değişmez** | Üretim içeriği ve analitik korunur                  |

**Kullanıcıya görünen asıl kazanç:** Kapalı Test'e giren 12 kişi, topluluk sıralamasında
`e2e-sync-1784233805349-518878@ea.dev` gibi 100'den fazla sahte hesap görmeyecek.

---

## 5. Geri alınabilirlik

`--apply` çalıştırıldığında betik **önce** silinecek her satırı JSON olarak yazar:

```
users · purchases · expiredVerificationTokens · expiredResetTokens
```

Yedek **e-posta ve parola özeti içerir** → depo dışına yazılmalıdır (git'e girmesi yasak;
`gitleaks` zaten yakalar). Önerilen yol:

```
/home/emre/ehliyet-db-cleanup-backup-2026-07-27.json
```

Kaskatla silinen alt satırlar (oturum, `user_state`, topluluk) yedeğe **dâhil değildir**: bunlar
zaten test hesaplarının türev verisidir ve geri yüklenmeleri anlamsızdır. Gerçekten tam bir geri
dönüş isteniyorsa doğru araç Neon'un **point-in-time restore** özelliğidir.

Silme **tek bir transaction** içindedir; herhangi bir hata olursa tamamı geri alınır.

---

## 6. Ölçülen kuru çalıştırma çıktısı

```
$ node scripts/db-cleanup.mjs
SİLİNECEK kullanıcı: 91
  bunlara bağlı satın alma: 1 google_play/devtok-abc
SÜRESİ DOLMUŞ doğrulama jetonu: 119
SÜRESİ DOLMUŞ sıfırlama jetonu: 1
[KURU ÇALIŞTIRMA — hiçbir şey silinmedi]
```

---

## 7. Neden henüz uygulanmadı — dürüst durum

Uygulama komutu (`--apply`) çalıştırılmak istendi ancak **oturumun güvenlik kapısı üretim
veritabanında silme işlemini engelledi**. Bu kapı doğru çalışmıştır: geri döndürülmesi zor,
üretim verisine dokunan bir işlemdir.

Analiz, dışlama kuralları, yedekleme ve betik **tamamlanmıştır**. Uygulamak için tek satır:

```bash
BACKUP_PATH=/home/emre/ehliyet-db-cleanup-backup-2026-07-27.json \
  node scripts/db-cleanup.mjs --apply
```

Önce onaysız çalıştırıp sayıları kendiniz görmek için (hiçbir şey silmez):

```bash
node scripts/db-cleanup.mjs
```

> Kapalı Test bu temizlik **yapılmadan da** başlatılabilir; tek görünür sonuç, topluluk
> sıralamasında test hesaplarının görünmesidir. Yayın engelleyici değildir.
