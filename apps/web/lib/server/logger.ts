/**
 * Yapısal loglama (Sprint 4 / ROADMAP Faz 31). Üretimde tek-satır JSON (log toplayıcı-dostu),
 * geliştirmede okunur. Bilinen sır anahtarları redakte edilir — hiçbir sır loglara sızmaz.
 */
export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

const LEVELS: Record<LogLevel, number> = { debug: 10, info: 20, warn: 30, error: 40 };
const MIN =
  LEVELS[
    (process.env.LOG_LEVEL as LogLevel) ??
      (process.env.NODE_ENV === 'production' ? 'info' : 'debug')
  ] ?? 10;

const REDACT = /(key|secret|token|password|authorization|cookie)/i;
function redact(meta: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(meta)) out[k] = REDACT.test(k) ? '[redacted]' : v;
  return out;
}

function emit(level: LogLevel, msg: string, meta?: Record<string, unknown>): void {
  if (LEVELS[level] < MIN) return;
  const safe = meta ? redact(meta) : undefined;
  if (process.env.NODE_ENV === 'production') {
    // eslint-disable-next-line no-console
    console[level === 'debug' ? 'log' : level](JSON.stringify({ level, msg, ...safe }));
  } else {
    // eslint-disable-next-line no-console
    console[level === 'debug' ? 'log' : level](`[${level}] ${msg}`, safe ?? '');
  }
}

export const logger = {
  debug: (m: string, meta?: Record<string, unknown>) => emit('debug', m, meta),
  info: (m: string, meta?: Record<string, unknown>) => emit('info', m, meta),
  warn: (m: string, meta?: Record<string, unknown>) => emit('warn', m, meta),
  error: (m: string, meta?: Record<string, unknown>) => emit('error', m, meta),
};
