# SplitLui release hardening — review and deployment

## Android signing (same no-key.properties approach as other Lui apps)

- Keystore on your Mac: ~/my-release-key.jks, alias: my-key-alias.
- Environment variables: SPLITLUI_STORE_PASSWORD and SPLITLUI_KEY_PASSWORD.
- No signing passwords or keystore are committed. Android Studio Run stays debug.
- Production Play Console upload uses flutter build appbundle --release.
- Verify the keystore upload certificate matches the fingerprint in Play Console.
- Release never falls back to debug signing. Build fails if credentials are missing.
- The Android app ID remains dev.cloudfullstack.splitlui.

## iOS

- Camera purpose: photograph expense receipts.
- Gallery purpose: select existing receipt photos.
- Test both permission prompts on a real iOS device and perform an Xcode archive.

## Required Supabase migration

After prior migrations through 000020, execute:

    supabase/migrations/20261103_000021_release_financial_integrity.sql

- Only a group owner can confirm a contribution received into Common Fund.
- Group members can still record Common Fund-paid expenses.
- Full repayment confirmation allows up to 2% or one spending-currency unit of rounded difference; bigger discrepancies must use partial repayment.
- Existing original paid amount and paid currency remain recorded. Recipient-only and row-level permissions remain in force.
- These are manual attestations, not independent verification of real bank transfers. Custom FX rates are still user-entered.
- Older repayments and contributions are not retroactively modified.

## Pagination and editing

- GroupPagedQuery retrieves 500-row pages in stable created_at/id order.
- Applied to expenses, fund purchases and entries, targets, top-up requests and refunds.
- Saved splits that fail to load now show Retry and disable Save until loaded.

## PDF language

- Report uses English or Simplified Chinese depending on app language.
- Chinese-compatible Noto Sans SC loads via printing and is cached after first fetch.
- First PDF export requires internet. No Thai font is included.

## Build/check commands

    flutter pub get
    flutter gen-l10n
    flutter analyze
    flutter test
    flutter build appbundle --release

CI checks Flutter analysis/tests and builds an unsigned-for-release debug APK without signing secrets.

## Manual test checklist

1. Verify signed AAB fingerprint; confirm debug builds still run.
2. Test iOS camera/gallery permission flows and Xcode release archive.
3. Nonowner cannot confirm fund contribution via UI or direct RPC.
4. Owner can record another member's contribution; ordinary member can record fund purchase.
5. THB trip SGD 135 rounded payment can settle SGD 135.23; SGD 1 cannot settle a much larger debt.
6. Partial repayments and reversals continue to work.
7. >1,000 expense/fund entries paginate without dropping or repeating rows.
8. Existing expense edit failure shows retry and never saves partial shares.
9. Chinese and English PDF rendering works, including Chinese member names.
10. Repeat offline receipt sync and settlement regression cases.

## Still to verify

Flutter/Xcode/PostgreSQL are unavailable in this repository editing environment.
SQL execution, automated test runs and device builds are required before merge.
pubspec.lock is currently ignored and should be generated and committed after dependency resolution for fully reproducible releases.
