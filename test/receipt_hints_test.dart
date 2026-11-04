import 'package:flutter_test/flutter_test.dart';
import 'package:splitlui/features/expenses/receipt_hints.dart';

void main() {
  test('Recognises explicit SGD receipt merchant and ISO date', () {
    final hints=ReceiptHints.parse(
      'KOPITIAM EXPRESS\nTAX INVOICE\nDATE 2025-11-03\nTOTAL SGD 23.50');
    expect(hints.merchant,'KOPITIAM EXPRESS');
    expect(hints.currency,'SGD');
    expect(hints.date,DateTime(2025,11,3));
  });
  test('Recognises Thai currency but not generic $', () {
    expect(ReceiptHints.parse('BANGKOK FOOD\nTOTAL ฿850.00').currency,'THB');
    expect(ReceiptHints.parse('SOME CAFE\nTOTAL $10.00').currency,isNull);
  });
  test('Recognises MYR and day-month-year dates', () {
    final hints=ReceiptHints.parse('MAMAK RESTAURANT\n02/04/2025\nRM 56.20');
    expect(hints.currency,'MYR');
    expect(hints.date,DateTime(2025,4,2));
  });
  test('Rejects invalid and future dates', () {
    expect(ReceiptHints.parse('CAFE\n31/02/2025').date,isNull);
    expect(ReceiptHints.parse('CAFE\n2099-12-30').date,isNull);
  });
  test('Skips receipt header when finding merchant', () {
    expect(ReceiptHints.parse(
      'TAX INVOICE\nMY COFFEE SHOP\nAMOUNT DUE 20.00').merchant,
      'MY COFFEE SHOP');
  });
  test('US dollar marker must not be mistaken for Singapore dollars', () {
    expect(ReceiptHints.parse(r'COFFEE STAND\nTOTAL US$25.00'
      .replaceAll(r'\n','\n')).currency,'USD');
    expect(ReceiptHints.parse(r'COFFEE STAND\nTOTAL S$25.00'
      .replaceAll(r'\n','\n')).currency,'SGD');
  });

  test('Conflicting SGD and MYR amounts require manual currency review', () {
    final result=ReceiptHints.parse(
      'SHOP\nTOTAL SGD 30.00\nCARD MYR 100.00');
    expect(result.currency,isNull);
  });

  test('A total printed before the merchant is never the merchant', () {
    expect(ReceiptHints.parse(
      'RECEIPT\nTOTAL 12.00\nMY LITTLE CAFE\nGST 1.00').merchant,
      'MY LITTLE CAFE');
  });

  test('RM directly adjacent to a figure is MYR', () {
    expect(ReceiptHints.parse('RESTORAN\nTOTAL RM100.00').currency,'MYR');
  });

  test('Ambiguous numeric dates require explicit review', () {
    final ambiguous=ReceiptHints.parse('COFFEE\n02/04/2025');
    expect(ambiguous.date,DateTime(2025,4,2));
    expect(ambiguous.dateNeedsReview,isTrue);
    expect(ReceiptHints.parse('COFFEE\n25/04/2025')
      .dateNeedsReview,isFalse);
    expect(ReceiptHints.parse('COFFEE\n2025-04-02')
      .dateNeedsReview,isFalse);
  });

}
