'use client';
/**
 * VideoPlayer — self-host video öğrenme oynatıcısı (Program 2 · Faz 4 · ADR-013).
 * Native <video> + bölümler + senkron transkript + yer imleri (localStorage) + hız +
 * WebVTT altyazı + klavye kısayolları (boşluk, ←/→ 5 sn). Üçüncü taraf isteği yok.
 */
import { useEffect, useRef, useState } from 'react';
import { videoById, summarizeTranscript } from '@/content/videos';

const BM_KEY = 'ea:videoBookmarks:v1';

type Bookmarks = Record<string, number[]>;

function loadBookmarks(): Bookmarks {
  if (typeof localStorage === 'undefined') return {};
  try {
    return JSON.parse(localStorage.getItem(BM_KEY) ?? '{}') as Bookmarks;
  } catch {
    return {};
  }
}

function fmt(t: number): string {
  const m = Math.floor(t / 60);
  const s = Math.floor(t % 60);
  return `${m}:${String(s).padStart(2, '0')}`;
}

export function VideoPlayer({ videoId }: { videoId: string }) {
  const v = videoById(videoId);
  const ref = useRef<HTMLVideoElement>(null);
  const [time, setTime] = useState(0);
  const [rate, setRate] = useState(1);
  const [marks, setMarks] = useState<number[]>([]);

  useEffect(() => {
    setMarks(loadBookmarks()[videoId] ?? []);
  }, [videoId]);

  if (!v || v.status !== 'available' || !v.src) return null;

  const seek = (t: number) => {
    const el = ref.current;
    if (!el) return;
    el.currentTime = t;
    void el.play();
  };

  const addBookmark = () => {
    const t = Math.round((ref.current?.currentTime ?? 0) * 10) / 10;
    const next = [...new Set([...marks, t])].sort((a, b) => a - b);
    setMarks(next);
    const all = loadBookmarks();
    all[videoId] = next;
    localStorage.setItem(BM_KEY, JSON.stringify(all));
  };

  const onKey = (e: React.KeyboardEvent) => {
    const el = ref.current;
    if (!el) return;
    if (e.key === ' ') {
      e.preventDefault();
      if (el.paused) void el.play();
      else el.pause();
    } else if (e.key === 'ArrowRight') {
      el.currentTime = Math.min(el.duration || 0, el.currentTime + 5);
    } else if (e.key === 'ArrowLeft') {
      el.currentTime = Math.max(0, el.currentTime - 5);
    }
  };

  const activeCue = v.transcript ? [...v.transcript].reverse().find((c) => time >= c.t) : undefined;
  const summary = summarizeTranscript(v);

  return (
    <div className="vplayer" data-testid={`video-${v.id}`} onKeyDown={onKey}>
      <video
        ref={ref}
        poster={v.poster}
        controls
        playsInline
        preload="metadata"
        className="vplayer__video"
        onTimeUpdate={(e) => setTime(e.currentTarget.currentTime)}
        onRateChange={(e) => setRate(e.currentTarget.playbackRate)}
        aria-label={v.title}
      >
        {v.srcWebm && <source src={v.srcWebm} type="video/webm" />}
        <source src={v.src} type="video/mp4" />
        {v.captions && (
          <track kind="captions" src={v.captions} srcLang="tr" label="Türkçe" default />
        )}
      </video>

      <div className="vplayer__bar">
        {v.chapters && (
          <div className="vplayer__chapters" role="group" aria-label="Bölümler">
            {v.chapters.map((c) => (
              <button
                key={c.t}
                type="button"
                className="chip"
                onClick={() => seek(c.t)}
                data-testid="video-chapter"
              >
                {fmt(c.t)} · {c.title}
              </button>
            ))}
          </div>
        )}
        <div className="vplayer__tools">
          <label className="muted" style={{ fontSize: '0.8rem' }}>
            Hız{' '}
            <select
              value={rate}
              onChange={(e) => {
                const r = Number(e.target.value);
                setRate(r);
                if (ref.current) ref.current.playbackRate = r;
              }}
              aria-label="Oynatma hızı"
            >
              {[0.75, 1, 1.25, 1.5].map((r) => (
                <option key={r} value={r}>
                  {r}×
                </option>
              ))}
            </select>
          </label>
          <button
            type="button"
            className="btn btn--ghost vplayer__bm"
            onClick={addBookmark}
            data-testid="video-bookmark"
          >
            🔖 Yer imi ekle ({fmt(time)})
          </button>
        </div>
      </div>

      {marks.length > 0 && (
        <div className="vplayer__marks" data-testid="video-bookmarks">
          <span className="muted" style={{ fontSize: '0.8rem' }}>
            Yer imleri:
          </span>
          {marks.map((t) => (
            <button key={t} type="button" className="chip" onClick={() => seek(t)}>
              {fmt(t)}
            </button>
          ))}
        </div>
      )}

      {v.transcript && (
        <div className="vplayer__transcript" data-testid="video-transcript">
          <strong style={{ fontSize: '0.9rem' }}>Transkript</strong>
          <ul>
            {v.transcript.map((c) => (
              <li key={c.t} className={activeCue?.t === c.t ? 'vplayer__cue--on' : undefined}>
                <button type="button" onClick={() => seek(c.t)}>
                  <span className="muted">{fmt(c.t)}</span> {c.text}
                </button>
              </li>
            ))}
          </ul>
        </div>
      )}

      {summary.length > 0 && (
        <div className="vplayer__summary" data-testid="video-summary">
          <strong style={{ fontSize: '0.9rem' }}>🤖 Özet (transkriptten)</strong>
          <ul className="prose" style={{ margin: '6px 0 0' }}>
            {summary.map((s, i) => (
              <li key={i}>{s}</li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
