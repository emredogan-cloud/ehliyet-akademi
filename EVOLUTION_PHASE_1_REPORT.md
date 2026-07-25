# Evolution Phase 1 Report — Official Traffic Sign Vectorization

**Phase Group 1 · Real Traffic Signs.** _Prepared: 2026-07-25 · Built on the existing architecture —
no new architecture introduced · device-validated on `AYXSUKIVJVPZ7HPZ` (Redmi, Android 11)._

## Verdict: 🟢 GO

The app's simplified, procedurally-drawn traffic signs are replaced with **faithful vector recreations
of the official Turkish standard signs**, produced by a committed, repeatable extraction pipeline from
the two official reference posters. **81 official sign vectors** now back **86 of the 121** catalog
signs (71%); everything else keeps the existing parametric renderer, and every exclusion is listed with
its reason. `flutter analyze` 0 · `flutter test` **91** · web `typecheck` 0 · web **336**.

## Completed work

1. **`apps/mobile/tool/extract_official_signs.py`** — a deterministic, documented PDF → per-sign SVG
   pipeline (poppler + Pillow), committed with the repo.
2. **`apps/mobile/assets/signs/*.svg`** — 81 normalized official sign vectors (680 KB on disk,
   520 KB of SVG payload), each on a square `0 0 100 100` viewBox.
3. **`apps/mobile/lib/core/official_signs.dart`** — generated binding: sign id → asset.
4. **`TrafficSignView`** renders the official vector when one exists and otherwise falls back to the
   existing parametric shell+glyph renderer (no dead UI, no blank tiles).
5. **`apps/web/content/signs.ts`** — three sign values corrected to the official artwork's values
   (see §5). Web rendering path untouched.
6. **`apps/mobile/test/official_signs_test.dart`** — 6 new tests (catalog integrity, normalization,
   performance budget, no dead assets, renderer source selection both ways).

## Architecture & decisions

**Preserved:** Riverpod · go_router · dio · drift · flutter_svg · offline-first content snapshot ·
design tokens. No package added. No backend endpoint added or changed.

- **Extract the official geometry, don't hand-trace it.** Both reference posters are true vector PDFs,
  and Turkish traffic signs are official standard symbols fixed by the Karayolları Trafik Yönetmeliği.
  Hand-drawing 121 pictograms could not match the standard; extracting and **normalizing into our own
  asset pipeline** does. The publisher's file is never republished as-is: each sign is isolated, the
  poster frame and label text are dropped, colors and coordinates are simplified, and the artwork is
  re-anchored to our own square viewBox.
- **Two official sources, best-per-sign.** `duseyisaretleme.pdf` (KGM 2020, the ministry standard sheet)
  is primary; `Pano.pdf` (İBB) is the fallback. This is necessary, not cosmetic: **parts of the KGM
  poster are transparency-flattened in the source itself** — e.g. `TT-42a` arrives as **3 837 sliver
  triangles** instead of ~13 curves. Where a source is flattened or carries the pictogram as an embedded
  raster, the other poster is used.
- **Selection rule = completeness first, then cleanliness.** A candidate must contain interior detail
  (≥ 1 path materially smaller than the sign box) — otherwise it is a shell whose pictogram lives in a
  raster, and it is rejected rather than shipped as an empty triangle. Among complete candidates the one
  with the fewest paths wins.
- **Mapping lives in the mobile app, not in the content snapshot.** Which asset to draw is a rendering
  concern, so it is a generated Dart table (like `AppImages`) — the content API, its version hash and the
  web app are untouched. _(This refines the roadmap's sketch of putting `officialCode` in `signs.ts`;
  the roadmap assumed a shared field, the implementation found no consumer for it outside rendering.)_
- **White backing is synthesized.** Official posters rely on the page being white — signs carry no white
  background layer, and some pictograms are knockout holes. The pipeline prepends a white copy of the
  outer contour so every sign is correct on the app's dark surfaces.
- **Numeric-parametric signs stay parametric.** Speed/minimum-speed/approach-distance signs vary by
  catalog entry while the official artwork bakes in one fixed number; drawing `TT-29a` (which shows "50")
  for "Azami Hız 20" would be wrong. These keep the shell+number renderer.

### Pipeline (what the script actually does)

```
pdftotext -bbox        → official code tokens + positions (a duplicated "ghost" text layer is
                         auto-detected via its constant offset and dropped)
label rows             → per row, the sign strip = between the previous row's labels and this row's
pdftoppm -r 150        → ink scan: bottom-most band in the strip, then per-column vertical re-banding
                         → the visible box of each sign (row-median sanity check rejects mis-slices)
pdftocairo -svg (page) → all page vectors in page space; each path is assigned to the box that
                         contains it (poster frame + labels fit no box → dropped); matrix transforms
                         are baked into the coordinates
normalize              → white outer-contour backing, consecutive same-style path merge, colors to
                         hex, coordinates retargeted to 0..100, shortest-form path data
```

## Assets produced (measured)

| Metric                           | Value                                                  |
| -------------------------------- | ------------------------------------------------------ |
| Official sign vectors            | **81** files · 680 KB on disk · **520 KB** SVG payload |
| Median sign size                 | **2.7 KB**                                             |
| Largest sign                     | `p-3a.svg` 57 KB / 368 elements (flattened source)     |
| Typical sign                     | 4–15 elements                                          |
| App signs backed by official art | **86 / 121 (71%)**                                     |
| Source split                     | KGM 35 · İBB 46                                        |
| Raster content                   | **none** — every asset is pure `<path>` geometry       |

## Screens & flows

`TrafficSignView` is the single rendering point, so the change lands everywhere signs appear: the
121-sign gallery (search + category groups), sign detail, lesson deep-links, and the visual-recall
practice surfaces. No screen, route or state shape changed.

