/// Conservative receipt-field hints. Users must review before saving.
/// No network or native plugin dependencies: safe for pure Dart tests.
class ReceiptHints {
  const ReceiptHints({
    this.merchant,
    this.itemDescription,
    this.currency,
    this.date,
    this.total,
    this.dateNeedsReview=false,
  });

  final String? merchant,itemDescription,currency,total;
  final DateTime? date;
  final bool dateNeedsReview;

  static ReceiptHints parse(String text) {
    final lines=text.split(RegExp(r'[\r\n]+'))
      .map((s)=>s.trim()).where((s)=>s.isNotEmpty).toList();

    String? merchant;
    final nonMerchant=RegExp(
      r'\b(TAX INVOICE|RECEIPT|INVOICE|DATE|TIME|CASHIER|'
      r'ORDER|THANK YOU|WELCOME|SUB\s*TOTAL|GRAND TOTAL|'
      r'TOTAL|AMOUNT DUE|NET TOTAL|GST|VAT|TEL|PHONE|'
      r'REGISTER|TERMINAL|TRANSACTION|TABLE|REF NO)\b',
      caseSensitive:false);
    for(final line in lines.take(8)) {
      if(line.length<3 || line.length>70 ||
        RegExp(r'^\W*\d').hasMatch(line) ||
        RegExp(r'^[\d\s,./:-]+$').hasMatch(line) ||
        nonMerchant.hasMatch(line)) continue;
      merchant=line.replaceAll(RegExp(r'\s+'),' ');
      break;
    }

    // Prefer a clear purchased item over the merchant/address as the
    // expense description. Only suggest a line item when exactly one
    // non-zero priced item can be identified; otherwise let users choose.
    // A receipt may put the quantity, description and price on one line
    // or place the amount on the following OCR line.
    final itemLine=RegExp(
      r'^\s*(\d{1,2})\s+(.+?)\s+'
      r'(?:(?:S\$|\$|RM|SGD|MYR|THB)\s*)?'
      r'(\d{1,7}[.,]\d{2})\s*
    // A receipt may contain multiple different explicit currencies.
    // Never guess which one was actually paid when that happens.
    final currencies=<String>{};
    void detect(String code,bool matches) {
      if(matches) currencies.add(code);
    }
    detect('SGD',RegExp(r'\bSGD\b').hasMatch(upper) ||
      RegExp(r'(?<![A-Z])S\$').hasMatch(upper));
    detect('MYR',RegExp(r'\bMYR\b|\bRM(?=\s*\d|\b)').hasMatch(upper));
    detect('THB',RegExp(r'\b(THB|BAHT)\b').hasMatch(upper) ||
      text.contains('฿'));
    detect('JPY',RegExp(r'\bJPY\b').hasMatch(upper));
    detect('USD',RegExp(r'\bUSD\b').hasMatch(upper) ||
      upper.contains('US\$'));
    detect('EUR',RegExp(r'\bEUR\b').hasMatch(upper) ||
      text.contains('€'));
    detect('GBP',RegExp(r'\bGBP\b').hasMatch(upper) ||
      text.contains('£'));
    detect('IDR',RegExp(r'\bIDR\b').hasMatch(upper));
    detect('KRW',RegExp(r'\bKRW\b').hasMatch(upper));
    detect('AUD',RegExp(r'\bAUD\b').hasMatch(upper));
    final currency=currencies.length==1?currencies.first:null;

    DateTime? date;
    var dateNeedsReview=false;
    final iso=RegExp(
      r'\b(20\d{2})[-/](0?[1-9]|1[0-2])[-/](0?[1-9]|[12]\d|3[01])\b')
      .firstMatch(text);
    final common=RegExp(
      r'\b(0?[1-9]|[12]\d|3[01])[-/](0?[1-9]|1[0-2])[-/](20\d{2})\b')
      .firstMatch(text);
    if(iso!=null) {
      date=_date(int.parse(iso.group(1)!),int.parse(iso.group(2)!),
        int.parse(iso.group(3)!));
    } else if(common!=null) {
      final day=int.parse(common.group(1)!);
      final month=int.parse(common.group(2)!);
      date=_date(int.parse(common.group(3)!),month,day);
      dateNeedsReview=date!=null && day<=12;
    }
    return ReceiptHints(
      merchant:merchant,itemDescription:itemDescription,\n      currency:currency,date:date,
      dateNeedsReview:dateNeedsReview);
  }

  static DateTime? _date(int year,int month,int day) {
    final date=DateTime(year,month,day);
    if(date.year!=year||date.month!=month||date.day!=day ||
      date.isAfter(DateTime.now().add(const Duration(days:1))))return null;
    return date;
  }
}
,
      caseSensitive:false);
    final quantityDescription=RegExp(r'^\s*\d{1,2}\s+(.+?)\s*
    // A receipt may contain multiple different explicit currencies.
    // Never guess which one was actually paid when that happens.
    final currencies=<String>{};
    void detect(String code,bool matches) {
      if(matches) currencies.add(code);
    }
    detect('SGD',RegExp(r'\bSGD\b').hasMatch(upper) ||
      RegExp(r'(?<![A-Z])S\$').hasMatch(upper));
    detect('MYR',RegExp(r'\bMYR\b|\bRM(?=\s*\d|\b)').hasMatch(upper));
    detect('THB',RegExp(r'\b(THB|BAHT)\b').hasMatch(upper) ||
      text.contains('฿'));
    detect('JPY',RegExp(r'\bJPY\b').hasMatch(upper));
    detect('USD',RegExp(r'\bUSD\b').hasMatch(upper) ||
      upper.contains('US\$'));
    detect('EUR',RegExp(r'\bEUR\b').hasMatch(upper) ||
      text.contains('€'));
    detect('GBP',RegExp(r'\bGBP\b').hasMatch(upper) ||
      text.contains('£'));
    detect('IDR',RegExp(r'\bIDR\b').hasMatch(upper));
    detect('KRW',RegExp(r'\bKRW\b').hasMatch(upper));
    detect('AUD',RegExp(r'\bAUD\b').hasMatch(upper));
    final currency=currencies.length==1?currencies.first:null;

    DateTime? date;
    var dateNeedsReview=false;
    final iso=RegExp(
      r'\b(20\d{2})[-/](0?[1-9]|1[0-2])[-/](0?[1-9]|[12]\d|3[01])\b')
      .firstMatch(text);
    final common=RegExp(
      r'\b(0?[1-9]|[12]\d|3[01])[-/](0?[1-9]|1[0-2])[-/](20\d{2})\b')
      .firstMatch(text);
    if(iso!=null) {
      date=_date(int.parse(iso.group(1)!),int.parse(iso.group(2)!),
        int.parse(iso.group(3)!));
    } else if(common!=null) {
      final day=int.parse(common.group(1)!);
      final month=int.parse(common.group(2)!);
      date=_date(int.parse(common.group(3)!),month,day);
      dateNeedsReview=date!=null && day<=12;
    }
    return ReceiptHints(
      merchant:merchant,currency:currency,date:date,
      dateNeedsReview:dateNeedsReview);
  }

  static DateTime? _date(int year,int month,int day) {
    final date=DateTime(year,month,day);
    if(date.year!=year||date.month!=month||date.day!=day ||
      date.isAfter(DateTime.now().add(const Duration(days:1))))return null;
    return date;
  }
}
);
    final amountOnly=RegExp(
      r'^\s*(?:(?:S\$|\$|RM|SGD|MYR|THB)\s*)?'
      r'(\d{1,7}[.,]\d{2})\s*
    // A receipt may contain multiple different explicit currencies.
    // Never guess which one was actually paid when that happens.
    final currencies=<String>{};
    void detect(String code,bool matches) {
      if(matches) currencies.add(code);
    }
    detect('SGD',RegExp(r'\bSGD\b').hasMatch(upper) ||
      RegExp(r'(?<![A-Z])S\$').hasMatch(upper));
    detect('MYR',RegExp(r'\bMYR\b|\bRM(?=\s*\d|\b)').hasMatch(upper));
    detect('THB',RegExp(r'\b(THB|BAHT)\b').hasMatch(upper) ||
      text.contains('฿'));
    detect('JPY',RegExp(r'\bJPY\b').hasMatch(upper));
    detect('USD',RegExp(r'\bUSD\b').hasMatch(upper) ||
      upper.contains('US\$'));
    detect('EUR',RegExp(r'\bEUR\b').hasMatch(upper) ||
      text.contains('€'));
    detect('GBP',RegExp(r'\bGBP\b').hasMatch(upper) ||
      text.contains('£'));
    detect('IDR',RegExp(r'\bIDR\b').hasMatch(upper));
    detect('KRW',RegExp(r'\bKRW\b').hasMatch(upper));
    detect('AUD',RegExp(r'\bAUD\b').hasMatch(upper));
    final currency=currencies.length==1?currencies.first:null;

    DateTime? date;
    var dateNeedsReview=false;
    final iso=RegExp(
      r'\b(20\d{2})[-/](0?[1-9]|1[0-2])[-/](0?[1-9]|[12]\d|3[01])\b')
      .firstMatch(text);
    final common=RegExp(
      r'\b(0?[1-9]|[12]\d|3[01])[-/](0?[1-9]|1[0-2])[-/](20\d{2})\b')
      .firstMatch(text);
    if(iso!=null) {
      date=_date(int.parse(iso.group(1)!),int.parse(iso.group(2)!),
        int.parse(iso.group(3)!));
    } else if(common!=null) {
      final day=int.parse(common.group(1)!);
      final month=int.parse(common.group(2)!);
      date=_date(int.parse(common.group(3)!),month,day);
      dateNeedsReview=date!=null && day<=12;
    }
    return ReceiptHints(
      merchant:merchant,currency:currency,date:date,
      dateNeedsReview:dateNeedsReview);
  }

  static DateTime? _date(int year,int month,int day) {
    final date=DateTime(year,month,day);
    if(date.year!=year||date.month!=month||date.day!=day ||
      date.isAfter(DateTime.now().add(const Duration(days:1))))return null;
    return date;
  }
}
,
      caseSensitive:false);
    final rejectedItem=RegExp(
      r'\b(TOTAL|GST|VAT|TAX|SERVICE|CHANGE|DISCOUNT|'
      r'SUBTOTAL|CASH|QUEUE|ORDER|DATE|TIME|PAYMENT)\b',
      caseSensitive:false);
    bool validItem(String description,String price) {
      final name=description.trim();
      if(name.length<5 || name.length>110 ||
          rejectedItem.hasMatch(name) ||
          !RegExp(r'[A-Za-z\u4e00-\u9fff]').hasMatch(name))return false;
      final amount=double.tryParse(price.replaceAll(',', '.'));
      return amount!=null && amount>0;
    }
    final purchased=<String>{};
    for(var i=0;i<lines.length;i++) {
      final line=lines[i];
      final match=itemLine.firstMatch(line);
      if(match!=null) {
        final name=match.group(2)!;
        if(validItem(name,match.group(3)!)) {
          purchased.add(name.trim().replaceAll(RegExp(r'\s+'),' '));
        }
        continue;
      }
      // Only accept a detached amount when directly beneath a
      // quantity-prefixed description.
      if(i+1<lines.length) {
        final item=quantityDescription.firstMatch(line);
        final price=amountOnly.firstMatch(lines[i+1]);
        if(item!=null && price!=null &&
            validItem(item.group(1)!,price.group(1)!)) {
          purchased.add(item.group(1)!.trim()
              .replaceAll(RegExp(r'\s+'),' '));
        }
      }
    }
    final itemDescription=purchased.length==1?purchased.first:null;

    final upper=text.toUpperCase();
    // A receipt may contain multiple different explicit currencies.
    // Never guess which one was actually paid when that happens.
    final currencies=<String>{};
    void detect(String code,bool matches) {
      if(matches) currencies.add(code);
    }
    detect('SGD',RegExp(r'\bSGD\b').hasMatch(upper) ||
      RegExp(r'(?<![A-Z])S\$').hasMatch(upper));
    detect('MYR',RegExp(r'\bMYR\b|\bRM(?=\s*\d|\b)').hasMatch(upper));
    detect('THB',RegExp(r'\b(THB|BAHT)\b').hasMatch(upper) ||
      text.contains('฿'));
    detect('JPY',RegExp(r'\bJPY\b').hasMatch(upper));
    detect('USD',RegExp(r'\bUSD\b').hasMatch(upper) ||
      upper.contains('US\$'));
    detect('EUR',RegExp(r'\bEUR\b').hasMatch(upper) ||
      text.contains('€'));
    detect('GBP',RegExp(r'\bGBP\b').hasMatch(upper) ||
      text.contains('£'));
    detect('IDR',RegExp(r'\bIDR\b').hasMatch(upper));
    detect('KRW',RegExp(r'\bKRW\b').hasMatch(upper));
    detect('AUD',RegExp(r'\bAUD\b').hasMatch(upper));
    final currency=currencies.length==1?currencies.first:null;

    DateTime? date;
    var dateNeedsReview=false;
    final iso=RegExp(
      r'\b(20\d{2})[-/](0?[1-9]|1[0-2])[-/](0?[1-9]|[12]\d|3[01])\b')
      .firstMatch(text);
    final common=RegExp(
      r'\b(0?[1-9]|[12]\d|3[01])[-/](0?[1-9]|1[0-2])[-/](20\d{2})\b')
      .firstMatch(text);
    if(iso!=null) {
      date=_date(int.parse(iso.group(1)!),int.parse(iso.group(2)!),
        int.parse(iso.group(3)!));
    } else if(common!=null) {
      final day=int.parse(common.group(1)!);
      final month=int.parse(common.group(2)!);
      date=_date(int.parse(common.group(3)!),month,day);
      dateNeedsReview=date!=null && day<=12;
    }
    return ReceiptHints(
      merchant:merchant,currency:currency,date:date,
      dateNeedsReview:dateNeedsReview);
  }

  static DateTime? _date(int year,int month,int day) {
    final date=DateTime(year,month,day);
    if(date.year!=year||date.month!=month||date.day!=day ||
      date.isAfter(DateTime.now().add(const Duration(days:1))))return null;
    return date;
  }
}
