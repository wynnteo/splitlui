# Phase 20 — Enhanced receipt OCR and safe expense editing

## Receipt recognition

When a member takes a receipt photo, the existing on-device Latin-script OCR now *suggests*:

- Merchant name → prefill Expense name if blank
- Original total → prefill Amount if blank
- Printed receipt date → preselect the receipt date if found
- Explicit currency markers (SGD, S$, MYR, RM, THB, ฿, USD, etc.) → select the currency if the member has **not** manually chosen one

The app **does not guess from a bare $ or ¥ symbol** because those symbols are ambiguous. It does not change an amount or merchant already entered by the user. The resulting fields can always be reviewed and edited before the expense is saved. OCR is a heuristic, not proof of payment. The recognised receipt date is saved as date metadata, while created_at continues recording when the expense was entered into SplitLui.

## Edit and delete

Open a member-paid expense from **Expenses**. The original author sees **Edit expense** and **Delete expense** actions:

- Edit: title, amount, original currency, conversion rate, payer, split participants and receipt date; server recomputes all original/spending currency shares atomically.
- Delete: confirmation dialog, followed by secure server-side deletion and best-effort receipt object cleanup.
- Other group members can see the expense and receipt but cannot edit or delete it.
- **Important safeguard:** Edit/delete are blocked on the server when the group has any *active confirmed repayment*. This conservative restriction avoids silently changing an already settled debt; reverse the repayment through its own audited flow first, and then re-evaluate whether the change is appropriate.
- Common Fund purchases are **not** editable/deletable in this PR because reversing pooled-money debits requires a dedicated ledger correction workflow.
- Concurrent edits are protected by `updated_at` optimistic concurrency: if another device saved a change, refresh before editing again.
- An expense attached to a receipt can be edited without losing its existing image. Replacing an existing photo is not yet supported in this PR.

## Required Supabase migration

Apply **after** the previous expense, receipt and reversal migrations:

    supabase/migrations/20261103_000014_expense_edit_delete.sql

It adds `receipt_date`, `updated_at`, and three authenticated, security-definer RPCs:
`set_trip_receipt_date`, `edit_trip_expense`, `delete_trip_expense`.

The RPCs enforce current group membership, creator-only mutation, financial input validation, confirmed-repayment checks and atomic expense-share consistency. Direct client write permissions remain restricted. When a receipt object cannot be removed after deleting an expense, the app reports that cleanup is required.

## Test checklist

```sh
git pull origin master
flutter pub get
flutter gen-l10n
flutter analyze
flutter test test/receipt_hints_test.dart
flutter test test/receipt_capture_test.dart
flutter build apk --release
```

1. Apply SQL in Supabase **before installing the APK**.
2. Photograph an SGD receipt. Check merchant, total, date, currency suggestions. Correct any wrong value before saving.
3. Photograph an RM/THB receipt, verify explicit-currency recognition and correct exchange rate prompts.
4. Verify existing user-entered fields are not overwritten, or guessed from a bare $ symbol.
5. Save a new expense with a receipt date and reopen it.
6. As creator, edit total and participants; compare original and converted shares, and Who Owes Whom net balances.
7. As another member, verify Edit/Delete are not available and server calls are denied.
8. Delete an expense, confirm the remaining totals/settlements reconcile.
9. Confirm a repayment, then ensure edit/delete are rejected by the server. Reversed repayments no longer count as active.
10. Open the same expense on two devices, edit on one, then attempt to save on the other; stale version must be rejected.
11. Confirm Common Fund purchases remain unaffected.
12. Test receipt image deletion/cleanup when the uploader has permissions.

**Known limitations:** OCR is Latin-script based and less reliable for Thai/Japanese text; merchant extraction is a best-effort guess. No automatic refresh after offline edits, no editing Common Fund purchases, and no replacement of an already attached photo in this version. Phase 2 offline outbox remains a separate workstream and must be integrated/rebased carefully.

This PR was checked for source syntax balance and JSON integrity, not compiled/tested in a Flutter environment or executed against a live Supabase database.
