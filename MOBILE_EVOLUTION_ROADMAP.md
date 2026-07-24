# Mobile Evolution Roadmap (permanent)

**Ehliyet Akademi · Flutter mobile app — the permanent roadmap for the post-launch EVOLUTION program
(Content · Social · Experience).**

_Created: 2026-07-25 · This is NOT a new project. The 9-phase build program
(`MOBILE_APP_IMPLEMENTATION_ROADMAP.md`) and the UI Redesign & Monetization sprint are COMPLETE and
shipped. Every architectural decision made there is preserved. Read order before every phase:_

1. `MOBILE_ENGINEERING_DISCIPLINE.md` (execution rules — unchanged, still binding)
2. `MOBILE_PROJECT_MEMORY.md` (append-only engineering memory)
3. **this file** (the evolution phase plan + DoD)

---

## 1. Executive summary

The app is live-quality: offline-first, dark-first, single-product premium (Komple Ehliyet Paketi
399 ₺), CI-green, device-validated. This program evolves it along three axes:

- **Content authenticity** — replace procedurally-drawn signs with faithful vector recreations of the
  **official KGM standard sign sheet**, and turn text-only mechanical pages into a rich visual library.
- **Reach** — expand from B-only to **B · A · D** licence categories, with the selected licence driving
  the whole learning experience.
- **Social & experience** — a real community platform, a redesigned onboarding + welcome experience,
  and a premium video-learning experience.

**13 phases**, executed strictly one at a time under the existing Definition of Done. No architecture
is replaced: Riverpod · go_router · dio · drift · freezed · Next.js/Drizzle backend, offline-first,
tokens→ThemeData, additive backward-compatible API changes only.

## 2. Baseline (measured 2026-07-25, at commit `165a35f`)

| Signal                | Value                                                                        |
| --------------------- | ---------------------------------------------------------------------------- |
| `flutter analyze`     | **0 issues**                                                                 |
| `flutter test`        | **85 passing**                                                               |
| Web tests             | **336 passing** · `typecheck` 0                                              |
| CI                    | Web CI · Mobile CI · CodeQL — all green at HEAD                              |
| Device                | `AYXSUKIVJVPZ7HPZ` (Redmi M1908C3JGG, Android 11 / API 30) — connected       |
| Toolchain             | Flutter 3.41.9 · Dart 3.11.5 · Java 17 · Android SDK 36.1.0                  |
| Content               | 19 lessons · 121 signs · 70 vehicle parts · 6 videos (2 available) · 1562 Qs |
| Mobile bundled assets | 1.6 MB (21 WebP illustrations)                                               |

**New source material verified present:**

| Source                                        | Type                                   | Verdict                                                                                             |
| --------------------------------------------- | -------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `duseyisaretleme.pdf`                         | KGM 2020 poster, **true vector**       | **Primary sign source.** 526 official sign codes with text bounding boxes; per-sign crop ≈ 11 paths |
| `Pano.pdf`                                    | İBB poster, **true vector**            | Cross-check + horizontal road markings (yatay işaretleme)                                           |
| `KARAYOLU-TRAFIK-ISARET-LEVHALARI.pdf`        | single 5787×8149 JPEG @300 dpi         | **Raster only** → visual reference, NOT a vector source (documented honestly)                       |
| `apps/assets/mekanik assets/` (11 PNG, 20 MB) | contact sheets on dark navy background | ~150 individual items across B / A / D; must be sliced, keyed and optimized                         |

**Feasibility probe already run (de-risks Phase E1):** `pdftocairo -svg` with a per-sign crop box
produced a clean **4.2 KB / 11-path** SVG for `(T-1a) SAĞA TEHLİKELİ VİRAJ`, and `pdftotext -bbox`
yielded all **526 official code tokens with coordinates** — so the sign catalog can be built
automatically from the official geometry instead of hand-traced.

## 3. Locked principles (carried forward, non-negotiable)

