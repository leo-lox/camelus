import 'package:intl/intl.dart';

class WalletNumberFormatting {
  final String langCode;
  final NumberFormat satFormat;
  final NumberFormat fiatFormat;

  WalletNumberFormatting({
    this.langCode = "en_US",
  })  : satFormat = NumberFormat("#,##0.##", langCode),
        fiatFormat = NumberFormat("#,##0.00", langCode);

  String formatSat(int amount) {
    return satFormat.format(amount);
  }

  String formatFiat(int amountInCents) {
    final amount = amountInCents / 100;
    return fiatFormat.format(amount);
  }

  String formatAmount({
    required int amount,
    required String unit,
  }) {
    if (unit == "sat") {
      return formatSat(amount);
    } else {
      return formatFiat(amount);
    }
  }
}
