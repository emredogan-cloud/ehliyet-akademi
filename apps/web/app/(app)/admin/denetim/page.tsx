'use client';

import { useEffect, useState } from 'react';

interface Log {
  id: string;
  userId: string;
  action: string;
  entity: string;
  entityId: string;
  at: string;
}

export default function AdminAudit() {
  const [rows, setRows] = useState<Log[] | null>(null);

  useEffect(() => {
    void fetch('/api/admin/audit', { credentials: 'same-origin' })
      .then((r) => (r.ok ? r.json() : { items: [] }))
      .then((d: { items: Log[] }) => setRows(d.items));
  }, []);

  return (
    <div>
      <h1 style={{ margin: '0 0 4px' }}>Denetim Kaydı</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        Tüm ayrıcalıklı işlemlerin değiştirilemez izi (ROADMAP Faz 25/30).
      </p>
      {!rows ? (
        <div className="skeleton" style={{ height: 200 }} />
      ) : rows.length === 0 ? (
        <div className="card">
          <p style={{ margin: 0 }}>Henüz kayıt yok.</p>
        </div>
      ) : (
        <div className="table-wrap">
          <table className="tbl" data-testid="audit-table">
            <thead>
              <tr>
                <th>İşlem</th>
                <th>Varlık</th>
                <th>Zaman</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((l) => (
                <tr key={l.id}>
                  <td>
                    <span className="pill">{l.action}</span>
                  </td>
                  <td className="muted">
                    {l.entity}/{l.entityId.slice(0, 8)}
                  </td>
                  <td className="muted">{new Date(l.at).toLocaleString('tr-TR')}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
