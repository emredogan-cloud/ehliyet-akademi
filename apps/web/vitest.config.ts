import { defineConfig } from 'vitest/config';
import { fileURLToPath } from 'node:url';

export default defineConfig({
  resolve: {
    alias: {
      // Next'in "@/*" path alias'ı ile birebir (tsconfig.json)
      '@': fileURLToPath(new URL('.', import.meta.url)),
    },
  },
  test: {
    environment: 'node',
    include: [
      'lib/**/*.test.ts',
      'app/**/*.test.ts',
      'content/**/*.test.ts',
      'components/**/*.test.ts',
    ],
    globals: false,
    // QIP zekâ katmanı (normalize+analyze+dedup+graph+families+validate) 1534 soru üzerinde soğuk
    // önbellekle ağırdır; çok sayıda test dosyası eşzamanlı çalışırken 5 sn varsayılanı aşabilir.
    testTimeout: 20000,
    hookTimeout: 20000,
  },
});
