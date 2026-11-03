import 'package:flutter_test/flutter_test.dart';
import 'package:splitlui/features/expenses/receipt_capture.dart';

void main() {
  test('Suggests the printed total, not subtotal or tax', () {
    const input = 'COFFEE SHOP\nSUBTOTAL 80.00\nGST 7.20\nTOTAL 87.20';
    expect(ReceiptCapture.extractTotal(input), '87.20');
  });

  test('Recognises amount due with comma decimal', () {
    expect(ReceiptCapture.extractTotal(
      'RESTAURANT\nAMOUNT DUE 125,50'), '125.50');
  });

  test('Does not guess amounts without a total label', () {
    expect(ReceiptCapture.extractTotal(
      'COFFEE 4.50\nTEA 5.20\nTAX 0.97'), isNull);
  });

  test('Removes non-positive suggestions', () {
    expect(ReceiptCapture.extractTotal('TOTAL 0.00'), isNull);
  });
}
