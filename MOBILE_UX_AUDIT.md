# Mobile UX Audit

**Ehliyet Akademi · Every screen, translated to mobile**
_Prepared: 2026-07-23 · Planning document. Parent: `MOBILE_APP_MASTERPLAN.md`._

The principle throughout: **preserve the web identity, re-express it natively.** Same tokens, cards,
colors, motion — but bottom-tab navigation, gestures, native transitions, offline states.

---

## 1. Navigation model

The web uses a persistent sidebar with grouped nav (Öğren / Pratik / İlerleme / Hesap). Mobile
collapses this into **5 bottom tabs**, each an independent navigation stack (state preserved per
tab), with the AI Coach as a persistent, reachable presence.

| Bottom tab    | Icon   | Root screen          | Contains (stack)                                                                                               |
| ------------- | ------ | -------------------- | -------------------------------------------------------------------------------------------------------------- |
| **Ana Sayfa** | home   | Dashboard (`/panel`) | readiness, daily plan, quick actions, streak, AI nudge                                                         |
| **Öğren**     | layers | Learn hub            | Lessons, Traffic signs, Vehicle, Videos, lesson/sign/part detail                                               |
| **Pratik**    | target | Practice hub         | Smart practice, Theory exam, Dynamic exam, Collections, Historical formats, Visual quiz, Scenarios, Diagnostic |
| **AI Koç**    | bot    | AI Coach chat        | proactive cards, chat, recommendations, quota                                                                  |
| **Profil**    | user   | Profile/Progress     | Progress(XP), Readiness, Study plan, Achievements, Search, Settings, Premium                                   |

- **Global entry points that float above tabs:** the AI Coach is also surfaced as (a) the tab, (b) a
  home nudge card, and (c) contextual bubbles after activities (see `AI_MOBILE_BEHAVIOR.md`).
- **Admin, CMS, SEO, media, legal, marketing:** **not in the app** — admins use the responsive web
  panel; legal links open a WebView/browser. Keeps the app focused on the learner.
- **Deep links / push targets:** every screen gets a deep link (`ehliyetakademi://pratik/deneme`,
  push → screen) so notifications and the AI can route users precisely.

### Gestures & transitions

- Native stack push/pop with iOS edge-swipe back + Android predictive back.
- Tab switch: no animation (instant) or subtle fade; per-tab scroll position preserved.
- Practice/exam question cards: swipe or tap to advance; long-press to flag/report (reuses
  `ReportQuestion`). Pull-to-refresh on lists (collections, historical, progress).
- Sign/vehicle galleries: horizontal paging + pinch-zoom on the SVG/photo.
- Haptics: light tick on answer select, success/heavy on exam pass, selection on tab change.

---

## 2. Onboarding (new — premium first-run)

Goal: within ~60 seconds the user understands the product, feels the polish, and personalizes. 5–6
swipeable screens with the brand teal, large illustrations (reuse `public/assets/art`), and the
`--ease-out` motion. Skippable but with a persuasive default.

1. **Hoş geldin** — brand, one-line promise ("Ehliyet sınavına en akıllı hazırlık"), animated logo.
2. **AI Koç tanıtımı** — the AI is your coach: shows a sample proactive card + chat.
3. **Öğren & Sınav** — lessons + real MEB-format exams + 1500+ original questions + traffic signs.
4. **İlerleme** — readiness ring, streak, weak-topic focus — "we adapt to you".
5. **Kişiselleştirme** — pick target exam date + current level → seeds adaptive learning + study
   plan + notification cadence. (The one screen that captures data.)
6. **Premium (soft)** — what premium unlocks (honest: unlimited AI, unlimited exams) → "start free".

End state: auth (register/login, or continue as guest with local progress), notification permission
primed contextually (not a cold prompt), first home render with a personalized AI welcome.

---

## 3. Home experience (the app's center)

Keep the dashboard philosophy; make it interactive and glanceable. Vertical scroll of live cards:

1. **Header:** greeting + streak flame + avatar; theme/notification in a compact top bar.
2. **Readiness ring** (from `hazirlik-skorum` / readiness): animated circular progress + traffic-light
   color; tap → readiness detail.