## Tests executed

- `flutter analyze` — **0 issues**.
- `flutter test` — **91 passed** (85 before, **+6 new**): catalog integrity (every mapping resolves to a
  file, kebab-case ids), normalization (square viewBox, no `<image>`, no `<text>`), performance budget
  (≤ 420 elements and ≤ 80 KB per sign, ≤ 900 KB total), no unused assets, and renderer source selection
  (official sign draws the asset with **no** text overlay; unmapped sign keeps the parametric glyph +
  number).
- Web — `typecheck` **0 errors**, **336 tests passed**, `prettier --check` clean, workspace verify clean.
- Visual verification — all 81 assets rendered in a browser contact sheet and reviewed before shipping;
  the sheet is regenerable with `--sheet`.

## Build

`flutter build apk --debug` → **215 MB** debug APK (normal for debug; the release build tree-shakes as
before). iOS — **N/A (no macOS on this Linux host)**; `ios/` config untouched and still valid.

## Device validation (`AYXSUKIVJVPZ7HPZ` · Redmi M1908C3JGG · Android 11 · USB)

Installed the rebuilt debug APK and exercised the Learn section in dark mode:

- **Tehlike Uyarı** grid — official Sola Tehlikeli Viraj, Devamlı Virajlar, Tümsek, Yaya Geçidi, Okul
  Geçidi, Ehli Hayvan (cow), Dönel Kavşak, Yol Daralması, İki Yönlü Trafik, Işıklı İşaret Cihazı; the
  parametric fallbacks (Kaygan Yol, Sağa Tehlikeli Viraj) sit in the same grid without reading as odd.
- **Mecburiyet** — official Ada Etrafında Dönünüz, Bisiklet Yolu, Sağdan Gidiniz, Yaya Yolu, Mecburi
  Asgari Hız Sonu, Patinaj Zinciri; parametric minimum-speed discs unchanged.
- **Geçici / Çalışma** — official **yellow** temporary-works signs (Yolda Çalışma, İş Makinesi
  Çıkabilir), correctly distinct from the permanent white/red group.
- **Öncelik** — official DUR octagon (letterforms inside the vector), Yol Ver, Ana Yol, Ana Yol Sonu,
  Karşıdan Gelene Yol Ver, Öncelikli Yön.
- Search, category grouping, scrolling (smooth, no jank at 121 tiles) and sign detail all behave as before.

No overflows, no blank tiles, no regressions observed.

## Honest limitations

**35 of 121 signs keep the parametric renderer.** Every case is recorded in
`apps/mobile/tool/official_signs_index.json`:

| Group                                                     | Count | Why                                                                                                             |
| --------------------------------------------------------- | ----- | --------------------------------------------------------------------------------------------------------------- |
| Numeric-parametric (speed 20–120, minimum speed, "300 m") | 15    | official artwork bakes in one fixed value; the catalog varies it                                                |
| No official counterpart on either poster                  | 7     | taxi rank, disabled parking, time-limited parking, airport, motorway exit, state-road panel, end-of-parking-ban |
| Pictogram is an embedded **raster** in both posters       | 4     | `T-8` kaygan yol, `T-3b` dik çıkış, `T-14b` vahşi hayvan, `TT-32` bütün yasakların sonu                         |
| Both sources heavily flattened (> 420 slivers)            | 5     | `P-1`, `B-20`, `B-28`, `B-49a`, `TT-35h`                                                                        |
| Extracted but visually wrong → deliberately dropped       | 4     | `T-1a`, `TT-21`, `TT-33a`, `TT-35g` — shipping a broken official asset would be worse                           |

Other honest notes:

- `KARAYOLU-TRAFIK-ISARET-LEVHALARI.pdf` is a **single 5787×8149 JPEG**, not vector — it was used as a
  visual cross-reference only and could not contribute geometry. Stated plainly rather than implied.
- Two app signs share one official sign where the standard has only one (`tumsek`/`kasisli-yol` → `T-7`;
  the çalışma-bölgesi variants → `T-15`/`T-19`/`T-4a`). That is correct, not a bug.
- Parametric blue discs have no white outline ring while official ones do — a small style difference
  visible only when the two sit side by side.
- The source PDFs are **git-ignored reference inputs**; the pipeline errors out with a clear message if
  they are absent. The generated assets are committed, so no contributor needs them.
- The roadmap's provisional per-sign budget (≤ 8 KB / ≤ 60 paths) was written before measurement and is
  superseded by the measured budget now enforced in tests (≤ 80 KB / ≤ 420 elements per sign, ≤ 900 KB
  total). Flagging the change rather than quietly moving the goalposts.

## Content correction (required by the artwork)

Shipping the official artwork forces three catalog values to match the official example values, since
the card would otherwise contradict the sign it shows:

| Sign            | Before | After (official) |
| --------------- | ------ | ---------------- |
| Ağırlık Sınırı  | 16 t   | **7 t**          |
| Dingil Ağırlığı | 7 t    | **6 t**          |
| Genişlik Sınırı | 2 m    | **2,30 m**       |

`yukseklik-siniri` (3,5 m) keeps its parametric rendering because the official `TT-21` value does not
extract cleanly — so its card and artwork stay consistent.

## Next phase prerequisites

**E2 — Mechanical Asset Pipeline & Vehicle Visual Library.** Inputs are present:
`apps/assets/mekanik assets/` (11 contact sheets, ~20 MB, B/A/D). The proven approach is the redesign
sprint's ImageMagick corner-flood-fill keying → WebP, plus a slicing step. Note for that phase: several
sheets carry third-party trademarks (BOSCH/VARTA/EXIDE/Mercedes) and each offers an unbranded variant of
the same part — prefer the unbranded one and record the choice.
