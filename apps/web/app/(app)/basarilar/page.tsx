'use client';

import { useEffect, useState } from 'react';
import { computeAchievements, type Achievement } from '@/lib/achievements';
import { loadAnswers, loadStreak } from '@/lib/progress';
import { loadEntitlements } from '@/lib/payments';
import { PageHeader } from '@/components/ui/layout';

export default function BasarilarPage() {
  const [list, setList] = useState<Achievement[] | null>(null);

  useEffect(() => {
    const answers = loadAnswers();
    const s = loadStreak();
    setList(
      computeAchievements({
        streakCurrent: s.current,
        streakBest: s.best,
        totalAnswers: answers.length,
        correctAnswers: answers.filter((a) => a.correct).length,
        examsFinished: 0,
        packsOwned: loadEntitlements().length,
      })
    );
  }, []);

  return (
    <>
      <PageHeader
        title="Başarılar"
        emoji="🏆"
        subtitle="Çalıştıkça rozetler açılır — hepsi kutlama, hiçbiri baskı."
      />
      {!list ? (
        <div className="grid" aria-busy="true">
          {[1, 2, 3].map((k) => (
            <div key={k} className="card">
              <div className="skeleton" style={{ width: '50%', height: 20 }} />
            </div>
          ))}
        </div>
      ) : (
        <div className="grid" data-testid="achievements">
          {list.map((a) => (
            <div
              key={a.id}
              className="card"
              style={a.earned ? undefined : { opacity: 0.55, filter: 'grayscale(0.6)' }}
              data-testid={a.earned ? 'ach-earned' : 'ach-locked'}
            >
              <div style={{ fontSize: '1.8rem' }}>{a.icon}</div>
              <h3 style={{ margin: '6px 0 2px' }}>{a.title}</h3>
              <p className="muted" style={{ margin: 0 }}>
                {a.desc}
              </p>
              {a.earned && (
                <span className="badge" style={{ marginTop: 8 }}>
                  ✓ Kazanıldı
                </span>
              )}
            </div>
          ))}
        </div>
      )}
    </>
  );
}
