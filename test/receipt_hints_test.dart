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
}
