import 'package:intl/intl.dart';

class WalletNumberFormatting {
  WalletNumberFormatting._();

  static String formatSat(int amount, {String langCode = "en_US"}) {
    final satFormat = NumberFormat("#,##0.##", langCode);
    return satFormat.format(amount);
  }

  static String formatFiat(int amountInCents, {String langCode = "en_US"}) {
    final fiatFormat = NumberFormat("#,##0.00", langCode);
    final amount = amountInCents / 100;
    return fiatFormat.format(amount);
  }

  static String formatAmount({
    required int amount,
    required String unit,
    String langCode = "en_US",
  }) {
    if (unit == "sat") {
      return formatSat(amount, langCode: langCode);
    } else {
      return formatFiat(amount, langCode: langCode);
    }
  }
}
