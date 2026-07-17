'use client';

/** Arama (Faz 28): SearchProvider soyutlaması üzerinden — Meili/Typesense/Algolia takılabilir. */
import { useEffect, useMemo, useState } from 'react';
import { getSearchProvider, type SearchHit } from '@/lib/search';
import { PageHeader } from '@/components/ui/layout';
import { Card, Badge, Button, Chip, IconBadge, type Accent } from '@/components/ui/primitives';
import { QuizLayout, QuizPanel, HintCard } from '@/components/ui/quiz';
import { Icon } from '@/components/ui/icons';

/** Sonuç türü → rozet etiketi/aksanı (lib/search SearchHit.type alanından). */
const TYPE_LABEL: Record<string, string> = {
  lesson: 'Ders',
  question: 'Soru',
  article: 'Makale',
};
const TYPE_ACCENT: Record<string, Accent> = {
  lesson: 'blue',
  question: 'amber',
  article: 'purple',
};

/** Gerçek içerikten türetilmiş sabit örnek sorgular (analitik verisi yok — öneridir). */
const SUGGESTIONS = ['hız', 'kavşak', 'park', 'dur', 'ilk yardım', 'emniyet kemeri'];

export default function AramaPage() {
  const [q, setQ] = useState('');
  const [hits, setHits] = useState<SearchHit[]>([]);
  const provider = useMemo(() => getSearchProvider(), []);

  useEffect(() => {
    let alive = true;
    if (q.trim().length < 2) {
      setHits([]);
      return;
    }
    void provider.search(q).then((h) => {
      if (alive) setHits(h);
    });
    return () => {
      alive = false;
    };
  }, [q, provider]);

  const empty = q.trim().length >= 2 && hits.length === 0;

  return (
    <>
      <PageHeader
        title="Arama"
        emoji="🔍"
        subtitle={<>Ders ve soru bankasında anında ara. (Sağlayıcı: {provider.name})</>}
      />
      <QuizLayout
        main={
          <>
            <div className="search-box" style={{ maxWidth: 'none' }}>
              <span className="search-box__icon" aria-hidden>
                <Icon name="search" size={20} />
              </span>
              <input
                className="ui-input search-box__input"
                value={q}
                onChange={(e) => setQ(e.target.value)}
                placeholder="örn. hız sınırı, kalp masajı, DUR levhası…"
                aria-label="Arama"
                data-testid="search-input"
                autoFocus
              />
            </div>

            {empty && (
              <Card style={{ marginTop: 'var(--sp-4)' }} data-testid="search-empty">
                <p style={{ margin: 0 }}>&quot;{q}&quot; için sonuç yok. Farklı bir kelime dene.</p>
              </Card>
            )}

            {hits.length > 0 && (
              <>
                <h2
                  className="section__title"
                  style={{ margin: 'var(--sp-4) 0 var(--sp-3)', fontSize: 'var(--fs-md)' }}
                >
                  Arama sonuçları ({hits.length} sonuç)
                </h2>
                <div style={{ display: 'grid', gap: 'var(--sp-3)' }} data-testid="search-results">
                  {hits.map((h) => (
                    <Card
                      key={h.type + h.id}
                      as="a"
                      href={h.href}
                      interactive
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 'var(--sp-4)',
                      }}
                    >
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: 'var(--sp-2)',
                            flexWrap: 'wrap',
                          }}
                        >
                          <Badge accent={TYPE_ACCENT[h.type] ?? 'teal'}>
                            {TYPE_LABEL[h.type] ?? h.type}
                          </Badge>
                          <strong style={{ fontSize: 'var(--fs-md)' }}>{h.title}</strong>
                        </div>
                        <p
                          className="muted"
                          style={{ margin: 'var(--sp-1) 0 0', fontSize: 'var(--fs-sm)' }}
                        >
                          {h.snippet}
                        </p>
                      </div>
                      <span style={{ color: 'var(--text-3)', flex: '0 0 auto' }} aria-hidden>
                        <Icon name="chevron-right" size={18} />
                      </span>
                    </Card>
                  ))}
                </div>
              </>
            )}
          </>
        }
        aside={
          <>
            <HintCard>
              En az 2 harf yazman yeterli. Türkçe karakter farkı sorun değil — &quot;donus&quot;
              yazsan da &quot;dönüş&quot; içeriklerini bulur.
            </HintCard>
            <QuizPanel title="Önerilen aramalar" icon="search">
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--sp-2)' }}>
                {SUGGESTIONS.map((term) => (
                  <Chip key={term} active={q === term} onClick={() => setQ(term)}>
                    {term}
                  </Chip>
                ))}
              </div>
            </QuizPanel>
            <Card>
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 'var(--sp-3)',
                  marginBottom: 'var(--sp-3)',
                }}
              >
                <IconBadge accent="teal" size="md">
                  <Icon name="bot" size={20} />
                </IconBadge>
                <strong>Aradığını bulamadın mı?</strong>
              </div>
              <p className="muted" style={{ margin: '0 0 var(--sp-3)', fontSize: 'var(--fs-sm)' }}>
                AI Koç&apos;a sor — sana en uygun içeriği bulmana yardımcı olur.
              </p>
              <Button variant="primary" full href="/ai-koc">
                AI Koç&apos;a Sor
                <Icon name="chevron-right" size={16} />
              </Button>
            </Card>
          </>
        }
      />
    </>
  );
}
