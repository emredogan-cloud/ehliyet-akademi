# Evolution Phase 3 Report — Dashboard Warning-Light Library

**Phase Group 2 · Mechanical Visual Library (second half).** _Prepared: 2026-07-25 · Existing
architecture preserved · device-validated on `AYXSUKIVJVPZ7HPZ`._

## Verdict: 🟢 GO

The 60 dashboard indicator icons are now a **first-class learning surface**: every icon extracted as a
transparent WebP (130 KB total), each with an original Turkish meaning, memory tip and **action level**,
presented in a searchable, severity-filterable gallery with a detail screen.
`flutter analyze` 0 · `flutter test` **107** (+7) · web unchanged.

## Completed work

1. **`apps/mobile/tool/extract_dash_icons.py`** — grid extractor for the 10×6 sheet; reuses the E2
   keying function, and is the **single source of truth for the content** (it generates both the asset
   catalog and the Dart content list).
2. **`apps/mobile/assets/dash/*.webp`** — 60 icons, **130 KB**, median ~2 KB, all transparent.
3. **`apps/mobile/lib/core/dash_assets.dart`** + **`lib/domain/content/dash_lights.dart`** — generated.
4. **`İkaz Işıkları` gallery + detail** (`/learn/lights`, `/learn/lights/:id`) and a new Learn-hub row.
5. **`apps/mobile/test/dash_lights_test.dart`** — 7 new tests.

## Architecture & decisions

- **Alternating-band grid detection.** The sheet alternates icon rows and English caption rows. Height
  alone is not a reliable discriminator (one two-line caption band is as thick as an icon band), so the
  extractor takes the **even-indexed** bands and asserts a minimum thickness. Each icon row is split
  into 10 equal columns and trimmed to its own ink — the captions never enter a crop.
- **Severity = action level, not icon colour.** `DashSeverity` is documented as _what must I do?_
  (`kirmizi` dur ve kontrol et · `sari` dikkat, kontrol ettir · `bilgi` sistem aktif). It usually matches
  the icon's colour, but a white "service due" wrench is classified `sari` because that is the action it
  demands. The gallery's filter chips use the action labels so the distinction is visible, not hidden.
- **Content is generated from the tool, not duplicated.** The Turkish copy lives once, in the extractor's
  `LIGHTS` table, and is emitted to `dash_lights.dart`. This removes the classic drift between an asset
  pipeline and a hand-maintained content list.
- **Original wording.** All 60 meanings and memory tips are written for this app; the sheet's English
  captions are used only to identify which indicator is which.

## Assets & content (measured)

| Metric        | Value                                                     |
| ------------- | --------------------------------------------------------- |
| Icons         | **60** transparent WebP · **130 KB** total · median ~2 KB |
| Content       | 60 × (ad + anlam + hafıza tekniği + eylem düzeyi)         |
| Severity mix  | kırmızı 18 · sarı 20 · bilgi 22                           |
| Budget (test) | ≤ 16 KB per icon, ≤ 300 KB total                          |

## Tests executed

- `flutter analyze` **0**; `flutter test` **107 passed** (100 before, **+7**): 60 unique ids with
  non-trivial copy (minimum meaning/tip length — this caught ten entries that were too terse and they
  were rewritten), every icon resolves to a file on disk, no dead assets, size budget, every severity
  populated and labelled, gallery search + severity filter + empty state, and the detail screen showing
  meaning, tip and action level.
- One E2 test updated (`scrollUntilVisible` instead of `ensureVisible`) because the new hub row pushed
  the Kabin row out of the lazily-built range — the same documented test-fold effect.

## Device validation (`AYXSUKIVJVPZ7HPZ`)

Learn hub → **İkaz Işıkları · 60**; the grid renders all icons at their true colours on the dark theme;
filter chips (Tümü / Dur ve kontrol et / Dikkat / Bilgi) narrow the grid; search works; the detail screen
shows the icon on a severity-tinted plate with the action pill, meaning and memory tip.

## Honest limitations

- The **lesson deep-link** planned in the roadmap is not wired: the current lesson corpus has no section
  granular enough to link a single indicator to, so a link would be decorative. Deferred to E5, where the
  A/D mechanical content is authored and real anchors will exist. Stated rather than faked.
- The icons are a **generic modern instrument cluster**, not one manufacturer's exact set; symbols follow
  ISO/ECE conventions, which is what the exam tests.
- Two indicators in the sheet ("Bilgi Mesajı", "Far Seviye Ayarı") are white/grey; their action level is
  our teaching classification, as documented above.

## Next phase prerequisites

**E4 — Multi-Licence Foundation (B · A · D).** The A/D mechanical assets from E2 (`moto-*`, `bus-*`,
33 items) are already bundled and catalogued, so E4 can scope content by licence and surface them
immediately. Onboarding already collects the category; E4 makes that choice drive the whole app.
