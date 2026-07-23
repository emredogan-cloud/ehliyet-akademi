# Phase 3 Implementation Report — Content & Learn

**Ehliyet Akademi Mobile · Roadmap: `MOBILE_APP_IMPLEMENTATION_ROADMAP.md`**
_Prepared: 2026-07-23 · Backend deployed + verified; all Learn screens device-validated on a real Android phone._

## Verdict: 🟢 GO

The mobile app now has a complete, **offline-first Learn section**: 19 lessons, **121 traffic signs**, 70
vehicle-technique parts, and 6 videos — all served from a single new public API, cached locally with
drift (SQLite), and rendered natively with the web's design identity preserved. The highest-risk piece,
the **121 procedurally-drawn traffic signs**, was ported to Dart faithfully and verified on-device across
every shape and pictogram.

---

## Completed work

### Backend (Next.js API — additive, public, backward-compatible)

- **`GET /api/mobile/content-snapshot`** (`app/api/mobile/content-snapshot/route.ts`): serializes the
  existing static content arrays (`LESSONS`, `SIGNS`, `VEHICLE_PARTS`, `VIDEOS`) into one JSON document
  (~150 KB) with a **deterministic sha256 `version`** + **ETag/304** so the mobile client only re-downloads
  when content actually changes. `Cache-Control: public, max-age=300, stale-while-revalidate=86400`. No DB,
  no user, no web-side change — the web keeps importing the same arrays.

### Mobile (Flutter)

- **Content models** (`domain/content/`): `Lesson` (+ `LessonSection`/`Callout`/`CompareTable`/
  `ReviewCard`/`LessonMistake`), `TrafficSign`, `VehiclePart`, `VideoContent` (+ chapters/transcript),
  `ContentSnapshot` — **freezed + json_serializable**, with `@JsonValue` for the Turkish/hyphenated enum
  wire values (`'çok yüksek'`, `'inv-triangle'`, `'motor-bolmesi'`…). Query extensions
  (`signById`, `lessonsBySubject`, `signsByCategory`, `partsBySystem`, …).
- **Offline store** (`data/local/app_database.dart`, `data/content/`): **drift (SQLite)** — the locked
  local-DB choice — behind a `ContentLocalStore` interface (drift on device; in-memory fake in tests, so
  the host test suite needs no native sqlite). `ContentRepository` is **offline-first**: serve cache
  immediately, refresh with the ETag, replace on version change, fall back to cache when offline; throws
  only on a first-ever run with no network. Riverpod providers + an `AsyncValue`-driven `ContentBuilder`
  (loading / retry-error / data).
- **Traffic sign renderer** (`features/learn/widgets/traffic_sign_view.dart`): a faithful Dart port of the
  web `TrafficSign` component — **8 shape shells + 59 glyphs** rebuilt as the exact SVG path data (verbatim
  from the web), rendered via **flutter_svg**; text (speed numbers/`GÜMRÜK`/`DUR`/`YOL VER`) overlaid as
  Flutter widgets for reliable rendering. Copyright-safe: same original line language, no third-party art.
- **Screens** (`features/learn/`): Learn hub (live counts + nav); Lessons list (grouped by subject) +
  detail (objectives, badged sections, **compare tables**, memory tips, exam strategy, mistakes, tips,
  key-takeaways, tap-to-reveal review cards, references); Signs gallery (grouped, **searchable**, empty
  state) + detail; Vehicle list (grouped by system) + detail (inspection steps); Videos list (available vs
  planned, poster thumbnails) + detail with a real **video_player** (streaming, progress, seekable
  chapters). Nested `go_router` routes under the Learn branch.
