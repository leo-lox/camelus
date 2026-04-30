import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Parsed result of a Lightning input string.
sealed class ParsedLnInput {
  const ParsedLnInput();
}

/// A valid BOLT11 invoice.
class LnInvoiceInput extends ParsedLnInput {
  /// The raw invoice string (without any `lightning:` URI prefix).
  final String invoice;

  /// Pre-decoded amount in satoshis, or null if the invoice has no fixed amount.
  final int? amountSat;

  /// Pre-decoded description/memo, or null if none present.
  final String? description;

  const LnInvoiceInput({
    required this.invoice,
    this.amountSat,
    this.description,
  });
}

/// A Lightning Address in `user@domain.tld` form.
class LnAddressInput extends ParsedLnInput {
  final String address;
  const LnAddressInput({required this.address});
}

/// Parses raw Lightning input strings (BOLT11 invoices and Lightning Addresses).
class LnInputParser {
  static final _lnAddressRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  /// Returns true if [input] looks like a Lightning Address (`user@domain.tld`).
  bool isLightningAddress(String input) =>
      _lnAddressRegex.hasMatch(input.trim());

  /// Attempts to parse [input] as a BOLT11 invoice or Lightning Address.
  ///
  /// Returns the appropriate [ParsedLnInput] subtype, or `null` if the input
  /// is neither a valid invoice nor a Lightning Address.
  ParsedLnInput? parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    if (isLightningAddress(trimmed)) {
      return LnAddressInput(address: trimmed);
    }

    // Strip optional lightning: URI scheme before decoding.
    final invoice = trimmed.toLowerCase().startsWith('lightning:')
        ? trimmed.substring(10)
        : trimmed;

    try {
      final decoded = Bolt11PaymentRequest(invoice);

      int? amountSat;
      final amountBtc = decoded.amount;
      if (amountBtc > Decimal.zero) {
        final sats = (amountBtc * Decimal.fromInt(100000000))
            .toBigInt()
            .toInt();
        if (sats > 0) amountSat = sats;
      }

      String? description;
      final descTag = decoded.tags
          .where((t) => t.type == 'description')
          .firstOrNull;
      final desc = descTag?.data as String?;
      if (desc != null && desc.isNotEmpty) description = desc;

      return LnInvoiceInput(
        invoice: invoice,
        amountSat: amountSat,
        description: description,
      );
    } catch (_) {
      return null;
    }
  }
}

final lnInputParserProvider = Provider<LnInputParser>((_) => LnInputParser());