1. **Preserve the architecture.** No state-management, routing, DB or networking swap. New surfaces
   follow the existing feature-first layering (`domain/` pure → `data/` repos → `features/` UI).
2. **Offline-first stays the default.** Anything derivable on-device is computed on-device. Only
   genuinely shared state (community) goes to the server, and it degrades gracefully offline.
3. **Additive, backward-compatible backend.** The web app and its 336 tests must keep passing
   untouched. New tables are added through the same idempotent bootstrap DDL + Drizzle schema.
4. **Design tokens only.** No hand-picked colors/spacing. Light + dark parity on every new surface.
5. **Honest completion.** Missing assets, missing infrastructure, external services, legal limits and
   platform limits are documented — never faked, never invented.
6. **Copyright discipline.** Traffic signs are official regulatory symbols reproduced for education;
   we normalize them into our own asset pipeline and never republish a third-party artwork file as-is.
   Where a supplied mechanical photo carries a third-party **trademark**, prefer the unbranded variant
   from the same sheet (each sheet provides one) and document the choice.
7. **One phase at a time.** Never skip, never merge, never partially complete.

## 4. Phase plan

| #       | Phase                                        | Group | Complexity | Backend | Depends on |
| ------- | -------------------------------------------- | ----- | ---------- | ------- | ---------- |
| **E1**  | Official Traffic Sign Vectorization          | PG1   | High       | small   | —          |
| **E2**  | Mechanical Asset Pipeline & Vehicle Library  | PG2   | High       | small   | —          |
| **E3**  | Dashboard Warning-Light Library              | PG2   | Medium     | small   | E2         |
| **E4**  | Multi-Licence Foundation (B · A · D)         | PG3   | High       | medium  | E2, E3     |
| **E5**  | A & D Category Content & Exam Flows          | PG3   | Very high  | medium  | E4         |
| **E6**  | Onboarding Experience (Coach + Insights)     | PG4   | Medium     | —       | E4         |
| **E7**  | Welcome Experience                           | PG5   | Low        | —       | E6         |
| **E8**  | Community Foundation (Profiles · XP · Ranks) | PG6   | Very high  | large   | E4         |
| **E9**  | Social Graph & Messaging                     | PG6   | Very high  | large   | E8         |
| **E10** | Study Groups & Challenges                    | PG6   | High       | large   | E9         |
| **E11** | Premium Video Player                         | PG7   | High       | small   | —          |
| **E12** | Video Content Production                     | PG7   | High       | small   | E11        |
| **E13** | Evolution Polish, Asset Optimization, Report | all   | Medium     | —       | all        |

**Dependency graph:** `E1 ∥ E2 → E3 → E4 → {E5, E6 → E7, E8 → E9 → E10}` ; `E11 → E12` (independent
of the rest) ; `E13` last. Execution order is the table order — E1/E2/E11 have no blockers but the
fixed order keeps memory/report continuity.

---

### E1 — Official Traffic Sign Vectorization (PG1)

**Goal.** Every traffic sign in the app renders as a faithful vector recreation of the official KGM
standard sign, replacing the simplified procedural shell+glyph renderer.

**Scope.**

- A repeatable extraction pipeline (`apps/web/scripts/` style, committed, documented):
  `duseyisaretleme.pdf` → `pdftotext -bbox` code+label catalog → per-code crop box → `pdftocairo -svg`
  → **normalizer** (strip clip paths/defs noise, drop the label text run, unify `viewBox` to a square,
  quantize coordinates, merge same-fill subpaths, gzip-friendly minify) → `assets/signs/<code>.svg`.
- **Catalog mapping:** each of the 121 app signs gains an `officialCode` (e.g. `T-1a`, `TT-2`, `B-15`);
  mapping is data in `apps/web/content/signs.ts` (additive optional field) so web + mobile share it.
- **Renderer:** `TrafficSignView` renders the bundled official SVG when a code maps, and keeps the
  existing procedural renderer as the fallback for any unmapped sign (no dead UI, no blank tiles).
