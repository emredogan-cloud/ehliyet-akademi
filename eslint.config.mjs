// Kök ESLint (flat) konfigürasyonu — tüm workspace'ler bunu miras alır.
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import prettier from 'eslint-config-prettier';

export default tseslint.config(
  {
    ignores: [
      '**/node_modules/**',
      '**/.next/**',
      '**/dist/**',
      '**/coverage/**',
      '**/.turbo/**',
      '**/playwright-report/**',
      '**/test-results/**',
      '**/next-env.d.ts',
      // Telif korumalı MEB sınav-arşivi (referans-only) + indirme venv'i — asla linte/derlemeye girmez.
      'sınav-soruları-pdf/**',
      'apps/mobile/**',
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  prettier,
  {
    rules: {
      // Ürün kuralı: konsol gürültüsü yok (uyarı/hata/debug — analitik sink — bilinçli)
      'no-console': ['warn', { allow: ['warn', 'error', 'debug'] }],
      '@typescript-eslint/no-unused-vars': [
        'error',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
      ],
      '@typescript-eslint/consistent-type-imports': ['warn', { fixStyle: 'inline-type-imports' }],
    },
  },
  {
    // TS/TSX: tip denetimini TypeScript yapar → no-undef kapalı; tarayıcı+node globalleri açık.
    files: ['**/*.ts', '**/*.tsx'],
    languageOptions: {
      globals: {
        window: 'readonly',
        document: 'readonly',
        localStorage: 'readonly',
        navigator: 'readonly',
        console: 'readonly',
        process: 'readonly',
        fetch: 'readonly',
        URL: 'readonly',
        setTimeout: 'readonly',
        clearTimeout: 'readonly',
        HTMLElement: 'readonly',
        React: 'readonly',
      },
    },
    rules: {
      'no-undef': 'off',
    },
  },
  {
    // Service worker: kendi global bağlamı (self/caches/fetch event'leri)
    files: ['**/public/sw.js'],
    languageOptions: {
      globals: {
        self: 'readonly',
        caches: 'readonly',
        fetch: 'readonly',
        URL: 'readonly',
        Promise: 'readonly',
      },
    },
  },
  {
    files: ['**/*.js', '**/*.mjs', '**/*.cjs'],
    languageOptions: {
      globals: {
        console: 'readonly',
        process: 'readonly',
        Buffer: 'readonly',
        __dirname: 'readonly',
        URL: 'readonly',
        fetch: 'readonly',
        setTimeout: 'readonly',
        clearTimeout: 'readonly',
      },
    },
    rules: {
      '@typescript-eslint/no-require-imports': 'off',
      'no-console': 'off', // CLI/betik dosyaları konsola yazar
    },
  }
);
