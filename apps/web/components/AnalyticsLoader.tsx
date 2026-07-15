'use client';

/**
 * Analitik yükleyici (Sprint 5) — sağlayıcıları YALNIZCA analitik rızası + ilgili ENV varsa yükler.
 * Rıza yoksa veya ENV yoksa hiçbir izleyici yüklenmez (gizlilik-öncelikli; KVKK/ePrivacy uyumlu).
 * Bizim dağıtımımızda ENV yok → tümüyle no-op (yalnız console sink olayları görür).
 */
import { useEffect } from 'react';
import { readConsent } from './CookieConsent';
import { analyticsConfig, enabledProviders, addProviderSink } from '@/lib/analytics';

function loadScript(src: string, async = true): void {
  const s = document.createElement('script');
  s.src = src;
  s.async = async;
  document.head.appendChild(s);
}

export function AnalyticsLoader() {
  useEffect(() => {
    const consent = readConsent();
    if (!consent?.analytics) return;
    const cfg = analyticsConfig();
    const providers = enabledProviders(true, cfg);
    if (providers.length === 0) return;

    const w = window as unknown as { dataLayer?: unknown[]; gtag?: (...a: unknown[]) => void };

    if (cfg.ga4) {
      w.dataLayer = w.dataLayer || [];
      w.gtag = function gtag(...args: unknown[]) {
        w.dataLayer!.push(args);
      };
      w.gtag('js', new Date());
      w.gtag('config', cfg.ga4, { anonymize_ip: true });
      loadScript(`https://www.googletagmanager.com/gtag/js?id=${cfg.ga4}`);
    }
    if (cfg.clarity) {
      loadScript(`https://www.clarity.ms/tag/${cfg.clarity}`);
    }
    if (cfg.posthog) {
      const host = cfg.posthogHost ?? 'https://eu.posthog.com';
      loadScript(`${host}/static/array.js`);
    }
    addProviderSink();
  }, []);

  return null;
}
