# Phase 4 — Common Fund (manual ledger)

## Setup
1. Merge PR and pull `master`.
2. In Supabase Dashboard → SQL Editor, **run**
   `supabase/migrations/20261103_000003_trip_common_fund.sql`.
   This migration requires Phase 2 groups schema. It is additive and does not
   change previous personal expense rows.
3. In Android Studio, run `flutter pub get`, `flutter gen-l10n`,
   and `flutter analyze`, then press **Run**.
4. Open **Shared Groups → select a group → Common fund**.

GitHub PRs do not apply database SQL to your Supabase project automatically.

## Scenario: Japan trip
Group currency: JPY. Alice and Bob each contribute ¥30,000.
Use **Record contribution** twice, selecting the actual contributor and
entering 30000 each. Balance = ¥60,000.

Use **Pay from common fund** to record dinner ¥9,000.
Balance = ¥51,000. The transaction is recorded as a **fund expense**,
not as a personal expense shared between Alice and Bob. Do not re-enter
the same dinner into the ordinary Expenses screen, or your overall travel
spending will be double-counted.

Set a low-balance threshold of ¥10,000 using **Low-balance alert**
(available to the group owner). When the fund balance becomes ≤ ¥10,000,
the fund page displays an in-app warning. This is not a push notification.

## Accounting rules
- Positive contributions are money **actually received**, not promises.
- Fund-paid expenses reduce the shared balance once.
- Every transaction records who entered it; contribution entries also
  identify whose money was received. All members can record a transaction.
- The fund ledger is separate from personal expense shares. Individual
  debts are *not* assigned for fund spending.
- A single group-level balance row is locked in each RPC transaction to
  prevent simultaneous devices from overspending the fund.
- The RPC rejects expenses larger than the available balance.
- Only the owner may set the low-balance threshold (0 disables warning).
- Both ledger reads are restricted to group members using RLS, and writes
  go through authenticated RPCs rather than direct table permissions.
- All amounts use the group's **spending currency** and at most 2 decimals.
  No FX conversion is applied.

## Validation
1. Join the same group on two devices with different Supabase sessions.
2. Each device records a real contribution, then refresh to see the updated
   shared balance and contributor history.
3. Pay a smaller amount; verify balance reduces exactly once.
4. Try a fund expense larger than the balance; confirm it fails without
   changing the balance or history.
5. Set threshold, spend until the balance reaches that threshold, refresh,
   and verify the warning appears.
6. Test RLS from a non-member session, and anonymous Auth behavior.
7. Test English/简体中文 and light/dark modes.

## Not included in this first release
- Refund of unused funds or closing a trip.
- Partial funding with fund + individual payer.
- Currency exchange / separate cash and card exchange rates.
- Automatic bank verification or payment collection.
- Realtime updates, push notifications or debt settlement.
- Editing/reversing an incorrect entry (do not use with real money yet).

Since entries are manually reported and currently irreversible, this
feature is **for testing**, not production financial records. Before
production release, implement undo/adjustments, idempotency and recoverable
accounts, then validate database RLS and concurrent operations.

The SQL migration and Android build have not been run in this
GitHub-editing environment.
