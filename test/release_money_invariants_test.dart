import 'package:flutter_test/flutter_test.dart';
import 'package:splitlui/features/expenses/split_allocation.dart';
import 'package:splitlui/features/settlement/settlement_calculator.dart';
import 'package:splitlui/features/expenses/receipt_total_detector.dart';

void main() {
  group('Money invariants', () {
    test('odd cents allocated in full', () {
      final shares=SplitAllocation.calculate(
        totalCents:10000,mode:ExpenseSplitMode.equal,values:[1,1,1]);
      expect(shares.cents,[3334,3333,3333]);
      expect(shares.totalCents,10000);
    });

    test('exact shares must reconcile', () {
      expect(()=>SplitAllocation.calculate(
        totalCents:1000,mode:ExpenseSplitMode.exact,
        values:[5.00,4.99]),throwsFormatException);
    });

    test('converted bill shares retain all cents', () {
      final shares=SplitAllocation.convertProportionally(
        convertedTotalCents:101,
        originalShareCents:[600,300,100]);
      expect(shares.cents,[61,30,10]);
    });

    test('settlement has a zero-sum ledger and one transfer', () {
      final result=SettlementCalculator.calculate(
        memberIds:['a','b'],
        expenses:[
          {'id':'e','paid_by':'a','amount_spending':'100.00'},
        ],
        shares:[
          {'expense_id':'e','user_id':'a','share_spending':'50.00'},
          {'expense_id':'e','user_id':'b','share_spending':'50.00'},
        ]);
      expect(result.transfers.length,1);
      expect(result.transfers.single.fromUserId,'b');
      expect(result.transfers.single.toUserId,'a');
      expect(result.transfers.single.cents,5000);
      expect(result.balances.fold<int>(0,(n,b)=>n+b.cents),0);
    });

    test('broken or incomplete share totals fail closed', () {
      expect(()=>SettlementCalculator.calculate(
        memberIds:['a','b'],
        expenses:[{'id':'e','paid_by':'a','amount_spending':'100.00'}],
        shares:[{'expense_id':'e','user_id':'b',
          'share_spending':'99.99'}]),throwsStateError);
    });

    test('receipt total ignores GST and cash received', () {
      final parsed=ReceiptTotalDetector.parse(
        'RECEIPT\nSUBTOTAL 100.00\nGST 9.00\n'
        'GRAND TOTAL 109.00\nCASH TENDERED 120.00');
      expect(parsed.suggested?.amount,'109.00');
    });
  });
}
