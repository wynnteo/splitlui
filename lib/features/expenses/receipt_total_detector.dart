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

  // Some thermal receipts show TOTAL 18 or TOTAL 18.5, rather than
  // exactly two decimal digits. Only consider those formats on a labelled
  // total line (or its immediately following value-only line).
  static final _shortMoney = RegExp(
    r'(?<![A-Za-z0-9])\\d{1,8}[.,]\\d(?![\\d.,])');
  static final _wholeMoney = RegExp(
    r'^\\s*(?:(?:SGD|MYR|THB|USD|EUR|GBP|RM|S\\$|\\$|€|£|฿)\\s*)?'
    r'(\\d{1,8})\\s*
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

  static String? _normalizeShortAmount(String input) {
    final text=input.trim().replaceAll(',', '.');
    final match=RegExp(r'^(\\d{1,8})(?:\\.(\\d))?
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
      var rawAmounts=_amounts(raw, labelled:true);
      // Thermal receipts may print TOTAL on one line and its value below.
      if(rawAmounts.isEmpty && i+1<lines.length &&
          !_exclude.hasMatch(lines[i+1]) &&
          !_total.hasMatch(lines[i+1]) &&
          !_strong.hasMatch(lines[i+1])) {
        final nextLine=lines[i+1].trim();
        // Require the next line to consist of a value with optional currency.
        // Otherwise OCR item lines like "Coffee 12" would be a bad guess.
        if(_money.hasMatch(nextLine) || _shortMoney.hasMatch(nextLine) ||
            _wholeMoney.hasMatch(nextLine)) {
          final onlyValue=RegExp(
            r'^\\s*(?:(?:SGD|MYR|THB|USD|EUR|GBP|RM|S\\$|\\$|€|£|฿)\\s*)?'
            r'(\\d{1,8}(?:[.,]\\d{1,2})?)\\s*$',
            caseSensitive:false).firstMatch(nextLine);
          if(onlyValue!=null) {
            rawAmounts=[onlyValue.group(1)!];
          }
        }
      }
      // Multiple numbers on a total line are ambiguous; require review.
      for(final rawAmount in rawAmounts) {
        final amount=normalizeAmount(rawAmount) ??\n            _normalizeShortAmount(rawAmount);
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
,
    caseSensitive: false);

  static List<String> _amounts(String raw, {required bool labelled}) {
    final exact = _money.allMatches(raw).map((m) => m.group(0)!).toList();
    if (exact.isNotEmpty) return exact;
    if (!labelled) return const [];
    final short = _shortMoney.allMatches(raw).map((m) => m.group(0)!).toList();
    if (short.isNotEmpty) return short;

    // Accept a whole-number total only when it is the sole numeric value
    // following the total label; never guess among item counts or IDs.
    final withoutLabel = raw.replaceAll(_strong, '')
        .replaceAll(_total, '')
        .replaceAll(RegExp(r'^[\\s:=-]+'), '').trim();
    final whole = _wholeMoney.firstMatch(withoutLabel);
    return whole == null ? const [] : [whole.group(1)!];
  }

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
).firstMatch(text);
    if(match==null)return null;
    final whole=int.tryParse(match.group(1)!);
    if(whole==null || whole==0 && (match.group(2)==null ||
        match.group(2)=='0'))return null;
    return '${whole}.${match.group(2)==null ? '00' : '${match.group(2)}0'}';
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
      var rawAmounts=_amounts(raw, labelled:true);
      // Thermal receipts may print TOTAL on one line and its value below.
      if(rawAmounts.isEmpty && i+1<lines.length &&
          !_exclude.hasMatch(lines[i+1]) &&
          !_total.hasMatch(lines[i+1]) &&
          !_strong.hasMatch(lines[i+1])) {
        final nextLine=lines[i+1].trim();
        // Require the next line to consist of a value with optional currency.
        // Otherwise OCR item lines like "Coffee 12" would be a bad guess.
        if(_money.hasMatch(nextLine) || _shortMoney.hasMatch(nextLine) ||
            _wholeMoney.hasMatch(nextLine)) {
          final onlyValue=RegExp(
            r'^\\s*(?:(?:SGD|MYR|THB|USD|EUR|GBP|RM|S\\$|\\$|€|£|฿)\\s*)?'
            r'(\\d{1,8}(?:[.,]\\d{1,2})?)\\s*$',
            caseSensitive:false).firstMatch(nextLine);
          if(onlyValue!=null) {
            rawAmounts=[onlyValue.group(1)!];
          }
        }
      }
      // Multiple numbers on a total line are ambiguous; require review.
      for(final rawAmount in rawAmounts) {
        final amount=normalizeAmount(rawAmount) ??\n            _normalizeShortAmount(rawAmount);
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
,
    caseSensitive: false);

  static List<String> _amounts(String raw, {required bool labelled}) {
    final exact = _money.allMatches(raw).map((m) => m.group(0)!).toList();
    if (exact.isNotEmpty) return exact;
    if (!labelled) return const [];
    final short = _shortMoney.allMatches(raw).map((m) => m.group(0)!).toList();
    if (short.isNotEmpty) return short;

    // Accept a whole-number total only when it is the sole numeric value
    // following the total label; never guess among item counts or IDs.
    final withoutLabel = raw.replaceAll(_strong, '')
        .replaceAll(_total, '')
        .replaceAll(RegExp(r'^[\\s:=-]+'), '').trim();
    final whole = _wholeMoney.firstMatch(withoutLabel);
    return whole == null ? const [] : [whole.group(1)!];
  }

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
