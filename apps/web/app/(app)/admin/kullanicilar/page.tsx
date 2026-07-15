'use client';

import { useCallback, useEffect, useState } from 'react';

interface U {
  id: string;
  email: string;
  name: string;
  role: string;
  createdAt: string;
}

export default function AdminUsers() {
  const [rows, setRows] = useState<U[] | null>(null);
  const [msg, setMsg] = useState('');
  const [err, setErr] = useState('');

  const load = useCallback(async () => {
    const r = await fetch('/api/admin/users', { credentials: 'same-origin' });
    if (r.ok) setRows(((await r.json()) as { items: U[] }).items);
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  async function setRole(userId: string, role: string) {
    setErr('');
    setMsg('');
    const r = await fetch('/api/admin/users', {
      method: 'PUT',
      headers: { 'content-type': 'application/json' },
      credentials: 'same-origin',
      body: JSON.stringify({ userId, role }),
    });
    if (r.ok) {
      setMsg('Rol güncellendi.');
      await load();
    } else {
      setErr(((await r.json()) as { error?: string }).error ?? 'Güncellenemedi.');
    }
  }

  return (
    <div>
      <h1 style={{ margin: '0 0 4px' }}>Kullanıcılar</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        Rol yönetimi (user / editor / admin). Kendi admin yetkini düşüremezsin.
      </p>
      {msg && (
        <div className="explain" role="status">
          {msg}
        </div>
      )}
      {err && (
        <div className="explain" role="alert" style={{ borderColor: 'var(--red)' }}>
          {err}
        </div>
      )}
      {!rows ? (
        <div className="skeleton" style={{ height: 200 }} />
      ) : (
        <div className="table-wrap">
          <table className="tbl" data-testid="users-table">
            <thead>
              <tr>
                <th>Kullanıcı</th>
                <th>Rol</th>
                <th>Kayıt</th>
                <th>İşlem</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((u) => (
                <tr key={u.id}>
                  <td>
                    <strong>{u.name || '—'}</strong>
                    <div className="muted" style={{ fontSize: '0.8rem' }}>
                      {u.email}
                    </div>
                  </td>
                  <td>
                    <span className="pill">{u.role}</span>
                  </td>
                  <td className="muted">{new Date(u.createdAt).toLocaleDateString('tr-TR')}</td>
                  <td>
                    <select
                      value={u.role}
                      onChange={(e) => setRole(u.id, e.target.value)}
                      aria-label={`${u.email} rolü`}
                      data-testid={`role-${u.email}`}
                    >
                      <option value="user">user</option>
                      <option value="editor">editor</option>
                      <option value="admin">admin</option>
                    </select>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
