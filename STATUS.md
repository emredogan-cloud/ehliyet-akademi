# STATUS

> Her ~3 fazda bir güncellenir. Tek doğru kaynak: üst dizindeki `ROADMAP.md` (v3.1, Faz 0–35).

_Son güncelleme: 2026-07-14 · Faz 0 sonu_

### Yaptım

- **Faz 0 — Mühendislik Temeli & DevOps ✅**
  - Monorepo (pnpm workspace + turbo), TS strict taban, ESLint(flat)+Prettier.
  - `pnpm gates` = verify(placeholder/sır taraması) + lint + format + typecheck + test + build — **yerelde yeşil**.
  - GitHub Actions: CI (quality/e2e-koşullu/gitleaks/commitlint) + CodeQL (public olunca aktif) + Dependabot + Changesets.
  - Yönetişim: LICENSE(proprietary), SECURITY, CONTRIBUTING(trunk-based+Conventional Commits), CODEOWNERS, PR/issue şablonları.
  - GitHub private repo: `emredogan-cloud/ehliyet-akademi` → main push'landı.

### Yapıyorum

- Faz 1–3: Vizyon/Araştırma referansları + Mimari ADR'leri (`docs/adr`).

### Yapacağım

- Faz 4: Next.js göçü + auth + DB omurgası (+ Faz 26/27 paralel temeli); v1 içerik portu; tanı denemesi → hazırlık skoru.
- Sonrası: ROADMAP sırasıyla Faz 5→35.

### Engeller / Riskler

- ⛔ **GitHub Actions faturalandırma kilidi (dış engel):** hesapta "payment failed / spending limit" nedeniyle private repo'da Actions **başlamıyor**. Geliştirme durmadı — CI kapılarının birebir yereli (`pnpm gates` + e2e) her faz sonunda çalıştırılıyor; workflow'lar repoda hazır. **Çözüm sahibi kullanıcı:** GitHub Billing'i düzeltmek **veya** repo'yu public yapmak (Actions ücretsizleşir + CodeQL açılır). Dependabot PR'ları da aynı sebeple CI'sız bekliyor.
- Branch protection: private+free planda API kısıtlı olabilir — denenecek; olmazsa trunk-based disiplin + yerel kapılar.
