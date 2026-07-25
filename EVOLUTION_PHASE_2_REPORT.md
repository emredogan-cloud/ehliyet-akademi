# Evolution Phase 2 Report — Mechanical Asset Pipeline & Vehicle Visual Library

**Phase Group 2 · Mechanical Visual Library.** _Prepared: 2026-07-25 · Built on the existing
architecture — no new architecture introduced · device-validated on `AYXSUKIVJVPZ7HPZ`._

## Verdict: 🟢 GO

The 11 supplied mechanical contact sheets are now a **101-asset transparent WebP library** (2.05 MB),
produced by a committed, repeatable slicing + keying pipeline. The vehicle library is **photo-led**
instead of icon-only, and a **new "Kabin Kumandaları" learning surface** teaches 39 real in-car
controls. `flutter analyze` 0 · `flutter test` **100** (+9) · web unchanged.

## Completed work

1. **`apps/mobile/tool/extract_mech_assets.py`** — deterministic slicing pipeline (Pillow only):
   object mask → connected-component labelling → reading-order boxes → background keying →
   trim/resize → WebP + generated Dart catalog.
2. **`apps/mobile/assets/mech/*.webp`** — **101** transparent assets (2.05 MB, median 16 KB).
3. **`apps/mobile/lib/core/mech_assets.dart`** — generated id → asset catalog.
4. **`apps/mobile/lib/domain/content/vehicle_visuals.dart`** — hand-written content binding: 29
   vehicle parts → photos, and the 39-entry cabin-control library with original Turkish copy.
5. **`apps/mobile/lib/design/mech_image.dart`** — `MechImage` primitive (token-styled plate, graceful
   icon fallback).
6. **Vehicle library is visual** — list rows show the real part, detail opens with a 220 px hero.
7. **New screen `Kabin Kumandaları`** (`/learn/cabin`) — searchable, grouped gallery; new Learn-hub row.
8. **`apps/mobile/test/mech_assets_test.dart`** — 9 new tests.

## Architecture & decisions

**Preserved:** feature-first layering, go_router nesting, design tokens, offline-first. No package
added, no backend change, web untouched.

- **Connected-component slicing, not row/column banding.** Banding merged items whose soft shadows
  overlap (one sheet collapsed to a single blob). Union-find labelling at ¼ scale, then merging
  components that sit within a small gap (a pair of gloves, a two-part control), then reading-order
  sorting, detects **every sheet exactly**. Three genuinely-touching pairs are separated by explicit
  fractional `SPLITS` entries derived from the verification sheet.
- **Border-connected keying, not fuzz flood-fill.** The redesign sprint's ImageMagick corner
  flood-fill fails here: most parts are **black plastic on dark navy**, so any tolerance high enough
  to clear the background eats the object's interior. Instead: distance-to-background map → BFS from
  the crop border → only background-connected pixels get alpha, with a soft ramp so edges stay
  anti-aliased. Interior dark pixels are unreachable from the border and stay opaque. Verified on a
  light **and** a dark backdrop for all 101 assets.
- **Trademark hygiene.** Five slots are deliberately skipped (`None` in the manifest): three branded
  battery variants and two branded engine variants. Each has an unbranded equivalent in the same sheet,
  which is what ships. Recorded in the tool and in `tool/mech_assets_index.json`.
- **Manifest order = detection order.** The dense 39-button sheet detects in a different order than a
  human reads it (a tall right-column button joins the previous row band). Rather than force the
  detector, the manifest is written in detection order and **verified against the rendered assets** —
  the first pass shipped shifted labels and the on-device screenshot caught it. Both the tool comment
  and the verification step now make this explicit.
- **Content binding is hand-written, catalog is generated.** `mech_assets.dart` is machine output;
  which photo illustrates which lesson concept is an editorial decision, so it lives in
  `vehicle_visuals.dart`. Only genuine same-part matches are mapped — no forced approximations.

## Assets produced (measured)

