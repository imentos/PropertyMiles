# App Languages

LandMile supports English, Simplified Chinese (`zh-Hans`) and Traditional Chinese
(`zh-Hant`) in the same app. iOS chooses the best supported language from the
user's preferred languages. Users can override the app language in iPhone Settings;
LandMile's Settings > Language button opens its system settings page.

Language and reporting country are independent. A Chinese interface with United
States reporting still uses miles, US$ and the existing IRS rate calculation.
Canada reporting still uses kilometres and optional custom CAD reimbursement.

## Resources and Data

- `Localizable.xcstrings` contains English, Simplified and Traditional Chinese UI
  translations, including onboarding choices and formatted counts.
- Chinese `InfoPlist.strings` files translate location and motion permission text.
- Built-in trip purposes keep their existing enum raw values. `displayName` is
  localized; `reportName` remains English for CSV exports and data compatibility.
- Custom purposes, location names, notes, vehicle names and addresses are user data
  and are never translated or rewritten.
- CSV column names and built-in purpose names remain English for accountants.
- Raw tracking events remain English for support diagnostics.
- Prices and purchase controls supplied by StoreKit follow Apple's localization.

## Verification

Run the catalog, permission and actual purpose-enum checks from the repository root:

```sh
node scripts/test-localizations.mjs
```

To also verify the packaged Chinese resources, pass the built `.app` directory:

```sh
node scripts/test-localizations.mjs /private/tmp/landmile-localization-build/Build/Products/Debug-iphonesimulator/RealEstateMileageTracker.app
```

Before release, test both Chinese languages with United States and Canada reporting,
permission prompts, onboarding, trip details, reporting, custom names and CSV export.
App Store description and screenshot localization is a separate publishing step.
