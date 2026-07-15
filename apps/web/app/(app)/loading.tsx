/** Uygulama kabuğu yükleme iskeleti (Sprint 5 · streaming) — anlık algılanan performans. */
export default function AppLoading() {
  return (
    <div aria-busy="true" aria-label="Yükleniyor" style={{ maxWidth: 760, margin: '0 auto' }}>
      <div className="skeleton" style={{ width: '40%', height: 28, marginTop: 24 }} />
      <div className="skeleton" style={{ width: '85%', height: 16, marginTop: 14 }} />
      <div className="skeleton" style={{ width: '70%', height: 16, marginTop: 8 }} />
      <div className="card" style={{ marginTop: 20 }}>
        <div className="skeleton" style={{ width: '50%', height: 18 }} />
        <div className="skeleton" style={{ width: '90%', height: 14, marginTop: 12 }} />
        <div className="skeleton" style={{ width: '80%', height: 14, marginTop: 8 }} />
      </div>
    </div>
  );
}
