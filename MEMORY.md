# MEMORY — proje sürdürme bağlamı

> Ani kesinti sonrası devam için. Tek doğru kaynak: üst dizin `ROADMAP.md` (v3.1, 36 faz).
> Ayrıntı: `STATUS.md` · GO/NO-GO: `FINAL_RELEASE_READINESS_REPORT.md`.

_Son güncelleme: 2026-07-15 · SPRINT 6 (son planlı uygulama sprinti) sonrası_

## Kilit durum

- **PRODUCTION CANLI:** https://ehliyet-akademi-nine.vercel.app (Vercel, proje `ehliyet-akademi`, rootDirectory=`apps/web`, NEXT_PUBLIC_SITE_URL env set). Deploy: `vercel deploy --prod --yes` (kökten).
- **CI GERÇEK ve YEŞİL:** repo PUBLIC; Actions (quality/E2E/gitleaks/CodeQL) her push'ta; branch protection açık.
- **MONETIZASYON PİVOTU (bağlayıcı):** abonelik YOK → **tek-seferlik paketler** (5 paket; Komple B = lifetime). ROADMAP Faz 16 güncellendi. Ödeme mock (demo); üretim tahsilatı = LemonSqueezy/Stripe one-time adaptörü kalan iş.

## SPRINT 6 (en güncel tur) — Oyunlaştırma, topluluk, platform zekâsı (SON planlı sprint)