3. **AI Coach nudge** (proactive): today's single most useful action (weak topic, streak protect,
   exam countdown). Tap → the action. (See `AI_MOBILE_BEHAVIOR.md`.)
4. **Bugünkü plan** (study plan): 2–3 tasks (practice N, review due cards, 1 exam) with progress.
5. **Quick actions** grid: Deneme çöz · Akıllı çalış · Zayıf konu · İşaretler (reuses feature-icons).
6. **Devam et:** resume the last lesson/exam.
7. **Gündem:** new practice exam / collection of the day / achievement just unlocked.

All cards use existing card styling, spacing (`--sp`), radius 16, motion. Skeleton loaders on first
paint; offline banner if content is cached-only.

---

## 4. Screen-by-screen audit

Legend — **Reuse**: logic/API reused; **Pattern**: native pattern; **Offline**: behavior without net.

### Öğren

| Web screen                    | Mobile behavior                                                           | Pattern                                                        | Offline                     |
| ----------------------------- | ------------------------------------------------------------------------- | -------------------------------------------------------------- | --------------------------- |
| `/panel` Dashboard            | Home tab (see §3)                                                         | scroll of live cards                                           | cached snapshot             |
| `/dersler`, `/dersler/[slug]` | Lesson list → detail with sections, figures, callouts, review cards, quiz | list → reader; sticky progress; "mark viewed"                  | fully offline (bundled)     |
| `/isaretler`, `/[id]`         | Sign gallery (121 SVG) by category; detail with meaning/memory tip/flip   | grid + filter chips + search; pager + pinch-zoom               | fully offline (SVG)         |
| `/arac`, `/[id]`              | Vehicle systems + parts (photos)                                          | grouped list → part detail                                     | offline (photos cached)     |
| `/videolar`                   | 8 videos                                                                  | list → native/embedded player; download-for-offline (premium?) | stream only (or downloaded) |

### Pratik

| Web screen                    | Mobile behavior                                                                            | Pattern                                             | Offline                                  |
| ----------------------------- | ------------------------------------------------------------------------------------------ | --------------------------------------------------- | ---------------------------------------- |
| `/calis` Smart practice (SRS) | Card-by-card practice; grade recall; streak                                                | swipeable question cards; instant feedback; haptics | **fully offline** (local SRS)            |
| `/e-sinav`, `/deneme-sinavi`  | Timed 50-Q MEB exam; results + per-subject                                                 | full-screen exam runner; timer; review; report      | offline (generate locally from snapshot) |
| `/koleksiyonlar`              | 10 auto collections                                                                        | list w/ counts → exam/preview                       | offline                                  |
| `/cikmis-sinavlar`, `/[id]`   | Browse sessions by year → original MEB-format practice; **"özgün deneme" label prominent** | year list → session → exam/review                   | offline                                  |
| `/gorsel-quiz`                | Identify sign/part visual quiz                                                             | image-first cards                                   | offline                                  |
| `/senaryolar`                 | Interactive driving scenarios (SceneCanvas)                                                | step-by-step decisions; animated scene              | offline (canvas)                         |
| `/tani` Diagnostic            | Placement test → weak map                                                                  | guided; feeds adaptive                              | offline                                  |

### AI Koç

| Web screen | Mobile behavior                                             | Pattern                                           | Offline                                                    |
| ---------- | ----------------------------------------------------------- | ------------------------------------------------- | ---------------------------------------------------------- |
| `/ai-koc`  | Chat + proactive cards; copy/regenerate; quota; persistence | chat UI + suggestion chips; proactive card stream | chat needs net; cached history + offline "ask later" queue |

### Profil / İlerleme

| Web screen                   | Mobile behavior                                  | Pattern                                               | Offline                 |
| ---------------------------- | ------------------------------------------------ | ----------------------------------------------------- | ----------------------- |
| `/ilerleme` XP/Progress      | XP, level, heatmap (StudyHeatmap), stats         | scroll; animated counters                             | cached                  |
| `/hazirlik-skorum` Readiness | Radar (MasteryRadar) + traffic light per subject | interactive radar                                     | cached                  |
| `/calisma-plani` Study plan  | Daily/weekly plan; adaptive                      | checklist; reschedule                                 | cached                  |
| `/basarilar` Achievements    | Badges/tiers                                     | grid; unlock animation                                | cached                  |
| `/arama` Search              | Search lessons/questions/signs                   | search field + results                                | offline index (bundled) |
| `/ayarlar`, `/profil`        | Settings + avatar (crop/upload)                  | native forms; image picker + crop; theme; notif prefs | local + sync            |
| `/fiyatlandirma` Premium     | Plans + benefits                                 | **native IAP** paywall (StoreKit/Play)                | needs net               |

