# Phase 4 — Trip Closing Report (PDF)

## User workflow

Group → **Trip closing report** → optional **Include receipt photos**
→ **Create and share PDF**.

The export uses Flutter's `pdf` package and the OS share sheet. There
is **no subscription, no server-side PDF generation, no automatic bank
transfer and no fund-closing operation** in this PR.

The report is a **read-only snapshot** of the data accessible to the
current authenticated group member:

- Original-currency member-paid expenses (SGD, THB, MYR, etc.), separated
  by currency. An estimated combined settlement-currency amount is
  calculated using the current trip rate and saved transaction rates.
- Remaining **Who pays whom** suggestions and member balances.
- Actual confirmed repayment receipts in their **paid currency**, with
  reversed receipts clearly marked. No THB back-conversion in history.
- Common Fund contributions, fund purchases, confirmed refunds, current
  balance, contribution targets, and amounts still to collect.
- An explicit reconciliation warning if fund contribution totals minus
  purchases and refunds do not equal the current fund account balance.
- An explicit pending sync count for offline expense creations on this
  exporting device. Other members' offline drafts are not visible here.
- Optional up-to-eight receipt photos downloaded from private Supabase
  Storage (never public URLs), subject to permissions and download limits.

Common Fund paid purchases are never added to member-paid shared expenses;
therefore the same purchase is not double-counted. A receipt confirmation
never creates a new payment.

## Privacy and limitations

- **Consent:** Receipt images are excluded by default. Sharing the PDF
  makes its contents (including any included receipt photos) available
  to whomever receives it; do not include account credentials or PayNow
  numbers. The PDF deliberately excludes saved PayNow numbers.
- **Unicode caveat:** In the first PDF iteration, output labels are
  English even if the app is in Chinese. The bundled PDF base font
  supports Latin characters only; names containing Chinese/Thai/
  Japanese characters are conservatively replaced with `?` rather
  than producing broken glyphs. A follow-up can embed an appropriate
  openly licensed CJK font and deliver proper multilingual reports.
- Pending local drafts are not sent to Supabase by exporting.
  Other members may have unsynced entries; therefore this is not a
  guarantee of finality.
- If any required Supabase query fails, export fails clearly rather
  than generating a misleading partial PDF.
- Reports are created in the app's temporary directory. The shared
  copy can be retained by recipients. Temp files may be removed by
  the operating system.
- Receipt photos are capped at 8 files / 5MB each. Skipped images
  are counted in the report.
- Trip exchange-rate estimates are not live FX quotes. Actual paid
  receipts retain their independently recorded values.
- Export does not certify that fund refunds were received beyond
  what members marked as confirmed.

## Dependencies and database

New dependency: `pdf: ^3.11.3`.

**No new SQL migration** in this PR. The previous Common Fund targets,
refunds, receipt storage, settlement and repayment migrations must already
be applied correctly.

## Verification

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test test/trip_closing_snapshot_test.dart
flutter build apk --release
```

On a real phone:

1. Create a group using THB spending and SGD settlement.
2. Add one SGD expense and one THB expense with different payers;
   export and compare the currency subtotals and converted estimate.
3. Pay for an additional purchase using Common Fund. It must appear
   ONLY in Common Fund accounting, not in member-paid expense totals.
4. Add a contribution, a refund, and a member target. Confirm cash
   totals, available fund balance and outstanding contribution amount.
5. Confirm one repayment, then reverse it. Both should be shown in
   receipt history with accurate status; reversed repayments do not
   reduce outstanding debt.
6. Create an offline expense without syncing and open report. It must
   warn about pending sync. If the current device is offline and server
   data cannot be fetched, export must fail rather than claim finality.
7. Include receipts and share through the OS share sheet. Check that
   no images are included if the switch is off, and a nonmember cannot
   access group receipt objects.
8. Test group and member names containing CJK text; this MVP
   transparently substitutes unsupported characters with `?`.
9. Check multi-page PDFs on Android and iOS, plus light/dark modes.
10. Run with a second group member and compare their current report.

## Premium / subscription direction

Treat the report as a candidate for a future **one-time Trip Pass** with
professional layouts and complete receipt archives. Do not gate existing
free settlement or Common Fund accounting behind subscription before
billing purchase restoration and account recovery are robust.

**Testing status:** GitHub source checks only. Flutter build, rendering
inspection and real-device Supabase tests were not run here. Keep this
feature behind a draft PR until validated.
