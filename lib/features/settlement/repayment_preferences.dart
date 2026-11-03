import 'package:shared_preferences/shared_preferences.dart';

/// Device-level preference; each recipient can choose the actual currency
/// for an individual receipt, regardless of the group's travel currency.
class RepaymentPreferences {
  static const key = 'repayment_default_currency';
  static const currencies = [
    'SGD', 'MYR', 'THB', 'IDR', 'JPY', 'KRW', 'TWD', 'CNY',
    'HKD', 'USD', 'EUR', 'GBP', 'AUD', 'NZD', 'PHP', 'VND',
    'INR', 'CAD', 'CHF', 'AED',
  ];

  static Future<String> getDefault() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(key);
    return currencies.contains(saved) ? saved! : 'SGD';
  }

  static Future<void> setDefault(String currency) async {
    if (!currencies.contains(currency)) {
      throw ArgumentError.value(currency, 'currency');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, currency);
  }
}
