# Phase 8 — Settlement preview (who owes whom)

This feature reads the existing Phase 3 / Phase 7 shared-expense rows and
produces **suggested repayments**. It does not send money or mark payments
as completed. No new SQL migration is required.

## How it works

Open **Groups → choose group → Who owes whom**.

For each shared expense:
- The recorded payer gets a credit for the full amount converted into the
  group's **spending currency** when the expense was created.
- Each selected participant is charged their stored converted share.
- Net credits and debts are calculated in **integer cents**, so rounding
  never creates or loses money.
- The app proposes transfers from members who owe money to members who
  should receive it. This is a **greedy suggestion**, not a guarantee of
  the mathematically fewest transfers.

For a Japan group with JPY spending currency and SGD settlement currency,
the preview shows the exact calculated JPY amount and an **approximate**
SGD equivalent using the group's **current** exchange rate.
Because of per-transfer rounding, the SGD estimates may not sum to a
perfectly reconciled SGD total. Agree on the actual rate and amount before
sending real money.

### Example

Two members: Alice and Bob.
- Alice pays SGD 300 for flights at a saved rate of JPY 115 per SGD.
  Group equivalent: JPY 34,500; each share: JPY 17,250.
- Bob pays JPY 9,000 for dinner. Each share: JPY 4,500.
- Net: Bob pays Alice **JPY 12,750** (SGD ~110.87 at 115 JPY/SGD).

This calculation uses the *original per-expense recorded FX conversion*,
not today's rate, to determine exact JPY debts.

## Common Fund limitation (important)

Common Fund contributions, expenses, and refunds are **not included** in
personal debt calculation. Fund-paid meals must not be added again as
individual expenses. Closing a trip still requires separately reviewing
any unused pooled money and refunding it through an agreed process.
The current feature is an **expense-only debt preview**, not final
trip-close accounting.

## Required setup

Make sure prior group, shared expense and multi-currency SQL migrations
are already applied; no new migration for this PR.

In Android Studio after merging:

    git checkout master
    git pull origin master
    flutter pub get
    flutter gen-l10n
    flutter analyze
    flutter test test/settlement_calculator_test.dart

Press **Run** and open a group.

## Validation

- Enter a JPY expense; check payer credit and participant shares.
- Enter a separate SGD flight with an explicit conversion to JPY;
  verify the suggestion uses JPY equivalents.
- Test 100.01 split by 3. The transfer amounts must sum exactly.
- Check 2+ expense pages (1000+ rows) to confirm the paging code
  includes all rows.
- Verify new members with no transactions are shown as balanced.
- If any share is missing or corrupted, the screen should show an error,
  rather than a misleading debt proposal.
- After recording another expense, tap Refresh.
- Test EN/简体中文, light/dark, and smaller devices.

## Limitations / future features

- No paid/unpaid state, PayNow QR, WhatsApp sharing, or bank integration.
- No splitting Common Fund refunds into per-member net debts.
- Cannot account for payments settled outside the app.
- A member removed from a group while still referenced by old expenses
  currently causes a visible reconciliation error.
- Uses the existing read-only RLS policies; **no new server write grants**.

The Flutter SDK is not available in the GitHub-editing environment, so
tests and analyzer must be run in Android Studio before merging to release.