| Metric                   | Value                                                      |
| ------------------------ | ---------------------------------------------------------- |
| Assets                   | **101** WebP · **2.05 MB** · median **16 KB**              |
| Largest                  | `bus-air-tank.webp` 80 KB                                  |
| Source                   | 10 contact sheets (1536×1024) ≈ 20 MB PNG → 2.05 MB (−90%) |
| Transparency             | **100%** carry an alpha channel (asserted by test)         |
| Skipped for trademarks   | 5 slots (branded battery ×3, branded engine ×2)            |
| Used now                 | 29 vehicle parts + 39 cabin controls = **68**              |
| Staged for E4/E5 (A · D) | 33 (`moto-*`, `bus-*`)                                     |

## Screens & flows

- **Araç Tekniği list** — every mapped part shows its real photo; unmapped parts keep the system icon.
- **Araç Tekniği detail** — 220 px hero photo above the existing text/tip/inspection blocks.
- **Kabin Kumandaları (new)** — 39 controls in 6 groups (Kollar & Farlar, Klima, Sürüş Yardımcıları,
  Kilitler & Kapaklar, Konfor, Soketler), each with the real photo and what it does; live search over
  name/function with an honest empty state.
- **Öğren hub** — new row with the live count (39).

## Tests executed

- `flutter analyze` — **0 issues**.
- `flutter test` — **100 passed** (91 before, **+9 new**): catalog integrity, no dead assets, per-asset
  and total size budget, **WebP alpha-channel assertion**, every content mapping resolves, cabin-control
  uniqueness + non-empty copy, null for unmapped parts, `MechImage` renders/falls back, and the gallery
  opens + searches + shows its empty state.
- Two existing tests updated for the taller layouts (vehicle detail hero; the new hub row pushing
  Videolar out of the lazily-built range) — the documented 800×600 test-fold gotcha.
- Web — untouched this phase (no backend or content change).

## Build

`flutter build apk --debug` builds clean. iOS — **N/A (no macOS)**.

## Device validation (`AYXSUKIVJVPZ7HPZ` · Redmi · Android 11)

- Öğren hub shows the new **Kabin Kumandaları · 39** row.
- Cabin gallery: correct photo↔label pairing across groups (verified after fixing the shifted first
  pass), search, scrolling smooth.
- Araç Tekniği: Motor Bölmesi / Akü / Yağ Çubuğu / Soğutma Suyu / Fren Hidroliği / Cam Suyu all render
  their real photo in the list; Akü detail opens with the hero photo above the existing content.
- Transparency composites correctly on the app's dark surfaces; no halos, no clipped interiors.

## Honest limitations

- **33 assets (`moto-*`, `bus-*`) are staged, not yet surfaced.** They are the A- and D-class parts and
  belong to **E4/E5 (multi-licence)** by design; they ship now because they come from the same sheets and
  the same pipeline run. Called out rather than presented as integrated.
- The 60-icon dashboard warning-light sheet is **deliberately not** part of this phase — it needs a
  meaning/severity per icon and is the whole of **E3**.
- Some vehicle parts have no honest photo match (e.g. `radiator-fan` vs the radiator photo,
  `timing-belt`, `spark-plug`); they keep the system icon rather than being illustrated with a
  different part. 41 of 70 parts are still icon-only for this reason.
- Source sheets are git-ignored reference inputs; the pipeline errors out with a clear message if they
  are absent. Generated assets are committed, so no contributor needs them.
- `tyre` and `spare-wheel` intentionally share one photo (the sheet has one wheel).

## Next phase prerequisites

**E3 — Dashboard Warning-Light Library.** Input is present:
`apps/assets/mekanik assets/B-sınıfı-gösterge-işaretleri.png`, a clean **10×6 grid of 60 indicator
icons with English captions underneath**. The slicing pipeline already handles it; the phase's real work
is the Turkish meaning, memory tip and severity (kırmızı = dur, sarı = dikkat, yeşil/mavi = bilgi) per
icon, plus the gallery/detail surface and lesson deep-links. Note: the captions are baked into the
sheet, so each icon must be cropped **above** its caption — the existing band logic does this, but the
caption row must be excluded explicitly.