- Per-sign **budgets** enforced by test: ≤ 8 KB, ≤ 60 paths, square viewBox, no raster `<image>`.
- `Pano.pdf` used to cross-check and to source **yatay işaretleme** (road markings) if any app sign
  needs it.

**Risks & mitigations.**

| Risk                                                        | Mitigation                                                                                                                                                                 |
| ----------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Crop boxes misaligned → wrong/half signs                    | Derive the box from the label bbox + column pitch; **render every extracted SVG to PNG and visually review** in batches; a golden contact-sheet is committed to the report |
| flutter_svg unsupported feature (gradient/clip/blend)       | Normalizer whitelists path/fill/stroke only; anything else → flagged, sign falls back to procedural                                                                        |
| Bundle-size blowout                                         | Per-sign budget test + total-budget assertion; measured before/after in the report                                                                                         |
| Some app signs have no official counterpart (informational) | Keep the procedural fallback and **list them in the report** — do not invent an official sign                                                                              |

**Testing.** Unit: catalog integrity (every `officialCode` resolves to a bundled asset; no duplicates;
budgets). Widget: `TrafficSignView` renders official asset when mapped and falls back when not; signs
gallery + detail render. Web: `signs.test.ts` extended for the new optional field. Device: scroll the
full 121-sign gallery, open details, verify shapes/colors/legibility at small and large sizes in dark
and light.

**Definition of Done.** Base DoD (§6) + every sign visually validated in-app + before/after bundle
size measured + unmapped signs listed honestly.

---

### E2 — Mechanical Asset Pipeline & Vehicle Visual Library (PG2)

**Goal.** The 11 supplied mechanical contact sheets become an optimized, transparent WebP library, and
every mechanical/vehicle learning surface becomes visual instead of text-only.

**Scope.**

- **Slicing pipeline** (committed script): per-sheet item grid → crop → background-key the dark navy
  to alpha (ImageMagick `-floodfill` operator, the technique proven in the redesign sprint) → trim →
  cap dimensions → **WebP** (lossy q86 for photos, lossless where edges demand it) → `assets/mech/`.
- **Catalog** `lib/core/mech_assets.dart` (mirroring `AppImages`): id → path, with the licence category
  and the vehicle system it belongs to.
- **Integration:** `VehiclePart` gains an optional image; Vehicle library list + detail become
  photo-led (engine bay, battery, dipstick, coolant, brake fluid, washer, air filter, radiator, fuse
  box, cabin controls, boot equipment, tyres…). Hub/section headers get real imagery.
- Items covered per the mission: **vehicle systems · dashboard buttons · engine bay · battery · fuse
  box · brake system · oil · cooling system · cabin controls** (+ boot/emergency equipment).
- **Trademark hygiene:** where a sheet offers branded and unbranded variants of the same part (e.g.
  batteries), the unbranded variant ships; the decision is recorded.

**Risks & mitigations.** Keying artifacts on dark-on-dark parts (mitigate: per-item fuzz map + visual
review of every keyed item on both light and dark surfaces, exactly as in the redesign sprint) · app
size growth (mitigate: dimension caps + a measured total budget, reported) · items that resist keying
(mitigate: ship on a token-colored rounded plate instead of transparent, documented per item).

**Testing.** Unit: catalog integrity (every id resolves to a declared asset; every declared asset is
referenced). Widget: vehicle list/detail render images with a graceful fallback when an asset is
missing. Device: browse all four vehicle systems, verify transparency and legibility on dark + light.

**Definition of Done.** Base DoD + zero text-only mechanical pages where an asset exists + measured
size delta + every keyed asset visually reviewed.

---

### E3 — Dashboard Warning-Light Library (PG2)

**Goal.** A new first-class learning surface for the **60 dashboard indicator lights** on the
`B-sınıfı-gösterge-işaretleri` sheet — the highest-yield "Motor ve Araç Tekniği" exam topic.

