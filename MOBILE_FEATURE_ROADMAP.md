# Mobile Feature Roadmap

**Ehliyet Akademi · Phased implementation plan**
_Prepared: 2026-07-23 · Planning document. Parent: `MOBILE_APP_MASTERPLAN.md`._

Eight phases, each **independently testable** and shipping value. Complexity is relative (S/M/L/XL).
Do **Phase 0 first** — it's backend work that benefits the web too and unblocks every client path.
No client code until Phase 0 contracts + the strategic decisions (`APP_ARCHITECTURE_PLAN.md` §12) are
approved.

Legend — **Cx**: complexity · **Dep**: depends on · **Pri**: priority.

---

## Phase 0 — Foundations (BFF API + contracts) · Cx: L · Pri: P0

Backend-only. The reusable asset for both Flutter and Capacitor.

| Item                                                                    | Cx  | Notes                                           |
| ----------------------------------------------------------------------- | --- | ----------------------------------------------- |
| Token auth mode (JWT access + rotating refresh) on existing auth routes | M   | Bearer accepted everywhere; reuse session table |
| `design-tokens.json` export from `globals.css`                          | S   | one source of truth for both platforms          |
| Content snapshot API (`/api/content/manifest` + `/bundle`)              | M   | versioned + hashed; delta-capable               |
| Exam-build API (`POST /api/exams/dynamic`) wrapping `buildDynamicExam`  | S   | historical/collections already exist            |
| Coach nudges API (`/api/coach/nudges`, `/ack`) — deterministic engine   | M   | reuses weakTopics/readiness/analytics           |
| IAP validation endpoint (`/api/iap/validate`)                           | M   | Apple/Google verification → `purchases`         |
| Push token registration (`/api/push/token`)                             | S   |                                                 |
| OpenAPI spec + contract tests                                           | M   | shared contract                                 |

