import 'package:flutter_test/flutter_test.dart';
import 'package:splitlui/features/expenses/receipt_total_detector.dart';

void main() {
  String? amount(String receipt) {
    final analysis=ReceiptTotalDetector.parse(receipt);
    return analysis.ambiguous ? null : analysis.suggested?.amount;
  }

  test('ordinary receipt with subtotal and GST fills grand total', () {
    expect(amount('Coffee 5.00\nSUBTOTAL 5.00\nGST 0.45\nGRAND TOTAL S\$5.45'), '5.45');
  });

  test('single decimal on a labelled total autofills to cents', () {
    expect(amount('Coffee 18.5\nTOTAL 18.5'), '18.50');
  });

  test('whole number total autofills to cents', () {
    expect(amount('Tea 18\nTOTAL 18'), '18.00');
  });

  test('amount printed beneath total is detected', () {
    expect(amount('Coffee 12.00\nTOTAL\nSGD 12.50'), '12.50');
  });

  test('total amount is not confused with unrelated item counts', () {
    expect(amount('TOTAL\nCoffee 12'), isNull);
  });

  test('ambiguous totals never autofill financial amount', () {
    final result=ReceiptTotalDetector.parse('TOTAL 12.00\nTOTAL 13.00');
    expect(result.ambiguous, isTrue);
    expect(amount('TOTAL 12.00\nTOTAL 13.00'), isNull);
  });

  test('subtotals and tax are not mistaken for total', () {
    expect(amount('SUBTOTAL 19.00\nGST 1.71'), isNull);
  });

  test('zero value never becomes a suggested total', () {
    expect(amount('TOTAL 0'), isNull);
  });

  test('existing two-decimal total behaviour remains', () {
    expect(amount('Amount due: 1,234.50'), '1234.50');
  });
}