**Scope.** Slice the 10×6 icon grid into 60 transparent WebP icons; author an original Turkish
meaning + memory tip + severity (kırmızı = dur, sarı = dikkat, yeşil/mavi = bilgi) for each; a
searchable/filterable gallery + detail screen reusing the signs-gallery pattern; deep-link from the
relevant lessons; wire into the existing visual-recall practice surfaces.

**Risks & mitigations.** Content authoring volume (mitigate: content is data-first, reviewed in one
pass, original wording only) · icon/colour semantics must be correct (mitigate: severity derived from
the sheet's own colour coding, cross-checked against lesson content).

**Testing.** Unit: catalog integrity + severity mapping + search. Widget: gallery renders, filters,
detail opens. Device: gallery scroll + detail + deep link from a lesson.

**Definition of Done.** Base DoD + all 60 lights present, searchable, and correct.

---

### E4 — Multi-Licence Foundation (B · A · D) (PG3)

**Goal.** Licence category becomes a first-class dimension of the whole app; the selected licence
drives dashboard, study plan, recommendations, AI Coach and learning order — and is switchable later.

**Scope.**

- **Content model:** lessons, signs, vehicle parts, dashboard lights and videos gain an optional
  `licences: ('b'|'a'|'d')[]` (absent = universal). Backend `content-snapshot` serializes it
  (additive; version hash changes, ETag flow unchanged).
- **Client:** a `LicenceScope` derived from `StudyProfile.category`, applied by the existing
  `content_queries` layer; Learn/Practice hubs, lesson lists, sign relevance and vehicle library
  filter + prioritize by it.
- **Switcher:** a licence switch in Profil (and from the hub) that re-scopes instantly and persists —
  progress is **not** wiped; per-licence progress is namespaced.
- **Personalization:** study plan, Home recommendations, nudges and the AI Coach context all carry the
  licence; coach answers stay grounded.
- Onboarding already collects B/A/D — this phase makes the choice _mean_ something end-to-end.

**Risks & mitigations.** Silent content starvation for A/D before E5 lands (mitigate: universal content
remains visible; category-specific sections show an honest "bu kategori için içerik hazırlanıyor" state
only until E5, and E5 removes it) · progress-key migration (mitigate: namespaced keys with a one-time
safe migration + unit tests) · snapshot version churn (mitigate: single additive change, ETag test).

**Testing.** Unit: scoping/prioritization pure functions, progress-key migration. Widget: switching
licence re-scopes the hubs. Backend: content-snapshot integration test for the new field. Device: pick
A in onboarding → verify the whole app re-scopes → switch to D in Profil → verify persistence.

**Definition of Done.** Base DoD + no dead ends in any category + progress preserved across switches.

---

### E5 — A & D Category Content & Exam Flows (PG3)

**Goal.** Real, complete learning content for **A (motosiklet)** and **D (otobüs)**.

**Scope.** For each of A and D: category lessons and rules (equipment/protective gear, chain & final
drive, engine-braking and cornering for A; air brakes, retarder, tachograph, driving/rest hours,
passenger safety, emergency door, battery isolator for D), a category vehicle/mechanical library built
on E2/E3 assets, sign relevance weighting, practice sets and the exam flow. Turkish e-Sınav theory is
common across categories — that is stated explicitly in-app, and the category-specific delta is what
the new content covers, so nothing is faked as a separate exam where none exists.

**Risks & mitigations.** **Largest content-authoring phase** (mitigate: data-first authoring validated
by the existing `@ea/content-schema` parser, reviewed in one pass) · factual accuracy for professional
D-class rules (mitigate: content limited to what the existing lesson corpus and the supplied assets
support; anything uncertain is left out rather than guessed, and listed in the report) · question bank
is B-oriented (mitigate: reuse the common theory bank, add category-tagged questions only where they
are genuinely category-specific; **no fabricated MEB questions**).

**Testing.** Content-schema validation for every new lesson · unit: category scoping returns non-empty
sets for A and D · widget: A and D hubs render complete journeys · device: full A journey and full D
journey end-to-end.

**Definition of Done.** Base DoD + zero placeholder sections in A and D + honest report of anything
deliberately out of scope.

---

### E6 — Onboarding Experience: Coach + Insight Cards (PG4)

**Goal.** Every onboarding screen gains value where it currently has empty space, with the AI Coach
present as an animated mascot and rotating, step-relevant insight cards.

**Scope.** Small animated mascot (subtle idle motion, `AppMotion` curves, respecting
`MediaQuery.disableAnimations`); an insight-card carousel rotating every 2–3 s with tips, facts,
motivation, driving advice, exam advice and learning strategy **tied to the current step**; layout
reworked to stay **vertically centered with no scrolling and always-visible buttons at every supported
size** (tested at small-phone metrics, large text scale, and landscape).

**Risks & mitigations.** Rotation timers leaking into tests (mitigate: inject the ticker/clock, cancel
on dispose — the pattern already used by the exam timer) · no-scroll guarantee at 320 dp width + 1.3×
text scale (mitigate: explicit widget tests at those constraints asserting zero overflow).

**Testing.** Unit: insight selection is deterministic per step and never repeats consecutively.
Widget: overflow-free at three viewport/text-scale combinations; rotation advances with fake time;
buttons always hit-testable. Device: full onboarding in dark mode, watch rotation, verify no scroll.

**Definition of Done.** Base DoD + no scrolling on any step + no overflow at any tested metric.

---

### E7 — Welcome Experience (PG5)

**Goal.** Finishing onboarding leads to a premium welcome moment, not an instant jump to Home.

**Scope.** A coach-led welcome screen that greets the user, summarizes **selected licence · study plan
· exam target · daily goal** from the just-saved `StudyProfile`, motivates, then transitions naturally
into Home (shared-axis transition, skippable, shown once and persisted).

**Risks & mitigations.** Becoming a nuisance on every launch (mitigate: one-shot flag `ea:welcomeSeen`,
plus an explicit "Atla") · router redirect interaction with the existing onboarding redirect (mitigate:
extend the same `redirect` chain with unit-tested ordering).

**Testing.** Widget: after onboarding completes, the welcome screen shows the exact chosen values, then
routes to Home; second launch skips it. Device: fresh-install run of onboarding → welcome → Home.

**Definition of Done.** Base DoD + shown exactly once + values match the saved profile.

---

### E8 — Community Foundation: Profiles · XP · Leaderboards (PG6)

**Goal.** The backbone of the community platform: identity, stats, ranking, and the licence-specific
community structure — with privacy, reporting and moderation designed in from the first line.

**Scope.**

- **Backend (new tables via the existing idempotent bootstrap DDL + Drizzle):** `community_profiles`
  (display name, avatar id, licence, visibility, created), `community_stats` (XP, streak, lessons,
  exams, accuracy — server-owned, derived from submitted progress), `community_achievements`,
  `leaderboard_snapshots` (weekly, per licence), `community_reports`, `community_blocks`.
- **APIs (Bearer, rate-limited, additive):** profile read/update, stats submit (validated,
  monotonic-only, anti-cheat clamped), leaderboard read (weekly + all-time, per licence, paginated),
  report/block.
- **Mobile:** community tab entry, own profile + custom avatar (built from bundled assets — no user
  photo upload, which removes an entire moderation/PII class), other-user profile, leaderboards
  (weekly + licence), achievements showcase, streak display.
- **Privacy:** opt-in participation (default **off**, explicit consent), display name distinct from
  real name, no email exposure, block + report from every profile, and a documented data-retention
  note. Guests can read nothing that identifies others until they opt in.

**Risks & mitigations.**

| Risk                                                  | Mitigation                                                                                                                                                                            |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Client-submitted XP is trivially spoofable            | Server clamps deltas per window, rejects non-monotonic and implausible jumps, and stores raw counters for audit                                                                       |
| Leaderboards leak identity/PII                        | Opt-in only, display name + avatar only, no email/name/location ever returned                                                                                                         |
| Store policy: UGC apps require reporting + moderation | Report/block shipped in **this** phase, before any user-authored text exists (E9)                                                                                                     |
| "Realtime" expectation vs Vercel serverless           | **Documented decision:** ETag/If-None-Match short-poll + optimistic UI now; persistent WebSockets would need a separate realtime service (not provisioned) — never claimed as working |
| Offline behavior                                      | Community surfaces degrade to a cached snapshot + honest offline state; nothing else regresses                                                                                        |

**Testing.** Backend integration tests (PGlite) for every route incl. authz, anti-cheat clamps,
opt-out invisibility, report/block. Unit: rank/aggregation pure functions. Widget: profile, leaderboard,
empty/offline states. Device: opt in, appear on the leaderboard, block/report flows.

**Definition of Done.** Base DoD + web CI + CodeQL green + privacy defaults verified + anti-cheat tested.

---

### E9 — Social Graph & Messaging (PG6)

**Goal.** Friends, direct messaging, discussion and question sharing.

**Scope.** Friend requests/accept/remove with block enforcement; 1:1 messaging (text only, length-capped,
rate-limited); topic discussion threads scoped to licence communities; **question sharing** (share a
question from the bank into a thread by reference — never a copied dump of the bank); notification
strategy for social events (respecting the existing local-notification lane and quiet hours); full
moderation surface (report → queue → admin action) building on E8's tables.

**Risks & mitigations.** Abuse/harassment (mitigate: block enforced server-side on every read/write
path, rate limits, report queue, message length + frequency caps) · unbounded message storage
(mitigate: pagination + retention policy) · polling cost (mitigate: ETag + backoff + foreground-only
polling) · content moderation cannot be automated here (mitigate: **honest statement** — reactive
human moderation via the report queue; no ML classifier is claimed).

**Testing.** Backend integration: friend lifecycle, block enforcement on every path, rate limits,
pagination, report queue transitions. Widget: chat list/thread, discussion, share sheet, empty/offline.
Device: two accounts on one device (login/logout) exercising request → accept → message → report.

**Definition of Done.** Base DoD + block/report enforced on every surface + rate limits tested.

---

### E10 — Study Groups & Challenges (PG6)

**Goal.** Group study and healthy competition.

**Scope.** Study groups (create/join by code, roster, group feed, group stats), community challenges
(server-defined, time-boxed, progress from validated stats), weekly rankings with a deterministic
snapshot/rollover, and licence-specific community landing pages tying E8–E10 together.

**Risks & mitigations.** Weekly rollover correctness across timezones (mitigate: single
`Europe/Istanbul` week boundary — the same choice already made for notifications — with pure,
unit-tested boundary math) · group spam (mitigate: caps on group creation/joins, report/block applies)
· challenge integrity (mitigate: challenge progress derives from the same clamped server-side stats).

**Testing.** Unit: week-boundary + ranking snapshot determinism. Backend integration: group lifecycle,
membership authz, challenge progress. Widget: group screens, challenge cards, rankings. Device: create
a group, join, complete a challenge step, see the ranking update.

**Definition of Done.** Base DoD + deterministic rollover + no unbounded growth path.

---

### E11 — Premium Video Player (PG7)

**Goal.** A genuinely premium video-learning experience, without replacing the existing architecture
unless a clear technical benefit is proven.

**Scope.**

- **Library research first, decision recorded:** evaluate staying on `video_player` + a custom controls
  layer vs adopting a higher-level player. Decision criteria: maintenance, size, Android 11 support,
  offline/caching support, PiP. The chosen option and the reasoning are written into the phase report
  and memory. Default expectation: keep `video_player` and build the premium layer ourselves (matches
  the "no third-party UI dependency" precedent), adopt otherwise only with justification.
- **Player UI:** custom controls, scrubbable timeline with buffered range, chapter markers + chapter
  list, speed control, replay/skip, fullscreen + orientation handling, brightness/volume gestures,
  captions toggle (the VTT tracks already exist).
- **Learning layer:** step overlays keyed to chapters, **bookmarks** (persisted), per-video **progress
  tracking** + resume, "watched" state feeding the study plan.
- **PiP** if practical on API 30 (else documented) and **offline readiness** — download-to-cache using
  the existing local-store pattern, or an honest statement of what the current architecture supports.

**Risks & mitigations.** PiP/native lifecycle bugs (mitigate: feature-detect, fall back cleanly, device
test) · offline download storage growth (mitigate: explicit per-video download with size shown + delete)
· gesture conflicts with go_router pop (mitigate: scoped gesture areas + device test).

**Testing.** Unit: chapter/bookmark/progress pure logic, resume position, formatting. Widget: controls
render and respond with a fake controller; no platform channel needed in tests. Device: play, scrub,
chapters, captions, bookmark, background/resume, rotate, PiP attempt.

**Definition of Done.** Base DoD + library decision documented + every control device-validated.

---

### E12 — Video Content Production (PG7)

**Goal.** Real premium lesson videos for the core manoeuvres, produced to one consistent standard.

**Scope.** Extend the existing, proven **SVG-scene → Playwright frame capture → ffmpeg** pipeline
(`apps/web/scripts/render-video.mjs`) to a premium standard: higher resolution and frame rate, the
current design tokens, labelled steps, chapters, Turkish captions, and a poster per video. Produce the
manoeuvre set — **paralel park · L park (dik park) · U dönüşü · 25 m geri gidiş** — plus the remaining
catalog entries currently marked `planned` (hill start, vehicle inspection, common mistakes) where an
animation can honestly teach them. Anything that genuinely requires real footage stays `planned` and is
**clearly marked for later replacement**, never presented as complete.

**Risks & mitigations.** Animation quality is authored, not filmed (mitigate: this is already the
project's stated, honest video model — original animations, labelled as such) · render pipeline drift
from the web scene source (mitigate: the existing test asserting videos exist on disk with sane sizes is
extended) · bundle/CDN size (mitigate: dual mp4/webm as today, size budget reported).

**Testing.** Web: video catalog test extended (every `available` video has src/poster/captions/chapters
and a real file on disk). Widget/mobile: new videos appear with chapters and the premium gate behaves.
Device: play each new video, verify chapters/captions/quality.

**Definition of Done.** Base DoD + every produced video plays on device + every remaining `planned`
entry honestly marked.

---

### E13 — Evolution Polish, Asset Optimization & Final Report

**Goal.** A pre-release pass over everything the program added, plus the program's final report.

**Scope.** Global asset audit (dedupe, re-compress, remove unreferenced assets, confirm every image is
WebP where beneficial and transparency is preserved, report the total before/after); performance pass
(scroll jank, first-frame, memory on the sign/mech galleries); consistency pass (tokens, motion,
empty/error/offline states, accessibility labels and tap targets across every new screen); light-theme
parity check for all new surfaces; final release-build validation; then
**`MOBILE_EVOLUTION_FINAL_REPORT.md`**.

**Testing.** Full suite + release APK build + a broad device sweep of every screen added by E1–E12.

**Definition of Done.** Base DoD + measured asset/performance numbers + final report written.

---

## 5. Execution workflow (per phase — unchanged discipline)

```
Read discipline → memory → this roadmap
        ↓
Implementation (one phase only)
        ↓
Tests written/updated (unit · widget · backend integration where applicable)
        ↓
flutter analyze (0)  →  flutter test (all pass)
        ↓
Backend gates when the backend changed: pnpm --filter @ea/web typecheck · test · pnpm format
        ↓
Android build (debug; release where relevant)
        ↓
Real-device validation on AYXSUKIVJVPZ7HPZ (+ screenshots)
        ↓
Update MOBILE_PROJECT_MEMORY.md (append only)
        ↓
Write EVOLUTION_PHASE_<N>_REPORT.md
        ↓
Commit → push → WAIT for Web CI + Mobile CI + CodeQL → all green
        ↓
Automatically continue to the next phase (no permission asked)
```

If any workflow is red: stop, investigate, fix, re-push, repeat until green. Never continue on red.

## 6. Definition of Done (base — every phase)

1. Production-ready: **no TODO/FIXME, no placeholder UI, no dead navigation, no incomplete screens**.
2. `flutter analyze` — **0 issues**.
3. `flutter test` — all pass, with **new tests for the new behavior** (never a lowered bar).
4. Backend changed → `typecheck` 0, all web tests pass, `prettier` clean, new routes have integration
   tests, web app unaffected.
5. **Android APK builds.**
6. **Real-device validation** on `AYXSUKIVJVPZ7HPZ` — exercise everything the phase touched (navigation,
   animation, scrolling, offline, loading/empty/error, state restoration), fix every issue found,
   capture screenshot evidence.
7. iOS — **N/A (no macOS)**, documented, config kept valid.
8. **Web CI + Mobile CI + CodeQL green** before the next phase starts.
9. `MOBILE_PROJECT_MEMORY.md` appended (decisions, APIs, gotchas, limitations).
10. `EVOLUTION_PHASE_<N>_REPORT.md` written (template §8).
11. Committed + pushed to `main`.

## 7. Program-level risk register

| Risk                                                           | Severity | Mitigation                                                                                        |
| -------------------------------------------------------------- | -------- | ------------------------------------------------------------------------------------------------- |
| Community (E8–E10) is as large as the original 9-phase program | High     | Split across three phases with a hard scope per phase; privacy/moderation shipped first           |
| No realtime infrastructure on Vercel serverless                | High     | ETag short-poll + optimistic UI; WebSocket service documented as **not provisioned**, never faked |
| UGC brings moderation/legal obligations (store policy, minors) | High     | Opt-in, no photo upload, report/block from day one, retention policy, reactive human moderation   |
| A/D content accuracy (professional D rules)                    | Medium   | Author only what the corpus + assets support; omit and document the rest                          |
| App size growth from signs + mechanical + video assets         | Medium   | Per-asset and total budgets enforced by test; measured in every asset phase                       |
| Third-party trademarks in supplied mechanical photos           | Medium   | Prefer unbranded variants; document choices                                                       |
| Real Play IAP / iOS / FCM still infrastructure-gated           | Medium   | Unchanged from the previous program; re-stated honestly, never faked                              |
| Golden tests still deferred                                    | Low      | Visual validation remains device screenshots + contact sheets                                     |

## 8. Report template (`EVOLUTION_PHASE_<N>_REPORT.md`)

```
# Evolution Phase <N> Report — <Title>
## Verdict: GO / NO-GO
## Completed work
## Architecture & decisions (what was preserved, what was added, why)
## Assets (produced / optimized — measured before→after)
## Screens & flows
## Tests executed (analyze / unit / widget / backend — with real counts)
## Build (APK size; iOS = N/A no macOS)
## Device validation (device, what was exercised, screenshot evidence)
## Honest limitations (missing assets / infrastructure / external services / legal / platform)
## Next phase prerequisites
```

## 9. Program completion

When E13 is done and green, write **`MOBILE_EVOLUTION_FINAL_REPORT.md`** — the full program summary
(all 13 phases, architecture continuity, content added, community architecture, video experience,
measured tests/CI, device validation, honest limitations, GO/NO-GO) — and append the closing entry to
`MOBILE_PROJECT_MEMORY.md`.

---

**Mission:** one phase, one report, one commit, one push, green CI, real-device validation — then
continue autonomously until the roadmap reaches 100%. Quality over speed. Never fabricate completion.
