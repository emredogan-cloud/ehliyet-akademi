# Final Release AAB Report — Ehliyet Akademi 1.0.0 (6)

**Built:** 11 August 2026, 19:58 · **Commit:** `117bede` ·
**Branch:** `release/preproduction-1.0.0`

> This artefact was built **after** every agent-owned gate reached PASS. It is **not uploaded** —
> the founder uploads it to Closed Testing (F-14), and only then performs the real purchase test
> (F-05), which is the one thing that cannot be verified without it.

---

## 1. Artefact

| Field         | Value                                                                       |
| ------------- | --------------------------------------------------------------------------- |
| Path          | `apps/mobile/build/app/outputs/bundle/release/app-release.aab`              |
| Size          | 63,433,113 bytes (61M)                                                      |
| SHA-256       | `2a434d044504890cfdf63d07620998ad8a532f8abdd62f9e746e773aba468e87`          |
| Build command | `flutter build appbundle --release --dart-define=GOOGLE_SERVER_CLIENT_ID=…` |

## 2. Identity — verified inside the artefact

| Check                 | Expected                            | Found   | Result |
| --------------------- | ----------------------------------- | ------- | ------ |
| Package name          | `com.ehliyetegitim.ehliyet_akademi` | same    | ✅     |
| **versionCode**       | **6** (was 5, incremented once)     | **6**   | ✅     |
| versionName           | `1.0.0`                             | `1.0.0` | ✅     |
| `allowBackup`         | `false`                             | `false` | ✅     |
| `dataExtractionRules` | present                             | present | ✅     |

## 3. Signing

| Check               | Result                                                                                            |
| ------------------- | ------------------------------------------------------------------------------------------------- |
| `jarsigner -verify` | **jar verified**                                                                                  |
| Signer              | `CN=Emre Dogan, OU=Mobile, O=Ehliyet Akademi - Sınav 2026, L=adana, C=TR`                         |
| Key                 | RSA **4096-bit**, SHA256withRSA                                                                   |
| Certificate SHA-256 | `46:B2:DF:CE:2F:78:BD:A0:EB:C6:A0:19:FE:4F:14:98:C0:52:37:42:19:94:68:C5:47:D0:4F:68:6F:06:07:D3` |
| **Debug-signed?**   | **NO** — the local debug keystore is `06:00:7A:16:…`, a different key                             |

> This is the **upload key**. With Play App Signing enabled, Google re-signs with the app signing
> key; the fingerprint that must go into `ANDROID_SHA256_FINGERPRINTS` (F-07) is the **app signing
> key**, read from the Console — **not** the fingerprint above.

## 4. Google Sign-In client ID — embedded

Omitting the dart-define makes Google Sign-In vanish from the build with no error, so this is
checked per ABI rather than assumed:

| ABI         | `…apps.googleusercontent.com` in `libapp.so` |
| ----------- | -------------------------------------------- |
| arm64-v8a   | ✅ 1 match                                   |
| armeabi-v7a | ✅ 1 match                                   |
| x86_64      | ✅ 1 match                                   |

## 5. No development configuration

| Marker           | Occurrences | Note                                                                                            |
| ---------------- | ----------- | ----------------------------------------------------------------------------------------------- |
| `IAP_DEV_ACCEPT` | 0           | the purchase-verification escape hatch is not in the build                                      |
| `10.0.2.2`       | 0           | no emulator host                                                                                |
| `localhost:3000` | 0           | no dev server                                                                                   |
| `flutter_test`   | 0           | no test harness                                                                                 |
| `debugPrint`     | 27          | **expected** — a Flutter framework symbol present in every release build; not app configuration |

## 6. Permissions in the bundle

Present: `INTERNET`, `com.android.vending.BILLING`, `POST_NOTIFICATIONS`,
`ACCESS_NETWORK_STATE`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`, `WAKE_LOCK`,
`USE_BIOMETRIC`/`USE_FINGERPRINT` (both arrive via a plugin manifest; both are _normal_
permissions with no runtime prompt and no Data Safety implication).

Absent, and verified absent: location, camera, contacts, SMS, external storage, `AD_ID`,
`QUERY_ALL_PACKAGES`.

## 7. Gates that were green before this build

| Gate               | State                                                      |
| ------------------ | ---------------------------------------------------------- |
| Mobile tests       | 1.105 passed                                               |
| Web tests          | 743 passed                                                 |
| Package tests      | 77 passed                                                  |
| `flutter analyze`  | No issues found                                            |
| typecheck / format | clean                                                      |
| lint               | clean (1 pre-existing warning in `packages/db`, unrelated) |
| ASO validator      | 134/134, stage `final`, OCR included                       |
| CI                 | 9/9 green                                                  |

## 8. What the founder does with this file

1. **Play Console → Test and release → Testing → Closed testing → Create new release**
2. Upload this `.aab`
3. Confirm it reaches the licence-tester account
4. **Then** run F-05 (real purchase + restore) — it needs this build to exist
5. Production release only after F-01, F-07, F-08…F-14 are complete

**Do not upload it to Production yet.** Founder-owned blockers remain; see
`FOUNDER_RELEASE_CHECKLIST.md`.

## 9. Reproducing

```bash
git checkout 117bede
cd apps/mobile
flutter build appbundle --release \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id from google-services.json, client_type 3>
sha256sum build/app/outputs/bundle/release/app-release.aab
```

The build is **not** byte-reproducible (Gradle/R8 embed timestamps), so the SHA-256 above
identifies _this_ artefact; a rebuild will differ while remaining functionally identical.
