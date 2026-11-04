import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/lui_style.dart';
import 'fund_reconciliation.dart';

class AdvancedFundSection extends StatefulWidget {
  const AdvancedFundSection({super.key,required this.groupId,
    required this.currency,required this.members,required this.entries,
    required this.balance,required this.isOwner,required this.onChanged});
  final String groupId,currency;
  final List<Map<String,dynamic>> members,entries;
  final double balance;
  final bool isOwner;
  final Future<void> Function() onChanged;
  @override State<AdvancedFundSection> createState()=>_AdvancedFundSectionState();
}

class _AdvancedFundSectionState extends State<AdvancedFundSection> {
  final db=Supabase.instance.client;
  List<Map<String,dynamic>> targets=[],requests=[],refunds=[];
  bool busy=true;
  String? error;
  String? _refundOperation;
  String? _refundFingerprint;

  @override void initState() {super.initState();refresh();}
  @override void didUpdateWidget(covariant AdvancedFundSection old) {
    super.didUpdateWidget(old);
    if(old.entries!=widget.entries || old.balance!=widget.balance) refresh();
  }
  List<Map<String,dynamic>> maps(dynamic rows)=>
    (rows as List).map((x)=>Map<String,dynamic>.from(x as Map)).toList();
  Future<void> refresh() async {
    if(!mounted)return;
    setState(()=>busy=true);
    try {
      final data=await Future.wait<dynamic>([
        db.from('trip_fund_targets').select('member_id,target_amount')
          .eq('group_id',widget.groupId),
        db.from('trip_fund_topup_requests')
          .select('id,member_id,requested_amount,note,cancelled_at')
          .eq('group_id',widget.groupId).order('created_at',ascending:false),
        db.from('trip_fund_refunds').select('member_id,amount,note,created_at')
          .eq('group_id',widget.groupId).order('created_at',ascending:false),
      ]);
      if(mounted)setState(() {targets=maps(data[0]);requests=maps(data[1]);
        refunds=maps(data[2]);error=null;});
    }catch(e) {if(mounted)setState(()=>error=e.toString());}
    finally {if(mounted)setState(()=>busy=false);}
  }
  int cents(num? value)=>FundReconciliation.cents(value??0);
  String money(int value)=>widget.currency+' '+(value/100).toStringAsFixed(2);
  String name(String id) {
    for(final m in widget.members) {
      if(m['user_id']==id)return m['nickname'] as String? ?? id;
    }
    return id;
  }
  int received(String id)=>widget.entries.where((x)=>
    x['entry_type']=='contribution'&&x['member_id']==id)
    .fold(0,(int n,x)=>n+cents(x['amount'] as num));
  int refunded(String id)=>refunds.where((x)=>x['member_id']==id)
    .fold(0,(int n,x)=>n+cents(x['amount'] as num));
  int target(String id) {
    for(final t in targets) {
      if(t['member_id']==id)return cents(t['target_amount'] as num);
    }
    return 0;
  }
  Future<String?> ask(String heading,{bool note=false,bool allowZero=false}) async {
    final l=AppLocalizations.of(context)!;
    final key=GlobalKey<FormState>();
    var entered='';
    return await showModalBottomSheet<String>(
        context:context,isScrollControlled:true,useSafeArea:true,
        showDragHandle:true,
        builder:(ctx)=>Padding(
          padding:EdgeInsets.only(bottom:MediaQuery.viewInsetsOf(ctx).bottom),
          child:SingleChildScrollView(padding:const EdgeInsets.all(20),
            child:Form(key:key,child:Column(mainAxisSize:MainAxisSize.min,
              crossAxisAlignment:CrossAxisAlignment.stretch,children:[
                Text(heading,style:Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height:14),
                TextFormField(autofocus:true,onChanged:(value)=>entered=value,
                  maxLength:note?120:null,
                  keyboardType:note?TextInputType.text:
                    const TextInputType.numberWithOptions(decimal:true),
                  decoration:InputDecoration(
                    prefixText:note?null:widget.currency+' '),
                  validator:(raw) {
                    final value=(raw??'').trim();
                    if(note) return value.length<3?l.required:null;
                    final n=double.tryParse(value);
                    if(!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)
                        ||n==null||!n.isFinite||n<0
                        ||(!allowZero&&n==0)||n>99999999999999.99) {
                      return l.invalid;
                    }
                    return null;
                  }),
                const SizedBox(height:16),
                FilledButton(onPressed:(){
                  if(key.currentState?.validate()??false) {
                    Navigator.pop(ctx,entered.trim());
                  }
                },child:Text(l.saveChanges)),
              ],
            ))),
          ),
        );
  }
  Future<bool> perform(Future<dynamic> Function() action) async {
    if(busy)return false;
    setState(()=>busy=true);
    try {
      await action();await widget.onChanged();
      if(mounted)await refresh();
      return true;
    } catch(e) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text(e.toString())));
      return false;
    } finally {if(mounted)setState(()=>busy=false);}
  }
  Future<void> setTarget(String id) async {
    final l=AppLocalizations.of(context)!;
    final value=await ask(l.fundTargetSet,allowZero:true);
    if(value==null||!mounted)return;
    await perform(()=>db.rpc('set_trip_fund_target',params:{
      'p_group':widget.groupId,'p_member':id,'p_target':double.parse(value)}));
  }
  Future<void> requestTopup(String id) async {
    final l=AppLocalizations.of(context)!;
    final value=await ask(l.fundTopUpRequest);
    if(value==null||!mounted)return;
    await perform(()=>db.rpc('request_trip_fund_topup',params:{
      'p_group':widget.groupId,'p_member':id,'p_amount':double.parse(value),
      'p_note':''}));
  }
  Future<void> refund(String id) async {
    final l=AppLocalizations.of(context)!;
    final amount=await ask(l.fundRefundConfirm);
    if(amount==null||!mounted)return;
    final note=await ask(l.fundRefundNote,note:true);
    if(note==null||!mounted)return;
    final yes=await showDialog<bool>(context:context,builder:(ctx)=>
      AlertDialog(title:Text(l.fundRefundConfirm),
        content:Text(l.fundRefundWarning),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),
            child:Text(l.cloudCancel)),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),
            child:Text(l.fundRefundConfirm)),
        ]));
    if(yes!=true||!mounted)return;
    final fingerprint=id+'|'+amount+'|'+note;
    if(_refundFingerprint!=fingerprint || _refundOperation==null) {
      _refundFingerprint=fingerprint;
      _refundOperation=const Uuid().v4();
    }
    final done=await perform(()=>db.rpc('confirm_trip_fund_refund',params:{
      'p_group':widget.groupId,'p_member':id,
      'p_amount':double.parse(amount),'p_note':note,
      'p_operation':_refundOperation}));
    if(done){_refundOperation=null;_refundFingerprint=null;}
  }
  Future<void> cancel(String id) async {
    await perform(()=>db.rpc('cancel_trip_fund_topup',params:{
      'p_group':widget.groupId,'p_request':id}));
  }

  @override Widget build(BuildContext context) {
    final l=AppLocalizations.of(context)!;
    final scheme=Theme.of(context).colorScheme;
    if(busy) return const Center(child:Padding(
      padding:EdgeInsets.all(20),child:CircularProgressIndicator()));
    if(error!=null)return Card(child:Padding(
      padding:const EdgeInsets.all(16),
      child:Column(children:[Text(l.fundAdvancedLoadError),
        Text(error!,style:Theme.of(context).textTheme.bodySmall),
        TextButton(onPressed:refresh,child:Text(l.cloudRefresh))])));
    final targetTotal=widget.members.fold(0,(int a,m)=>
      a+target(m['user_id'] as String));
    final collected=widget.members.fold(0,(int a,m)=>
      a+received(m['user_id'] as String));
    final totalRefunds=FundReconciliation.sumRefunds(refunds);
    final spent=FundReconciliation.sumEntries(widget.entries,'expense');
    final outstanding=widget.members.fold(0,(int a,m) {
      final id=m['user_id'] as String;
      final diff=target(id)-received(id);
      return a+FundReconciliation.contributionOutstanding(
        targetCents:target(id),contributedCents:received(id));
    });
    final balance=cents(widget.balance);
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      LuiSectionHeading(title:l.fundContributionTargets),
      const SizedBox(height:12),
      Card(child:Padding(padding:const EdgeInsets.all(16),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          summaryLine(l.fundTargetTotal,money(targetTotal)),
          summaryLine(l.fundTotalReceived,money(collected)),
          summaryLine(l.fundOutstandingToCollect,money(outstanding)),
          const SizedBox(height:8),
          Text(l.fundTargetsNotBalance,
            style:Theme.of(context).textTheme.bodySmall),
        ]))),
      const SizedBox(height:12),
      for(final member in widget.members) ...[
        Builder(builder:(ctx) {
          final id=member['user_id'] as String;
          final due=target(id)-received(id);
          final net=received(id)-refunded(id);
          return Card(child:Padding(padding:const EdgeInsets.all(14),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(name(id),style:Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height:6),
              Text(l.fundTargetTotal+': '+money(target(id))),
              Text(l.fundTotalReceived+': '+money(received(id))),
              Text(l.fundOutstandingToCollect+': '+money(due>0?due:0)),
              if(refunded(id)>0)
                Text(l.fundRefunded+': '+money(refunded(id))),
              if(widget.isOwner) ...[
                const SizedBox(height:10),
                Row(children:[
                  Expanded(child:OutlinedButton(
                    onPressed:()=>setTarget(id),
                    child:Text(l.fundTargetSet,
                      textAlign:TextAlign.center))),
                  const SizedBox(width:8),
                  Expanded(child:OutlinedButton(
                    onPressed:()=>requestTopup(id),
                    child:Text(l.fundTopUpRequest,
                      textAlign:TextAlign.center))),
                ]),
                if(net>0) ...[
                  const SizedBox(height:8),
                  SizedBox(width:double.infinity,
                    child:TextButton.icon(
                      onPressed:()=>refund(id),
                      icon:const Icon(Icons.undo_outlined,size:18),
                      label:Text(l.fundRefundConfirm))),
                ],
              ],
            ]),
          ));
        }),
        const SizedBox(height:8),
      ],
      const SizedBox(height:18),
      LuiSectionHeading(title:l.fundTopUpRequests),
      const SizedBox(height:8),
      if(requests.isEmpty)Text(l.fundNoRequests,
        style:Theme.of(context).textTheme.bodySmall),
      for(final req in requests) ...[
        Card(child:ListTile(
          title:Text(name(req['member_id'] as String)),
          subtitle:Text(req['cancelled_at']==null
            ? l.fundTopUpPending:l.fundTopUpCancelled),
          trailing:Column(mainAxisSize:MainAxisSize.min,
            crossAxisAlignment:CrossAxisAlignment.end,children:[
              Text(money(cents(req['requested_amount'] as num))),
              if(widget.isOwner&&req['cancelled_at']==null)
                GestureDetector(onTap:()=>cancel(req['id'] as String),
                  child:Text(l.fundCancelRequest,
                    style:TextStyle(color:scheme.primary))),
            ]),
        )),
        const SizedBox(height:6),
      ],
      const SizedBox(height:20),
      LuiSectionHeading(title:l.fundRefundHistory),
      const SizedBox(height:8),
      if(refunds.isEmpty)Text(l.fundNoRefunds,
        style:Theme.of(context).textTheme.bodySmall),
      for(final refundRecord in refunds) ...[
        Card(child:ListTile(
          leading:Icon(Icons.undo_outlined,color:scheme.primary),
          title:Text(name(refundRecord['member_id'] as String)),
          subtitle:Text(refundRecord['note'] as String),
          trailing:Text(money(cents(refundRecord['amount'] as num)),
            style:const TextStyle(fontWeight:FontWeight.w700)),
        )),
        const SizedBox(height:6),
      ],
      const SizedBox(height:20),
      LuiSectionHeading(title:l.fundClosingPreview),
      const SizedBox(height:10),
      Card(child:Padding(padding:const EdgeInsets.all(16),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          summaryLine(l.fundTotalReceived,money(collected)),
          summaryLine(l.fundTotalSpent,money(spent)),
          summaryLine(l.fundRefunded,money(totalRefunds)),
          const Divider(),
          summaryLine(l.fundBalance,money(balance)),
          const SizedBox(height:10),
          Text(l.fundClosingNotFinal,
            style:Theme.of(context).textTheme.bodySmall),
          if(!FundReconciliation.reconciles(
              contributions:collected,purchases:spent,
              refunds:totalRefunds,balance:balance))
            Text(l.fundReconciliationMismatch,
              style:TextStyle(color:scheme.error)),
        ]),
      )),
    ]);
  }
  Widget summaryLine(String label,String amount)=>Padding(
    padding:const EdgeInsets.symmetric(vertical:4),
    child:Row(children:[
      Expanded(child:Text(label)),
      Text(amount,style:const TextStyle(fontWeight:FontWeight.w700)),
    ]));
}
