'use client';

import { useEffect } from 'react';

/** SW kaydı (Faz 18) — yalnız üretimde (dev'de cache karmaşasını önler). */
export function RegisterSW() {
  useEffect(() => {
    if (process.env.NODE_ENV !== 'production') return;
    if (!('serviceWorker' in navigator)) return;
    navigator.serviceWorker.register('/sw.js').catch(() => {
      /* offline desteği opsiyonel — sessiz geç */
    });
  }, []);
  return null;
}
