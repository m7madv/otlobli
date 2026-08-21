import js from '@eslint/js'
import globals from 'globals'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import tseslint from 'typescript-eslint'

export default tseslint.config(
  {
    ignores: [
      '.claude/**',
      'android/app/build/**',
      'dist/**',
      'admin/dist/**',
      'driver/dist/**',
      'ios/App/App/public/**',
      'node_modules/**',
    ],
  },
  {
    files: ['api/**/*.{ts,tsx}', 'vite.config.ts'],
    languageOptions: {
      ecmaVersion: 2022,
      globals: globals.node,
    },
  },
  {
    extends: [js.configs.recommended, ...tseslint.configs.recommended],
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      ecmaVersion: 2022,
      globals: globals.browser,
    },
    plugins: {
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
    },
    rules: {
      ...reactHooks.configs.recommended.rules,
      // This is a legacy imperative Capacitor shell, not a React Compiler
      // target. Keep the canonical Hooks rules while disabling compiler-only
      // heuristics that flag its established native/ref orchestration.
      'react-hooks/refs': 'off',
      'react-hooks/set-state-in-effect': 'off',
      'react-hooks/immutability': 'off',
      'react-hooks/purity': 'off',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      'react-refresh/only-export-components': ['warn', { allowConstantExport: true }],
    },
  },
  {
    files: ['src/services/storeBrowser.ts'],
    rules: {
      // useNativeBackend is a pure platform predicate with a historical name,
      // not a React Hook. The file is hash-frozen for the release.
      'react-hooks/rules-of-hooks': 'off',
    },
  },
  {
    files: [
      'src/services/storeProductCaptureScript.ts',
      'src/services/sheinHumanCheck.ts',
    ],
    rules: {
      // Backslashes are intentional inside JavaScript injected as strings.
      'no-useless-escape': 'off',
    },
  },
  {
    files: ['supabase/functions/payment-webhook/core.ts'],
    rules: {
      'no-misleading-character-class': 'off',
    },
  },
)
