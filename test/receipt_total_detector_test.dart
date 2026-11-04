import 'package:flutter_test/flutter_test.dart';
import 'package:splitlui/features/expenses/receipt_total_detector.dart';

void main() {
  test('Prefers final labelled total over subtotal, GST and cash change', () {
    const text='DINER\nSUBTOTAL 100.00\nGST 9.00\n'
      'SERVICE CHARGE 10.00\nGRAND TOTAL 119.00\n'
      'CASH TENDERED 120.00\nCHANGE 1.00';
    final result=ReceiptTotalDetector.parse(text);
    expect(result.suggested?.amount,'119.00');
    expect(result.ambiguous,isFalse);
    expect(result.candidates.map((c)=>c.amount),isNot(contains('120.00')));
  });

  test('Parses 1,234.50 and 1.234,50 without dropping thousands', () {
    expect(ReceiptTotalDetector.parse('AMOUNT DUE 1,234.50')
      .suggested?.amount,'1234.50');
    expect(ReceiptTotalDetector.parse('AMOUNT DUE 1.234,50')
      .suggested?.amount,'1234.50');
  });

  test('Handles TOTAL label on previous OCR line', () {
    expect(ReceiptTotalDetector.parse('MARKET\nTOTAL\n85.20')
      .suggested?.amount,'85.20');
  });

  test('Flags conflicting plausible totals for user review', () {
    const text='TOTAL DUE 100.00\nAMOUNT PAYABLE 105.00';
    final result=ReceiptTotalDetector.parse(text);
    expect(result.ambiguous,isTrue);
    expect(result.candidates.length,2);
  });

  test('Will not invent a total from item prices or change', () {
    expect(ReceiptTotalDetector.parse(
      'COFFEE 5.00\nCAKE 6.20\nTAX 0.80\nCHANGE 1.00')
      .suggested,isNull);
    expect(ReceiptTotalDetector.parse('TOTAL 0.00').suggested,isNull);
  });

  test('Last receipt total wins among equally plausible labels', () {
    final result=ReceiptTotalDetector.parse(
      'TOTAL 100.00\nSOMETHING\nTOTAL 102.00');
    expect(result.candidates.first.amount,'102.00');
    expect(result.ambiguous,isTrue);
  });
}
