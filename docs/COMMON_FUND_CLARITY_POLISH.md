# Common Fund clarity polish — existing screen only

This is a user-interface cleanup built on master after PR #42.
No new database migration, no packages, no financial algorithm changes.

## Improvements

- Removes the repeated trip name from the Common Fund page.
  The AppBar already provides the Common Fund title.
- Leads with the **available fund balance**, then puts **Add money**
  and **Pay expense** beside each other at matching widths.
  The short notice reinforces that only actual cash is recorded.
- Replaces the wordy aggregate target card with two values:
  **Received** and **Still to collect**. When targets exist, a single
  progress bar and target amount provide the overall context.
- Each member card shows a compact Received and Still to collect row.
  If a target exists, an optional thin progress indicator shows the
  member's progress. Members at/above their target receive a check icon.
  Confirmed refunds remain visible when relevant.
- **Set target** and **Request top-up** remain equal-width buttons.
  Owner-only **Confirm refund received** still appears only when
  contributions net of refunds are positive.
- Requests, refund history, and fund closing reconciliation have been
  placed in three clearly labelled, borderless, **collapsed sections**.
  They are still accessible (no information is discarded), with counts
  for active top-up requests and confirmed refunds.
- Closing reconciliation is **a preview**, never a real fund closure.

## Financial behaviour unchanged

- No new RPCs or writes.
- Targets and requests do not credit the account.
- Actual contributions credit funds and purchases/refunds debit funds
  only via existing server RPCs.
- Group owner permissions, member checks, refund confirmation, and
  accounting reconciliation are unchanged.
- The existing Common Fund activity ledger stays visible.

## Validation

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --release
```

Manual UI checklist:

1. Group with four members: no targets, partially collected targets,
   fully collected target, and over-funded target.
2. Confirm all member amounts and progress indicators align with the
   previous version. Target not set should not appear overdue.
3. Use Add money and Pay expense side by side on narrow screens
   in English and Chinese.
4. Ensure only the owner can change targets, create/cancel requests,
   or confirm refunds.
5. Expand and collapse Requests, Confirmed refunds and Closing preview;
   verify the expected history, notes and reconciliation warning.
6. Confirm actual fund balance does not change when a target/request
   is created. Confirm real contributions and refunds still update the
   balance accurately.
7. Check dark and light themes and long member names.

Source delimiter and EN/Chinese translation checks passed, but the
Flutter build and device UI tests were not executed here.
