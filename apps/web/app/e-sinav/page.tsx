import type { Metadata } from 'next';
import { EXAM_BLUEPRINT, SUBJECT_LABEL, THEORY_SUBJECTS } from '@ea/content-schema';
import { subjectCounts } from '@ea/question-bank';

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
      <h1 style={{ margin: '24px 0 6px' }}>Teorik e-Sınav</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        Gerçek sınav: {EXAM_BLUEPRINT.totalQuestions} soru · {EXAM_BLUEPRINT.durationMinutes} dk ·
        geçmek için {EXAM_BLUEPRINT.passCorrect} doğru. Bu bir <em>resmî MEB sınavı değildir</em>;
        gerçek sınav formatında denemedir.
      </p>
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
