# Mobile Engineering Discipline (permanent)

**Read this file BEFORE every phase.** It defines the non-negotiable execution rules for the
Ehliyet Akademi mobile build. It never changes except to add rules.

## Read order at the start of every phase

1. `MOBILE_ENGINEERING_DISCIPLINE.md` (this file)
2. `MOBILE_PROJECT_MEMORY.md` (append-only engineering memory)
3. `MOBILE_APP_IMPLEMENTATION_ROADMAP.md` (the phase plan + DoD)

Only then determine the current phase and work **only** on it.

## Rules

1. **Understand before coding.** Read the current phase's scope + dependencies first.
2. **One phase at a time.** Never skip, never merge, never partially complete a phase.
3. **No TODO / FIXME / placeholder UI / dead navigation / incomplete screens.** Production quality only.
4. **Never bypass tests.** `flutter analyze` = 0 issues; `flutter test` (unit + widget + golden where
   applicable) all pass; new API routes get integration tests.
5. **Never bypass CI.** Push → wait for **web CI + Mobile CI + CodeQL** → all green. If any fails:
   stop, investigate, fix, re-push, repeat until green. Never continue on red.
6. **Always validate on the real Android device** (`AYXSUKIVJVPZ7HPZ`, Redmi, Android 11): install,
   launch, exercise everything changed, capture a screenshot as evidence. Fix every issue found.
7. **iOS build = N/A on this host** (Linux, no macOS). Keep `ios/` config valid; never fake an iOS build.
8. **Keep web and mobile compatible.** Backend changes must keep the web app + its CI green; mobile
   consumes the same API. Additive, backward-compatible changes only.
9. **Preserve the design system.** One token source → `ThemeData`. Never hand-pick colors/spacing
   outside the tokens. Light + dark parity.
10. **Follow the architecture** (`APP_ARCHITECTURE_PLAN.md`): Riverpod, go_router, dio, drift, secure
    storage, layered/feature-first. Reuse the backend/QIP; port only tiny pure logic (SRS).
11. **Real data / honest reports.** Measured numbers only; never fabricate. Document limitations.
12. **Repo hygiene.** `apps/mobile/` excluded from JS tooling (eslint/prettier/verify). Never commit
    build artifacts (`build/`, `.dart_tool/`, `*.apk`) or secrets.
13. **Format gate.** Run `pnpm format` (prettier) after writing any web-side file **including reports**
    before committing (a report written after the format pass will fail CI — learned in Phase 1).
14. **Finish the phase fully** (implementation → tests → analyze → build → device → CI → report →
    memory) before starting the next. Then continue autonomously.

## Blockers

If a blocker appears: **document it** (in the report + memory), **solve it**, **continue**. Never
change the implementation order unless a blocker forces a documented deviation.

## Quality bar

Senior-mobile-architect quality throughout. Never reduce quality to finish faster. The final phase is
**Final Polish & Delight** — a dedicated pre-launch review.
