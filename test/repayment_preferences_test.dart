import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitlui/features/settlement/repayment_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Defaults to SGD', () async {
    expect(await RepaymentPreferences.getDefault(), 'SGD');
  });

  test('Persists MYR then SGD', () async {
    await RepaymentPreferences.setDefault('MYR');
    expect(await RepaymentPreferences.getDefault(), 'MYR');
    await RepaymentPreferences.setDefault('SGD');
    expect(await RepaymentPreferences.getDefault(), 'SGD');
  });

  test('Rejects an unsupported default', () async {
    await expectLater(
      RepaymentPreferences.setDefault('THB'), throwsArgumentError);
  });

  test('Falls back to SGD for an invalid saved preference', () async {
    SharedPreferences.setMockInitialValues({
      RepaymentPreferences.key: 'INVALID',
    });
    expect(await RepaymentPreferences.getDefault(), 'SGD');
  });
}
