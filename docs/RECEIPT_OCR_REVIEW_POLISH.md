# Receipt OCR Review — existing Add Expense improvement

## Scope

This PR improves the **existing** camera/gallery receipt flow without
introducing a new page, paid tier, cloud OCR service, SQL migration or
dependency.

The image still uses on-device Latin-script Google ML Kit recognition and
keeps the same private, compressed JPEG storage and offline queue from PR #40.

### Detection improvements

- Candidate totals are ranked from *labelled* receipt lines rather than
  simply choosing the greatest number. Explicit labels such as GRAND TOTAL,
  AMOUNT DUE, TOTAL PAYABLE and NET TOTAL rank above generic TOTAL.
- Excludes likely GST/VAT, discount, subtotal, tip, cash tendered and
  change lines. Supports a thermal-receipt TOTAL heading on one line
  followed by its amount on the next.
- Supports both `1,234.50` and `1.234,50` forms and two decimal digits.
  No amount suggestion is made when only item prices are present.
- If several similarly credible but different totals appear, **no total is
  automatically entered**. The user can tap the correct candidate.
- Currency detection handles `S$` versus `US$` distinctly, recognises
  `RM100.00`, and avoids choosing when different explicit currencies
  appear on the receipt. A plain `$` remains ambiguous.
- Merchant detection skips common RECEIPT/TAX INVOICE/TOTAL/date/phone lines.
- ISO dates remain unambiguous. Ambiguous day/month dates (for example
  02/04/2025) are **not auto-applied**; users explicitly tap a suggested
  date after checking the printout.

### Review UI

After choosing a receipt, the existing Add Expense form shows a compact
**Detected on receipt** section alongside the saved photo. Each available
merchant, amount, currency and date is a tap-to-apply suggestion.
This is important for blurred receipts and ambiguous totals.

Previously entered amount/title/currency/date values are not silently
overwritten. The user can tap a suggestion to replace a field manually,
or type their own value. If no reliable total exists, the app explains
that it must be entered manually.

The separate member-paid split modes, Common Fund handling, exchange-rate
selection and receipt upload/retry rules are unchanged.

### Tests and validation

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test test/receipt_total_detector_test.dart
flutter test test/receipt_capture_test.dart
flutter test test/receipt_hints_test.dart
flutter test
flutter build apk --release
```

Device testing should include SGD/MYR/THB receipts, S$ vs US$, amounts
with thousands separators, multiple amounts labelled TOTAL, tax/discount
lines, mixed-currency card slips, missing totals, bad OCR text,
ISO vs ambiguous DD/MM dates, and a receipt attached to a queued
offline expense. Check that applying suggested total also updates the
existing split preview and that a manual correction is never lost.

**Known limitations:** Latin OCR cannot read Thai script reliably;
poor scans can still produce wrong suggestions; date formats not covered
by the parser are intentionally left blank. This is not item-level
receipt splitting or receipt replacement for existing expenses.

Source syntax/translation checks are not a substitute for running
Flutter tests and verifying the UI on a device.