- **Dep:** none. **Risk:** auth-token security, IAP verification correctness. **Testable:** API
  integration tests (mirror the web's harness). **Outcome:** a clean, documented mobile API + tokens
  - the AI nudge engine, all reusing existing logic. **The web gains a real API too.**

---

## Phase 1 — App shell · Cx: L · Pri: P0

| Item                                                                                                                | Cx  | Notes                             |
| ------------------------------------------------------------------------------------------------------------------- | --- | --------------------------------- |
| Flutter project, flavors, CI (Codemagic/Fastlane)                                                                   | M   | `apps/mobile` in monorepo         |
| `AppTheme` from tokens (light+dark) + design parity primitives (AppCard, PageHeader, Callout, EmptyState, QuizCard) | L   | golden tests lock parity          |
| `go_router` + 5 bottom tabs + per-tab stacks + deep links                                                           | M   | nav map from `MOBILE_UX_AUDIT.md` |
| Auth flow (login/register/guest) + secure token storage + refresh                                                   | M   | biometric optional                |
| Home skeleton (static cards, real readiness/streak from API)                                                        | M   | the app's center                  |
| Local DB (Drift) scaffold + content snapshot download                                                               | M   | offline foundation                |

- **Dep:** Phase 0. **Risk:** design drift (mitigated by tokens+golden). **Testable:** widget/golden +
  auth integration. **Outcome:** installable app that logs in, shows a themed home, navigates — feels
  like the product.

---

## Phase 2 — Learn · Cx: M · Pri: P1

| Item                                                              | Cx  | Notes                      |
| ----------------------------------------------------------------- | --- | -------------------------- |
| Lessons list + reader (sections, callouts, figures, review cards) | M   | offline from snapshot      |
| Traffic signs gallery + detail (121 SVG via flutter_svg)          | M   | filter/search, pinch-zoom  |
| Vehicle systems + parts (photos)                                  | S   |                            |
| Videos                                                            | S   | player + optional download |
| Search (offline index)                                            | S   |                            |

- **Dep:** Phase 1 + content snapshot. **Risk:** SVG rendering fidelity. **Testable:** widget +
  offline read. **Outcome:** full learning content, offline.

---

## Phase 3 — Practice & Exams · Cx: XL · Pri: P1

The core value. Offline-first.

| Item                                                                            | Cx  | Notes                         |
| ------------------------------------------------------------------------------- | --- | ----------------------------- |
| SRS ported to Dart + smart practice (`/calis`) card runner                      | L   | offline; grades → sync queue  |
| Exam runner (timer, 50-Q MEB, results, per-subject, review)                     | L   | `/e-sinav`, `/deneme-sinavi`  |
| Dynamic exam / Collections / Historical formats (with the "özgün deneme" label) | M   | deterministic seeds → offline |
| Visual quiz + Scenarios (SceneCanvas port)                                      | M   |                               |
| Diagnostic (`/tani`) → feeds adaptive                                           | S   |                               |
| Answer-sync queue + optimistic XP/streak                                        | M   | reconciles with `/api/state`  |

- **Dep:** Phase 2, ported SRS, sync. **Risk:** offline correctness, sync conflicts (last-write-wins),
  exam-timer edge cases. **Testable:** integration (practice→exam→sync), deterministic-seed golden.
  **Outcome:** the whole practice/exam experience, offline, synced.

---

## Phase 4 — AI Coach & Notifications · Cx: L · Pri: P1 (the differentiator)

| Item                                                                | Cx  | Notes                             |
| ------------------------------------------------------------------- | --- | --------------------------------- |
| Chat (reuse `/api/ai/ask`) + context-aware "Açıkla"                 | M   | grounded, copy/regenerate/persist |
| Proactive nudge cards (home + coach inbox) from `/api/coach/nudges` | M   | deterministic                     |
| FCM push + `flutter_local_notifications` + permission flow          | L   | categories, quiet hours, caps     |
| Celebrations (achievement/exam-pass) + haptics + Lottie             | S   |                                   |

- **Dep:** Phase 0 nudge engine, Phase 3 (activity data). **Risk:** push fatigue, iOS APNs setup, AI
  cost. **Testable:** nudge-engine unit tests (deterministic), notification scheduling tests.
  **Outcome:** a proactive, alive coach — the premium feel (`AI_MOBILE_BEHAVIOR.md`).

---

## Phase 5 — Progress & Gamification · Cx: M · Pri: P2

| Item                                           | Cx  | Notes                          |
| ---------------------------------------------- | --- | ------------------------------ |
| Readiness radar (MasteryRadar) + traffic light | M   | `/hazirlik-skorum`             |
| XP/level + heatmap (StudyHeatmap) + counters   | M   | `/ilerleme`                    |
| Study plan (adaptive) + achievements/tiers     | M   | `/calisma-plani`, `/basarilar` |
| Analytics views                                | S   | reuse summary API              |

- **Dep:** Phase 3 data. **Risk:** low. **Testable:** widget + data. **Outcome:** the motivational
  progress layer.

---

## Phase 6 — Premium (native IAP) · Cx: L · Pri: P1 (revenue)

| Item                                                  | Cx  | Notes                             |
| ----------------------------------------------------- | --- | --------------------------------- |
| `in_app_purchase` (StoreKit/Play) + store products    | L   | one Komple B entitlement          |
| Purchase → `/api/iap/validate` → entitlement sync     | M   | server = truth; restore purchases |
| Native paywall + honest upsell surfaces + PremiumGate | M   | mirrors `/fiyatlandirma`          |
| Quota gating (free AI 5/day, exams) parity            | S   | reuse `payments.ts` rules         |

- **Dep:** Phase 0 IAP endpoint, store accounts. **Risk:** **store review + billing rules**, margin
  after cut, cross-platform entitlement. **Testable:** sandbox IAP integration. **Outcome:** compliant
  in-app premium.

---

## Phase 7 — Onboarding, Polish & Launch · Cx: L · Pri: P0-for-launch

| Item                                                                          | Cx  | Notes                       |
| ----------------------------------------------------------------------------- | --- | --------------------------- |
| Premium onboarding (5–6 screens, personalization → adaptive)                  | M   | `MOBILE_UX_AUDIT.md` §2     |
| Animation/haptics pass (micro-interactions, reveal, counters)                 | M   | flutter_animate/Lottie/Rive |
| Accessibility (dynamic type, labels, contrast, reduced-motion)                | M   |                             |
| Tablet two-pane                                                               | M   | optional-but-designed-for   |
| Offline hardening + error/empty/loading states everywhere                     | M   |                             |
| Store assets, listings, privacy, beta (TestFlight/Play internal) → production | M   |                             |

- **Dep:** all prior. **Risk:** review timelines, a11y gaps. **Testable:** full integration + manual
  device matrix. **Outcome:** a shippable, premium app.

---

## Dependency & order summary

```
Phase 0 ─┬─► Phase 1 ─► Phase 2 ─► Phase 3 ─┬─► Phase 4
         │                                   ├─► Phase 5
         └─────────────────────────────────► Phase 6 (needs Phase 0 IAP)
                                                   Phase 7 (needs all)
```

- **Critical path to a usable beta:** 0 → 1 → 2 → 3 (offline practice/exams) → 7-lite (onboarding +
  store) — a genuinely valuable app even before AI/premium.
- **Critical path to revenue:** + Phase 6.
- **Critical path to the premium differentiator:** + Phase 4.

## Priority recommendation

1. **P0 now:** Phase 0 (do regardless of client choice) + decide client strategy.
2. **First release (MVP):** Phases 1–3 + minimal 7 → offline learn/practice/exam app that _feels_ like
   Ehliyet Akademi.
3. **Fast-follow:** Phase 4 (AI/notifications — the hook) + Phase 6 (IAP — the revenue).
4. **Then:** Phase 5 depth + Phase 7 full polish + tablet.

## Risk register (rolled up)

| Risk                                    | Phase | Mitigation                                      |
| --------------------------------------- | ----- | ----------------------------------------------- |
| IAP/billing compliance                  | 6     | native IAP + server validation; model margin    |
| Offline sync correctness                | 3     | deterministic seeds, sync queue, LWW, tests     |
| Design drift web↔mobile                 | 1     | shared tokens + golden tests                    |
| Logic duplication                       | 0     | BFF reuse, port only SRS                        |
| Push fatigue / iOS APNs                 | 4     | caps, quiet hours, opt-in; proper APNs setup    |
| Token/security                          | 0/7   | secure storage, refresh rotation, biometric     |
| Store review (Capacitor "thin wrapper") | 6/7   | real native value (push/IAP/offline/onboarding) |
| Scope creep (admin on mobile)           | all   | admin stays web                                 |

---

**This roadmap, with the four companion documents, is the complete foundation for the mobile build.**
Nothing is implemented; the next step is a decision meeting on `APP_ARCHITECTURE_PLAN.md` §12, then
Phase 0.