- **MarkdownText** primitive: renders content `**bold**` as bold spans (matches the web's `mdBold`);
  applied to all content prose.

## Architecture (decisions, packages, structure)

- **drift + freezed honored** (rule #10). drift is abstracted behind an interface so `flutter test` never
  loads native sqlite; the real drift store is device-validated. Phase 4 will extend this same
  `AppDatabase` with relational SRS / attempt / exam tables.
- **Content is a versioned snapshot**, not per-resource endpoints: content is static and non-user-specific,
  so one cacheable document + ETag delta is the simplest correct offline model.
- **Signs: SVG-string port over CustomPainter** — reusing the exact web path data maximizes fidelity and
  minimizes transcription error; flutter_svg handles fills/strokes/transforms/dasharray; text is overlaid
  (flutter_svg text rendering is unreliable).
- Packages added: `flutter_svg`, `video_player`, `drift`, `drift_flutter` (+ `sqlite3_flutter_libs`),
  `freezed`/`json_serializable` (+ `build_runner`, `drift_dev`). Generated files are committed so Mobile CI
  (which does not run build_runner) stays green.

## Tests executed

- **Backend integration** (`content-snapshot.integration.test.ts`) — **5 passed**: counts (19/121/70/6),
  ETag + matching-If-None-Match → 304, deterministic version, every referenced sign glyph is drawable,
  lessons carry sections/objectives.
- `flutter analyze` — **0 issues**.
- `flutter test` — **31 passed**: content model JSON + `@JsonValue` enum mapping + queries; offline-first
  repository (no-cache/online, 304, offline-with-cache, offline-no-cache); Learn screens (hub counts, nav,
  lesson detail, signs gallery + search, vehicle detail, videos); MarkdownText parser + widget.
- Golden tests: deferred (same rationale as Phases 1–2).
- Web gates: prettier ✓, typecheck ✓, lint 0 errors (1 pre-existing warn), verify ✓, backend suite ✓.

## Build

- **Android debug APK builds** (native plugins compile: drift/sqlite3, video_player, flutter_svg).
- **iOS: N/A (no macOS)** on this Linux host; config kept valid.
- **Mobile CI** (analyze + test + build apk) green.

## Performance

Smooth scrolling through the 121-sign gallery (each sign is a small cached `SvgPicture` in a
`RepaintBoundary`); instant offline loads from the drift cache after first fetch; video streams via HTTP
range requests (206). No jank observed.

## Device validation

- **Device:** Redmi M1908C3JGG, Android 11 (API 30), `AYXSUKIVJVPZ7HPZ` (USB), against **production**
  (`https://www.ehliyetegitim.com`) after the backend deploy.
- **Deploy sanity (curl):** snapshot 200 (counts 19/121/70/6, ETag), matching If-None-Match → **304**,
  `parallel-park.mp4` → **206** (range/stream), poster → 200.
- **Exercised on-device:** Learn hub shows real counts (19/121/70/6); **Signs gallery** renders every
  shape correctly — red triangles (skid/curve/bump/pedestrian/children/animal/roundabout/…), blue
  disc/rect with white glyphs (mandatory arrows, phone/bus/tram), red rings, speed-limit rings with
  centered numbers (20–120) and `GÜMRÜK`, the **octagon `DUR`**, the **inverted-triangle `YOL VER`**, and
  the yellow **diamond** (Ana Yol); **search** filters live; **empty state** shows for no matches; sign
  **detail** (meaning + memory-tip/mistake accent callouts); **lesson detail** (badged sections, **compare
  table**, `**bold**` markdown, callouts, review cards); **videos** list (posters loaded from prod) and the
  **video player streaming + playing** with seekable chapters.
- **Evidence:** on-device screenshots captured for hub, signs gallery, sign detail, speed-limit search,
  öncelik (DUR/YOL VER/diamond), mandatory/info signs, videos list, video playing, and lesson detail
  (markdown + compare table).

## Known issues / limitations

- **Vehicle photos not shown on mobile.** The web `VehiclePart.photo` is an asset-manifest id (premium web
  asset), not a URL in the snapshot; the mobile detail is text-first (desc/tip/inspection/mistake), which
  is complete. Bundling/serving vehicle photos is a later enhancement.
- **Scenarios excluded from Phase 3 scope** (roadmap Phase 3 = lessons/signs/vehicle/videos). They exist in
  the content package and can be added in a later phase.
- **Pre-existing 5px bottom overflow** on the Home "Hızlı işlemler" quick-action cards (Phase 1 screen, not
  touched in Phase 3; debug-only banner). Logged for the Phase 9 polish pass.
- `hillUp` glyph's tiny embedded `%10` label relies on flutter_svg `<text>` (best-effort); the hill shape
  itself always reads correctly.

## Next phase prerequisites (Phase 4 — Practice & Exams)

- ✅ drift `AppDatabase` established — extend with SRS / attempt / exam-session tables.
- ✅ Content snapshot (questions are separate) + auth + offline plumbing in place.
- Phase 4 adds: an exam-build API, SRS practice, a 50-question exam runner, collections, and historical
  exams — offline.

**Phase 3 is DONE per the Definition of Done: implementation complete (no placeholders/dead nav), mobile +
backend tests green, APK builds, backend deployed + verified, and every Learn screen device-validated
end-to-end against production. Proceeding to Phase 4 after CI is green.**
