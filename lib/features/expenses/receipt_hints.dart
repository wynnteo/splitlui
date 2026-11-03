/// Heuristic receipt hints. These are never trusted without user confirmation.
/// Keep this pure Dart so basic parsing can be unit-tested without plugins.
class ReceiptHints {
  const ReceiptHints({this.merchant,this.currency,this.date,this.total});
  final String? merchant,currency,total;
  final DateTime? date;

  static ReceiptHints parse(String text) {
    final lines=text.split(RegExp(r'[\r\n]+'))
      .map((s)=>s.trim()).where((s)=>s.isNotEmpty).toList();
    String? merchant;
    for (final line in lines.take(6)) {
      if (line.length < 3 || line.length > 70 ||
          RegExp(r'^\W*\d').hasMatch(line) ||
          RegExp(r'(TAX INVOICE|RECEIPT|INVOICE|DATE|TIME|CASHIER|ORDER|THANK YOU|WELCOME)',caseSensitive:false).hasMatch(line) ||
          RegExp(r'^[\d\s,./:-]+$').hasMatch(line)) continue;
      merchant=line.replaceAll(RegExp(r'\s+'),' ');
      break;
    }
    final upper=text.toUpperCase();
    String? currency;
    if (RegExp(r'\b(SGD|S\$)\b').hasMatch(upper) || upper.contains('S\$')) currency='SGD';
    else if (RegExp(r'\b(MYR|RM)\b').hasMatch(upper)) currency='MYR';
    else if (RegExp(r'\b(THB|BAHT)\b').hasMatch(upper) || text.contains('฿')) currency='THB';
    else if (RegExp(r'\b(JPY)\b').hasMatch(upper)) currency='JPY';
    else if (RegExp(r'\b(USD|US\$)\b').hasMatch(upper) || upper.contains('US\$')) currency='USD';
    else if (RegExp(r'\b(EUR)\b').hasMatch(upper) || text.contains('€')) currency='EUR';
    else if (RegExp(r'\b(GBP)\b').hasMatch(upper) || text.contains('£')) currency='GBP';
    else if (RegExp(r'\b(IDR)\b').hasMatch(upper)) currency='IDR';
    else if (RegExp(r'\b(KRW)\b').hasMatch(upper)) currency='KRW';
    else if (RegExp(r'\b(AUD)\b').hasMatch(upper)) currency='AUD';
    // A bare $ or ¥ is ambiguous; deliberately do not guess.
    DateTime? date;
    final iso=RegExp(r'\b(20\d{2})[-/](0?[1-9]|1[0-2])[-/](0?[1-9]|[12]\d|3[01])\b').firstMatch(text);
    final common=RegExp(r'\b(0?[1-9]|[12]\d|3[01])[-/](0?[1-9]|1[0-2])[-/](20\d{2})\b').firstMatch(text);
    if(iso!=null) date=_date(int.parse(iso.group(1)!),int.parse(iso.group(2)!),int.parse(iso.group(3)!));
    else if(common!=null) date=_date(int.parse(common.group(3)!),int.parse(common.group(2)!),int.parse(common.group(1)!));
    return ReceiptHints(merchant:merchant,currency:currency,date:date);
  }

  static DateTime? _date(int y,int m,int d) {
    final date=DateTime(y,m,d);
    if(date.year!=y||date.month!=m||date.day!=d ||
      date.isAfter(DateTime.now().add(const Duration(days:1)))) return null;
    return date;
  }
}
