# AI Coach — Mobile Behavior Specification

**Ehliyet Akademi · The AI as a proactive assistant, not a chatbot**
_Prepared: 2026-07-23 · Planning document. Parent: `MOBILE_APP_MASTERPLAN.md`._

The web AI is a **grounded** Q&A coach (server-side Anthropic, scoped to Turkish B-class driving,
refuses off-domain, defers exact regulations to MEB/MTSK). On mobile it becomes a **proactive
companion** that participates throughout the app. The design principle:

> **Deterministic brain, natural voice.** A rule engine driven by real QIP/progress data decides
> _what to say and when_; the LLM is used for the _chat_ and for occasionally phrasing a summary
> — never to invent facts. This keeps it cheap, safe (no hallucinated rules), and instant.

---

## 1. Two layers

1. **Nudge Engine (deterministic, server-side).** Consumes existing signals — `weakTopicsFrom`
   (adaptive), readiness/traffic-light (srs-engine), `analyticsSummary`, families, streak, exam
   history, entitlements, exam-date (from onboarding) — and emits **typed nudges** with a priority
   score. No LLM needed; fully testable; zero hallucination. Runs on a schedule (server) and
   on-demand (app open).
2. **Conversational AI (LLM, existing `/api/ai/ask`).** The chat, reused as-is: grounded answers +
   copy/regenerate/persistence. On mobile it also accepts **context** (the screen/question the user
   is on) so "Bunu açıkla" works from anywhere.

The LLM may _rephrase_ a deterministic nudge into a warmer sentence (optional, cached, capped), but
the **decision and any numbers come from the engine**, not the model.

---

## 2. Nudge catalog (typed, data-driven)

Each nudge = `{ id, type, priority, title, body, action(deeplink), trigger, channel }`. Channels:
`home-card`, `in-app-bubble`, `push`, `coach-inbox`.

| Type                       | Trigger (from real data)                      | Example (voice)                                                              | Action               |
| -------------------------- | --------------------------------------------- | ---------------------------------------------------------------------------- | -------------------- |
| **welcome**                | first open of day / after onboarding          | "Günaydın! Bugün 15 dk çalışsak sınava bir adım daha yaklaşırsın."           | open plan            |
| **daily-motivation**       | daily, streak-aware                           | "3 günlük serin var 🔥 Bugün de devam?"                                      | practice             |
| **weak-topic**             | `weakTopicsFrom` mastery < 0.7                | "'Işıklı işaretler'de %55 başarındasın. 5 soruyla toparlayalım mı?"          | targeted practice    |
| **study-reminder**         | user's chosen time, if inactive               | "Çalışma vaktin geldi — kısa bir tekrar?"                                    | due SRS cards        |
| **recommendation**         | after activity / family variants              | "Bu konuyu kavradın — sıradaki: 'Takip mesafesi'."                           | next lesson/practice |
| **progress-summary**       | weekly / after N activities                   | "Bu hafta 120 soru, %78 doğruluk, +2 hazır konu."                            | progress             |
| **exam-readiness**         | readiness computation                         | "Genel hazırlığın %82 — deneme sınavına hazırsın."                           | dynamic exam         |
| **exam-countdown**         | exam-date set                                 | "Sınavına 9 gün kaldı. Planında bugün 2 görev var."                          | plan                 |
| **streak-protection**      | streak at risk (day nearly over, no activity) | "Serini kaybetme! 3 soru yeter."                                             | quick practice       |
| **achievement**            | badge/tier unlocked (gamification)            | "🏅 '100 Soru' rozetini açtın!"                                              | achievements         |
| **premium-recommendation** | free AI/exam quota hit, high engagement       | "Bugünkü 5 AI hakkını kullandın. Sınırsız için Premium?" (honest, not naggy) | paywall              |
| **contextual-tip**         | on a screen (sign detail, exam result)        | "İpucu: Kırmızı üçgen = tehlike uyarısı."                                    | inline               |

Priority ordering ensures **one primary nudge on home** at a time (avoid clutter); the rest live in
a "Koç" inbox.

---

## 3. Where the AI appears

