import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _vndFormat = NumberFormat('#,###', 'vi_VN');
  static final NumberFormat _usdFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  /// Formats amount in VND with '₫' symbol: e.g. 150000 -> "150.000 ₫"
  static String formatVND(double amount) {
    final formatted = _vndFormat.format(amount.round()).replaceAll(',', '.');
    return '$formatted ₫';
  }

  /// Formats amount in USD: e.g. 12.5 -> "$12.50"
  static String formatUSD(double amount) {
    return _usdFormat.format(amount);
  }

  /// Automatically formats depending on currency code
  static String format(double amount, {String currency = 'VND'}) {
    if (currency.toUpperCase() == 'USD') {
      return formatUSD(amount);
    }
    return formatVND(amount);
  }

  /// Compact format for charts (e.g. 1.5M, 250K)
  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      final m = amount / 1000000;
      return '${m.toStringAsFixed(m % 1 == 0 ? 0 : 1)}tr';
    } else if (amount >= 1000) {
      final k = amount / 1000;
      return '${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}k';
    }
    return amount.toStringAsFixed(0);
  }
}