### Auth & system

| Web                                 | Mobile                                                      |
| ----------------------------------- | ----------------------------------------------------------- |
| `/giris` login/register             | native auth screen; token flow; biometric unlock (optional) |
| `/dogrula` verify, `/sifirla` reset | deep-link from email; in-app handling                       |
| Legal (KVKK/gizlilik/…)             | in-app WebView / external browser                           |

---

## 5. Component parity (web → Flutter)

Every web primitive gets a named native equivalent sharing tokens (spacing/radius/elevation/motion):

| Web (`components/ui`)              | Flutter equivalent                      | Notes                                |
| ---------------------------------- | --------------------------------------- | ------------------------------------ |
| Card                               | `AppCard`                               | radius 16, surface, subtle elevation |
| PageHeader (emoji+title+subtitle)  | `AppPageHeader`                         | reuse emoji + type scale             |
| Callout (info/success/warn/danger) | `AppCallout`                            | tone → accent color                  |
| CompareTable                       | `AppCompareTable`                       | scrollable                           |
| EmptyState                         | `AppEmptyState`                         | illustration + CTA                   |
| quiz (QuizPanel, InfoRow)          | `QuizCard`, `InfoRow`                   | answer states, explanation reveal    |
| PremiumBadge / PremiumLessonGate   | `PremiumBadge` / `PremiumGate`          | lock overlay + upsell                |
| MasteryRadar                       | `MasteryRadar` (CustomPainter/fl_chart) | readiness radar                      |
| StudyHeatmap                       | `StudyHeatmap` (grid painter)           | activity heatmap                     |
| icons.tsx (icon set)               | `AppIcons` (SVG/icon font)              | same glyphs                          |
| ReportQuestion                     | `ReportSheet` (bottom sheet)            | reuses `/api/qip/report`             |
| AICoach                            | `CoachChat` + `CoachCard`               | chat + proactive                     |
| Sidebar/TopBar                     | Bottom nav + `AppBar`                   | nav re-expressed                     |

---

## 6. Cross-cutting states

- **Loading:** skeletons matching card shapes (never spinners on content); shimmer with brand tint.
- **Empty:** friendly EmptyState with illustration + one CTA (e.g., "İlk denemeni çöz").
- **Error:** inline, retryable, calm; never a raw error; offline → "çevrimdışısın, kayıtlı içerik".
- **Offline:** a slim persistent banner when offline; disable net-only actions (AI chat, IAP,
  purchase) with clear messaging; practice/exams/lessons keep working from the snapshot; answers
  queue and sync on reconnect.
- **Optimistic UI:** answer logs, XP, streak update instantly and reconcile with server on sync.

---

## 7. Accessibility

- Dynamic type support (scale the type scale); minimum 44×44 touch targets; semantic labels on all
  interactive elements; sufficient contrast in both themes (audit the amber/teal on surfaces);
  reduced-motion honoring (`--dur` → 0); screen-reader order; focus management on route change; the
  existing "skip to content" concept maps to logical reading order.

## 8. Tablet

- Two-pane where it helps: Öğren (list + detail), Pratik (list + runner). Home stays single-column,
  wider cards. Reuse Flutter `LayoutBuilder`/`MediaQuery` breakpoints mirroring the web's shell
  behavior. Not a v1 blocker, but design components pane-aware from the start.

## 9. Performance

- 60fps target: const widgets, list virtualization, image caching, SVG rasterization cache, lazy
  content load, precomputed QIP snapshots (don't recompute the graph on device — fetch/derive
  lightweight views). Cold start < 2s to interactive home (cached).

---

This audit + the navigation map is the blueprint for the Flutter screen tree in
`APP_ARCHITECTURE_PLAN.md` and the build order in `MOBILE_FEATURE_ROADMAP.md`.
