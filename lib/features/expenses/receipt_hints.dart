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
    for(final line in lines.take(8)) {
      if(line.length<3 || line.length>70 ||
         RegExp(r'^\W*\d').hasMatch(line) ||
         RegExp(r'^[\d\s,./:-]+$').hasMatch(line) ||
         RegExp(
           r'\b(TAX INVOICE|RECEIPT|INVOICE|DATE|TIME|CASHIER|'
           r'ORDER|THANK YOU|WELCOME|SUB\s*TOTAL|GRAND TOTAL|'
           r'TOTAL|AMOUNT DUE|NET TOTAL|GST|VAT|TEL|PHONE|'
           r'REGISTER|TERMINAL|TRANSACTION|TABLE|REF NO)\b',
           caseSensitive:false).hasMatch(line))continue;
      merchant=line.replaceAll(RegExp(r'\s+'),' ');
      break;
    }
    final upper=text.toUpperCase();
    // Do not silently guess if multiple distinct currency codes appear:
    // some receipts print a transaction amount plus an FX conversion.
    final foundCurrencies=<String>{};
    void found(String code,bool matches) {
      if(matches) foundCurrencies.add(code);
    }
    found('SGD',RegExp(r'\bSGD\b').hasMatch(upper) ||
      RegExp(r'(?<![A-Z])S\
    found('MYR',RegExp(r'\bMYR\b|\bRM(?=\s*\d|\b)').hasMatch(upper));
    found('THB',RegExp(r'\b(THB|BAHT)\b').hasMatch(upper) ||
      text.contains('฿'));
    found('JPY',RegExp(r'\bJPY\b').hasMatch(upper));
    found('USD',RegExp(r'\bUSD\b').hasMatch(upper) ||
      upper.contains('US\$'));
    found('EUR',RegExp(r'\bEUR\b').hasMatch(upper) ||
      text.contains('€'));
    found('GBP',RegExp(r'\bGBP\b').hasMatch(upper) ||
      text.contains('£'));
    found('IDR',RegExp(r'\bIDR\b').hasMatch(upper));
    found('KRW',RegExp(r'\bKRW\b').hasMatch(upper));
    found('AUD',RegExp(r'\bAUD\b').hasMatch(upper));
    String? currency=foundCurrencies.length==1
      ? foundCurrencies.first : null;
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
).hasMatch(upper));
    found('MYR',RegExp(r'\b(MYR|RM)\b').hasMatch(upper));
    found('THB',RegExp(r'\b(THB|BAHT)\b').hasMatch(upper) ||
      text.contains('฿'));
    found('JPY',RegExp(r'\bJPY\b').hasMatch(upper));
    found('USD',RegExp(r'\bUSD\b').hasMatch(upper) ||
      upper.contains('US\$'));
    found('EUR',RegExp(r'\bEUR\b').hasMatch(upper) ||
      text.contains('€'));
    found('GBP',RegExp(r'\bGBP\b').hasMatch(upper) ||
      text.contains('£'));
    found('IDR',RegExp(r'\bIDR\b').hasMatch(upper));
    found('KRW',RegExp(r'\bKRW\b').hasMatch(upper));
    found('AUD',RegExp(r'\bAUD\b').hasMatch(upper));
    String? currency=foundCurrencies.length==1
      ? foundCurrencies.first : null;
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
