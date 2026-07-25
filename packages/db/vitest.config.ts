import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    globals: false,
    // Her test `freshTestDb()` ile BELLEK İÇİ bir Postgres (PGlite) açar ve bootstrap DDL'ini
    // çalıştırır. Tek başına ~0.9 sn sürer; ancak turbo bütün paketleri EŞZAMANLI koştururken
    // (web tarafı tek başına 71 dosya / 432 test) CPU çekişmesi altında 10 sn'yi aşabiliyor ve
    // 5 sn'lik vitest varsayılanı yüzünden testler SEBEPSİZ kırmızıya dönüyordu.
    // `apps/web/vitest.config.ts` aynı sorunu aynı biçimde çözüyor — desen bilinçli olarak ortak.
    testTimeout: 20000,
    hookTimeout: 20000,
  },
});
