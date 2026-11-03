# Phase 12 — Mobile layout and Common Fund expense payer

## Changes
- **Groups home:** show "Your groups" once (in the app bar); retain the intro line.
- **Create Group / Group Members / Add Expense / Common Fund:** add safe-area
  wrapping and bottom padding so the Android navigation bar does not obscure
  the bottom actions or final list item.
- Replace the generic nickname, invite, group deletion, and Common Fund
  threshold text dialogs with keyboard-aware rounded Material bottom sheets.
- In **Add Expense**, show **currency before amount**.
- If the group Common Fund has a positive balance, the form offers a
  **Common Fund** toggle as payer. Choosing it hides the member payer and
  individual split selection, and shows the available fund balance.
- A fund-paid expense is saved once, into `trip_fund_entries`, with the
  **original amount/currency and saved conversion**. The account balance
  is debited atomically under a database row lock; insufficient balances
  fail without creating a ledger entry.
- These purchases appear in the Expenses list, marked
  **Paid by: Common fund**. They also remain visible in Common Fund history.
- Personal shared expenses still use `trip_expenses` and
  `trip_expense_shares`; **fund purchases do not create member debts**
  or change the existing settlement calculation.

## Supabase SQL migration (required)
After merging PR, run this SQL file in Supabase Dashboard's SQL Editor:

    supabase/migrations/20261103_000009_fund_purchases.sql

This depends on the existing Phase 4 Common Fund tables and Phase 7
expense currency convention. Execute it once before using the new APK.
The migration is additive and does not delete old fund history.

If the migration is not applied, the Expenses screen's fund-history query
may fail because the new columns are missing.

## Build and verify

    git checkout master
    git pull origin master
    flutter pub get
    flutter gen-l10n
    flutter analyze
    flutter build apk --release

Test using a group with a positive fund balance:
1. Add a contribution in Common Fund.
2. Add Expense → select currency → enter amount → Paid by Common Fund.
3. Verify only one fund ledger expense is added, and fund balance drops by
   the converted amount. Check no new personal settlement debt is created.
4. Test a fund purchase exceeding its balance; expect rejection and no
   balance change.
5. Add a normal member-paid expense; verify member split calculation
   still works.
6. Verify safe-area bottom padding on a phone with 3-button navigation,
   gesture navigation, and while the keyboard is open.
7. Verify name, invite, delete and threshold bottom sheets in EN/Chinese.

## Google Play invite URL
The existing Share Invite feature already accepts a real published
app-install URL by passing a build-time flag:

    flutter build apk --release --dart-define='SPLITLUI_INSTALL_URL=https://play.google.com/store/apps/details?id=YOUR_ACTUAL_PACKAGE_ID'

Replace the placeholder only when a real Play Store listing is accessible
to invited users. Before publication, the invitation includes the code
and installation instructions without a broken/fabricated URL.

## Known limitations
- This is not bank integration. Fund entries reflect manual bookkeeping.
- Fund-paid expenses are entirely paid from the pool; split payment across
  pool and an individual is not part of this phase.
- Existing, older Common Fund entries lack original-currency metadata
  (their stored amount is already in the group spending currency).
- No automatic currency rate lookup; use the agreed manual rate.
- Flutter build and live Supabase migration were not run by the assistant.
