# Damanak localization authoring

The application uses bundled ARB resources only. No translation service, model,
Python runtime, or customer-data upload is part of the application.

- `catalog.json` records developer-owned source templates from the initial
  migration; `lib/l10n/arb/app_ar.arb` is the application source catalog.
- `overrides.json` contains editorial corrections. Keys are the original Arabic
  template, values map language codes to corrected translations.
- `editorial/<language>.json` contains additional contextual corrections using
  the original Arabic template as key. It takes precedence over draft output.
- `build-catalog.mjs` generates ARB files and the restricted known-label lookup
  from the authoring cache. Run with `--strict` before accepting a batch.
- `extract.dart` and `migrate.dart` are one-time migration tools. Do not rerun the
  migration blindly: new strings should receive deliberate, descriptive keys.
- `translate.mjs` is disabled after the public provider declined automation.
  Do not retry it or work around the provider restriction.
- `translate_offline.py` optionally creates drafts with the MIT-licensed
  `facebook/m2m100_418M` model. Its environment and model stay ignored. Drafts
  require editorial review, especially placeholder sentence order, scanning,
  subscription restoration (not refunds), plan names, and the Damanak brand.

The locally inspected model revision is
`55c2e61bbf05dfb8d7abccdc3fae6fc8512fd636`; downloaded weights are 1,935,796,948
bytes with SHA-256
`D907EA45E4E4B9DB163382A6674F6218B3C59566FE06D77F4055C208B4E87ED1`.
Local authoring used Python 3.12, torch 2.11.0+cu128, transformers 4.57.6 and
sentencepiece 0.2.2. These are not Flutter dependencies or release artifacts.

From the application directory, run:

```text
flutter gen-l10n
node scripts/verify_localizations.mjs
flutter analyze
flutter test
```

The release gate must pass for all 10 catalogs. Passing it establishes structural
completeness, not linguistic approval. Do not translate customer-entered names,
stored status identifiers, SKU/barcodes, currency codes, product IDs, receipts,
or security tokens. Only apply `L10n.knownLabel` to explicitly-owned static labels.

Screenshot harness: set `DAMANAK_SCREENSHOT_LOCALE` to an app language code and
run `flutter test tool/app_store_marketing_screenshots_test.dart`. It renders
five real screens in both device sizes under `app_store_assets/ios/localized`.
Installed Windows fonts are used for the screenshot harness only and must not
be redistributed inside the application. Inspect every screenshot for glyphs,
clipping, RTL/LTR, terminology, and sample data before upload.

App Store screenshot uploader accepts `DAMANAK_STORE_VERSION` and an exact
`DAMANAK_STORE_LOCALE`. A new localization must already exist in the editable
version; it never substitutes a different language. Do not run apply against
an in-review or live version without the corresponding release decision.
