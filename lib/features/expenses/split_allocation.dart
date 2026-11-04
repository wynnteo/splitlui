/// Computes penny-perfect expense allocations before sending them to the
/// server. All amounts are integer cents; the server validates everything.
enum ExpenseSplitMode { equal, exact, percent, shares }

class SplitAllocation {
  const SplitAllocation(this.cents);
  final List<int> cents;
  int get totalCents => cents.fold(0,(a,b)=>a+b);

  static SplitAllocation calculate({
    required int totalCents,
    required ExpenseSplitMode mode,
    required List<double> values,
  }) {
    if(totalCents<=0 || values.isEmpty || values.length>50) {
      throw const FormatException('Invalid split amount or participants');
    }
    if(values.any((v)=>!v.isFinite || v<0)) {
      throw const FormatException('Split values cannot be negative');
    }
    if(mode==ExpenseSplitMode.exact) {
      final cents=values.map((v)=>(v*100).round()).toList();
      if(values.asMap().entries.any((e)=>
          (cents[e.key]/100-e.value).abs()>0.0000001)) {
        throw const FormatException('Use at most 2 decimals for exact amounts');
      }
      if(cents.reduce((a,b)=>a+b)!=totalCents) {
        throw const FormatException('Exact amounts must equal the expense total');
      }
      return SplitAllocation(cents);
    }

    final weights=mode==ExpenseSplitMode.equal
      ? List<double>.filled(values.length,1)
      : List<double>.from(values);
    final totalWeight=weights.fold<double>(0,(a,b)=>a+b);
    if(totalWeight<=0 || !totalWeight.isFinite) {
      throw const FormatException('Select positive split weights');
    }
    if(mode==ExpenseSplitMode.percent && (totalWeight-100).abs()>0.00001) {
      throw const FormatException('Percentages must add up to 100%');
    }

    // Largest remainder method: split converted cents deterministically
    // using the selected participant order, with no missing or extra cents.
    final quotas=weights.map((v)=>totalCents*v/totalWeight).toList();
    final whole=quotas.map((v)=>v.floor()).toList();
    var remainder=totalCents-whole.fold(0,(a,b)=>a+b);
    final indices=List<int>.generate(weights.length,(i)=>i)
      ..sort((a,b) {
        final fractionCompare=(quotas[b]-whole[b])
          .compareTo(quotas[a]-whole[a]);
        return fractionCompare!=0?fractionCompare:a.compareTo(b);
      });
    for(var i=0;i<remainder;i++) {
      whole[indices[i]]++;
    }
    return SplitAllocation(whole);
  }

  static SplitAllocation convertProportionally({
    required int convertedTotalCents,
    required List<int> originalShareCents,
  }) {
    return calculate(totalCents:convertedTotalCents,
      mode:ExpenseSplitMode.shares,
      values:originalShareCents.map((e)=>e.toDouble()).toList());
  }
}
