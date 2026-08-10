# Play Store / ASO Lessons Learned — a reusable playbook

**Source of these lessons:** the FormAI (`com.emredogan.formaifit`) Google Play
production preparation, July–August 2026. Three audit rounds over 22 store
assets in two locales produced 14 critical policy findings, then 4 blockers,
then 9 pixel-level defects. Every lesson below is traceable to something that
actually happened; nothing here is hypothetical.

**Who this is for:** the next coding agent, designer, or founder preparing a
Play listing. It is written to be read cold, without knowing FormAI.

**What this is not:** a status report. FormAI's outcome is recorded in
`FINAL_PRODUCTION_SUBMISSION_REPORT.md`. This document only carries forward
what is reusable.

**Hard requirement vs recommendation.** Throughout, findings are tagged:

- **[HARD]** — Google Play will reject the upload, the listing, or the app.
- **[REC]** — quality, featuring eligibility, or conversion. Not a rejection
  cause on its own. Do not present these to a founder as policy.

---

## Table of contents

1. [Executive summary](#1-executive-summary)
2. [The original ASO mistakes](#2-the-original-aso-mistakes)
3. [The most important principle: screenshots are product claims](#3-the-most-important-principle-screenshots-are-product-claims)
4. [Asset generation prompt lessons](#4-asset-generation-prompt-lessons)
5. [How to write better asset prompts](#5-how-to-write-better-asset-prompts)
6. [Never trust generated text](#6-never-trust-generated-text)
7. [Source-of-truth validation](#7-source-of-truth-validation)
8. [CLI / automation lessons](#8-cli--automation-lessons)
9. [Technical Google Play asset validation](#9-technical-google-play-asset-validation)
10. [App icon lessons](#10-app-icon-lessons)
11. [Localization / locale parity](#11-localization--locale-parity)
12. [ASO metadata lessons](#12-aso-metadata-lessons)
13. [Play Console pre-submission checklist](#13-play-console-pre-submission-checklist)
14. [Final pre-submission audit](#14-final-pre-submission-audit)
15. [Do-not-repeat checklist](#15-do-not-repeat-checklist)
16. [Golden rules](#16-golden-rules)
17. [References](#17-references)

---

## 1. Executive summary

### What the ASO process was meant to accomplish

Produce a complete Google Play listing asset set — 8 phone screenshots, a
feature graphic and a 512×512 icon, in English and Turkish — that would (a)
pass Play review, (b) communicate what the app does within the two seconds a
search result gets, and (c) convert.

The intended workflow was: write image-generation prompts, generate the art,
upload. A prompt library was written for exactly this
(`PLAY_STORE_ASO_PROMPTS.html`), and it already contained a policy section
derived from an earlier audit.

### What went wrong in the first generation

**Zero of 22 assets passed.** Fourteen findings were critical. The prompt
library's own rules — no iPhone frames, no outcome promises, no invented
features, fix the "PERSONEL TRAINER" typo — were violated by the assets
generated *from that library*. Writing the rule down did not make the
generator follow it, and nobody checked afterwards.

Three findings were not merely policy risks; they were **statements the app's
own source code contradicts**:

1. Screenshots claimed *"Your data stays on your device. We never send it to
   servers."* The coach is a server-side LLM —
   `lib/features/coach/domain/coach_brain.dart` calls a Supabase Edge Function
   (`coach-chat`) holding `ANTHROPIC_API_KEY`. The app's own localized string is
   honest about this; the screenshots were not.
2. The Community screenshots depicted a public feed with free-text posts,
   photos and comment counts. `squad_feed_screen.dart` states *"Three reactions
   and no text field … `activity_reactions` has no text column to moderate."*
   The screenshots advertised a social network the app deliberately does not
   have.
3. Six assets showed a "calories burned" figure. No burned-energy computation
   exists anywhere in `lib/`.

Alongside those: every device mockup but two was an **iPhone with a Dynamic
Island**, in an Android listing. Both feature graphics and both icons carried
an **X-ray skeleton annotated "HIP ALIGNMENT: 5° DEVIATION"** — a
musculoskeletal assessment claim. The Turkish icon's lockup read **"YAPAY"**,
which alone means *artificial / fake*, not *AI*.

### Why polished screenshots were still unsafe

Because visual quality and factual accuracy are independent axes, and the
generation process optimised only the first.

The assets were genuinely well-designed: consistent palette, premium glass
cards, real typographic hierarchy. A designer reviewing them would have
approved. The defects were invisible to design review because **they were not
design defects** — they were claims. "Calories burned: 1,840 kcal" is
typographically indistinguishable from "Active time: 1h 42m". One is a
feature; the other is a fabrication. Only a reviewer holding the source code
can tell them apart.

This is the trap: a beautiful asset *lowers* scrutiny. Polish reads as
diligence. It is not.

### Why visual quality alone is not enough

Google Play review does not grade aesthetics. It checks whether the listing
describes the app that was uploaded. The relevant policies —
Misrepresentation, Deceptive Behavior, Health Content & Services,
AI-Generated Content, Data Safety accuracy — are all about **correspondence
between claim and product**. A rough screenshot that tells the truth passes. A
gorgeous one that does not, does not.

Worse: the Data Safety declaration is a separate, binding statement about the
same data the listing describes. When a screenshot contradicts it, the problem
is no longer "this asset needs reworking" — it is that the developer has made
two incompatible statements to Google about how user data is handled. FormAI's
first asset set carried exactly that contradiction in six assets.

### Why screenshots are product claims, not marketing artwork

Because Google treats them that way, and because users do.

A screenshot showing a nav rail and a two-pane grid is a claim that the app
renders a nav rail and a two-pane grid. A screenshot showing "Join thousands
of motivated members" is a claim about user base scale. A screenshot showing
a wireframe body with joint markers is a claim about body analysis. None of
these are softened by being pictures rather than sentences. If anything they
are stronger, because a picture reads as evidence.

Section 3 develops this into an operational rule.

### What the final successful process looked like

Three passes, each with a different job:

| Pass | Method | Result |
| --- | --- | --- |
| **1 · Policy audit** | Every asset inspected at full resolution; every claim checked against `lib/` | 14 critical, 8 high, 0 pass |
| **2 · Re-audit after regeneration** | Same method on the regenerated set | 14 criticals closed; 4 blockers + 6 string defects remained |
| **3 · Engineering repair** | Deterministic pipeline: repair → canvas → encode, plus an independent validator | 9 pixel fixes, format normalised, 131/131 checks pass |

The third pass is the one worth copying. Instead of hand-editing images, two
committed scripts do the work and prove it:
`tool/playstore_asset_pipeline.py` builds the upload set from untouched
sources, and `tool/validate_play_assets.py` re-opens every output and asserts
Play's published rules independently of the tool that produced them. Both are
reproducible on any machine; the pipeline is byte-for-byte deterministic
across runs.

### The single most important lesson

> **Every pixel in a store asset is a claim about the product, and every claim
> must be traceable to the source code. Beauty is not evidence. Verify against
> `lib/`, not against taste.**

If a future project remembers one sentence, that is the one. The corollary is
procedural: **the person who generates the asset must not be the only person
who checks it**, and the check must be a source-code comparison, not a look.

---

## 2. The original ASO mistakes

Each entry: what was generated, why it looked fine, why it was wrong, its
category, how it was caught, how it was fixed, how to prevent it.

Categories used: **POLICY** (compliance risk) · **INTEGRITY** (product
misrepresentation) · **FACT** (false claim/number) · **L10N** (localization) ·
**DESIGN** (visual) · **FORMAT** (Play asset spec) · **ASO** (conversion).

---

### 2.1 False privacy absolutes — the most dangerous class

**Generated:** *"100% PRIVACY — Your data stays on your device. We never send
it to servers."* and, in Turkish, *"%100 GÜVENLİK — Verilerin cihazında kalır.
Sunucuya gönderilmez."* The Turkish chat asset went further: *"Sohbetlerin
şifrelenir ve cihazında kalır"* — your chats are encrypted and stay on your
device.

**Why it looked fine:** privacy is a genuine differentiator for this app. The
camera pipeline *is* on-device — ML Kit pose detection, no frame uploaded. The
claim felt earned.

**Why it was wrong:** it was true of the camera and false of everything else.
The chat coach is a server-side LLM. Progress, profile, squads and
leaderboards are all Supabase-backed. The app's own string says so:
*"Camera footage never leaves your device … Your training progress and profile
details are stored on secure servers, tied to your account."* The screenshots
contradicted the app's own privacy disclosure **and** its Data Safety form.

**Category:** POLICY + FACT. Deceptive Behavior, Data Safety accuracy.

**Detected:** grepping `lib/features/coach/` for the LLM transport while
auditing the claim. `coach_brain.dart` names the Edge Function in a doc
comment.

**Fixed:** every absolute replaced with a **scoped** claim —
*"ON-DEVICE FORM ANALYSIS — Camera frames are analysed on your phone and never
uploaded."* and *"YOUR CHATS, YOUR ACCOUNT — Conversations are tied to your
account and sent over an encrypted connection."*

**Failure pattern:** *scope inflation*. A true narrow claim gets widened into
a false broad one because the broad version markets better. The words that do
this are **"all", "100%", "never", "always", "completely", "nothing"**.

**Prevention:** ban unscoped privacy absolutes in the prompt. Every privacy
sentence must name *which data* it covers. Then diff every privacy line
against the Data Safety form before upload — if the form says data is
collected, no asset may say it isn't.

---

### 2.2 Claims broader than the implementation

**Generated:** *"SHOPPING LIST — Auto-generate missing ingredients based on
your plan."*

**Why it looked fine:** a shopping list genuinely ships.

**Why it was wrong:** what ships is an **export of favourited recipes**
(`recipe_ingredient_lines.dart`, `shoppingListExported` analytics). It does
not diff your plan against your pantry. The feature was real; the described
behaviour was not.

**Category:** INTEGRITY.

**Detected:** grepping for the feature, then reading what it actually does
rather than stopping at "it exists".

**Fixed:** *"SHOPPING LIST — Export the recipes you favourited."*

**Failure pattern:** *verify-by-existence*. Confirming a feature exists and
treating the marketing description as validated. The dangerous gap is between
"the noun is real" and "the verb is real".

**Prevention:** validate the **verb**, not the noun. For every feature claim,
find the function that implements the described behaviour, not merely the
feature's directory.

---

### 2.3 Medical and anatomical imagery

**Generated:** both feature graphics and both icons showed an X-ray-style
skeleton with red-highlighted spine and joints, annotated
**"HIP ALIGNMENT: 5° DEVIATION"** and **"HIP ALIGNMENT: 3° DEVIATION"** —
two different values for the same measurement. Reinforced by
*"POSTURE CHECK · 5° tilt"* and the headline *"ANALYZE YOUR BODY."* The
Turkish hero carried a body diagram with red-highlighted musculature under
**"VÜCUT ANALİZİ"**.

**Why it looked fine:** it looks like advanced computer vision, which is the
product's differentiator, and "posture" sounds like fitness rather than
medicine.

**Why it was wrong:** degree-of-deviation readings over a skeleton is a
**musculoskeletal assessment** — a medical representation. The app does 2-D
pose estimation via ML Kit; it does not measure skeletal alignment, and no
camera app can claim clinical postural measurement without substantiation.
This sat in the two most-viewed assets on the listing.

**Category:** POLICY. Health Content & Services.

**Detected:** visual inspection asking "what is this image claiming the app
can measure?"

**Fixed:** skeleton and annotations removed; replaced with the sparse green
joint-node overlay that honestly depicts pose detection.

**Failure pattern:** *credibility theatre*. Medical-looking visuals are
reached for because they signal sophistication. In a health-category listing
they signal a claim that needs clinical evidence.

**Prevention:** in a health/fitness app, prohibit X-rays, anatomical diagrams,
red-highlighted body parts, degree/angle readouts, and any numeric measurement
of a body structure — unless the app genuinely performs it and can substantiate
it. A joint-node overlay on a clothed person is fine; it depicts what pose
detection actually is.

---

### 2.4 Transformation and body-change promises

**Generated:** *"30-DAY TRANSFORMATION"*, *"REAL RESULTS"*,
*"Accelerate your results."*, *"DAY 30 · New you"*, and in Turkish
*"30 GÜNDE DÖNÜŞÜM"*, *"GERÇEK SONUÇLAR"*, *"GÜN 30 · Yeni vücut"* — literally
*a new body*. Plus *"TRACK YOUR PROGRESS — Speeds up your progress and helps
you maximize your results."*

**Why it looked fine:** it is the native dialect of fitness marketing.

**Why it was wrong:** these are outcome guarantees. Build 38 had already
stripped exactly this language *out of the app*, so the assets contradicted
the product's own corrected copy. Turkish made it blunter — **dönüşüm**
unambiguously means physical transformation.

**Category:** POLICY + INTEGRITY. Misrepresentation, Health Content.

**Detected:** reading every headline against the app's shipped strings.

**Fixed:** duration reframed as duration, never as outcome. *"30 DAYS. 24
SESSIONS."*, *"Day 30 · Program complete"* — never *"New you"*.

**Failure pattern:** *the app was cleaned, the marketing was not*. Compliance
work on product copy does not propagate to store assets unless someone
propagates it.

**Prevention:** when product copy is corrected for compliance, add the store
assets to the same change. Keep a banned-phrase list in the prompt and grep
the finished assets' text for it.

---

### 2.5 Fabricated metrics — calories burned

**Generated:** *"CALORIES BURNED · 1,840 kcal"* and *"2,450 kcal"* across six
assets, in both locales.

**Why it looked fine:** every fitness app shows calories burned. Its absence
would look like a gap.

**Why it was wrong:** FormAI computes no such value. A grep for
`caloriesBurned|burnedCalor|yakilanKalori` across `lib/` returns **zero**
matches. The screenshots showed a screen no user will ever see. In one asset
the same figure appeared twice with two different meanings — once as calories
*burned*, once as nutrition *intake*.

**Category:** INTEGRITY + FACT.

**Detected:** grep. This class is trivially detectable and was the highest
finding-per-minute check in the whole audit.

**Fixed:** replaced with metrics the app does compute — sessions completed,
active time, streak, completion percentage.

**Failure pattern:** *category-expectation filling*. The generator adds what
apps of this type usually have, not what this app has. It is the single most
common invention class and the easiest to catch.

**Prevention:** extract every number and metric label from the finished assets
and grep each one against the codebase. Anything without a computation is a
fabrication.

---

### 2.6 Apple hardware in an Android listing

**Generated:** iPhone Pro mockups with a pill-shaped **Dynamic Island** and
iOS status bar in most assets, plus an **Apple Watch** on the model's wrist.
The landscape feature graphic used an iPhone identifiable by its corner
radius, paired volume buttons and action button.

**Why it looked fine:** image models have overwhelmingly more iPhone
marketing imagery in their training distribution. "Premium phone mockup"
converges to iPhone.

**Why it was wrong:** it is an Android store. It is also a feature claim — the
Apple Watch implies wearable pairing the app does not ship.

**Category:** POLICY + INTEGRITY. Store Listing, device misrepresentation.

**Detected:** looking at the notch. Confirmed by cropping and zooming the
feature graphic's device edge at 2×.

**Fixed:** every mockup regenerated as a bezel-less Android handset with a
**centred punch-hole** camera; wrists left bare.

**Failure pattern:** *training-distribution default*. The model's prior beats
an unstated requirement every time.

**Prevention:** state the device positively **and** negatively in the prompt —
"a modern bezel-less Android smartphone with a small centred punch-hole
camera. No notch, no Dynamic Island, no iOS status bar, no Apple device of any
kind." Then check every generated frame's top bezel before accepting it.

---

### 2.7 UI layouts that do not exist — the tablet frames

**Generated:** a tablet screenshot with a left navigation rail, a wide hero
card, a two-up workout grid and a category chip row, under the headline
**"BUILT FOR THE BIG SCREEN"**.

**Why it looked fine:** it is what a well-adapted tablet layout looks like,
and large-screen support is a Play quality signal.

**Why it was wrong:** the app does not render it. The only width-responsive
layout in the codebase is `admin_dashboard_screen.dart` (an internal admin
screen, `width >= 600`). There is no consumer master/detail or two-pane
layout. The headline was a design claim about a design that did not exist.
The Turkish version additionally stated **%60** for "12 of 30 days", which is
40%.

**Category:** INTEGRITY + FACT.

**Detected:** grepping for width-responsive layout code after the asset
claimed one.

**Fixed:** **both tablet frames dropped from the upload set.** Play requires
no tablet screenshot. An absent tablet asset costs a quality signal; a
fictional one is a deceptive listing.

**Failure pattern:** *aspirational asset*. Generating the product you intend
to build rather than the one you are shipping.

**Prevention:** never generate a form-factor asset before confirming the app
renders that form factor. If the tablet build is a stretched phone, either
screenshot the stretched phone or ship no tablet asset.

---

### 2.8 Fabricated community and social content

**Generated:** a public feed with free-text posts, user photographs, trending
topics, category chips, a "Nearby" tab, comment counts (24, 18, 32), and four
**photorealistic human faces with names** — Emre K., Selin A., Mert T., Burak
D. Below it: *"REAL PEOPLE — Join thousands of motivated members."* One post
sat over a photograph of protein-powder tubs.

**Why it looked fine:** social proof is the highest-converting element in most
listings, and community is a real feature area.

**Why it was wrong:** four separate problems in one asset.

- The feed **does not exist**. `squad_feed_screen.dart`: *"Three reactions and
  no text field, which is a decision rather than an omission … no positions,
  no totals compared between people."* The real feed is squad-scoped presence
  events with three reactions and no comment box.

- **"Nearby" does not exist** — no geolocation anywhere in `lib/`.
- **"Join thousands"** is fabricated scale for a pre-launch app.
- The **named photorealistic faces** read as testimonials from real people:
  fabricated identities plus likeness risk. All four were Turkish names in the
  *English* asset.

Depicting a public UGC feed also invites a moderation review the product
deliberately designed away.

**Category:** POLICY + INTEGRITY + FACT. Deceptive Behavior,
Misrepresentation, UGC exposure.

**Detected:** reading the feature's source file, which explains its own design
constraints in a doc comment.

**Fixed:** rebuilt to the shipped behaviour — squad header with a `7 / 12`
member pill (`maxMembers = 12` in `community_models.dart`), presence-event
rows, three reaction icons, **abstract monogram avatars**, and "Someone" for
members whose profile is private, which is what the code actually renders.
Every scale claim removed.

**Failure pattern:** *social-proof gravity*. Community sections attract
invented users, invented counts and invented engagement because that is what
makes them work. It is also the fastest route to a Deceptive Behavior finding.

**Prevention:** never render a human face as a user. Use monogram avatars.
Never state a user count you cannot evidence. Read the feature's source before
depicting its UI — this one documented its own constraints.

---

### 2.9 AI disclosure and AI-as-human

**Generated:** the AI coach was given a **photorealistic human portrait**
beside the label "AI Fitness Coach". Supporting cards claimed
*"TRUSTED INFORMATION — Backed by scientific sources"*,
*"ACCURATE & RELIABLE — Science-based, trustworthy fitness guidance"*, and
*"AI-POWERED — Continuously learns and gives you better recommendations."*

**Why it looked fine:** a human face humanises the coach; "science-based"
sounds responsible.

**Why it was wrong:**

- A photographic face for an LLM presents AI ambiguously as a person —
  precisely what Play's AI-Generated Content policy is concerned with.

- *"Backed by scientific sources"* asserts evidentiary provenance an LLM does
  not carry unless built to cite. In a health category this draws a
  substantiation request.

- *"Continuously learns"* states the model trains on user data. If false it is
  misrepresentation; if true it is an undeclared Data Safety item. Either
  answer creates work.

**Category:** POLICY. AI-Generated Content, Health Content, Data Safety.

**Detected:** reading the claims as a reviewer would — "what would I have to
prove if asked?"

**Fixed:** avatar replaced with an abstract violet orb labelled
**"AI assistant"**; a permanent disclosure strip retained
(*"General fitness advice only, not medical advice"*); and an explicit
disclosure added: **"AI-GENERATED REPLIES — Answers are produced by an AI
model."** The unsubstantiated claims were deleted.

**What went right, worth copying:** the in-app disclaimer strip and the
report-a-reply affordance were already built (Play's AI policy requires
in-app flagging of offensive AI output), and surfacing them *in the
screenshot* is a genuine trust asset most competitors do not ship.

**Failure pattern:** *anthropomorphise-then-over-claim*. Making the AI feel
human, then borrowing the authority of science it does not have.

**Prevention:** AI avatars must be visibly synthetic. Disclose AI generation
in the asset. Never claim accuracy, reliability or scientific backing for
model output.

---

### 2.10 Copy-paste contamination between screenshots

**Generated:** the Turkish **form-detection** screenshot — headlined
*"HER TEKRARI TAKİP EDER"* (tracks every rep) — opened with three feature
columns reading **KÜÇÜK TAKIMLAR / SIRALAMA DEĞİL, KATILIM / VARSAYILAN
GİZLİ** (small squads / presence not ranking / private by default). Those are
the **Squad** screenshot's columns, verbatim.

**Why it looked fine:** each element was individually well-made, correctly
localised and policy-clean. The row was only wrong *in context*.

**Why it was wrong:** a screenshot about camera form analysis opened by
discussing 12-person squads and profile privacy. Incoherent to any reader.
The English twin had no such row at all.

**Category:** INTEGRITY + DESIGN.

**Detected:** cross-reading the two locales side by side. This defect is
invisible when auditing one asset at a time — the row is only wrong relative
to its own headline and to its English twin.

**Fixed:** row removed and the violet gradient background reconstructed; the
English twin's composition became the reference.

**Failure pattern:** *batch contamination*. Regenerating a set in one session
lets content migrate between frames. Neither a policy check nor a design check
catches it; only a coherence check does.

**Prevention:** after generation, read each asset asking **"does every element
belong to this screen?"** and diff each locale against its twin. Cheap, and
nothing else catches it.

---

### 2.11 Localization and Turkish glyph failures

**Generated (all shipped):**

| Asset | Rendered | Should be |
| --- | --- | --- |
| Hero (TR) | `AI TEKNOLO.iSi` | `AI TEKNOLOJİSİ` |
| Coach (TR) | `CEBINDE` / `DIYOR KI` / `tamamlandi` | `CEBİNDE` / `DİYOR Kİ` / `tamamlandı` |
| Nutrition (TR) | `250+ TURK TARIFI` | `250+ TÜRK TARİFİ` |
| Form (TR) | `CANLI ANALIZ` | `CANLI ANALİZ` |
| Challenges (TR) | `Kendine güveiinş.` | `Kendine güven.` |
| Tablet (TR) | `Tüm ozellikler` | `Tüm özellikler` |

Plus untranslated English left inside Turkish assets: the hero coaching cue
**"Chest up"** (the most prominent element on that screen), the badge
**"COMMUNITY · MOTIVATION · SUPPORT"**, the screen title **"Community"**, and
`Core`, `keypoint`, `AI Form Coach`. In the *other* direction, Turkish percent
notation (`%94`, `%60`) and European decimals (`2.450 kcal`) were left in the
**English** assets — twelve occurrences.

**Why it looked fine:** at thumbnail size a missing dot on an `İ` is
invisible. `AI TEKNOLO.iSi` reads as `AI TEKNOLOJİSİ` if you already know what
it should say.

**Why it was wrong:** `ı`/`i` and `I`/`İ` are **different letters** in
Turkish. `güveiinş` is not a word. To a Turkish speaker these are conspicuous
defects, and localization quality is a documented review dimension.

**Category:** L10N + DESIGN.

**Detected:** reading every Turkish glyph at 100% zoom. There is no shortcut.

**Fixed:** regenerated; the two survivors (`Β0` for `30`, and a stale
non-Turkish issue) were repaired programmatically.

**Failure pattern:** *diacritic decay*. Image models drop dots and cedillas
and invent glyphs when confidence runs out. The failure is silent — it never
looks like an error, only like a slightly odd word.

**Prevention:** **generate art without non-ASCII text and typeset it
afterwards.** No prompt wording reliably prevents this. If text must be
generated, proofread every glyph at 100% zoom against a written reference
string, and have a native reader check.

---

### 2.12 Incorrect numbers, percentages, dates and counts

**Generated (a representative sample):**

- `Day 12 of 30` beside `28-DAY SERIES` beside `Day 30 Champion routine` —
  three incompatible states on one screen.

- `18 / 30 days completed` beside `TODAY'S WORKOUT: Day 1`.
- `Time remaining: 12 days` while the milestone list said `DAY 21 — 12 days
  left` and `DAY 30 — 21 days left` — the two swapped.

- `10 days current streak` above a row of **7** check marks.
- Streak card reading `6 days` above **7** filled dots (both locales).
- `%60` shown for `12 of 30 days` (which is 40%).
- Recipe macros that did not reconcile: `440 kcal · 30g P · 50g C · 8g F`
  computes to 392 kcal.

- An in-app date of **May 17, 2025** on a listing being submitted in 2026.
- A plan pill rendering `30` as a beta-like glyph: **`Β0 Günlük Plan`**.
- The readout *"Two weeks of data"* under a chart spanning **May 1 – May 29**
  with the 30-day range tab active.

**Why it looked fine:** each number is plausible in isolation. Nobody
cross-reads a screenshot's internal arithmetic.

**Why it was wrong:** a screenshot depicts **one user at one moment**. Numbers
that cannot co-exist reveal the asset as mocked-up, which invites the question
of what else was mocked up.

**Category:** FACT + INTEGRITY.

**Detected:** treating each asset as a single state and checking every number
against every other. Dot counts were counted.

**Fixed:** a single canonical state defined per asset and applied everywhere
(*day 12 of 30 · 40% · 18 remaining · 6-day streak · 4 sessions this week*);
the surviving defects repaired pixel-wise by
`tool/playstore_asset_pipeline.py`.

**Failure pattern:** *locally plausible, globally incoherent*. Generators
produce each number independently.

**Prevention:** **define the depicted state before generating.** Write it down
— day N of M, streak S, sessions C — and put it in the prompt as a consistency
rule. Then verify arithmetic after generation: percentages, remaining-day
counts, macro sums, and *counted* UI primitives like streak dots.

---

### 2.13 Misleading subscription / trial claims

**Generated:** *"7 DAYS FREE — Try all features, feel the difference."* /
*"7 GÜN ÜCRETSİZ"*, unqualified, in five assets.

**Why it looked fine:** free trials convert, and the app has subscriptions.

**Why it was wrong:** `paywall_screen.dart` is deliberately careful — the
trial badge renders *"ONLY when that card's live RevenueCat SKU carries a free
trial."* A hard-coded "7 DAYS FREE" asserts unconditionally what **the app
itself refuses to assert**. If the live SKU has no trial, or a different
length, the asset is a false offer. Promotional material stating a trial must
also state the price and billing period.

**Category:** POLICY + FACT. Subscriptions & Monetisation.

**Detected:** reading the paywall implementation, which documents its own
caution.

**Fixed:** trial claims removed from the assets entirely.

**Failure pattern:** *marketing asserts what the product hedges*. When code
goes out of its way to avoid a claim, that is a signal, not an obstacle.

**Prevention:** any price, trial or refund claim in an asset must match a
live, configured store SKU, and must carry the terms. If the SKU is not final,
omit the claim.

---

### 2.14 Technical Play asset-format defects

**Generated:**

- **All 18 screenshots had an alpha channel** (`RGBA`). Play requires 24-bit
  PNG with no transparency — this fails at upload.

- **None reached 1080 px** on the short side (941, 1023, 992), and none was
  9:16 — most were 2:3.

- **`US/008.png` was byte-identical to `US/007.png`** (md5
  `d5d71539720a3d9ef8ccf6b0361da551`). The carousel would have shown the same
  slide twice, and the intended eighth asset was missing entirely.

- Dimensions varied *within* a locale (941×1672 vs 1023×1537 vs 992×1586), so
  the carousel would letterbox inconsistently.

- Two different 512×512 icons were produced, one per locale — but **Play does
  not localize the app icon**; it is global. One had to be discarded.

- The delivered icon later carried a **12-row band of pure white** across its
  bottom edge (rows 500–511, 6,144 px) — an export artefact Play's rounded
  mask would have rendered as a white arc.

**Why it looked fine:** none of this is visible when viewing the files.

**Category:** FORMAT.

**Detected:** a scripted pass over the files —
`PIL.Image.mode`, `size`, and `md5sum`. Seconds of work.

**Fixed:** `tool/playstore_asset_pipeline.py` flattens alpha onto the brand
canvas, re-canvases to 1080×1920 by cover-fit and centre-crop, strips every
ancillary PNG chunk, and losslessly recompresses;
`tool/validate_play_assets.py` asserts the result.

**Failure pattern:** *invisible defects need scripts*. Human review cannot see
an alpha channel or a hash collision.

**Prevention:** run a format validator before any human review. It is the
cheapest gate in the process.

---

### 2.15 Brand identity drift

**Generated:** the hero wordmark rendered as **`FORMI`** (both locales), not
`FormAI`. The English icon lockup read **"AI FITNESS COACH"**; the Turkish one
read **"YAPAY | FİTNESS KOÇUNUZ"**. `android:label` is **`FormAI`**.

`YAPAY` deserves its own note: *yapay zekâ* is Turkish for artificial
intelligence, but **`yapay` alone means artificial / fake**. Rendered at the
largest type size in the app's most-viewed asset, it read as
*"FAKE — Your Fitness Coach."*

**Category:** L10N + DESIGN + ASO. Metadata consistency.

**Detected:** cropping the wordmark and zooming to 800%.

**Fixed:** the icon was replaced with a language-free F monogram, which cannot
recur because it contains no words.

**Failure pattern:** *three names for one product* across the assets a
reviewer sees first, plus a compound-term translation truncated to its
modifier.

**Prevention:** the app name is a fixed string — check it glyph by glyph in
every asset. Never let a generator render the brand mark if you can composite
a real one. Never translate half a compound term.

---

### 2.16 Conversion defects that were not policy problems

Worth separating, because they were the majority by count and none of them
would have caused a rejection.

- **Every asset was a poster.** `US/001` carried ~24 discrete text elements.
  In the Play carousel it renders roughly 25 mm wide, where none is legible.

- **The strongest asset was in slot 6.** The live pose skeleton is the one
  visual no competitor can honestly use; it sat behind five weaker frames.
  Slots 1–3 are what appear in search results.

- **The English listing was a translated Turkish listing** — Turkish cuisine
  as the nutrition hook, Turkish names in the community feed, Turklish dish
  names (`Chicken Bulgurlu Salad`), Turkish number formats.

- **Locale carousels advertised different features.** English shipped Body
  Metrics in slot 8; Turkish shipped Challenges. One slot meant two different
  things depending on storefront.

- **Every human figure across 22 assets was a young, lean, muscular man**,
  for features with no gender skew.

**Category:** ASO. **[REC]** throughout.

**Fixed (partially):** slot parity was corrected programmatically — the seven
shared features now occupy identical slots with the locale-specific extra
last. Carousel *ordering* was deliberately left to the founder: it is a
marketing judgment, and it is drag-and-drop in the Console.

**Prevention:** decide slot order and per-locale positioning before
generating. Cap text elements per asset. Cast for the audience you want.

---

## 3. The most important principle: screenshots are product claims

### The principle

> A store asset is not an illustration of the product. It is a **public
> statement about what the product does**, made by the developer, reviewed by
> Google, and relied on by users deciding whether to install.

Everything in section 2 follows from teams treating assets as marketing
artwork — a domain where exaggeration is normal and expected — when Play
treats them as claims, a domain where accuracy is enforced.

### Why generation models invent

Image models are trained to produce *plausible* images of a category. A "fitness
app dashboard" has a distribution, and the model samples from it. Anything the
prompt does not pin down gets filled from that distribution rather than from
your product. Observed in FormAI, the model invented:

| Invented | Concrete example |
| --- | --- |
| Metrics | "Calories burned · 1,840 kcal" — no such computation exists |
| UI elements | A "Nearby" tab; a public feed with comment counts |
| Layouts | A tablet nav rail and two-pane grid the app never renders |
| Device frames | iPhone with Dynamic Island, in an Android listing |
| Privacy statements | "We never send it to servers" |
| Health claims | "HIP ALIGNMENT: 5° DEVIATION"; "reduces injury risk" |
| Statistics | "Join thousands of motivated members" |
| Feature cards | "Auto-generate missing ingredients based on your plan" |
| User states | A 10-day streak above 7 check marks |
| Social proof | Four named photorealistic users with posts |
| Hardware | An Apple Watch implying wearable pairing |

The pattern: **the model completes the category, not the product.** It is not
lying; it has no access to your product. Every gap you leave becomes a
plausible fabrication. This is why "make it look like a premium fitness app"
is the most dangerous prompt you can write — it explicitly instructs the model
to sample the category.

### Why the inventions are dangerous on Play

1. **Misrepresentation** covers depicting features the app lacks.
2. **Deceptive Behavior** covers fabricated social proof and false claims.
3. **Health Content & Services** covers diagnosis, treatment and outcome
   claims — a low bar in a fitness app.
4. **Data Safety accuracy** — the form is a binding declaration about data
   handling. A privacy claim in an asset that contradicts it puts two
   incompatible statements on record.
5. **AI-Generated Content** requires disclosure and prohibits presenting AI
   deceptively.

And the reviewer has the app. Assets that disagree with it are the specific
thing review is designed to catch.

### The claim-traceability rule

Apply before accepting any asset:

> **Every element that carries meaning must trace to one of four sources:**
>
> 1. **Real shipped UI** — this screen exists, at this layout, in this build.
> 2. **Real computed data** — this number comes from code that computes it.
> 3. **Real product behaviour** — this sentence describes what the code does,
>    with the same scope.
> 4. **Valid marketing framing** — a benefit statement with no factual or
>    outcome claim ("Train with a coach that replies" — not "Get results
>    faster").
>
> **Anything traceable to none of the four is a fabrication and must be
> removed, regardless of how good it looks.**

Operationally, for each asset write a two-column table: every text string,
number, icon and UI element on the left; its trace on the right. Any row you
cannot fill is a finding. FormAI's audits were exactly this exercise, and the
unfillable rows were the 14 criticals.

### The corollary about scope

Traceability is not only "does it exist" — it is "**does it exist with this
scope**". *"Camera frames are never uploaded"* traces to real behaviour.
*"Your data stays on your device"* traces to nothing, because "your data" is
broader than the camera. **Most FormAI failures were scope failures, not
existence failures.** Check the quantifier, not just the noun.

---

## 4. Asset generation prompt lessons

### What the FormAI prompt library got right

`PLAY_STORE_ASO_PROMPTS.html` already contained a non-negotiable rules
section: no outcome promises, no invented social proof, no iPhone frames, no
features that do not ship, no fake Play badges, honest AI claims, fix the
`PERSONEL TRAINER` typo, correct Turkish typography, treat generated text as
unreliable. It also specified safe areas, palette and per-asset composition.

**The rules were right and the assets violated them anyway.** That is the
central prompt lesson: a policy section at the top of a document does not
constrain a generator. Constraints must be *in the prompt for the specific
image*, phrased as instructions, repeated per asset, and **verified after
generation**.

### What every prompt must explicitly specify

Positive statement is not enough for anything the model has a strong prior
about. Each of these needs an explicit prohibition alongside the requirement:

| Must specify | Why FormAI needed it |
| --- | --- |
| **Exact device** | "Premium phone" produced iPhones with Dynamic Islands |
| **Android-only hardware** | Must be stated negatively too: no notch, no iOS status bar, no Apple device, no smartwatch |
| **Exact screen composition** | Otherwise card counts and positions drift between locales |
| **Exact UI content** | The generator added a "Nearby" tab and a comment-count feed |
| **Exact text, verbatim** | Paraphrase becomes claim inflation |
| **No invented UI** | Enumerate what may appear; prohibit additions |
| **No invented metrics** | List the metrics allowed; prohibit calories burned explicitly if not computed |
| **No medical imagery** | X-ray, anatomy, red-highlighted body parts, degree readouts |
| **No transformation promises** | Ban the vocabulary: transformation, dönüşüm, new you, results, guaranteed |
| **No privacy absolutes** | Ban 100%, all data, never, completely; require a named scope |
| **No fabricated statistics** | Ban ratings, download counts, member counts, awards |
| **No fake social proof** | No human faces as users, no names, no testimonials |
| **No unsupported features** | Wearables, heart rate, barcode scanning, health-platform sync |
| **Exact locale** | Which language every string is in, including in-UI text |
| **Exact numeric values** | Give the model the numbers; do not let it choose |
| **Feature relationships** | Which figure is intake vs expenditure, etc. |
| **Realistic app state** | One user, one moment, one internally consistent state |

### Why "make it premium" is insufficient

Because it is a style instruction with no factual content, and style is the
one thing the model was already going to get right.

"Premium" tells the model nothing about which metrics exist, which device to
draw, what the privacy architecture is, or which language the UI is in. It
fills all of that from the category prior — the exact mechanism that produced
every finding in section 2. Worse, it actively pulls toward category clichés:
transformation language, calorie counters, wearables, idealised bodies,
iPhone hardware.

**A good prompt is 80% specification and 20% style.** FormAI's corrected
prompts run roughly 500–900 words each, of which the style paragraph is about
60. The rest is what must appear, what must not, and what the exact strings
are.

### Three structural prompt techniques that worked

1. **Negative constraints beside positive ones.** "A modern bezel-less Android
   smartphone with a small centred punch-hole camera. No notch, no Dynamic
   Island, no iOS status bar, no Apple device of any kind." The negative half
   is what actually suppresses the prior.

2. **An `ABSOLUTELY FORBIDDEN` block per asset,** listing the exact banned
   strings for that image, not a general policy. It is easier to check
   afterwards, too — the block doubles as the QA list.

3. **A `CONSISTENCY RULE` block** stating the single depicted state: *"this
   asset depicts ONE user at ONE moment. Use day 12 of 30, 40% complete, 18
   days remaining, a 6-day streak, 4 sessions this week, everywhere these
   appear."* This is what eliminates the section 2.12 class.

---

## 5. How to write better asset prompts

Two reusable templates. Both are written to be filled in and pasted.

### 5.1 Template — generating a new Play screenshot

```text
PLATFORM
  Google Play (Android). This asset will be uploaded to a production Play
  listing and reviewed by Google.

DEVICE
  A modern bezel-less ANDROID smartphone. Symmetric thin bezels, small
  CENTRED PUNCH-HOLE front camera.
  FORBIDDEN: notch, Dynamic Island, iOS status bar, Apple device of any kind,
  rounded-iPhone silhouette, side action button, smartwatch on any wrist,
  any wearable, any second device.

SCREEN SIZE / ASPECT RATIO
  1080 x 1920 px, 9:16 portrait, vertical.

EXACT APP SCREEN
  <name the real screen, e.g. "the Progress dashboard as it renders in build
  1.0.0+38">
  Layout, top to bottom: <enumerate every region>
  Nothing may be added to this screen that is not listed here.

REAL FEATURES  (only these may be depicted)
  - <feature>  — <the file that implements it>
  - <feature>  — <the file that implements it>
  FORBIDDEN FEATURES (do not depict, they do not ship):
  - <e.g. heart rate, calories burned, wearable pairing, barcode scanning,
    health-platform sync, location/nearby, public text feed>

REAL DATA  (use these exact values; do not invent or vary them)
  Depicted state: ONE user at ONE moment.
    <e.g. day 12 of 30 · 40% complete · 18 days remaining · 6-day streak ·
     4 sessions this week · 1h 42m active>
  Every number appearing anywhere in this asset must be consistent with that
  state. Counted UI primitives (streak dots, progress segments, check marks)
  must match their stated count exactly.
  Percentages must be arithmetically correct against the underlying figures.

TEXT / LOCALIZATION
  Language: <en-US | tr-TR | ...>. EVERY visible string, including in-app UI
  labels and navigation, is in this language. No mixed-language text.
  Number format: <"1,840" and "87%" for en-US | "1.840" and "%87" for tr-TR>
  Verbatim strings (reproduce exactly, character for character):
    Headline:    "<...>"
    Sub-headline:"<...>"
    Card 1:      "<...>" / "<...>"
    ...
  <For non-Latin or diacritic-heavy locales, add:>
  Render these characters correctly: <e.g. ı İ ş ğ ç ö ü Ç Ğ İ Ö Ş Ü>.
  Dotted İ and dotless ı are DIFFERENT letters and must not be swapped.
  Every word must be a real word in this language.

PROHIBITED CONTENT
  - No outcome or transformation promise: transformation, "new you",
    "real results", "guaranteed", "maximize your results", any timeframe
    attached to a body change.
  - No privacy absolute: "100%", "all data", "never", "completely",
    "nothing leaves". Privacy wording must name the specific data it covers.
  - No health or medical claim: injury prevention, diagnosis, treatment,
    immune/digestive/metabolic benefit, posture or alignment measurement.
  - No medical imagery: X-ray, skeleton, anatomical diagram, red-highlighted
    body part, degree or angle readout over a body.
  - No fabricated social proof: star ratings, download counts, member counts,
    testimonials, press logos, awards, "#1" claims.
  - No human face presented as a user or as the AI. Avatars are abstract
    monogram circles.
  - No price, trial or refund claim.
  - No Google Play badge, Google logo, drawn Install button, or imitation of
    Play's own UI chrome.
  - No bare torso, no idealised-physique hero framing.
  - <project-specific bans>

COMPLIANCE CONSTRAINTS
  - If the app uses AI: the AI must be visibly synthetic and labelled as AI.
  - If the app gives fitness/health guidance: include the in-app disclaimer
    exactly as it ships: "<verbatim disclaimer string>"
  - Any privacy statement must match the Data Safety declaration.

VISUAL STYLE
  <60 words maximum. Palette hex values, lighting, card treatment, typeface
  character. This section is deliberately the shortest.>

UI FIDELITY
  The UI inside the device frame must match the real app's layout, navigation
  labels and terminology. Navigation: <the exact tab set and labels>.
  Do not invent tabs, screens, chips or sections.

MARKETING CLAIM LIMITS
  Benefit statements are allowed; factual and outcome claims are not.
  Allowed:  "Train with a coach that replies."
  Not:      "Get results faster."

OUTPUT REQUIREMENTS
  1080x1920, vertical, ultra sharp, PNG.
  No transparency. No border. No rounded corners. No drop shadow on the canvas.
```

### 5.2 Template — correcting an already-generated asset

Use when the composition is acceptable and only specific elements are wrong.
This is what FormAI's second round used, and it preserved the design
investment while removing the risk.

```text
TASK
  Regenerate this asset. PRESERVE the existing composition, branding, layout,
  device mockup, card structure and visual style. Change ONLY the elements
  listed under CHANGES. Do not redesign. Do not add elements.

PRESERVE EXACTLY
  <enumerate: e.g. "dark violet hero, left typographic stack, right athletic
  figure, three left glass cards, two right glass cards, centre phone,
  bottom trust bar, full colour system">

CHANGES  (each with the exact replacement)
  1. DEVICE: replace the iPhone with a modern bezel-less ANDROID smartphone,
     symmetric thin bezels, small CENTRED PUNCH-HOLE camera. No notch, no
     Dynamic Island, no Apple device. Remove the smartwatch; wrists are bare.
  2. HEADLINE: replace "<old string>" with "<new string>".
  3. CARD <n>: replace "<old>" with "<new>".
  4. REMOVE ENTIRELY: <element>, because <reason>.
  5. METRIC: replace "<old metric>" with "<real metric>" — the app does not
     compute <old>.

ABSOLUTELY FORBIDDEN IN THE OUTPUT
  <the exact strings and elements that must not reappear, copied from the
  audit finding — this doubles as the QA checklist for the result>

CONSISTENCY RULE
  This asset depicts ONE user at ONE moment: <the canonical state>.
  Every number must agree with it, including counted UI primitives.

TEXT FIDELITY
  Reproduce every string character for character as written above.
  <locale-specific glyph instructions>

OUTPUT
  <dimensions>, PNG, no transparency.
```

### 5.3 Practical note on where prompts stop

Some defects are not worth another generation round. In FormAI's third pass,
nine defects were repaired **programmatically** — a misspelled word, a
mis-rendered digit, two off-by-one dot counts, a stale year, a mis-stacked
label, a leaked feature row. Regenerating those assets risked introducing new
defects into art that was otherwise correct.

**Rule of thumb:** if the defect is localised text or a countable UI
primitive, repair it in pixels. If the defect is compositional, a claim, or a
device frame, regenerate. Section 8 covers the repair pipeline.

---

## 6. Never trust generated text

### What image models did to text in this project

Every one of these shipped into a reviewed asset:

| Failure | FormAI instance |
| --- | --- |
| Plain typo | `naximum.` for `maximum.` (the `m` rendered as `n`) |
| Character substitution | `Β0 Günlük Plan` — the digit `3` rendered as a beta-like glyph |
| Broken diacritics | `CEBINDE`, `DIYOR KI`, `tamamlandi`, `TURK TARIFI`, `CANLI ANALIZ`, `ozellikler` |
| Invented non-word | `Kendine güveiinş.` — not Turkish, not anything |
| Punctuation for a letter | `AI TEKNOLO.iSi` — the `J` became a full stop |
| Brand corruption | The wordmark rendered `FORMI`, not `FormAI` |
| Truncation | `Kalori Avc.`, `30 Gün Ş.` — cut mid-word |
| Hallucinated metric | `CALORIES BURNED · 1,840 kcal` |
| Wrong percentage | `%60` shown for 12 of 30 days (40%) |
| Wrong locale convention | `%94` in an English asset; `2.450 kcal` in en-US |
| Duplicated / mismatched | A 10-day streak label above 7 check marks |
| Content from another screen | The Squad feature row inside the form-detection asset |
| Stale date | `May 17, 2025` on a 2026 submission |
| Mistranslation | `YAPAY` (= artificial/fake) used to mean "AI" |
| Untranslated string | `Chest up` and `Community` left English in Turkish assets |

Two observations from the pattern:

- **Latin ASCII text survived reasonably well.** English headlines were mostly
  correct. The failures cluster in diacritics, digits, and long words.

- **Failures are silent.** None of these looks like an error. `AI TEKNOLO.iSi`
  looks like a word you do not know. `%60` looks like a number. Nothing draws
  the eye, which is why they all shipped.

### The rule

> **Text that carries meaning must be validated against a source of truth, and
> should be typeset programmatically rather than generated whenever the layout
> allows it.**

"Source of truth" means: the ARB/strings file, the codebase, a written
reference string, or a computed value — not the prompt, and not memory.

### When generated text is acceptable

| Acceptable | Because |
| --- | --- |
| Short ASCII marketing headlines | Low glyph risk; still proofread |
| Decorative/illegible-at-size micro-copy | Carries no claim |
| Text you will proofread at 100% zoom against a written reference | The check is the control, not the generation |

### When text must be composited, not generated

| Composite it | Because |
| --- | --- |
| **The brand wordmark** | `FORMI` shipped. Never let a model draw your name |
| **Any non-ASCII locale** | Diacritic decay is unpreventable by prompt |
| **Any number** | Digits substitute silently (`3` → `Β`) |
| **Legal / disclaimer strings** | Must match the shipped string exactly |
| **Privacy and AI-disclosure lines** | These are the claims Play checks |
| **Navigation labels and screen titles** | Must match the app's ARB exactly |

The workflow that actually works for a diacritic-heavy locale: **generate the
art with no non-ASCII text at all, then typeset every string in a design tool
with a font that has full coverage.** This was the explicit recommendation
after round one, and the round-two Turkish set — where it was followed —
carried only two glyph defects instead of six.

### Verification procedure

1. Extract every visible string from every asset into a list.
2. Diff each against the ARB / reference copy deck, character by character.
3. Grep every number and metric label against the codebase.
4. Recompute every percentage and every arithmetic relationship.
5. Count every counted primitive (dots, checks, bars) against its label.
6. For non-ASCII locales, have a native reader review at 100% zoom.
7. Diff each asset against its other-locale twin for contamination.

Steps 3–5 are scriptable. Steps 1–2 and 6–7 are not, and are where the
expensive defects hide.

---

## 7. Source-of-truth validation

The single highest-yield technique in the whole process: **audit the assets
against `lib/`, not against the design brief.** Every one of the three
enforcement-grade findings came from a grep, not from looking.

### What to validate, and where the answer lives

| Claim in the asset | Where the truth is | FormAI example |
| --- | --- | --- |
| **Screen exists** | The screen's widget file | `squad_feed_screen.dart` — presence feed, no text field |
| **Navigation labels** | The l10n ARB `nav*` keys | `navCommunity` is `Topluluk`; there is no `Takım` label |
| **Feature availability** | Grep the feature name across `lib/` | `nearby` → zero matches; the tab was invented |
| **Metrics computed** | Grep the metric name | `caloriesBurned` → zero matches |
| **Metric exists** | The domain file | `video_analysis/domain/form_score.dart` — the form score is real |
| **Counts and caps** | The model constant | `maxMembers = 12` in `community_models.dart` |
| **Content volume** | The asset directory | `assets/meals` = 298 → "250+ recipes" is safe |
| **Privacy architecture** | The transport code + the shipped privacy string | `coach_brain.dart` names the Supabase Edge Function |
| **AI behaviour** | The brain/provider implementation | `LlmCoachBrain` — server-side, not on-device |
| **Subscription claims** | The paywall implementation | Trial badge renders only when the live SKU carries one |
| **Layout support** | Responsive breakpoints | Only `admin_dashboard_screen.dart` has a `>= 600` branch |
| **Localization truth** | Both ARB files | Compare `app_en.arb` and `app_tr.arb` key by key |

### A caution learned the hard way

**Verify before recommending a fix, not only before accepting an asset.**

An intermediate FormAI review flagged the Turkish Challenges screenshot for
using the nav label `Topluluk` and recommended changing it to `Takım` for
consistency with another asset. Checking the ARB showed the opposite:
`navCommunity` is `Topluluk` and **`Takım` is not a nav label at all**. The
recommendation would have made a correct asset wrong. The error was caught
before any pixel changed, but only because the code was consulted at
implementation time rather than at review time.

The lesson generalises: **an audit finding is a hypothesis until the code
confirms it.** Consistency between two assets is not evidence that either is
right.

### The checklist — "can this pixel be traced to the actual product?"

Run per asset. Any **No** is a finding.

#### Screen and layout

- [ ] Does this screen exist in the app, at this layout, in the build being shipped?
- [ ] Do the navigation labels match the ARB exactly?
- [ ] Do the screen title and section headings match the ARB?
- [ ] Is every tab, chip, filter and section real?
- [ ] Does the app render this form factor at all?

#### Data and numbers

- [ ] Does code exist that computes every metric shown?
- [ ] Is every number consistent with a single depicted state?
- [ ] Is every percentage arithmetically correct?
- [ ] Does every counted primitive match its label?
- [ ] Are dates current, or intentionally neutral?
- [ ] Do repeated figures carry the same meaning everywhere?

#### Claims

- [ ] Does every feature claim describe the implemented *behaviour*, not just the feature's existence?
- [ ] Is every privacy statement scoped to data it is actually true of?
- [ ] Does every privacy statement agree with the Data Safety declaration?
- [ ] Is every AI capability claim true of the model, and is AI disclosed?
- [ ] Is every health-adjacent statement free of outcome, diagnosis and prevention claims?
- [ ] Does every price/trial claim match a live, configured SKU?
- [ ] Is every count of users, ratings or downloads real?

#### Representation

- [ ] Is every device frame the target platform's hardware?
- [ ] Is every depicted person a model, never a fabricated user identity?
- [ ] Does every element belong to *this* screen?
- [ ] Does the asset agree with its other-locale twin on product truth?

---

## 8. CLI / automation lessons

### What was installed, and what each tool was actually for

The build host had ImageMagick and ffmpeg but not the PNG toolchain, and no
passwordless sudo. Both obstacles have clean workarounds:

```bash
# Debian packages extract into a private prefix without root
apt-get download <pkg>            # fetches the .deb, no privileges needed
dpkg-deb -x <pkg>.deb ~/.cache/<project>-tools/prefix

# pip is PEP 668-blocked on modern distros; a venv is the supported path
python3 -m venv ~/.cache/<project>-tools/venv
~/.cache/<project>-tools/venv/bin/pip install pyoxipng numpy pillow
```

| Tool | Role | Verdict |
| --- | --- | --- |
| **Pillow** | Load, inspect, resample, composite; the pipeline's backbone | Essential |
| **numpy** | Per-pixel repair maths — inpainting, extrapolation, alpha masks | Essential |
| **oxipng** (`pyoxipng`) | Primary lossless recompressor; fast, strips safely | Essential |
| **exiftool** | Removes EXIF/XMP Pillow leaves behind | Essential — run **before and after** optimisation, because optimisers reintroduce chunks |
| **ImageMagick** | Inspection crops, zooms, contact sheets during review | Essential for review, not for output |
| **optipng** | Fallback recompressor when the Python binding is unavailable | Useful |
| **fonts-inter** | Metric-compatible typeface for replaced glyph runs | Needed for pixel repair |
| **pngquant / pngcrush / zopflipng** | Installed, **deliberately unused** | See below |
| **ffmpeg** | Available; not needed — no video assets | Unused |

**On pngquant specifically:** it is lossy (palette quantisation). These are
gradient-heavy dark UI frames where banding shows immediately, and the set had
4× headroom against Play's 8 MB limit. **Installing a tool is not a reason to
use it.** Choose lossless unless a hard size limit forces otherwise, and if it
does, check the gradients afterwards.

### Why the pipeline beat hand-fixing

The first attempt at repairs was interactive — crop, inspect, patch, re-inspect.
It worked, and then the scratchpad was cleared and **all of it was lost**. That
accident forced the right architecture.

A committed script is better for reasons that outlive the accident:

| Hand-fixing | Scripted pipeline |
| --- | --- |
| Irreproducible | Byte-identical on every run and every machine |
| Undocumented magic numbers | Coordinates in source, with the finding that motivated each |
| Silent partial failure | `selfcheck()` re-measures and fails loudly |
| Re-doing work when sources change | Re-run |
| Unreviewable | Diffable, commentable, code-reviewable |
| Sources at risk | Sources read-only by construction |

Concretely: `tool/playstore_asset_pipeline.py` reads
`playstore-new-ASO/{US,TUR}/NEW/` and never writes to it, regenerates
`playstore-new-ASO/FINAL/{en-US,tr-TR}/` from scratch each run, and ends with
assertions that fail the build if a repair silently missed. It was verified
deterministic — 20/20 outputs byte-identical across consecutive runs.

### Two validators, not one

`tool/validate_play_assets.py` is deliberately **independent of the pipeline**.
It re-opens every output file and asserts Play's published rules from scratch,
so it also catches a file edited or replaced by hand afterwards. A tool that
validates its own output only proves it is self-consistent.

131 assertions across format, alpha, bit depth, dimensions, aspect ratio, file
size, PNG chunk composition, asset counts, contiguous slot numbering,
promotion eligibility, locale parity, icon identity across locales, and
duplicate detection.

### The pipeline principle

```text
GENERATE → VALIDATE → REPAIR → NORMALIZE → VERIFY → EXPORT
```

| Stage | What happens | Why here |
| --- | --- | --- |
| **GENERATE** | Produce artwork from a specified prompt | — |
| **VALIDATE** | Audit against source code and policy | Before investing in repair, know what is wrong |
| **REPAIR** | Pixel fixes **at native resolution** | See below |
| **NORMALIZE** | Resample to target, flatten alpha, sRGB, strip metadata | One canonical transform for the whole set |
| **VERIFY** | Independent conformance pass | Catches both tool bugs and later hand-edits |
| **EXPORT** | Write the upload set with slot-ordered filenames | Founder drags a folder into the Console |

### Why repairs must precede resampling

**A patch applied after upscaling is pixel-sharp against surroundings the
resample has softened, and the mismatch reads as an obvious paste.**

FormAI's sources were 941×1672 and the target is 1080×1920 — a 1.148× upscale.
Repairing first means the patch and its surroundings go through the same
Lanczos pass and land at identical sharpness. Repairing after would have
produced text visibly crisper than the artwork around it.

Measured: edge-energy ratio between the native source region and the final
1080 output was **1.055** — the calibrated unsharp pass returned essentially
what the resample cost, with no local sharpness discontinuity.

### Repair techniques worth reusing

Three helpers covered every FormAI repair:

- **`inpaint(box)`** — bilinear blend from the four clean margins. Correct for
  smooth gradient backgrounds, which is most dark-UI chrome.
  **Gotcha:** if a left/right margin falls on neighbouring glyphs, the
  horizontal blend drags them across the box as streaks. A `mode="v"` variant
  using only top/bottom margins fixes this.

- **`extrapolate_up(box)`** — least-squares fit on the clean band *below*,
  extrapolated upward. The only option when a region is boxed in on three
  sides by other text. Also what repaired the icon's white band.

- **`render_fit(text, font, target_box, colour, angle)`** — rasterise at high
  supersampling, rotate to the mockup's tilt, then scale the tight bbox onto a
  **measured** target box. Fitting to a measured box is what keeps a
  replacement glyph run on the same baseline and advance width.

**Two hard-won details:**

- **Device mockups are tilted.** One FormAI phone sat at **−5.93°**. Rendered
  glyphs need the matching rotation or they read as pasted immediately.
  Measure the tilt from a text baseline across the screen.

- **Measure coordinates, never guess them.** Every constant came from a
  luminance-threshold bounding-box pass over the source. Eyeballed coordinates
  produced two visible artefacts on the first attempt — a rectangular band and
  a pair of vertical streaks — both traced to boxes that crossed a bezel or
  sampled a descender.

### Automation that pays for itself immediately

Before any human looks at an asset, run:

- alpha-channel detection (`Image.mode`)
- dimension and aspect-ratio check
- file-size check
- `md5sum` across the set for duplicates
- PNG chunk enumeration for leftover metadata

FormAI's duplicate (`US/008` ≡ `US/007`) and universal alpha channel were both
found this way in seconds, and neither is visible to human review.

---

## 9. Technical Google Play asset validation

Specs as they applied to this project. **Verify against current Play Console
documentation before relying on them** — Google changes these.

### Hard requirements

| Asset | Requirement | Tag |
| --- | --- | --- |
| **Phone screenshots** | PNG or JPEG | **[HARD]** |
| | **No alpha channel / transparency** | **[HARD]** |
| | Each side 320–3840 px | **[HARD]** |
| | Longest side ≤ 2 × shortest side | **[HARD]** |
| | ≤ 8 MB per file | **[HARD]** |
| | Minimum 2, maximum 8 per device type | **[HARD]** |
| **App icon** | 512 × 512 px | **[HARD]** |
| | PNG or JPEG, ≤ 1 MB | **[HARD]** |
| | One icon globally — **not localizable** | **[HARD]** |
| **Feature graphic** | 1024 × 500 px | **[HARD]** |
| | PNG or JPEG, ≤ 15 MB | **[HARD]** |
| | Required for the listing | **[HARD]** |

### Recommendations — quality and featuring, not policy

| Item | Guidance | Tag |
| --- | --- | --- |
| **1080 × 1920 phone screenshots** | The canonical size used in this project | **[REC]** |
| **≥ 4 screenshots at ≥ 1080 px, 16:9 or 9:16** | Gates promotional/featuring eligibility. Not an upload blocker | **[REC]** |
| **Consistent dimensions within a set** | Mixed sizes letterbox inconsistently in the carousel | **[REC]** |
| **Feature-graphic safe areas** | Keep the centre ~250 × 250 px quiet (a promo video overlays a play button there) and ~64 px clear at every edge | **[REC]** |
| **Icon legible at 48 px** | The size it renders at in search and the app drawer | **[REC]** |
| **Locale parity of slots** | Same feature in the same slot per storefront | **[REC]** |
| **Screenshot ordering** | Slots 1–3 appear in search results | **[REC]** |
| **No duplicate screenshots** | Documented asset-quality concern; also wastes a slot | **[REC]** |
| **Deterministic generation** | Engineering hygiene, not a Play rule | **[REC]** |
| **Stripped metadata** | Hygiene; nothing for Play to misread | **[REC]** |

**Do not present [REC] items to a founder as policy.** Doing so burns
credibility and misallocates their time. FormAI's tablet decision is the
distinction in practice: shipping *no* tablet screenshot is entirely
permitted; shipping a *fictional* one is a Misrepresentation risk. The
requirement was never "you must have tablet assets".

### RGB vs RGBA

The most common FormAI defect and the easiest to miss. All 18 screenshots were
`RGBA`. Play requires no transparency. Flatten against an explicit background
colour — for a dark listing, the artwork's own canvas colour (FormAI used
`#060012`) — rather than white, which would fringe.

`Image.mode == "RGBA"` is the whole check.

### Device authenticity and tablet representation

- Every device frame must be the target platform's hardware. **[HARD]** as a
  misrepresentation matter.

- Tablet screenshots are optional. Only ship them if the app genuinely renders
  a tablet layout. Verify by finding the responsive breakpoint in code, not by
  assuming.

### Deterministic generation and duplicates

Run the pipeline twice and diff the hashes. Non-determinism means the artefact
you validated is not necessarily the artefact you upload. Separately,
`md5sum` the finished set — FormAI shipped a byte-identical duplicate into a
reviewed asset set, and no human noticed.

---

## 10. App icon lessons

The icon produced **two** distinct failures in this project, at different
stages. Both were avoidable and both are common.

### Failure 1 — a poster masquerading as an icon

The first icon contained two photographic human figures, an X-ray hologram
with `HIP ALIGNMENT: 5° DEVIATION` annotations, a three-word text lockup
(`AI FITNESS COACH` / `YAPAY FİTNESS KOÇUNUZ`), a shirtless torso, and
**pre-rounded corners with a baked gradient border**.

Every one of those is a problem:

- **Pre-rounded corners with a border.** Play applies **its own** rounded mask
  and shadow. A pre-rounded icon gets masked twice: the border is clipped into
  four disconnected arcs and the square black corners show behind the mask.

- **Text.** Three words at 512 px become an illegible smear at 48 px. Icons
  with words fail at render size, and the text duplicated the app title.

- **Medical imagery** in the asset that appears in search results, on the home
  screen and in every notification — the worst possible placement for an
  unsubstantiated health claim.

- **Two locale variants.** Play stores **one** icon globally; icons are not
  localizable. One had to be discarded regardless of quality.

- **`YAPAY`.** See §2.15 — a compound-term translation truncated to its
  modifier, meaning *fake*.

A second-round replacement (neon wireframe human bodies) fixed the wording but
repeated the structural errors: still pre-rounded with a glowing border, still
illegible at 48 px, still implying body scanning, and the figures were
unclothed anatomical forms.

**The correct icon** was a flat vector **F monogram** on a full-bleed
near-black square with a radial glow: no rounding, no border, no shadow, no
text, no figures. Verified at 48 px — contrast ratio 52:1, instantly readable.

### Failure 2 — an export artefact nobody looked for

The correct icon shipped with a **12-row band of pure white across its entire
bottom edge** (rows 500–511, 6,144 pixels). The artwork was 512×500; the export
padded the remainder white.

Play's rounded mask would have rendered it as a white arc under the mark. It
survived because everyone was reviewing the *design*, and the design was right.

Detection was a four-line script: count pure-white pixels, and find rows that
are uniformly white. Repair was to extrapolate the background gradient over
the band — the mark ends far above it, so no artwork was touched.

**Lesson:** validate the icon's *pixels*, not only its design. Sample the
corners, sample the edges, count extreme values. This class of defect is
invisible at a glance and fatal under a mask.

### Reusable icon checklist

#### Structure

- [ ] Exactly 512 × 512 px
- [ ] PNG or JPEG, ≤ 1 MB
- [ ] **Full-bleed square** — no pre-rounded corners
- [ ] No border, stroke or outline
- [ ] No self-applied drop shadow (Play adds one)
- [ ] Background is a solid full square, edge to edge
- [ ] All meaning inside the central ~400 × 400 px (corners get clipped)

#### Pixel integrity

- [ ] No pure-white or pure-black bands at any edge — scan the outer rows and columns
- [ ] Corner samples match the intended background
- [ ] No stray transparency

#### Legibility

- [ ] Downscale to 48 × 48 and look at it. Is the mark identifiable?
- [ ] Thick strokes, high contrast, generous internal spacing
- [ ] No fine detail, no texture, no photographic content

#### Content

- [ ] No text — especially not the app name
- [ ] No human figures or anatomical forms
- [ ] No medical imagery, X-rays, skeletons, or measurement readouts
- [ ] No imitation of another app's mark or a Google product icon

#### Consistency

- [ ] **One icon for all locales** — it is not localizable
- [ ] Matches the in-app launcher icon, or the mismatch is a deliberate, recorded decision
- [ ] Matches `android:label` / the store title conceptually

---

## 11. Localization / locale parity

### The locale rule

> **Localization changes language, not product truth.**

Two locales must describe the same product with the same features, the same
numbers, the same privacy scope and the same claims. If they differ on
anything factual, at least one is wrong.

### What actually diverged in FormAI

The brief for the second audit stated the Turkish set was "identical except
language". It was not:

- **Different features in the same slot.** English slot 8 was Body Metrics;
  Turkish slot 8 was Challenges. One carousel position advertised two
  different products depending on storefront. (Both features are real — this
  was a parity defect, not a claim defect.)

- **A trust bar present in one locale only.** `US/005` carried
  *"100% PRIVACY · 7 DAYS FREE · REAL PEOPLE — Join thousands of motivated
  members"*; the Turkish twin had no such bar. The English asset was
  *more wrong*, but the divergence itself meant neither could be validated by
  checking the other.

- **The same garment spelled two ways** across the Turkish set —
  `PERSONAL TRAINER` in one asset, `PERSONEL TRAINER` in another.

- **A whole feature row leaked** from the Squad asset into the Turkish
  form-detection asset, with no English counterpart (§2.10).

- **Different dimensions per slot** within a locale.

### Turkish-specific lessons that generalise

- **Diacritics are semantic.** `ı`/`i` and `I`/`İ` are different letters.
  `TURK TARIFI` and `TÜRK TARİFİ` are not variants of one word.

- **Number formats invert.** Turkish writes `%87` (sign first) and `1.840`
  (period as thousands separator); English writes `87%` and `1,840`. Both
  conventions leaked into the wrong locale — twelve occurrences in the English
  set.

- **Compound terms cannot be truncated.** `yapay zekâ` means AI; `yapay` alone
  means fake.

- **Native copy beats literal translation.** The Turkish long description was
  written *for* Turkish rather than translated, and reads better for it. The
  Turkish nutrition angle (Turkish cuisine, 250+ Türk tarifi) is a genuine
  differentiator in-market and dead weight in en-US — the same asset concept
  should carry different content per locale where the market differs.

- **The English listing was a translated Turkish listing**, and it showed:
  Turkish cuisine as the nutrition hook, Turkish names in the community feed,
  Turklish dish names. Localization has a direction, and the second direction
  is usually the neglected one.

### Locale parity checklist

#### Product truth (must be identical)

- [ ] Same features depicted, in the same carousel slots
- [ ] Same numbers, states and metrics in equivalent assets
- [ ] Same privacy scope and wording meaning
- [ ] Same AI disclosure
- [ ] Same health/medical disclaimers
- [ ] Same subscription terms
- [ ] One global app icon

#### Language (must differ correctly)

- [ ] Every visible string in the target language — including in-app UI, nav labels, screen titles, and badges
- [ ] Correct number, date and percentage conventions per locale
- [ ] Correct diacritics, verified glyph by glyph at 100% zoom
- [ ] Native-reader review, not machine round-trip
- [ ] Market-appropriate content where the market genuinely differs
- [ ] Navigation labels match that locale's ARB file exactly

#### Structural

- [ ] Same asset count and dimensions per locale
- [ ] Same composition in equivalent slots
- [ ] Diff each asset against its twin for contaminated or missing elements

---

## 12. ASO metadata lessons

### The Play-specific structural fact

**Google Play has no keyword field.** There is no Apple-style 100-character
keyword box. Ranking signals come from the **app title**, the **short
description**, and term frequency and relevance in the **long description**,
plus behavioural signals Google collects.

Consequences:

- Keywords must be placed **naturally inside copy a human will read**. There
  is nowhere to hide a keyword list.

- Keyword stuffing is visible to users and is a policy matter under
  Misrepresentation/spam, not merely an optimisation mistake.

- The **title carries the most weight per character** and is the shortest
  field. Spend it deliberately.

### Field limits, and validating them programmatically

| Field | Limit | FormAI final |
| --- | --- | --- |
| App name | 30 characters | `FormAI: AI Fitness Coach` — 24 |
| Short description | 80 characters | 75 |
| Long description | 4,000 characters | 2,457 (en-US) / 2,468 (tr-TR) |

Character counts must be **computed, not estimated**. FormAI's were validated
by script against the limits, and the displayed figures in the review document
were corrected when the script disagreed with the hand-written estimate. A
Turkish string with multi-byte characters is especially easy to misjudge —
count characters, not bytes, and confirm which one the Console counts.

### Claim rules that apply to metadata exactly as they apply to screenshots

Everything in §3 applies to text. The long description is a denser claim
surface than any screenshot.

- **No outcome promises.** No "results", "transformation", "guaranteed".
- **Privacy wording must be scoped.** FormAI's long description states the
  split explicitly: *"Camera footage never leaves your device … Your training
  history, profile and chat are stored on secure servers, tied to your account
  and sent over an encrypted connection."* Naming the boundary is a stronger
  trust signal than a vague absolute, and it survives review.

- **AI must be disclosed** and its limits stated: *"Replies are produced by an
  AI model and are general fitness guidance, not medical advice."*

- **Health disclaimers belong in the copy**, not only in-app. FormAI's
  descriptions close with an explicit *"what this is not"* paragraph
  disclaiming diagnosis, treatment and body-change promises.

- **Subscription claims must match live SKUs**, with terms.
- **Feature claims must match implemented behaviour** — the shopping-list
  wording was narrowed in the description for the same reason it was narrowed
  in the screenshot.

### Structural technique that worked

Writing the long description as **feature blocks with a verb-first heading**,
each traceable to a shipped feature, then closing with two honesty sections
(privacy split, and what the app is not). This makes the traceability audit
trivial: one heading, one feature, one file.

### Keyword strategy without a keyword field

- **Primary terms** in the title, the short description, and the first ~200
  characters of the long description.

- **Secondary terms** as natural feature-block headings, 2–3 mentions each.
- **Long-tail terms** appear once, inside a sentence that genuinely describes
  the behaviour ("app that checks your squat form").

- **Locale-specific terms** only in that locale — the Turkish cuisine angle in
  tr-TR, absent from en-US.

Every term in FormAI's keyword sets already appeared naturally in the written
copy; the keyword list was derived from the copy, not injected into it. That
ordering is the anti-stuffing control.

---

## 13. Play Console pre-submission checklist

Two columns, deliberately. Mixing them wastes the founder's time and lets
engineering assume someone else did the Console work.

### 13.1 ENGINEERING TASKS

#### Build

- [ ] `flutter analyze` clean; full test suite green
- [ ] Release AAB built, signed, obfuscated, and 16 KB page-size verified
- [ ] Version code incremented above the last uploaded build
- [ ] CI green on the exact commit being shipped

#### Assets — content

- [ ] Every asset audited against source code (§7 checklist)
- [ ] No invented features, metrics, layouts or UI
- [ ] No privacy absolutes; every privacy line scoped and matching Data Safety
- [ ] No outcome, transformation, diagnosis or prevention claims
- [ ] No fabricated social proof, ratings, counts or testimonials
- [ ] AI disclosed; AI avatars visibly synthetic
- [ ] Correct platform hardware in every device frame
- [ ] Every number internally consistent; every percentage correct
- [ ] Every string proofread against the ARB, glyph by glyph in non-ASCII locales
- [ ] Each asset diffed against its other-locale twin

#### Assets — format

- [ ] No alpha channel anywhere
- [ ] Dimensions, aspect ratio and file size within Play limits
- [ ] No duplicate screenshots (hash the set)
- [ ] Metadata/ancillary chunks stripped
- [ ] Icon validated at 48 px and at the pixel level (edges, corners)
- [ ] One global icon, byte-identical across locale folders
- [ ] Slot ordering consistent across locales
- [ ] Pipeline re-run and verified deterministic

#### Metadata

- [ ] Title, short and long description within limits — computed, not estimated
- [ ] Both locales written natively, not round-tripped
- [ ] Claims in copy audited exactly as screenshot claims were

#### In-app prerequisites for policy

- [ ] AI output can be reported in-app without leaving the app
- [ ] Medical/fitness disclaimer present where guidance is given
- [ ] Account deletion works end to end, including cascaded data
- [ ] Privacy policy content matches the actual data flow

### 13.2 FOUNDER / CONSOLE TASKS

#### Prerequisites

- [ ] Backend live and not paused
- [ ] Database migrations applied to **production**
- [ ] Reviewer/demo account created and working, with any entitlement it needs
- [ ] Support mailbox monitored (DSR requests land on a statutory clock)

#### Store listing

- [ ] App name, short and long description pasted per locale
- [ ] Screenshots uploaded in slot order, per locale
- [ ] Feature graphic uploaded per locale
- [ ] App icon uploaded (once — global)
- [ ] Any "early access"/beta wording removed from the listing

#### App content — the compliance section

- [ ] Privacy policy URL live and correct
- [ ] Data deletion URL set
- [ ] Data Safety form completed and **cross-checked against every listing claim**
- [ ] Content rating questionnaire completed
- [ ] Target audience and age groups set
- [ ] Health apps declaration completed, if applicable
- [ ] Generative-AI declarations completed, if applicable
- [ ] Ads, news, financial-features declarations as applicable

#### Monetisation

- [ ] Subscription products active in every target country
- [ ] Billing platform credentials valid; products mapped to entitlements
- [ ] License tester account added
- [ ] **One real purchase and one restore completed on a device** — no automated check covers this
- [ ] Trial/price wording in the listing matches the live SKUs

#### Release

- [ ] Closed-test requirements met, if the account is subject to them
      (opted-in tester count and continuous-day requirement)
- [ ] Production-access eligibility confirmed
- [ ] AAB uploaded, release notes written per locale
- [ ] Staged rollout percentage chosen
- [ ] Submitted

#### Reviewer-facing consistency

- [ ] The reviewer can log in, reach the features shown in the screenshots,
      and see the same kind of numbers — not identical values, but the same
      metrics existing
- [ ] Nothing in the listing describes a feature the reviewer cannot reach

---

## 14. Final pre-submission audit

A reusable procedure. Each step names who runs it and what "pass" means.

### 1 · Source-code verification — *engineering*

Grep every feature, metric, screen and label claimed anywhere in the listing.
**Pass:** every claim maps to a file; every metric maps to a computation.

### 2 · Real-device verification — *founder or engineering*

Install the exact release artefact on a physical device. Walk every flow the
listing advertises.
**Pass:** every advertised flow completes.

### 3 · Screenshot-to-code verification — *engineering*

Run the §7 checklist per asset.
**Pass:** zero unfillable traceability rows.

### 4 · Localization verification — *native reader*

Every string in every locale at 100% zoom; number formats; parity diff.
**Pass:** no glyph defects, no untranslated strings, no product-truth divergence.

### 5 · Asset-format verification — *script*

Run the validator.
**Pass:** all assertions green, on a freshly regenerated set.

### 6 · Privacy / legal verification — *engineering + founder*

Diff every privacy sentence in every asset and description against the Data
Safety form and the live privacy policy.
**Pass:** no claim broader than the declared data flow.

### 7 · AI disclosure verification — *engineering*

AI presence disclosed in-app and in the listing; AI visibly synthetic;
in-app reporting of AI output works.
**Pass:** disclosure present, reporting functional.

### 8 · Health-claim verification — *engineering*

Sweep for outcome, diagnosis, prevention, treatment and measurement claims in
assets, descriptions and in-app copy.
**Pass:** none present, or each substantiated.

### 9 · Subscription verification — *founder*

Purchase and restore on a device with a license tester account.
**Pass:** entitlement granted and restored; listing wording matches the SKU.

### 10 · Play Console metadata verification — *founder*

Every field per locale; character counts; no stale wording.
**Pass:** complete and within limits.

### 11 · Data Safety verification — *founder + engineering*

Re-answer the form against the current architecture, not last quarter's.
**Pass:** form matches code and listing.

### 12 · Account-deletion verification — *founder*

Create a throwaway account, delete it, confirm cascaded rows are gone.
**Pass:** data actually removed.

### 13 · Purchase / restore verification — *founder*

Covered by step 9; listed separately because it is the flow most often skipped.

### 14 · Final reviewer-style walkthrough — *anyone not involved in building it*

Open the listing as a stranger. Read every asset and every description. Install
and use the app. Ask only: **does the listing describe this app?**
**Pass:** yes, with nothing surprising.

### The submission rule

> **Do not submit merely because the app builds.**
> **Do not submit merely because CI is green.**
> **Do not submit merely because the screenshots look premium.**
>
> Submit only when **product + screenshots + metadata + policies + Console
> configuration + real-device behaviour** all tell the same truth.

FormAI's CI was green throughout the period when its listing claimed a
privacy model the app did not implement, showed a device it does not run on,
and advertised a social feed it does not have. **Green CI is a statement about
the code, not about the listing.**

---

## 15. Do-not-repeat checklist

Run before generating any Play Store asset, and again before uploading.
Every line is a YES/NO. A **NO** blocks upload until resolved or consciously
waived with a recorded reason.

### Product truth

- [ ] Does every screenshot depict a real shipped feature?
- [ ] Does every depicted screen exist, at that layout, in the build being shipped?
- [ ] Does every layout actually exist — including every tab, chip, filter and section?
- [ ] Does every feature claim describe the implemented **behaviour**, not just the feature's existence?
- [ ] Has every claim been checked against the source code rather than the design brief?

### Numbers and state

- [ ] Does every number come from a real, computed state?
- [ ] Is every metric backed by code that computes it?
- [ ] Are percentages mathematically correct against their own figures?
- [ ] Does every counted UI primitive (dots, checks, bars) match its label?
- [ ] Does each asset depict one user at one internally consistent moment?
- [ ] Are dates current, or deliberately neutral?

### Claims and policy

- [ ] Does every privacy statement match the actual data flow, with the correct scope?
- [ ] Does every privacy statement agree with the Data Safety declaration?
- [ ] Are all health claims defensible — no diagnosis, prevention, treatment or measurement?
- [ ] Is there any transformation or outcome promise anywhere?
- [ ] Are AI features disclosed, and is the AI visibly synthetic rather than human?
- [ ] Is every subscription, trial or refund claim matched to a live SKU with terms?
- [ ] Is every user count, rating and download figure real?
- [ ] Is there any fabricated social proof, testimonial or named user?

### Representation and imagery

- [ ] Does every device mockup match the target platform's hardware?
- [ ] Is there an Apple device, notch, Dynamic Island or smartwatch anywhere?
- [ ] Is any depicted person presented as a real user?
- [ ] Is there medical or anatomical imagery that is not genuinely earned?
- [ ] Does every element belong to the screen it appears on?

### Localization

- [ ] Are all screenshots localized, including in-app UI strings?
- [ ] Are non-ASCII characters verified glyph by glyph at 100% zoom?
- [ ] Has a native reader reviewed each locale?
- [ ] Are number, date and percentage conventions correct per locale?
- [ ] Do the locales agree on every product fact?
- [ ] Are all locales feature-equivalent, with the same feature in the same slot?

### Technical

- [ ] Are screenshots technically Play-compatible — format, dimensions, ratio, size?
- [ ] Is there any alpha channel?
- [ ] Are there duplicate screenshots? (hash the set)
- [ ] Is metadata stripped?
- [ ] Is the icon readable at 48 px?
- [ ] Is the icon free of pre-rounded corners, borders, baked shadows and edge artefacts?
- [ ] Is there exactly one icon across all locales?
- [ ] Does the pipeline regenerate byte-identical output?

### Process

- [ ] Has the listing been reviewed against the actual source code?
- [ ] Has someone other than the asset's author reviewed it?
- [ ] Has a real-device reviewer walkthrough been performed?
- [ ] Do the app, the assets, the metadata, the Data Safety form and the Console configuration all tell the same story?

---

## 16. Golden rules

1. **Never invent a feature for an ASO screenshot.** The reviewer has the app.
2. **Never put a claim into an image that the code cannot prove.**
3. **Treat every store asset as part of the product's public contract**, not as marketing artwork.
4. **Verify the verb and the scope, not just the noun.** "The feature exists" does not validate "the feature does *this*", and a true narrow claim is not a true broad one. Most failures are true-but-widened.
5. **Never make a privacy claim broader than the actual data flow** — and never one that contradicts Data Safety.
6. **Ban the absolutes:** 100%, all data, never, always, completely, nothing.
7. **Never use transformation or outcome promises.** Duration is not a result.
8. **Never fabricate a metric.** If no code computes it, it does not go in the picture.
9. **Never fabricate users, counts, ratings or testimonials.** No human face is a user.
10. **Never show an Apple device in an Android Play listing** — state the prohibition explicitly in the prompt.
11. **Never ship a tablet layout the consumer app does not render.** Shipping *no* tablet asset is permitted; shipping a fictional one is not.
12. **Never let a generator draw your brand name.** Composite it.
13. **Never trust generated text.** Validate against the ARB, or typeset it programmatically.
14. **Generate art without non-ASCII text and typeset the locale afterwards.** No prompt prevents diacritic decay.
15. **Define the depicted state before generating**, and make every number in the asset agree with it.
16. **Disclose AI, and make AI look synthetic.** Never claim scientific backing for model output.
17. **No medical imagery in a fitness app** unless the app performs the measurement and can substantiate it.
18. **Repair before resampling.** A patch applied after upscaling reads as a paste.
19. **Measure coordinates; never guess them.** And measure the mockup's tilt.
20. **Script the invisible checks** — alpha, dimensions, hashes, chunks — run them before any human review, and run them from a tool independent of the one that produced the asset.
21. **Localization changes language, not product truth.**
22. **Distinguish hard Play requirements from recommendations**, and never present a recommendation to a founder as policy.
23. **An audit finding is a hypothesis until the code confirms it** — including your own.
24. **Never assume green CI means Play-ready.** CI validates the code, not the claims.
25. **Beauty lowers scrutiny.** The better an asset looks, the harder you should check what it says.

---

## 17. References

Files in this repository that a future agent should consult. All paths verified
present at the time of writing.

### The FormAI audits — read these first for worked examples

| File | What it contains |
| --- | --- |
| `ASO_SCREENSHOT_COMPLIANCE_REPORT.html` | Round-one audit of all 22 assets. 14 critical + 8 high findings, each with policy category, risk level, detection method, and a corrected generation prompt. The corrected prompts are the best available examples of §5.2 in practice. |
| `FINAL_PLAY_STORE_REVIEW.html` | Round-two re-audit of the regenerated set, plus the final English and Turkish metadata (title, short and long descriptions, both verified against Play's limits) and the keyword strategy. Carries a status banner recording which blockers were later closed. |
| `FINAL_PRODUCTION_SUBMISSION_REPORT.md` | The production submission record. **§11** documents the asset-preparation pass with `DONE BY ENGINEERING` and `FOUNDER ACTIONS` separated, and §11.2 records the residuals that were deliberately not fixed. |
| `FINAL_GOOGLE_PLAY_PRODUCTION_AUDIT.md` | The earlier production audit whose findings drove build 38's copy corrections. |

### Prompt and design source material

| File | What it contains |
| --- | --- |
| `PLAY_STORE_ASO_PROMPTS.html` | The original per-asset GPT image prompt library, with a non-negotiable rules section, safe-area specifications and the palette. Instructive both for what it specifies and for the fact that the generated assets violated it anyway. |
| `ASO_VISUAL_MASTERPLAN.md` | Turkish-language ASO strategy: positioning, competitor style analysis, screenshot strategy and concepts, generation prompts, overlay-text system. |
| `docs/IMAGE_PROMPTS.md`, `docs/WORKOUT_IMAGE_PROMPTS.md`, `docs/MEAL_IMAGE_PROMPTS.md` | In-app imagery prompt libraries — same prompt-discipline lessons apply. |

### Tooling — the pipeline and validator

| File | What it contains |
| --- | --- |
| `tool/playstore_asset_pipeline.py` | The repair → canvas → encode pipeline. Every `fix_*` function documents the defect it repairs and why the technique suits it. Contains the `inpaint` / `extrapolate_up` / `render_fit` helpers and the `selfcheck()` assertions. |
| `tool/validate_play_assets.py` | Independent conformance validator — 131 assertions over format, alpha, dimensions, ratio, size, PNG chunks, counts, slot ordering, promotion eligibility, locale parity and duplicates. `--json` for CI. |
| `tool/README_play_assets.md` | Sudo-free toolchain setup, the rationale for each tool (including why pngquant is installed and deliberately unused), and how to add a repair. |
| `tool/format_play_store_assets.py` | The earlier asset formatter — resize/crop to Play targets with palette quantisation as a size fallback. Predates the pipeline above; useful as a simpler reference. |

### Play Console preparation

| File | What it contains |
| --- | --- |
| `PLAY_CONSOLE_PRODUCTION_GUIDE.md` | Step-by-step Console walkthrough: pre-flight, store listing, App content compliance section, monetisation, countries and pricing, testing, creating the production release, post-submission watch, rollout expansion, emergency rollback, and a final pre-submission checklist. |
| `docs/store/PLAY_CONSOLE_ANSWERS.md` | Pre-written answers for the Console declaration forms. |
| `docs/store/LISTING_EN.md`, `docs/store/LISTING_TR.md` | Per-locale listing copy. |
| `docs/store/PRICING_SETUP.md` | Subscription product and pricing configuration. |
| `docs/store/APP_STORE_ANSWERS.md` | App Store equivalents, for cross-platform releases. |
| `FINAL_STORE_SUBMISSION_CHECKLIST.md`, `FINAL_STORE_SUBMISSION_ROADMAP.md` | Submission checklist and sequencing. |
| `FOUNDER_ACTIONS_TODO.md`, `EXTERNAL_ACTION_LEDGER.md` | The running separation of founder-owned from engineering-owned work — the model §13 generalises. |
| `docs/STORE_LAUNCH_REPORT.md`, `docs/MASTER_LAUNCH_ROADMAP.md` | Launch sequencing context. |

### Source files used as ground truth during the audits

These are the specific files the audits grepped. They are listed because
*which* files answer *which* question is itself the reusable lesson (§7).

| Question | File |
| --- | --- |
| Is the AI coach on-device or server-side? | `lib/features/coach/domain/coach_brain.dart`, `lib/features/coach/domain/llm_coach_brain.dart` |
| What does the community feed actually render? | `lib/features/community/presentation/squad_feed_screen.dart` |
| What is the squad member cap? | `lib/features/community/domain/models/community_models.dart` |
| Is the form score real? | `lib/features/video_analysis/domain/form_score.dart` |
| Does the app compute burned calories? | grep `caloriesBurned` across `lib/` — zero matches |
| What are the real navigation labels? | `lib/l10n/app_en.arb`, `lib/l10n/app_tr.arb` (`nav*` keys) |
| What does the app itself say about privacy? | `lib/l10n/app_localizations_en.dart` — the camera/servers split string |
| Are trial claims safe? | `lib/features/monetization/presentation/paywall_screen.dart` |
| Does the app support tablets? | grep for width breakpoints — only `lib/features/admin/presentation/admin_dashboard_screen.dart` |
| How many recipes ship? | `assets/meals` |

### Note on asset storage

`playstore-new-ASO/` is gitignored — roughly 30 MB of PNG in a public
repository. The **scripts** are versioned; the **binaries** are not. Re-run
`tool/playstore_asset_pipeline.py` to regenerate the upload set on any machine.
Future projects should adopt the same split.

---

*Compiled from the FormAI Google Play production preparation, July–August 2026.
Every finding, file path and code reference above was verified against the
repository at the time of writing. Nothing in this document is hypothetical.*
