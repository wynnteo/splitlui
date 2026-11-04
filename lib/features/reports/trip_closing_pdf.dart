import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../settlement/settlement_calculator.dart';
import 'trip_closing_report_api.dart';

class TripClosingPdf {
  static final teal=PdfColor.fromInt(0xFF138C7C);
  static final ink=PdfColor.fromInt(0xFF23303B);
  static final grey=PdfColor.fromInt(0xFF67747D);
  static const bucket='splitlui-receipts';

  static String money(String currency,int cents) =>
    currency+' '+(cents/100).toStringAsFixed(2);
  static String clean(String source) => source;

  static pw.Widget heading(String title)=>pw.Padding(
    padding:const pw.EdgeInsets.only(top:14,bottom:7),
    child:pw.Text(clean(title),style:pw.TextStyle(
      fontSize:14,fontWeight:pw.FontWeight.bold,color:teal)));

  static pw.Widget line(String label,String value,{bool strong=false})=>
    pw.Padding(padding:const pw.EdgeInsets.symmetric(vertical:4),
      child:pw.Row(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
        pw.Expanded(child:pw.Text(clean(label),
          style:pw.TextStyle(fontSize:10,color:ink))),
        pw.SizedBox(width:14),
        pw.Text(clean(value),style:pw.TextStyle(
          fontSize:10,fontWeight:strong ? pw.FontWeight.bold :
            pw.FontWeight.normal,color:ink)),
      ]));

  static pw.Widget note(String value)=>pw.Padding(
    padding:const pw.EdgeInsets.symmetric(vertical:5),
    child:pw.Text(clean(value),style:pw.TextStyle(fontSize:9,color:grey)));

  static Future<Uint8List> build({
    required TripClosingReportData data,
    required String groupName,
    required String spendingCurrency,
    required String settlementCurrency,
    required double exchangeRate,
    required Map<String,String> memberNames,
    required bool includeReceipts,
    bool chinese=false,
  }) async {
    // Noto Sans SC covers English and Simplified Chinese. The font is
    // downloaded/cached by printing; a PDF export requires connectivity.
    final font=await PdfGoogleFonts.notoSansSCRegular();
    String t(String en,String zh)=>chinese?zh:en;
    final pdf=pw.Document(
      title:'SplitLui Trip Report - '+clean(groupName),author:'SplitLui');
    final snapshot=data.snapshot;
    String person(String id)=>clean(memberNames[id]??'Member');
    String spending(int cents)=>money(spendingCurrency,cents);
    String estimated(int cents) =>
      spendingCurrency==settlementCurrency ? spending(cents) :
        'about '+settlementCurrency+' '+
        (cents/100/exchangeRate).toStringAsFixed(2);

    final content=<pw.Widget>[
      pw.Text(t('TRIP SUMMARY','旅程结算报告'),style:pw.TextStyle(
        color:teal,fontSize:10,letterSpacing:1.5)),
      pw.SizedBox(height:6),
      pw.Text(clean(groupName),style:pw.TextStyle(
        fontSize:24,fontWeight:pw.FontWeight.bold,color:ink)),
      pw.SizedBox(height:5),
      note(t('Generated: ','生成时间：')+data.generatedAt.toLocal().toIso8601String()
        .substring(0,16)+t(' | Read-only snapshot; no money moved','｜只读快照，不会转账')),
      pw.SizedBox(height:10),
      pw.Container(
        padding:const pw.EdgeInsets.all(12),
        decoration:pw.BoxDecoration(
          color:PdfColor.fromInt(0xFFEAF7F3),
          borderRadius:pw.BorderRadius.circular(10)),
        child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
          pw.Text(snapshot.needsReview?t('ACTION STILL NEEDED','仍有待处理事项'):
            t('NO OPEN BALANCES DETECTED','暂无待结余额'),
            style:pw.TextStyle(color:teal,
              fontWeight:pw.FontWeight.bold,fontSize:11)),
          note(snapshot.needsReview ?
            t('Review pending sync, outstanding transfers, collection targets and fund reconciliation.',
              '请检查待同步开销、未结清还款、贡献目标及基金对账。') :
            t('This does not confirm transfers or formally close the group.',
              '这不代表已确认转账，也不会正式关闭群组。')),
        ])),
      heading(t('Shared expenses by original currency','按原币种统计开销')),
      for(final row in snapshot.expenseSummary.totals)
        line(row.currency+' ('+row.count.toString()+t(' expenses',' 笔开销')+')',
          money(row.currency,row.cents)),
      pw.Divider(color:PdfColors.grey300),
      line(t('Estimated combined spending','换算后开销总额'),
        money(snapshot.expenseSummary.totalSettlementCurrency,
          snapshot.expenseSummary.totalSettlementCents),strong:true),
      note(t('Exchange-rate totals are estimates. Common Fund purchases are tracked separately.',
        '汇率换算仅为估算；共同基金支出独立记录，不重复计算。')),
      heading(t('Who pays whom - remaining suggestions','待结清的还款建议')),
      if(snapshot.settlements.transfers.isEmpty)
        note(t('No suggested repayments remain.','暂无待结清还款。'))
      else
        for(final transfer in snapshot.settlements.transfers)
          line(person(transfer.fromUserId)+t(' pays ',' 支付给 ')+person(transfer.toUserId),
            estimated(transfer.cents)),
      note(t('These are suggestions, not proof of payment. Members can agree to rounded amounts.',
        '仅供还款参考，并非付款证明；成员可协商四舍五入金额。')),
      heading(t('Member balances','成员结算余额')),
      for(final balance in snapshot.settlements.balances)
        line(person(balance.userId),
          balance.cents==0?t('Settled','已结清'):
            balance.cents>0?t('To receive: ','应收：')+estimated(balance.cents):
              t('To pay: ','应付：')+estimated(-balance.cents)),
      heading(t('Common Fund - ','共同基金 - ')+spendingCurrency),
      line(t('Contributions received','已收贡献金额'),spending(snapshot.fundContributionsCents)),
      line(t('Fund purchases','共同基金支出'),spending(snapshot.fundSpentCents)),
      line(t('Confirmed refunds','已确认退款'),spending(snapshot.fundRefundsCents)),
      pw.Divider(color:PdfColors.grey300),
      line(t('Available fund balance','共同基金余额'),spending(snapshot.fundBalanceCents),
        strong:true),
      line(t('Contribution target','贡献目标'),spending(snapshot.fundTargetCents)),
      line(t('Still to collect','仍待收取'),spending(snapshot.fundOutstandingCents)),
      if(!snapshot.fundReconciles)
        note(t('WARNING: Fund balance does not reconcile with contributions, purchases and refunds.',
          '警告：基金余额与贡献、支出和退款总额不一致。')),
      heading(t('Repayment confirmations','已确认还款')),
      line(t('Confirmed receipts','已确认收款'),snapshot.activeRepayments.toString()),
      line(t('Reversed receipts','已撤销收款'),snapshot.reversedRepayments.toString()),
      for(final row in data.repayments)
        line(person(row['from_user_id'] as String)+' to '+
          person(row['to_user_id'] as String),
          money(row['paid_currency'] as String,
            SettlementCalculator.cents(row['paid_amount']))+
          (row['reversed_at']!=null?t(' (REVERSED)','（已撤销）'):t(' (CONFIRMED)','（已确认）'))),
      heading(t('Confirmed Common Fund refunds','已确认的共同基金退款')),
      if(data.fundRefunds.isEmpty) note(t('No confirmed refunds.','暂无已确认退款。'))
      else for(final row in data.fundRefunds)
        line(person(row['member_id'] as String),
          spending(SettlementCalculator.cents(row['amount']))),
      heading(t('Pending and sync checks','待同步事项')),
      line(t('Pending expenses on this device','本机待同步开销'),
        snapshot.pendingLocalCount.toString()),
      if(snapshot.pendingLocalCount>0)
        note(t('Expenses on this device have not all synced; other members may have unsynced items.',
          '本机仍有开销未同步；其他成员也可能有未同步记录。')),
      if(snapshot.fundOutstandingCents>0)
        note(t('Contribution targets are requests only, not received money.',
          '贡献目标只是待收金额，并非实际收到的资金。')),
      note(t('PayNow numbers and bank details are excluded. Recipients may retain this PDF.',
        '报告不包含 PayNow 号码或银行资料；收件人可能保留此 PDF。')),
    ];

    // Opt-in only: private receipt files are downloaded with the signed-in
    // member's permission. Limit count and size on mobile devices.
    var count=0,skipped=0;
    if(includeReceipts && data.receipts.isNotEmpty) {
      content.add(heading(t('Receipt photos (up to 8)','收据照片（最多8张）')));
      for(final receipt in data.receipts) {
        if(count>=8){skipped++;continue;}
        try {
          final bytes=await Supabase.instance.client.storage.from(bucket)
            .download(receipt['object_path'] as String);
          if(bytes.isEmpty||bytes.length>5*1024*1024) {
            skipped++;continue;
          }
          content.add(pw.Column(
            crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
              heading((receipt['expense_id']!=null ?
                t('Shared expense','共同开销') : t('Common Fund','共同基金'))+t(' receipt ',' 收据 ')+(count+1).toString()),
              pw.Image(pw.MemoryImage(bytes),
                height:220,fit:pw.BoxFit.contain),
            ]));
          count++;
        }catch(_){skipped++;}
      }
      if(skipped>0)content.add(note(skipped.toString()+
        t(' receipt image(s) omitted (limit or download error).',
          ' 张收据照片未附上（数量上限或下载失败）。')));
    }

    pdf.addPage(pw.MultiPage(
      pageFormat:PdfPageFormat.a4,
      theme:pw.ThemeData.withFont(base:font,bold:font),
      margin:const pw.EdgeInsets.fromLTRB(36,38,36,42),
      maxPages:250,
      footer:(context)=>pw.Align(alignment:pw.Alignment.centerRight,
        child:pw.Text('SplitLui | Page '+context.pageNumber.toString()+
          ' of '+context.pagesCount.toString(),
          style:pw.TextStyle(fontSize:8,color:grey))),
      build:(_)=>content,
    ));
    return Uint8List.fromList(await pdf.save());
  }
}
