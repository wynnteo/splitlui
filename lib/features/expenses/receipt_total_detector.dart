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
  final int score,lineIndex;
}

class ReceiptTotalAnalysis {
  const ReceiptTotalAnalysis(this.candidates);
  final List<ReceiptTotalCandidate> candidates;
  ReceiptTotalCandidate? get suggested =>
    candidates.isEmpty || candidates.first.score<7 ? null : candidates.first;
  bool get ambiguous => candidates.length>1 &&
    candidates[1].score>=7 &&
    candidates.first.score-candidates[1].score<=1 &&
    candidates.first.amount!=candidates[1].amount;
}

class ReceiptTotalDetector {
  static final _money=RegExp(
    r'(?<![A-Za-z0-9])(?:\d{1,3}(?:[.,]\d{3})+|\d{1,8})[.,]\d{2}(?!\d)');
  static final _strong=RegExp(
    r'\b(GRAND\s+TOTAL|TOTAL\s+DUE|AMOUNT\s+DUE|NET\s+TOTAL|'
    r'TOTAL\s+PAYABLE|TOTAL\s+AMOUNT|BALANCE\s+DUE|AMOUNT\s+PAYABLE)\b',
    caseSensitive:false);
  static final _total=RegExp(
    r'\b(TOTAL|AMOUNT\s+PAID|PAYABLE)\b',caseSensitive:false);
  static final _exclude=RegExp(
    r'\b(SUB\s*TOTAL|CHANGE|CASH\s+BACK|CASH\s+TENDERED|'
    r'TENDERED|DISCOUNT|SAVINGS|GST|VAT|SERVICE\s+CHARGE|'
    r'TAX|TIP|ROUNDING|POINTS|LOYALTY|UNIT\s+PRICE)\b',
    caseSensitive:false);

  static String? normalizeAmount(String input) {
    var text=input.replaceAll(RegExp(r'\s'),'');
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
    final cents=int.tryParse(integer);
    final decimals=int.tryParse(fractional);
    if(cents==null || decimals==null || cents==0 && decimals==0)return null;
    return '$cents.$fractional';
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
      var rawAmounts=_money.allMatches(raw).map((m)=>m.group(0)!).toList();
      // Common thermal receipts print TOTAL and its number on next line.
      if(rawAmounts.isEmpty && i+1<lines.length &&
          !_exclude.hasMatch(lines[i+1]) &&
          !_total.hasMatch(lines[i+1]) &&
          !_strong.hasMatch(lines[i+1])) {
        rawAmounts=_money.allMatches(lines[i+1])
          .map((m)=>m.group(0)!).toList();
      }
      // Multiple numbers on a total line are ambiguous; require review.
      for(final rawAmount in rawAmounts) {
        final amount=normalizeAmount(rawAmount);
        if(amount==null)continue;
        found.add(ReceiptTotalCandidate(
          amount:amount,label:label,score:score,lineIndex:i));
      }
    }
    // Later totals tend to be final after item subtotals, but never let a
    // weak TOTAL override a stronger AMOUNT DUE. De-duplicate numbers.
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
