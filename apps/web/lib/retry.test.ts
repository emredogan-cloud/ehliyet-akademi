import { describe, it, expect } from 'vitest';
import { withRetry } from './retry';

const noSleep = async () => {};

describe('withRetry', () => {
  it('ilk denemede başarılıysa tek çağrı', async () => {
    let calls = 0;
    const r = await withRetry(
      async () => {
        calls++;
        return 'ok';
      },
      { sleep: noSleep }
    );
    expect(r).toBe('ok');
    expect(calls).toBe(1);
  });

  it('geçici hatada yeniden dener ve sonunda başarır', async () => {
    let calls = 0;
    const r = await withRetry(
      async () => {
        calls++;
        if (calls < 3) throw new Error('geçici');
        return 'sonunda';
      },
      { retries: 3, sleep: noSleep }
    );
    expect(r).toBe('sonunda');
    expect(calls).toBe(3);
  });

  it('tüm denemeler tükenirse son hatayı fırlatır', async () => {
    let calls = 0;
    await expect(
      withRetry(
        async () => {
          calls++;
          throw new Error('kalıcı');
        },
        { retries: 2, sleep: noSleep }
      )
    ).rejects.toThrow('kalıcı');
    expect(calls).toBe(3); // 1 + 2 retry
  });

  it('shouldRetry false ise denemeyi durdurur', async () => {
    let calls = 0;
    await expect(
      withRetry(
        async () => {
          calls++;
          throw new Error('kalıcı');
        },
        { retries: 5, shouldRetry: () => false, sleep: noSleep }
      )
    ).rejects.toThrow();
    expect(calls).toBe(1);
  });
});