- **Home:** one proactive card (highest-priority nudge).
- **AI Koç tab:** chat + a stream of recent nudges + suggestion chips ("Zayıf konum ne?", "Sınava
  hazır mıyım?", "Bugün ne çalışayım?") that are answered by the **engine** (deterministic) when
  possible, LLM when open-ended.
- **Contextual bubbles:** after an exam ("Sonucunu yorumlayayım mı?"), on a hard question
  ("Açıkla"), on a sign ("Bu levhayı sor").
- **Push:** the subset of nudges the user opted into (see §4).
- **Celebrations:** achievement/exam-pass moments get a coach reaction + confetti + haptic.

---

## 4. Notification strategy (intelligent, contextual, respectful)

### Categories (user-togglable, granular)

`Günlük hatırlatma` · `Zayıf konu` · `Sınav geri sayımı` · `Seri koruma` · `Başarı` · `Yeni deneme` ·
`İlerleme özeti` · `AI önerisi`. Each maps to nudge types above.

### Rules

- **Opt-in, contextual permission prompt** (after the user sees value, not on cold start).
- **Frequency cap:** max 1–2 push/day default; hard daily ceiling; category budgets.
- **Quiet hours:** default 22:00–08:00; user-adjustable; timezone-aware.
- **Relevance gating:** only send if the trigger is real (e.g., streak-protection only when the
  streak truly is at risk and the user is inactive). No filler.
- **Smart timing:** learn the user's active window from activity timestamps (analytics `at`); send
  study reminders near it.
- **Dedupe & decay:** don't repeat the same nudge; back off if ignored repeatedly.

### Delivery

- **FCM (Android + iOS via APNs).** (This is a strong argument for Flutter/Capacitor over pure PWA,
  whose iOS push is limited.)
- **Scheduling:** deterministic nudges computed server-side (cron) → push; plus **local
  notifications** scheduled on-device for time-based reminders (study time, quiet-hours-safe) so they
  fire even offline.
- **Deep links:** every push targets an exact screen.

---

## 5. Data the engine already has (reuse)

- **Weak topics / mastery:** `weakTopicsFrom(answers)`, `analyticsSummary` (per-topic mastery).
- **Readiness / traffic light:** `srs-engine` `computeReadiness`.
- **Due reviews:** SRS card due dates.
- **Streak & counters:** `ea:streak`, `ea:counters`.
- **Families / recommendations:** `familyVariants`, `relatedContent`, `adaptiveSelect`.
- **Exam readiness:** dynamic-exam scoring history + readiness.
- **Entitlements / quota:** `remainingFreeAI`, exam quota, `hasCapability`.
- **Exam date:** captured at onboarding.

→ The nudge engine is mostly **assembly of signals that already exist** — low build cost, high value.

---

## 6. Guardrails

- **Grounding preserved:** the LLM chat keeps the existing scope (Turkish B-class only, refuse
  off-domain, defer exact regulations to MEB/MTSK, disclaimer). No change to safety posture.
- **No fabricated numbers:** every stat in a nudge comes from measured data.
- **Cost control:** deterministic nudges are free (no LLM); LLM used for chat + optional phrasing
  with per-user caps + caching; fall back to templated copy if the model is unavailable.
- **Privacy:** progress data stays the user's; on-device where possible; server nudge computation
  uses the user's own data only.
- **Tone:** encouraging, concise, Turkish, never guilt-tripping; premium prompts are honest and rare.

---

## 7. Architecture summary

```
[QIP/progress signals]──►[Nudge Engine (deterministic, server)]──►[typed nudges + priority]
                                                     │
              ┌──────────────────────────────────────┼───────────────────────────┐
              ▼                                        ▼                           ▼
        home-card / coach-inbox (app fetch)     FCM push (opted-in, capped)   local notif (on-device schedule)

[User chat]──►[/api/ai/ask (LLM, grounded)]──►answer (+context aware)
```

- New API: `GET /api/coach/nudges` (per-user, deterministic) + `POST /api/coach/ack` (dismiss/act).
- Reuse: `/api/ai/ask` (add optional `context`).
- On-device: notification scheduler, quiet-hours, category prefs, permission flow.

The AI is what makes the app feel _premium and alive_. Build the deterministic engine in Phase 4;
it's the differentiator and it's cheap because the signals already exist.
