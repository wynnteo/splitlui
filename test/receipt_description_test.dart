import 'package:flutter_test/flutter_test.dart';
import 'package:splitlui/features/expenses/receipt_hints.dart';

void main() {
  test('suggests single purchased item from Singapore food receipt', () {
    const text = '''
30 Sembawang Drive
#01-24 Sun Plaza
Singapore 757713
Queue No: 08
Date & time: 12-11-26 11:39
1 Ma La Pork Bone Collagen Soup 13.45
1 Medium 0.00
1 Fried 0.00
Total Incl. GST 13.45
TOTAL 13.45
UOB MDR 13.45
''';
    expect(ReceiptHints.parse(text).itemDescription,
      'Ma La Pork Bone Collagen Soup');
  });

  test('does not auto-suggest one of several purchases', () {
    const text = '1 Coffee 4.50\n1 Chicken Rice 6.50\nTOTAL 11.00';
    expect(ReceiptHints.parse(text).itemDescription, isNull);
  });

  test('ignores free modifiers and total lines', () {
    const text = '1 Chicken Rice 6.50\n1 Extra Chilli 0.00\nTOTAL 6.50';
    expect(ReceiptHints.parse(text).itemDescription, 'Chicken Rice');
  });

  test('recognises split description and amount OCR lines', () {
    const text = '1 Ma La Pork Bone Collagen Soup\n13.45\nTOTAL 13.45';
    expect(ReceiptHints.parse(text).itemDescription,
      'Ma La Pork Bone Collagen Soup');
  });

  test('does not use queue numbers as receipt item descriptions', () {
    expect(ReceiptHints.parse('Queue No: 08\nTOTAL 13.45')
      .itemDescription, isNull);
  });
}
