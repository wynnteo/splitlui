# Phase 7 — Multi-currency expenses (one group)

## User scenario

A Japan trip uses **JPY as spending currency** and **SGD as settlement
currency**. The group rate is **1 SGD = 115 JPY**.

- Local restaurant: choose **JPY**, enter 9,000. Rate is 1 and is hidden.
  When split among 3 members each share is 3,000 JPY.
- Flight ticket: choose **SGD**, enter 300.00. The form defaults to the
  group rate of 115 JPY per SGD. In the expense list and per-member
  breakdown, the app records and shows SGD 300.00 and its JPY 34,500.00
  equivalent, split as SGD 100.00 / JPY 11,500.00 per member.
- Hotel paid in **USD**: choose USD, enter the USD amount and manually
  enter **how many JPY equal 1 USD**. E.g. 1 USD = 150.5 JPY. The rate
  is saved with the hotel expense, not fetched from a live FX provider.

You may override the default SGD→JPY rate for an individual ticket if your
actual bank/card conversion differed. Expenses originally recorded in JPY
remain unchanged. **Every expense stores its original currency, original
amount, fixed per-expense rate, rounded group-equivalent amount and two
equal-split allocations** (original and converted). We do *not* modify the
Common Fund balance: it still uses the group's spending currency.

## Important accounting convention

The rate is always:

    1 expense currency unit = X group spending currency units

Do not enter the inverse. For an SGD 300 flight with group currency JPY,
enter 115 (not 1/115) to record a JPY 34,500 equivalent.

Do not add a second duplicate JPY expense for the same flight.

These are **user-supplied bookkeeping conversion rates**. The app does not
fetch live exchange rates, verify bank charges, or move money. Conversions
are rounded to two decimal places. For split amounts where cents cannot
divide evenly, remainder cents are allocated deterministically so shares
sum exactly to the stored total in each currency.

The group currency itself remains locked after creation: changing the
denomination would invalidate historical expense and Common Fund amounts.
You *can* edit the group's default rate via Edit Group; saved expense
rates will not change.

## Setup (one time)

1. Merge this PR.
2. In Supabase Dashboard → SQL Editor, run:
   `supabase/migrations/20261103_000006_expense_currencies.sql`
   **after** the Phase 3 expense migration.
3. In Android Studio Terminal:

       git checkout master
       git pull origin master
       flutter pub get
       flutter gen-l10n
       flutter analyze

4. Press Android Studio's normal **Run** button.

The migration backfills historical expense currency to the group's
spending currency and the rate to 1; it does not delete old expenses.
It also retains the old RPC for older mobile app versions.

## Regression tests

- Create one group; use Expenses, Common Fund and Members without any
  'local group / shared group' choice.
- Enter a group-currency JPY expense. Rate stays 1.
- Enter an SGD flight in a JPY group. The default exchange rate comes
  from the group's SGD settlement rate; verify original/converted shares.
- Enter a USD hotel and set a custom positive rate; verify persistence.
- Split an amount ending in 0.01 among 3 members and check totals in
  *both* currencies exactly match the original and converted totals.
- Edit the group's default rate; existing expenses must keep their own
  saved rates.
- Verify the currency dropdown shows simply **THB**.
- Test owner-only Edit/Delete Group, including group names longer than
  80 characters (delete confirmation supports 120).
- Test EN/简体中文, both themes, and smaller Android phones.
- Ensure Phase 4 Common Fund spending remains in the group's spending
  currency and is not double-counted.

## Limits

- There is no automatic bank-rate API or historical FX-rate lookup.
- Individual group debt settlements/PayNow are separate future features.
- There is no edit or delete of individual expenses yet.
- SQL and Flutter tooling have **not** been executed in this GitHub editing
  environment; verify on a test Supabase project before using real money.
