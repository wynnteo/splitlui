import 'package:flutter_test/flutter_test.dart';
import 'package:splitlui/features/reports/trip_closing_snapshot.dart';
import 'package:splitlui/features/reports/trip_closing_pdf.dart';
import 'package:splitlui/features/reports/trip_closing_report_api.dart';

void main() {
  test('Renders a PDF report without contacting Storage', () async {
    final snapshot=TripClosingSnapshot.calculate(
      memberIds:['alex','ben'],spendingCurrency:'THB',
      settlementCurrency:'SGD',spendingPerSettlement:25,
      expenses:[
        {'id':'1','paid_by':'alex','amount':500.0,
         'currency':'THB','amount_spending':500.0},
      ],
      shares:[
        {'expense_id':'1','user_id':'alex','share_spending':250.0},
        {'expense_id':'1','user_id':'ben','share_spending':250.0},
      ],
      repayments:const [],fundEntries:const [],fundRefunds:const [],
      fundTargets:const [],fundBalanceCents:0,pendingLocalCount:0);
    final report=TripClosingReportData(
      snapshot:snapshot,expenses:const [],repayments:const [],
      fundEntries:const [],fundRefunds:const [],receipts:const [],
      generatedAt:DateTime(2026,11,4,12),
    );
    final result=await TripClosingPdf.build(
      data:report,groupName:'Bangkok trip',
      spendingCurrency:'THB',settlementCurrency:'SGD',
      exchangeRate:25,
      memberNames:const {'alex':'Alex','ben':'Ben'},
      includeReceipts:false,
    );
    expect(result.length,greaterThan(100));
    expect(String.fromCharCodes(result.take(4)), '%PDF');
  });
}
