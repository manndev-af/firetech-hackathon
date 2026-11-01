import js from "@eslint/js";
import globals from "globals";
import tseslint from "typescript-eslint";

export default tseslint.config(
  {
    ignores: ["node_modules/**", "dist/**", "build/**", "*.js", "eslint.config.mts"],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ["**/*.{ts,mts,cts}"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
      globals: {
        ...globals.node,
        ...globals.es2021,
      },
      parserOptions: {
        project: "./tsconfig.json",
      },
    },
    rules: {
      // TypeScript specific rules
      "@typescript-eslint/no-explicit-any": "warn",
      "@typescript-eslint/explicit-function-return-type": "off",
      "@typescript-eslint/no-unused-vars": [
        "error",
        {
          argsIgnorePattern: "^_",
          varsIgnorePattern: "^_",
        },
      ],
      "@typescript-eslint/no-non-null-assertion": "warn",

      // General code quality
      "no-console": ["warn", { allow: ["warn", "error"] }],
      "prefer-const": "error",
      "no-var": "error",
      "eqeqeq": ["error", "always"],

      // Code style
      "semi": ["error", "always"],
      "quotes": ["error", "single", { avoidEscape: true }],
      "indent": ["error", 2, { SwitchCase: 1 }],
      "comma-dangle": ["error", "always-multiline"],
      "object-curly-spacing": ["error", "always"],
      "arrow-spacing": "error",
    },
  }
);
