'use client';
/**
 * Reveal — görünür alana girince yumuşak beliriş (Program 1 · Bölüm D · hareket sistemi).
 * IntersectionObserver ile bir kez tetiklenir. prefers-reduced-motion global kuralı
 * animasyonu nötrler; JS destekleneme durumunda içerik varsayılan olarak görünür kalır.
 */
import { useEffect, useRef, useState } from 'react';

export function Reveal({
  children,
  as: Tag = 'div',
  delay = 0,
  className,
}: {
  children: React.ReactNode;
  as?: 'div' | 'section' | 'li';
  delay?: number;
  className?: string;
}) {
  const ref = useRef<HTMLElement | null>(null);
  const [shown, setShown] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    if (typeof IntersectionObserver === 'undefined') {
      setShown(true);
      return;
    }
    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) {
            setShown(true);
            io.disconnect();
          }
        }
      },
      { rootMargin: '0px 0px -8% 0px', threshold: 0.05 },
    );
    io.observe(el);
    return () => io.disconnect();
  }, []);

  return (
    <Tag
      ref={ref as never}
      className={`reveal${shown ? ' reveal--in' : ''}${className ? ` ${className}` : ''}`}
      style={delay ? { transitionDelay: `${delay}ms` } : undefined}
    >
      {children}
    </Tag>
  );
}
