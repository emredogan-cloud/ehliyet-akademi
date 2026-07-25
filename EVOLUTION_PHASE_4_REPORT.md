# Evolution Phase 4 Report — Multi-Licence Foundation (B · A · D)

**Phase Group 3 · Multi Licence Support (foundation).** _Prepared: 2026-07-25 · Existing architecture
preserved · device-validated on `AYXSUKIVJVPZ7HPZ`._

## Verdict: 🟢 GO

Licence category is now a **first-class dimension of the content model and the UI**. The app ships
**42 new A/D vehicle components** (motorcycle + bus) built on the E2 asset library, scopes and
prioritizes the vehicle library by the selected licence, and adds a **licence switcher in Profil** that
re-scopes the app instantly and persists. `flutter analyze` 0 · `flutter test` **113** (+6) ·
web `typecheck` 0 · web **336**.

## Completed work

1. **Content model** — `VehiclePart.licences?: ('b'|'a'|'d')[]` (absent = universal), added on both
   sides (`apps/web/content/vehicle.ts` + the freezed mobile model, codegen committed).
2. **`apps/web/content/vehicle-licence.ts`** — 42 new components: **22 A-class** (motosiklet kumandaları,
   zincir, çatal, kask/eldiven/dizlik/yelek…) and **20 D-class** (takograf, havalı fren valfleri, basınç
   göstergeleri, retarder, akü şalteri, cam kırma çekici…), each with meaning, tip and where useful
   inspection steps and a common-mistake note.
3. **36 existing parts tagged** as `['b']` or `['b','d']` where they are genuinely not motorcycle parts.
4. **`ALL_VEHICLE_PARTS`** — served by `/api/mobile/content-snapshot`; the web keeps importing
   `VEHICLE_PARTS`, so **web behaviour is byte-identical**.
5. **`lib/domain/content/licence_scope.dart`** — pure scoping/prioritization; `partsBySystem(licence:)`
   and `partCountFor(licence)` in `content_queries`.
6. **Licence switcher** in Profil (bottom sheet, persisted to `StudyProfile`), licence badge in the
   vehicle-library title, licence-scoped hub count, and a licence-aware AI-Coach context.
7. **`apps/mobile/test/licence_scope_test.dart`** — 6 new tests.

## Architecture & decisions

- **Additive on both sides, zero web behaviour change.** New parts live in a separate module and are
  merged only into the mobile snapshot — the same `MOBILE_PRODUCTS`/`anyProductById` pattern the premium
  work established. The web's gallery, quiz, match and SEO counts all still read `VEHICLE_PARTS`.
- **Untagged = universal.** Engine, fluids, tyres and emergency equipment apply to every category, so
  they carry no tag and appear for all three. Only genuinely category-bound content is tagged. This
  keeps every category non-empty by construction — asserted by a test.
- **Progress is NOT namespaced per licence — a deliberate deviation from the roadmap sketch.** The
  Turkish e-Sınav theory bank is _common to all categories_; splitting SRS/answers per licence would
  fragment a shared body of knowledge, discard real progress on a switch, and require a risky migration
  for no learning benefit. What is category-specific is **content scope and prioritization**, and that is
  what the phase implements. The decision is documented in `licence_scope.dart` next to the code it
  governs.
- **Identity rule removes a mapping table.** New A/D part ids are identical to their mech asset ids, so
  `vehiclePartAsset()` resolves them directly — E2's hand-written map remains only for the older parts
  whose ids differ.
- **Prioritization, not just filtering.** `prioritizedFor()` puts category-specific parts first and keeps
  shared ones right after, so an A student sees motorcycle content first without losing common theory.

## Content added (measured)

| Item                  | Count                                                           |
| --------------------- | --------------------------------------------------------------- |
| A-class components    | **22** (kumandalar 10 · mekanik 6 · koruyucu donanım 4 · dış 2) |
| D-class components    | **20** (kabin 9 · motor bölmesi 5 · dış 1 · acil/muayene 5)     |
| Existing parts tagged | 36 (`['b']` 5 · `['b','d']` 31)                                 |
| Snapshot part count   | 70 → **112**                                                    |
| Web part count        | **70 (unchanged)**                                              |

## Tests executed

- `flutter analyze` **0** · `flutter test` **113** (107 before, **+6**): untagged content matches every
  category, tagged content matches only its own, `forLicence` returns the exact set per category,
  `prioritizedFor` fronts specific content without dropping shared content, **no category can end up
  empty**, and the Profil switcher changes the licence and updates the row.
- Web: `typecheck` **0**, **336 tests** pass; the content-snapshot integration test now asserts the
  snapshot carries A and D parts **and** that the web list stays smaller than the snapshot list — so a
  future change that leaks licence parts into the web would fail.
- A real overflow was found and fixed while testing: the licence sheet overflowed by 44 px at 800×600, so
  it is now scroll-safe and height-capped — a genuine small-screen fix, not a test workaround.

## Device validation (`AYXSUKIVJVPZ7HPZ`)

Profil → **Ehliyet sınıfı · B · Otomobil** → bottom sheet lists B/A/D with the current one checked →
picking **A · Motosiklet** persists and the vehicle library title becomes **"Araç Tekniği · A"**.

**Post-deploy validation is required for the new A/D components**: the app reads content from the live
`/api/mobile/content-snapshot`, so the 42 new parts only appear on device after this commit deploys to
Vercel. This is the sequencing rule already recorded in project memory from Phase 2 ("deploy the backend
change, then device-validate the happy path"). The scoping mechanism itself is validated above with the
currently-cached content.

## Honest limitations

- **A/D lessons, rules, practice sets and exam flow are not in this phase** — they are E5. This phase
  delivers the foundation plus the vehicle/mechanical dimension; lessons and videos are not yet tagged,
  so they still show in full for every category (which is correct today, since the theory corpus is
  common).
- The 42 new components are **content authored against the supplied asset set**; where a claim would have
  needed a source we do not have (e.g. exact statutory driving/rest-hour figures), it was left out rather
  than guessed. Those belong to E5's rules content.
- Licence category is stored in the local `StudyProfile` only; it is not synced server-side. Sync is not
  part of this phase and no server field pretends otherwise.

## Next phase prerequisites

**E5 — A & D Category Content & Exam Flows.** The scoping layer, the tagged content model and the A/D
component library are in place; E5 adds category lessons/rules (with `licences` on `Lesson`), category
practice sets and the honest statement that the theory exam itself is common. The pattern for tagging is
established and one test already guarantees no category can be starved.
