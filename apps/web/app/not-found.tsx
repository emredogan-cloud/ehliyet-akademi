/** 404 (Sprint 4) — bulunamayan sayfa için dostane yönlendirme. */
export default function NotFound() {
  return (
    <div className="container" style={{ padding: '48px 16px', maxWidth: 560 }}>
      <div className="card" data-testid="not-found">
        {/* Üretilmiş 404 illüstrasyonu (ASSET A15) */}
        <img src="/assets/ui/error-404.webp" alt="" className="nf-art" aria-hidden />
        <h1 style={{ margin: '8px 0' }}>Sayfa bulunamadı</h1>
        <p className="muted">Aradığın sayfa taşınmış veya hiç var olmamış olabilir.</p>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', marginTop: 8 }}>
          <a className="btn" href="/panel">
            Panele git
          </a>
          <a className="btn btn--ghost" href="/dersler">
            Derslere göz at
          </a>
        </div>
      </div>
    </div>
  );
}
