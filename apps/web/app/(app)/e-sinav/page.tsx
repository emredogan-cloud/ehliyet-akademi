import type { Metadata } from 'next';
import { EXAM_BLUEPRINT, SUBJECT_LABEL, THEORY_SUBJECTS } from '@ea/content-schema';
import { subjectCounts } from '@ea/question-bank';
import { PageHeader } from '@/components/ui/layout';

export const metadata: Metadata = {
  title: 'e-Sınav Hazırlık',
  description:
    'Teorik e-Sınav dersleri ve deneme: trafik ve çevre, ilk yardım, araç tekniği, trafik adabı.',
};

const THEORY = THEORY_SUBJECTS;

export default function ESinavPage() {
  const counts = subjectCounts();
  return (
    <>
      <PageHeader
        title="Teorik e-Sınav"
        emoji="📝"
        subtitle={
          <>
            Gerçek sınav: {EXAM_BLUEPRINT.totalQuestions} soru · {EXAM_BLUEPRINT.durationMinutes} dk
            · geçmek için {EXAM_BLUEPRINT.passCorrect} doğru. Bu bir{' '}
            <em>resmî MEB sınavı değildir</em>; gerçek sınav formatında denemedir.
          </>
        }
      />
      <div className="grid">
        {THEORY.map((s) => (
          <div className="card" key={s}>
            <span className="badge">{EXAM_BLUEPRINT.distribution[s]} soru</span>
            <h3 style={{ margin: '10px 0 6px' }}>{SUBJECT_LABEL[s]}</h3>
            <p className="muted" style={{ margin: 0 }}>
              Bankada {counts[s] ?? 0} özgün soru hazır.
            </p>
          </div>
        ))}
      </div>
      <div style={{ marginTop: 20 }}>
        <a className="btn" href="/tani">
          Tanı denemesiyle başla →
        </a>
      </div>
    </>
  );
}
