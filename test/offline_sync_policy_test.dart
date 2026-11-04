import 'package:flutter_test/flutter_test.dart';
import 'package:splitlui/features/expenses/offline_expense_outbox.dart';

void main() {
  test('Failure during financial create keeps queue order', () {
    expect(OfflineSyncPolicy.shouldContinueAfterFailure(
      expenseCommitted:false),isFalse);
    expect(OfflineSyncPolicy.failedStatus(
      expenseCommitted:false),'needs_review');
  });

  test('Receipt-only failure does not block subsequent expenses', () {
    expect(OfflineSyncPolicy.shouldContinueAfterFailure(
      expenseCommitted:true),isTrue);
    expect(OfflineSyncPolicy.failedStatus(
      expenseCommitted:true),'receipt_pending');
  });
}
