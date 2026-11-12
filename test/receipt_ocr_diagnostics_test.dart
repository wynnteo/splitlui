import 'package:flutter_test/flutter_test.dart';
import 'package:splitlui/features/expenses/receipt_total_detector.dart';

void main() {
  test('Singapore receipt: TOTAL and GST-inclusive total both recognised', () {
    final analysis=ReceiptTotalDetector.parse('''
1 Ma La Pork Bone Collagen Soup 13.45
1 Medium 0.00
1 Fried 0.00
Total Incl. GST 13.45
TOTAL 13.45
UOB MDR 13.45
''');
    expect(analysis.ambiguous,isFalse);
    expect(analysis.suggested?.amount,'13.45');
    expect(analysis.candidates.length,1);
  });

  test('repeated amount without a recognised total is reviewable, not auto-fill', () {
    final analysis=ReceiptTotalDetector.parse('''
1 Ma La Pork Bone Collagen Soup 13.45
T0TAL 13.45
UOB MDR 13.45
''');
    expect(analysis.suggested,isNull);
    expect(analysis.candidates.first.amount,'13.45');
    expect(analysis.candidates.first.score,lessThan(7));
  });

  test('single item amount without total never auto-fills', () {
    final analysis=ReceiptTotalDetector.parse('Coffee 8.50');
    expect(analysis.suggested,isNull);
    expect(analysis.candidates,isEmpty);
  });

  test('GST-only rows do not become totals', () {
    final analysis=ReceiptTotalDetector.parse('GST 1.20\nVAT 0.50');
    expect(analysis.candidates,isEmpty);
  });

  test('conflicting totals need manual selection', () {
    final analysis=ReceiptTotalDetector.parse(
      'TOTAL 12.50\nTOTAL 13.45');
    expect(analysis.ambiguous,isTrue);
  });
}
