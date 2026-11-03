# Phase 3 — Shared expenses (equal split)

This feature is cloud-only. Before testing, merge the PR and open your Supabase project's **SQL Editor**. Run `supabase/migrations/20261103_000002_trip_expenses.sql` after the earlier groups migration. Merging app code alone **does not create database tables**.

## Android Studio test

1. Pull master and run `flutter pub get` and `flutter gen-l10n` after merging.
2. Press the ordinary Android Studio **Run** button.
3. Open **Shared Groups** and enter a group with at least two members.
4. Choose **Expenses → Add expense**; enter "Dinner", amount 100.01, choose who paid and which members share it.
5. Save; the new expense appears in the list. Tap it to inspect each person's exact share.
6. On the second device, refresh the expense list and verify the same expense and shares appear.

For 100.01 split among 3 people, the database records 33.34 + 33.34 + 33.33 (in selected-member order). Shares always sum to the original amount.

## Included

- Shared expense list visible to all group members.
- Paid-by selector is independent from split-between selection.
- Equal split with deterministic smallest-unit remainder handling.
- Group currency used as the expense currency; entries are in that currency.
- Database RLS for members-only reads; atomic security-definer RPC for validated writes.
- English and Simplified Chinese labels; existing light and dark themes.

## Not yet included

- Custom/percentage/weighted splits, expense edit/delete, receipts, notifications, realtime updates, budgets, FX overrides, common fund, net settlement and PayNow.
- Group member identities use existing anonymous auth (device-bound), so do not use with real financial records until recoverable sign-in is added.
- The database migration must be applied manually in Supabase. No remote schema has been modified by the PR.

## Security checks

Test logged-in non-member reads against both tables, non-member payer/participants, duplicate selected participants, invalid amount and unauthorized RPC calls. Database implementation and Flutter build have not been executed in this editing environment.
