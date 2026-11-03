# Phase 16 — Repayment currency (SGD/MYR)

## What changes

- Under **Settings → Default repayment currency**, each installation can
  save **SGD** (default) or **MYR**. This is a local per-device preference,
  not a group-wide rule and not a synced account setting.
- In **Who owes whom → Confirm money received**, the recipient can choose
  **SGD**, **MYR**, or the group's spending currency and enter the
  **amount actually received**.
- The form also shows the unpaid balance in the group's spending currency
  and the amount that the receipt will credit against the debt.
- When the chosen paid currency equals the group's spending currency, its
  conversion rate is **1**. When it equals the group's settlement currency,
  its rate defaults to the **registered group exchange rate**.
- For MYR on a THB/SGD group, or SGD for a group with no registered SGD
  conversion, the recipient must enter a **manually agreed** rate:
  **1 repayment-currency unit = N spending-currency units**.
  The app does **not** silently assume an SGD/MYR exchange rate.
- The receipt history displays the **original paid amount and currency**,
  e.g. MYR 100.00, and its THB accounting equivalent.

## Database migration (required)

Run `supabase/migrations/20261103_000010_repayment_currencies.sql`
in the Supabase SQL Editor **after** merging and **before** installing
the new APK.

It adds `paid_amount`, `paid_currency` and `paid_rate_to_spending`
to `trip_repayments`, backfills existing receipts using their prior
spending-currency value, and adds the
`record_trip_repayment_currency` RPC.

The new RPC validates amount/currency/rate, converts to spending currency
(to two decimals), then calls the existing `record_trip_repayment` RPC.
That function checks that **only the recipient** can confirm,
locks the group for concurrent writes and rejects overpayment.
Repayments remain manual confirmations; **no bank transfer takes place**.
An insert trigger keeps older client versions compatible.

Example: For a group using **THB spending / SGD settlement**, with
**1 SGD = 25 THB**:

- Receive SGD 40.00: auto rate 25; credit **THB 1,000.00**.
- Receive MYR 100.00: enter a mutually agreed rate such as
  **1 MYR = 8 THB** (illustrative only); credit **THB 800.00**.
- A recipient may record a partial receipt. The converted amount must
  not exceed the outstanding debt in THB.

The default currency does not change past records or rewrite group exchange
rates. Changing Settings only changes what the repayment form preselects.

## Verify after merge

```sh
git checkout master
git pull origin master
flutter pub get
flutter gen-l10n
flutter analyze
flutter test test/repayment_preferences_test.dart
flutter build apk --release
```

On two phones, test SGD and MYR, a manual rate, partial repayment,
overpayment rejection, recipient-only permission and old repayment history.
This PR was reviewed with source delimiter and ARB JSON checks, but the
Flutter build and live Supabase migration were not executed by the assistant.
