/// Receipt totals are hints only, never authoritative payment records.
/// Pure Dart logic so OCR issues can be reproduced with extracted text.
class ReceiptTotalCandidate {
  const ReceiptTotalCandidate({
    required this.amount,
    required this.label,
    required this.score,
    required this.lineIndex,
  });
  final String amount;
  final String label;
  final int score, lineIndex;
}

class ReceiptTotalAnalysis {
  const ReceiptTotalAnalysis(this.candidates);
  final List<ReceiptTotalCandidate> candidates;
  ReceiptTotalCandidate? get suggested =>
    candidates.isEmpty || candidates.first.score < 7 ? null : candidates.first;
  bool get ambiguous => candidates.length > 1 &&
    candidates[1].score >= 7 &&
    candidates.first.score - candidates[1].score <= 1 &&
    candidates.first.amount != candidates[1].amount;
}

class ReceiptTotalDetector {
  static final _money = RegExp(
    r'(?<![A-Za-z0-9])(?:\d{1,3}(?:[.,]\d{3})+|\d{1,8})[.,]\d{2}(?!\d)');
  static final _strong = RegExp(
    r'\b(GRAND\s+TOTAL|TOTAL\s+DUE|AMOUNT\s+DUE|NET\s+TOTAL|'
    r'TOTAL\s+PAYABLE|TOTAL\s+AMOUNT|BALANCE\s+DUE|AMOUNT\s+PAYABLE)\b',
    caseSensitive:false);
  static final _total = RegExp(
    r'\b(TOTAL|AMOUNT\s+PAID|PAYABLE)\b', caseSensitive:false);
  static final _exclude = RegExp(
    r'\b(SUB\s*TOTAL|CHANGE|CASH\s+BACK|CASH\s+TENDERED|'
    r'TENDERED|DISCOUNT|SAVINGS|GST|VAT|SERVICE\s+CHARGE|'
    r'TAX|TIP|ROUNDING|POINTS|LOYALTY|UNIT\s+PRICE)\b',
    caseSensitive:false);
  static final _shortMoney = RegExp(
    r'(?<![A-Za-z0-9])\d{1,8}[.,]\d(?![\d.,])');
  static final _wholeMoney = RegExp(
    r'^\s*(?:(?:SGD|MYR|THB|USD|EUR|GBP|RM|S\$|\$|€|£|฿)\s*)?'
    r'(\d{1,8})\s*$',
    caseSensitive: false);
  static final _valueLine = RegExp(
    r'^\s*(?:(?:SGD|MYR|THB|USD|EUR|GBP|RM|S\$|\$|€|£|฿)\s*)?'
    r'(\d{1,8}(?:[.,]\d{1,2})?)\s*$',
    caseSensitive:false);

  static String? normalizeAmount(String input) {
    final text=input.replaceAll(RegExp(r'\s'),'');
    final comma=text.lastIndexOf(',');
    final dot=text.lastIndexOf('.');
    if(comma<0 && dot<0)return null;
    final decimal=comma>dot?',':'.';
    final pos=decimal==','?comma:dot;
    if(text.length-pos!=3)return null; // Exactly two fractional digits.
    final integer=text.substring(0,pos).replaceAll(RegExp(r'[.,]'),'');
    final fractional=text.substring(pos+1);
    if(!RegExp(r'^\d{1,8}$').hasMatch(integer) ||
       !RegExp(r'^\d{2}$').hasMatch(fractional))return null;
    final units=int.tryParse(integer);
    final decimals=int.tryParse(fractional);
    if(units==null || decimals==null || units==0 && decimals==0)return null;
    return units.toString()+'.'+fractional;
  }

  static String? _normalizeShort(String input) {
    final text=input.trim().replaceAll(',', '.');
    final match=RegExp(r'^(\d{1,8})(?:\.(\d))?$').firstMatch(text);
    if(match==null)return null;
    final units=int.tryParse(match.group(1)!);
    if(units==null || units==0 && (match.group(2)==null ||
        match.group(2)=='0'))return null;
    final decimals=match.group(2);
    return units.toString()+'.'+(decimals==null?'00':decimals+'0');
  }

  static List<String> _labelledAmounts(String raw) {
    final exact=_money.allMatches(raw).map((m)=>m.group(0)!).toList();
    if(exact.isNotEmpty)return exact;
    final oneDecimal=_shortMoney.allMatches(raw).map((m)=>m.group(0)!).toList();
    if(oneDecimal.isNotEmpty)return oneDecimal;
    // For an integer amount the numeric text must be the only remaining
    // value after removing the explicit TOTAL label and punctuation.
    final remaining=raw.replaceAll(_strong,'').replaceAll(_total,'')
      .replaceAll(RegExp(r'^[\s:=-]+'),'').trim();
    final whole=_wholeMoney.firstMatch(remaining);
    return whole==null?const []:[whole.group(1)!];
  }

  static ReceiptTotalAnalysis parse(String ocrText) {
    final lines=ocrText.split(RegExp(r'[\r\n]+'));
    final found=<ReceiptTotalCandidate>[];
    for(var i=0;i<lines.length;i++) {
      final raw=lines[i],upper=raw.toUpperCase();
      if(_exclude.hasMatch(upper))continue;
      final strong=_strong.hasMatch(upper);
      final total=!strong&&_total.hasMatch(upper);
      if(!strong&&!total)continue;
      final label=raw.trim().replaceAll(RegExp(r'\s+'),' ');
      final score=strong?12:8;
      var rawAmounts=_labelledAmounts(raw);
      if(rawAmounts.isEmpty && i+1<lines.length &&
          !_exclude.hasMatch(lines[i+1]) &&
          !_total.hasMatch(lines[i+1]) &&
          !_strong.hasMatch(lines[i+1])) {
        // If the total value appears on the next line, require the entire
        // next line to contain only one amount and optional currency.
        final value=_valueLine.firstMatch(lines[i+1].trim());
        if(value!=null)rawAmounts=[value.group(1)!];
      }
      for(final rawAmount in rawAmounts) {
        final amount=normalizeAmount(rawAmount) ?? _normalizeShort(rawAmount);
        if(amount==null)continue;
        found.add(ReceiptTotalCandidate(
          amount:amount,label:label,score:score,lineIndex:i));
      }
    }
    found.sort((a,b) {
      final priority=b.score.compareTo(a.score);
      return priority!=0 ? priority : b.lineIndex.compareTo(a.lineIndex);
    });
    final seen=<String>{};
    return ReceiptTotalAnalysis([
      for(final candidate in found)
        if(seen.add(candidate.amount))candidate,
    ]);
  }
}