- **Oyunlaştırma (Faz 34):** `lib/gamification.ts` (totalXp/levelForXp/xpToReach/dailyGoal/weeklyGoal/studyHeatmap/learningJourney; XP sabitleri; hepsi saf/testli). `components/StudyHeatmap.tsx` (SVG). Yeni `app/(app)/ilerleme/page.tsx` (data-testid=ilerleme/level-title/daily-challenge/journey/insights).
- **Topluluk (Faz 32/33):** `lib/community.ts` (tierForXp [Bronz→Elmas, uydurma rakip YOK], dailyChallenge deterministik, getOrCreateReferralCode/referralLink, Friend arayüzü=gelecek). ea:referral:v1.
- **Platform zekâsı (Faz 35):** `lib/insights.ts` (learningInsights — best/worst/trend/tempo/due), `lib/notifications.ts` (computeNudges — streak-risk/due-cards/start-today), `components/NudgeBanner.tsx` (Dashboard'da).
- **Gerçek veri:** progress.ts +loadCounters/incrementExamsFinished (ea:counters:v1) +loadViewedLessons/markLessonViewed (ea:lessonsViewed:v1). ExamSimulator finish→incrementExamsFinished; `components/LessonViewTracker.tsx` (lesson page). authClient SYNC_KEYS + api/state ALLOWED_KEYS bu iki key eklendi. Sidebar +İlerleme(XP).
- **e2e `gamification.spec.ts`** (3: ilerleme panosu, panel nudge, davet kopyala). Panel testinde nudge storageState fresh veriyle görünür.
- **3 belge:** SPRINT_6_REPORT.md, VISUAL_TRANSFORMATION_ROADMAP.md (subagent, 367 satır, 7 bölüm — asset YOK), FINAL_PLATFORM_AUDIT.md (Kritik 0 / Yüksek: DATABASE_URL, tahsilat/e-posta ENV, ilk yardım uzman onayı, yasal hukukçu / Orta / Düşük).
- **Canlı doğrulandı:** /ilerleme gerçek veriyle (Seviye 2, 165 XP, Bronz, ısı haritası bugün dolu), 0 konsol.

## SPRINT 5 — AI platformu, analitik, gözlemlenebilirlik, güvenlik, performans

- **AI (ADR-010):** `lib/server/ai.ts` (answerGrounded: retrieve→halüsinasyon kapısı→MockModel/AnthropicModel→fallback; SYSTEM_PROMPT; aiConfigured=ANTHROPIC_API_KEY). `/api/ai/ask` (rate-limited, no DB). `lib/server/ai-eval.ts` (AI_EVAL_CASES + runEval; test %100). `lib/ai.ts` retrieve YENİDEN yazıldı: önek-duyarlı token eşleşme (scoreTokens, startsWith her iki yön, min 3) + genişletilmiş STOPWORDS (kadar/zaman/kim/…). AICoach send() → fetch /api/ai/ask (yerel mock fallback) + coach-action-readiness (examReadinessAnalysis/formatReadinessAnalysis, study.ts'e eklendi).
- **Analitik (ADR-011):** `lib/analytics.ts` genişletildi (event union + enabledProviders(consent,cfg) saf/testli + ProviderSink + analyticsConfig). `components/AnalyticsLoader.tsx` (root layout; rıza+ENV varsa GA4/Clarity/PostHog yükler). ENV yok → no-op.
- **Gözlemlenebilirlik:** `app/api/health/route.ts` (GET, DB'ye dokunmaz). `lib/server/observability.ts` (captureException/Message, Sentry-hazır). `instrumentation.ts` (register→logEnvChecks). `lib/server/env-check.ts` (checkEnv saf/testli).
- **Güvenlik:** `next.config.ts` buildCsp() (SSG statik CSP; analitik domainleri yalnız ENV'le; 'unsafe-inline' bilinçli) + tam header seti (HSTS/X-Frame DENY/nosniff/Referrer/Permissions). `middleware.ts` (CSRF same-origin, matcher /api/:path*, webhook muaf, mutating metodlar). `SECURITY_REVIEW.md` (OWASP Top 10).
- **Performans:** PremiumLessonGate → `dynamic(() => import(PurchaseDialog), {ssr:false})`. `app/(app)/loading.tsx` streaming iskeleti. next.config /icon.svg cache header.
- **e2e:** `security.spec.ts` (4: güvenlik başlıkları/CSP, /api/health, CSRF çapraz-origin 403, grounded AI + readiness aksiyonu).
- **Canlı doğrulandı:** CSP+başlıklar (curl), /api/health 200, /api/ai/ask grounded, CSRF 403, /ai-koc grounded yanıt 0 konsol/CSP hatası.

## SPRINT 4 — Ticaret, yasal & üretim servisleri

- **Ödeme (ADR-008 LemonSqueezy MoR):** `lib/server/checkout.ts` (PaymentGateway/MockGateway/LemonSqueezyGateway/validateReceipt/variantForProduct); `/api/checkout` + `/api/webhooks/lemonsqueezy` (HAM gövde HMAC + parseOrder order_created + idempotent external_ref + confirmation email). Client `lib/checkoutClient.ts` startCheckout (mock→serverPurchase / 401|503→local grant / redirect→url). ENV: LEMONSQUEEZY_API_KEY/STORE_ID/WEBHOOK_SECRET/VARIANT_<PRODUCT>.
- **E-posta (ADR-009 Resend):** `lib/server/email.ts` (EmailProvider/Console/Resend + welcomeEmail/verificationEmail/passwordResetEmail/purchaseConfirmationEmail/supportRequestEmail; escapeHtml). Bağlı: register (welcome+verify), forgot (reset link), `/api/auth/verify` (+`/dogrula`), `/sifirla`, `/api/support`. ENV: RESEND_API_KEY/EMAIL_FROM/SUPPORT_EMAIL.
- **Şema (bootstrap ALTER/CREATE IF NOT EXISTS):** users.email_verified, purchases.external_ref, email_verification_tokens tablosu.
- **Yasal:** `app/(marketing)/{gizlilik,kullanim-kosullari,cerez-politikasi,kvkk}/page.tsx` (server, taslak+yer-tutucu). `components/CookieConsent.tsx` (CONSENT_KEY=ea:consent, root layout'ta) + Ayarlar rıza yönetimi. `DELETE /api/account` (cascade). Footer legal linkleri.
- **Üretim:** `lib/server/logger.ts` (JSON+redact), `lib/server/rate-limit.ts` (rateLimit saf + checkRateLimit; NODE_ENV=test||RATE_LIMIT_DISABLED=1 bypass), `lib/retry.ts` (withRetry). `app/error.tsx`, `app/not-found.tsx`.
- **Premium:** `Lesson.premium` (schema), `lib/entitlements.ts` (canAccessLesson/requiredCapability/productForLesson; LESSON_CAPABILITY map), `PremiumBadge`/`PremiumLessonGate`/`PurchaseDialog`. Premium dersler: park-manevra, kavsak-uygulama, sollama-serit. İlk yardım/güvenlik ASLA premium.
- **e2e:** `playwright.config.ts` storageState=./e2e/storage-state.json (ea:consent seed) + env RATE_LIMIT_DISABLED=1. `commerce.spec.ts` (5). Mobil drawer testi scrim'e SAĞDAN tıklar (position x:350).
- **Canlı doğrulandı:** /dersler/park-manevra premium kilit→demo satın al→açıldı; çerez bannerı; /kvkk taslak; /api/checkout & /api/account 401.

## SPRINT 3 — İçerik & öğrenme deneyimi

- **Soru bankası 198 özgün soru** (trafik 63/ilkyardim 42/motor 39/adab 26/pratik 28; 82 konu). Dosyalar: `packages/question-bank/src/questions-{trafik,ilkyardim,motor,adab,pratik}.ts` (yeni id namespace -101+). index.ts: RAW→`parseQuestion` map (yüklemede Zod parse). Gate: ≥150 soru + ≥140 zenginleştirilmiş.
- **19 ders**: `content/lessons.ts` (çekirdek 5, zenginleştirildi) + `theory-lessons.ts` (THEORY_EXTRA_LESSONS, no 6-14) + `driving-lessons.ts` (DRIVING_LESSONS, no 15-19). `LESSONS = [...].map(parseLesson).sort(no)`.
- **Şema:** Question +whyWrong/objective/tags; Lesson +memoryTips/examStrategy/keyTakeaways/reviewCards/practiceQuestionIds/figureId + ReviewCard. **QuestionInput/LessonInput** (z.input) yazım tipleri — kaynak dosyalar bu tiple, parse çıktı tipini (defaults dolu) verir.
- **AI/çalışma zekâsı:** `lib/study.ts` (weakTopics/buildStudyPlan/personalizedReview/explainWrongAnswer/nextStudySuggestion/formatWeakTopics/formatStudyPlan) — grounded, saf, testli (`study.test.ts`). AICoach.tsx: coach-action-{plan,weak,review} + ?soru= prefill. Yeni sayfa `/calisma-plani` (data-testid=study-plan/plan-steps) + `MasteryRadar.tsx` (4 eksen SVG).
- **Görseller:** `LessonFigure.tsx` figureId ile 12 SVG. `LessonPractice.tsx` (client): review-card flip + practice-q anında geri bildirim. Sidebar'a "Çalışma Planım" (İlerleme grubu).
- **Analytics:** `ai_question_asked` props +`action?`.
- **Canlı doğrulandı:** /dersler/hiz-takip (görsel+özet+kart+alıştırma grounded), /calisma-plani (radar+adımlar), /ai-koc (kişisel plan).

## SPRINT 2 — CMS/Admin/İçerik hattı/Medya/Arama

- **CMS (ADR-007):** şema-öncelikli özel çekirdek (Payload'a açık kapı). `packages/db/src/cms.ts` = content_items/content_versions/media_assets/audit_logs (JSONB payload, Zod doğrulama). Türler: lesson/question/article/seo_page/kb; `locale`+`licence` kolonları (gelecekteki sınıflar).
- **İçerik hattı:** `@ea/content-schema` WORKFLOW state machine `draft→in_review→approved→published→retired` + `canTransition`/`validatePayload`. `lib/server/cms.ts` = createContent/updateContent(sürüm+1)/transitionContent(sunucuda zorlar + audit + arama kancası)/list/get/listPublished/upload/list/getMedia/listUsers/setUserRole/listAudit/adminStats.
- **RBAC:** `users.role` user/editor/admin; `requireRole()` (401/403); rol bootstrap `api/auth/register` (ADMIN_EMAILS → ADMIN_EMAIL_PATTERN regex → yönetici-yoksa-ilk-kullanıcı-admin); öz-adminlik düşürme kilidi.
- **Admin UI:** `app/(app)/admin/*` (layout client-guard `admin-denied` + 6 sayfa) **aynı SaaS kabuğunda**; Sidebar `isAdmin`→Yönetim linki. API: `app/api/admin/{content,content/[id],media,users,audit,stats}` + `app/api/media/[id]` (hepsi `guarded()`+`requireRole`).
- **Medya:** base64 DB'de (2MB cap; svg/png/jpeg/webp/lottie), servis `/api/media/[id]` (immutable cache). Blob/S3 adaptör kapısı.
- **Arama:** `lib/search.ts` SearchProvider arayüzü + LocalSearchProvider (TR-normalize, published registry); `getSearchProvider()` + `SEARCH_PROVIDER` env → Meili/Typesense/Algolia takılır. `/arama` yeniden yazıldı (`data-testid=search-results/search-empty`).
- **ENV yeni:** `ADMIN_EMAILS`, `ADMIN_EMAIL_PATTERN` (e2e: `^admin-e2e-` playwright webServer'da), `SEARCH_PROVIDER`.
- **Canlı doğrulandı:** /arama sonuç veriyor · /admin misafirde admin-denied · /api/admin/content oturumsuz 401.

## SPRINT 1

- **@ea/db**: users/sessions/password_reset_tokens/user_state/purchases; getDb() çift sürücü; `webpackIgnore` native-import (PGlite ESM bundling fix); testte memory://, devde .pglite/.
- **Auth**: lib/server/auth.ts (scrypt, token-hash oturum, guarded() 503); api/auth/* + api/state + api/purchases; lib/authClient.ts (syncSet/fullSync/restore/serverPurchase).
- **Playwright prod-build'e koşuyor** (webServer: build && start).
- **Prod DATABASE_URL bekleniyor** — Neon şartlar linki SPRINT_1_REPORT.md'de; kabul→`vercel integration add neon`→redeploy.

## Önceki tur

- **(app)/(marketing) route grupları** — uygulama kalıcı SOL SIDEBAR kabuğunda (components/Sidebar.tsx); /panel dashboard (components/Dashboard.tsx).
- AI Koç mock/grounded: lib/ai.ts (retrieval, testli) + /ai-koc. Analitik: lib/analytics.ts (tipli olaylar). Başarılar: lib/achievements.ts + /basarilar. Arama: /arama. Ayarlar/tema: /ayarlar (ea:theme, FOUC-safe kök script).
- Vitest alias: '@' → apps/web kökü (vitest.config.ts).

## Tamamlanan fazlar

0–4 ✅ · 5–8 ✅ · **9–16, 18, 20(çekirdek), 21 ✅** · **24 CMS · 25 Admin · 28 Arama ✅ (Sprint 2)** · 26/27 auth-DB ✅ (Sprint 1) · 34 streak çekirdeği ✅.
**Kalan:** 17 (ASO), 19 (sınıf genişleme — altyapı hazır), 22 (gerçek AI), 23 (gerçek analitik), gerçek tahsilat, 30 (güvenlik sertleştirme), 31 (gözlemlenebilirlik), 32/33 (topluluk), 35 (platform zekâsı).

## Mimari hatırlatmalar

- Banka **53 özgün soru** → tam sınav dağılımı (23/12/9/6); test kapısı `question-bank/index.test.ts`.
- SRS: `@ea/srs-engine` (SM-2) + `apps/web/lib/progress.ts` (kart/cevap/seri localStorage).
- Ödeme/entitlement: `apps/web/lib/{products,payments}.ts` — kota: günde 1 deneme; `sinirsiz-deneme` yeteneği → sınırsız.
- SW: `public/sw.js` (yalnız prod'da kayıt). JSON-LD: `components/JsonLd.tsx`.
- Vercel token: CLI keyring (`~/.local/share/com.vercel.cli/auth.json`) — proje ayarı API ile PATCH edildi.

## Komutlar

`pnpm gates` · `pnpm --filter @ea/web e2e` · deploy: yukarıda · CI izleme: `gh run watch $(gh run list --workflow CI --branch main --limit 1 --json databaseId -q '.[0].databaseId')`

## Son durum

- **Testler:** 164 unit/integration (129 web + 35 paket) + 44 e2e ✅ · build 30 sayfa + 22 API rotası ✅ · CI ✅ · CodeQL ✅ · **prod tarayıcı doğrulaması ✅** (konsol/CSP 0 hata).
- **İçerik:** 198 soru (82 konu) + 19 ders (Sprint 3). Tümü review:draft (uzman onayı bekliyor, özellikle ilk yardım).
- **DUR:** Sprint 6 SON planlı uygulama sprintiydi. Yeni uygulama sprinti direktif olmadan başlatılmaz (görsel dönüşüm = ayrı yol haritası).
- **Kalan dış aksiyonlar (ENV):** DATABASE_URL (Neon), LEMONSQUEEZY_* (tahsilat), RESEND_API_KEY (e-posta), ANTHROPIC_API_KEY (gerçek AI), NEXT_PUBLIC_GA_ID/CLARITY_ID/POSTHOG_KEY (analitik), SENTRY_DSN (izleme), yasal metin hukukçu onayı. Kod hazır; hepsi ENV ile aktifleşir.
- Dependabot 9 PR bekliyor (major bump'lar) — hijyen turu.
