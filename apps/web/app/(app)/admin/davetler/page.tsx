'use client';

import { useEffect, useState } from 'react';
import { PageHeader } from '@/components/ui/layout';

/**
 * Beta Faz 8 — davet yönetimi ekranı.
 *
 * `/api/admin/referrals` Faz 8'de (önceki sprint) yazılmıştı ama ONU KULLANAN BİR EKRAN YOKTU:
 * sahte bir daveti iptal etmenin tek yolu elle API çağırmaktı. Bir yönetim yeteneği, yüzeyi
 * olmadan var sayılmaz.
 */

interface Row {
  id: string;
  status: string;
  code: string;
  createdAt: string;
  qualifiedAt: string | null;
  referrerEmail: string;
  referredEmail: string;
}

const STATUS_LABEL: Record<string, string> = {
  pending: 'Bekliyor',
  qualified: 'Nitelikli',
  void: 'İptal',
};

export default function AdminReferrals() {
  const [rows, setRows] = useState<Row[] | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  const [msg, setMsg] = useState('');

  const load = () =>
    fetch('/api/admin/referrals', { credentials: 'same-origin' })
      .then((r) => (r.ok ? r.json() : { referrals: [] }))
      .then((d: { referrals: Row[] }) => setRows(d.referrals));

  useEffect(() => {
    void load();
  }, []);

  async function voidOne(id: string) {
    setBusy(id);
    setMsg('');
    const res = await fetch('/api/admin/referrals', {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ referralId: id, reason: 'admin-panel' }),
    });
    setBusy(null);
    setMsg(res.ok ? 'Davet iptal edildi.' : 'İptal edilemedi.');
    if (res.ok) await load();
  }

  return (
    <div>
      <PageHeader
        title="Davetler"
        emoji="🎁"
        subtitle="Davet ilişkilerini görüntüle ve sahte olanları iptal et."
      />

      {msg && (
        <div className="explain" role="status">
          {msg}
        </div>
      )}

      {/* Ödül GERİ ALINMAZ ve bu bilinçli. Verilmiş bir erişimi geri çekmek iyi niyetli
          kullanıcıyı da vurur; iptal yalnız GELECEKTEKİ basamak sayımını düşürür. */}
      <div className="explain">
        İptal, daveti ödül sayımından düşürür. <strong>Verilmiş ödüller geri alınmaz</strong> — bu,
        iyi niyetli kullanıcıyı da vurabilecek bir işlem olduğu için elle karar gerektirir.
      </div>

      {!rows ? (
        <div className="skeleton" style={{ height: 200 }} />
      ) : rows.length === 0 ? (
        <div className="card">
          <p style={{ margin: 0 }}>Henüz davet yok.</p>
        </div>
      ) : (
        <div className="table-wrap">
          <table className="tbl" data-testid="referrals-table">
            <thead>
              <tr>
                <th>Durum</th>
                <th>Kod</th>
                <th>Davet eden</th>
                <th>Davet edilen</th>
                <th>Tarih</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.id}>
                  <td>{STATUS_LABEL[r.status] ?? r.status}</td>
                  <td>{r.code}</td>
                  <td>{r.referrerEmail}</td>
                  <td>{r.referredEmail}</td>
                  <td className="muted">{new Date(r.createdAt).toLocaleDateString('tr-TR')}</td>
                  <td>
                    {r.status !== 'void' && (
                      <button
                        type="button"
                        className="ui-btn ui-btn--ghost ui-btn--sm"
                        disabled={busy === r.id}
                        onClick={() => void voidOne(r.id)}
                      >
                        {busy === r.id ? '…' : 'İptal et'}
                      </button>
                    )}
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
