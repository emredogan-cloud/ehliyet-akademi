/**
 * CompareTable — ders içi karşılaştırma tablosu (Program 1 · Bölüm D).
 * "X vs Y" türü ayrımları (DUR/Yol Ver, ABS var/yok, kısa/uzun far) görselleştirir.
 * İlk sütun satır etiketidir; kalan sütunlar karşılaştırılan seçenekler. Tema-uyumlu.
 */
import type { CompareTable as CompareData } from '@ea/content-schema';

/** Basit **kalın** işaretlemesini <strong>'a çevirir. */
function mdBold(s: string): string {
  const escaped = s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  return escaped.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
}

export function CompareTable({ caption, headers, rows }: CompareData) {
  return (
    <div className="cmp-wrap">
      <table className="cmp" role="table">
        {caption && <caption className="cmp__cap">{caption}</caption>}
        <thead>
          <tr>
            {headers.map((h, i) => (
              <th key={i} scope="col" className={i === 0 ? 'cmp__rowhead' : undefined}>
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, r) => (
            <tr key={r}>
              {row.map((cell, c) =>
                c === 0 ? (
                  <th key={c} scope="row" className="cmp__rowhead">
                    {cell}
                  </th>
                ) : (
                  <td key={c} dangerouslySetInnerHTML={{ __html: mdBold(cell) }} />
                ),
              )}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
