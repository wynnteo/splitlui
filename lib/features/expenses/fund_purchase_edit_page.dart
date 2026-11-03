import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/lui_style.dart';

class FundPurchaseEditPage extends StatefulWidget {
  const FundPurchaseEditPage({super.key,required this.groupId,
    required this.groupCurrency,required this.entry});
  final String groupId,groupCurrency;
  final Map<String,dynamic> entry;
  @override State<FundPurchaseEditPage> createState() => _FundPurchaseEditPageState();
}

class _FundPurchaseEditPageState extends State<FundPurchaseEditPage> {
  final form=GlobalKey<FormState>();
  final title=TextEditingController(),amount=TextEditingController(),
    rate=TextEditingController();
  late String currency;
  DateTime? date;
  bool saving=false;
  static const supported=['SGD','MYR','THB','JPY','USD','EUR','GBP','AUD',
    'IDR','KRW','TWD','CNY','HKD','PHP','VND','INR','NZD','CAD'];

  @override void initState() {
    super.initState();
    final e=widget.entry;
    title.text=e['description'] as String? ?? '';
    amount.text=((e['original_amount'] ?? e['amount']) as num).toStringAsFixed(2);
    currency=e['original_currency'] as String? ?? widget.groupCurrency;
    rate.text=e['rate_to_spending']?.toString() ?? '1';
    date=DateTime.tryParse(e['receipt_date'] as String? ?? '');
  }
  @override void dispose() {title.dispose();amount.dispose();rate.dispose();super.dispose();}

  String? get dateText => date==null ? null :
    '${date!.year.toString().padLeft(4,'0')}-${date!.month.toString().padLeft(2,'0')}-${date!.day.toString().padLeft(2,'0')}';
  Future<void> chooseDate() async {
    final v=await showDatePicker(context:context,
      initialDate:date ?? DateTime.now(),firstDate:DateTime(1990),
      lastDate:DateTime.now().add(const Duration(days:1)));
    if(v!=null && mounted) setState(()=>date=v);
  }
  Future<void> save() async {
    if(saving || !(form.currentState?.validate()??false)) return;
    setState(()=>saving=true);
    try {
      await Supabase.instance.client.rpc('correct_trip_fund_purchase',params:{
        'p_group':widget.groupId,'p_entry':widget.entry['id'],
        'p_expected_updated_at':widget.entry['updated_at'],
        'p_delete':false,'p_title':title.text.trim(),
        'p_amount':double.parse(amount.text.trim()),
        'p_currency':currency,'p_rate_to_spending':double.parse(rate.text.trim()),
        'p_date':dateText,
      });
      if(mounted) Navigator.pop(context,true);
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text(e.toString())));
    } finally {if(mounted) setState(()=>saving=false);}
  }

  @override Widget build(BuildContext context) {
    final l=AppLocalizations.of(context)!;
    final codes={...supported,widget.groupCurrency,currency}.toList();
    final value=double.tryParse(amount.text),fx=double.tryParse(rate.text);
    final equivalent=value!=null&&fx!=null ? value*fx : null;
    return Scaffold(
      appBar:AppBar(title:Text(l.editExpense)),
      body:SafeArea(top:false,child:Form(key:form,child:ListView(
        padding:const EdgeInsets.fromLTRB(20,20,20,38),
        children:[
          Text(l.fundPaidFromPool,style:Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height:20),
          LuiFormLabel(l.expenseTitle),
          TextFormField(controller:title,maxLength:120,
            validator:(v)=>v==null||v.trim().isEmpty ? l.required : null),
          const SizedBox(height:12),
          LuiFormLabel(l.expenseAmount),
          TextFormField(controller:amount,
            keyboardType:const TextInputType.numberWithOptions(decimal:true),
            onChanged:(_)=>setState((){}),
            validator:(v) {
              final t=(v??'').trim(),n=double.tryParse(t);
              return n==null||!n.isFinite||n<=0||n>99999999999999.99||
                !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(t) ? l.invalid : null;
            }),
          const SizedBox(height:12),
          LuiFormLabel(l.expenseCurrency),
          DropdownButtonFormField<String>(value:currency,isExpanded:true,
            items:codes.map((c)=>DropdownMenuItem(value:c,child:Text(c))).toList(),
            onChanged:saving?null:(v) {
              if(v==null) return;
              setState(() {currency=v;rate.text=v==widget.groupCurrency?'1':'';});
            }),
          const SizedBox(height:16),
          LuiFormLabel(l.expenseRateToGroup),
          TextFormField(controller:rate,
            enabled:currency!=widget.groupCurrency&&!saving,
            keyboardType:const TextInputType.numberWithOptions(decimal:true),
            onChanged:(_)=>setState((){}),
            validator:(v) {
              final t=(v??'').trim(),n=double.tryParse(t);
              return n==null||!n.isFinite||n<=0||n>99999999999999||
                !RegExp(r'^\d+(\.\d{1,8})?$').hasMatch(t)||
                (currency==widget.groupCurrency&&n!=1) ? l.invalid : null;
            }),
          if(equivalent!=null&&equivalent.isFinite) ...[
            const SizedBox(height:10),
            Text('${l.groupEquivalent}: ${widget.groupCurrency} ${equivalent.toStringAsFixed(2)}'),
          ],
          const SizedBox(height:20),
          LuiFormLabel(l.expenseReceiptDate),
          OutlinedButton.icon(onPressed:saving?null:chooseDate,
            icon:const Icon(Icons.calendar_today_outlined),
            label:Text(dateText??l.expenseChooseDate)),
          const SizedBox(height:30),
          FilledButton.icon(onPressed:saving?null:save,
            icon:const Icon(Icons.save_outlined),label:Text(l.saveChanges)),
        ],
      ))),
    );
  }
}
