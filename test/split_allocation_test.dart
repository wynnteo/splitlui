import 'package:flutter_test/flutter_test.dart';
import 'package:splitlui/features/expenses/split_allocation.dart';

void main() {
  test('Equal split never drops a cent', () {
    final result=SplitAllocation.calculate(
      totalCents:10000,mode:ExpenseSplitMode.equal,
      values:[1,1,1]);
    expect(result.cents,[3334,3333,3333]);
    expect(result.totalCents,10000);
  });
  test('Exact original amounts must total exactly', () {
    expect(SplitAllocation.calculate(
      totalCents:13500,mode:ExpenseSplitMode.exact,
      values:[100,30,5]).cents,[10000,3000,500]);
    expect(()=>SplitAllocation.calculate(
      totalCents:13500,mode:ExpenseSplitMode.exact,
      values:[100,30,4.99]),throwsFormatException);
    expect(()=>SplitAllocation.calculate(
      totalCents:1000,mode:ExpenseSplitMode.exact,
      values:[5.001,4.999]),throwsFormatException);
  });
  test('Percentages require 100 and round accurately', () {
    final result=SplitAllocation.calculate(
      totalCents:101,mode:ExpenseSplitMode.percent,
      values:[50,25,25]);
    expect(result.cents,[51,25,25]);
    expect(()=>SplitAllocation.calculate(
      totalCents:1000,mode:ExpenseSplitMode.percent,
      values:[50,30,10]),throwsFormatException);
  });
  test('Shares can represent couples and non-participants', () {
    final result=SplitAllocation.calculate(
      totalCents:10000,mode:ExpenseSplitMode.shares,
      values:[2,1,1,0]);
    expect(result.cents,[5000,2500,2500,0]);
  });
  test('Converted shares total matches converted expense exactly', () {
    final converted=SplitAllocation.convertProportionally(
      convertedTotalCents:129,originalShareCents:[3334,3333,3333]);
    expect(converted.totalCents,129);
    expect(converted.cents,[43,43,43]);
    final uneven=SplitAllocation.convertProportionally(
      convertedTotalCents:101,originalShareCents:[600,300,100]);
    expect(uneven.cents,[61,30,10]);
  });
  test('Invalid inputs are rejected', () {
    expect(()=>SplitAllocation.calculate(totalCents:0,
      mode:ExpenseSplitMode.equal,values:[1]),throwsFormatException);
    expect(()=>SplitAllocation.calculate(totalCents:100,
      mode:ExpenseSplitMode.shares,values:[0,0]),throwsFormatException);
    expect(()=>SplitAllocation.calculate(totalCents:100,
      mode:ExpenseSplitMode.percent,values:[110,-10]),throwsFormatException);
  });
}
