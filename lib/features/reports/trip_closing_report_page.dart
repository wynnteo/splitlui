import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/lui_style.dart';
import 'trip_closing_report_api.dart';
import 'trip_closing_pdf.dart';

class TripClosingReportPage extends StatefulWidget {
  const TripClosingReportPage({super.key,required this.groupId,
    required this.groupName,required this.members,
    required this.spendingCurrency,required this.settlementCurrency,
    required this.exchangeRate});
  final String groupId,groupName,spendingCurrency,settlementCurrency;
  final List<Map<String,dynamic>> members;
  final double exchangeRate;
  @override State<TripClosingReportPage> createState()=>
    _TripClosingReportPageState();
}

class _TripClosingReportPageState extends State<TripClosingReportPage> {
  bool includeReceipts=false;
  bool exporting=false;
  String? error;
  Future<void> export() async {
    if(exporting)return;
    setState(()=>exporting=true);
    try {
      final data=await TripClosingReportApi().load(
        groupId:widget.groupId,
        memberIds:widget.members
          .map((m)=>m['user_id'] as String).toList(),
        spendingCurrency:widget.spendingCurrency,
        settlementCurrency:widget.settlementCurrency,
        rate:widget.exchangeRate,
        includeReceipts:includeReceipts,
      );
      final names=<String,String>{
        for(final member in widget.members)
          member['user_id'] as String:
            member['nickname'] as String? ?? 'Member',
      };
      final pdf=await TripClosingPdf.build(
        data:data,groupName:widget.groupName,
        spendingCurrency:widget.spendingCurrency,
        settlementCurrency:widget.settlementCurrency,
        exchangeRate:widget.exchangeRate,
        memberNames:names,includeReceipts:includeReceipts,
      );
      final temp=await getTemporaryDirectory();
      final filename='splitlui_trip_'+DateTime.now()
        .millisecondsSinceEpoch.toString()+'.pdf';
      final output=File(p.join(temp.path,filename));
      await output.writeAsBytes(pdf,flush:true);
      if(!mounted)return;
      await SharePlus.instance.share(ShareParams(
        text:'SplitLui trip summary - '+widget.groupName,
        files:[XFile(output.path,mimeType:'application/pdf')],
      ));
    }catch(e) {
      if(mounted)setState(()=>error=e.toString());
    }finally {
      if(mounted)setState(()=>exporting=false);
    }
  }

  @override Widget build(BuildContext context) {
    final l=AppLocalizations.of(context)!;
    final colors=Theme.of(context).colorScheme;
    return Scaffold(
      appBar:AppBar(title:Text(l.tripReportTitle)),
      body:SafeArea(top:false,child:ListView(
        padding:const EdgeInsets.fromLTRB(20,22,20,40),
        children:[
          Icon(Icons.description_outlined,size:38,color:colors.primary),
          const SizedBox(height:14),
          Text(widget.groupName,style:Theme.of(context)
            .textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.bold)),
          const SizedBox(height:12),
          Text(l.tripReportIntro,
            style:Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height:20),
          Card(child:Padding(padding:const EdgeInsets.all(18),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              LuiSectionHeading(title:l.tripReportIncludes),
              const SizedBox(height:10),
              Text(l.tripReportContents,
                style:Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height:14),
              SwitchListTile.adaptive(
                value:includeReceipts && !exporting,
                contentPadding:EdgeInsets.zero,
                onChanged:exporting?null:
                  (v)=>setState(()=>includeReceipts=v),
                title:Text(l.tripReportIncludeReceipts),
                subtitle:Text(l.tripReportReceiptNotice,
                  style:Theme.of(context).textTheme.bodySmall),
              ),
            ]))),
          const SizedBox(height:14),
          Text(l.tripReportWarning,
            style:Theme.of(context).textTheme.bodySmall),
          if(error!=null) ...[
            const SizedBox(height:14),
            Text(error!,style:TextStyle(color:colors.error)),
          ],
          const SizedBox(height:22),
          FilledButton.icon(
            onPressed:exporting?null:export,
            icon:exporting?const SizedBox(width:18,height:18,
              child:CircularProgressIndicator(strokeWidth:2)):
              const Icon(Icons.picture_as_pdf_outlined),
            label:Text(exporting?l.tripReportGenerating:
              l.tripReportSharePdf),
          ),
        ],
      )),
    );
  }
}
