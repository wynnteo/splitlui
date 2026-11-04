# Phase 24 — Simplified settlements, migration repair, cute UI

## 1. Supabase migration repair (fixes reported error 42883)

The original migration `20261103_000017_advanced_common_fund.sql`
accidentally declared `request_trip_fund_topup` with five arguments,
including an unused `p_operation uuid`. Its following `REVOKE/GRANT`
statements correctly referenced four arguments. PostgreSQL therefore
raised `ERROR 42883: function public.request_trip_fund_topup(uuid, uuid, numeric, text) does not exist`.

The corrected 000017 migration declares the top-up function with exactly
four arguments and removes a stray five-argument version if one was left
by a partially applied script. It is safe to rerun after a failed attempt.
The missing `public.trip_fund_targets` table error is consistent with
the original failed migration not having committed.

**Run in Supabase SQL Editor in this order:**
1. **After merging this PR**, copy and execute the COMPLETE corrected
   `supabase/migrations/20261103_000017_advanced_common_fund.sql`.
   Do not execute just the GRANT statement.
2. Verify with:

   ```sql
   select to_regclass('public.trip_fund_targets') as targets,
          to_regclass('public.trip_fund_topup_requests') as requests,
          to_regclass('public.trip_fund_refunds') as refunds;
   select to_regprocedure(
     'public.request_trip_fund_topup(uuid,uuid,numeric,text)'
   ) as request_function;
   ```

   All four results should be **non-null**. If anything is null, stop
   rather than proceeding to additional payments.
3. Execute `supabase/migrations/20261103_000018_repayment_fx_rounding.sql`.
4. Rebuild the APK and reopen Common Fund.

Do NOT run `DROP TABLE` on the production Common Fund tables.

## 2. Repayment UX and accounting

- Who Owes Whom now focuses on the person to pay and the estimated
  settlement currency (e.g. SGD), not multiple THB ledgers or long
  exchange-rate explanations.
- Original-currency trip spending and member balances remain available
  under a collapsed **More details** section.
- The Receive Payment form asks for **the actual amount received**,
  e.g. SGD 135. It no longer shows a THB outstanding debt, converted
  THB total or disables confirmation for tiny FX overages.
- The history shows the **actual paid amount/currency**, not an
  additional THB equivalent.
- The confirmation form includes a single **This payment settles the full
  amount** switch, enabled by default. Leave it enabled for an agreed
  rounded final payment (such as SGD 135 instead of SGD 135.23). Turn it
  off for a *partial payment*.
- The new `record_trip_repayment_agreed` RPC records the original cash
  amount/currency regardless of rounding. A full confirmation clears the
  **selected suggested transfer amount** (not everyone's combined debts);
  a partial confirmation credits no more than the actual converted amount. Ledger credit cannot exceed the selected transfer or either
  party's outstanding net debt; accidental excess payment does not create
  a negative new debt. A receipt cannot be recorded if no net debt exists.
- Existing older clients can continue using the seven-argument
  `record_trip_repayment_currency` RPC, which now caps overpayments rather
  than rejecting FX-rounding differences.
- Only the recipient can confirm a payment; a mistaken confirmation
  can still be reversed through the audited Undo flow.
- Manual conversion rate entry is only presented when the chosen
  currency isn't the group's configured spending/settlement pair.
  The registered rate is applied automatically otherwise.

## 3. Design adjustments

- **Light mode** keeps its existing teal palette.
- **Dark mode** uses neutral charcoal surfaces and gentle lavender
  accents, including Material 3 generated container colours.
- Create/Join Group shortcuts use large pastel circular icons and labels.
- The Common Fund purchase bottom sheet no longer has a forced 66%
  height or the resulting empty gap.
- The Add Expense form hides redundant Paid By wording when spending
  from the Common Fund.

## 4. Test before merging

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --release
```

Suggested manual checks:
- Four-member trip, THB spending and SGD settlement: pay SGD 135 when
  the equivalent THB figure exceeds outstanding by a small amount.
  Confirm succeeds with **full settlement** enabled; history shows
  SGD 135 only; remaining debt is zero, not negative.
- Record partial SGD 50 with **full settlement turned off**: remaining
  balance decreases appropriately instead of being completely cleared.
- Attempt to confirm money on behalf of a different recipient: rejected.
- Confirm against a fully settled debt: rejected (no more debt to credit).
- Undo a confirmed receipt and verify it no longer affects the ledger.
- Confirm payment using third-party currency MYR with explicit rate.
- Switch languages: English/Chinese labels display correctly.
- Check Group screen Create/Join round icons, and dark-mode scaffold,
  cards, buttons and PayNow containers for unintended green backgrounds.
- Open a small Common Fund purchase without a receipt: bottom sheet
  should fit content without a huge blank region.
- Run corrected migration 000017 and verify Common Fund targets/refunds
  load for both a group owner and a regular member.

**Validation status:** Code structurally checked, not built in a Flutter
runtime or executed against live Supabase. Do not promote the PR until
real-device and SQL migration checks succeed.
