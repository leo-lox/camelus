import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Resolves a Lightning Address (LNURL-pay, NIP-57 style) to a BOLT11 invoice.
///
/// Flow:
///   1. Parse `user@domain` → GET `https://domain/.well-known/lnurlp/user`
///   2. Read `callback`, `minSendable`, `maxSendable` from the JSON response.
///   3. GET `$callback?amount=${amountSat * 1000}` (amount in millisatoshis).
///   4. Return the `pr` (BOLT11 payment request) from the response.
class LightningAddressResolver {
  final http.Client _client;

  LightningAddressResolver({http.Client? client})
    : _client = client ?? http.Client();

  /// Resolves [lnAddress] (e.g. `user@domain.com`) for [amountSat] satoshis
  /// and returns a BOLT11 invoice string.
  ///
  /// Throws a [LightningAddressException] with a human-readable message on any
  /// failure (HTTP error, malformed response, amount out-of-range, etc.).
  Future<String> resolveToInvoice(String lnAddress, int amountSat) async {
    final parts = lnAddress.trim().split('@');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      throw LightningAddressException('Invalid Lightning Address: $lnAddress');
    }
    final user = parts[0];
    final domain = parts[1];

    // Step 1: Fetch LNURL-pay metadata (HTTPS only per spec)
    final metadataUrl = Uri.https(domain, '/.well-known/lnurlp/$user');
    final metaResponse = await _client
        .get(metadataUrl)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw LightningAddressException(
            'Timeout fetching Lightning Address metadata from $domain',
          ),
        );

    if (metaResponse.statusCode != 200) {
      throw LightningAddressException(
        'Failed to fetch Lightning Address metadata: '
        'HTTP ${metaResponse.statusCode} from $metadataUrl',
      );
    }

    final Map<String, dynamic> metaJson;
    try {
      metaJson = jsonDecode(metaResponse.body) as Map<String, dynamic>;
    } catch (_) {
      throw LightningAddressException(
        'Invalid JSON from Lightning Address server at $domain',
      );
    }

    if (metaJson['status'] == 'ERROR') {
      final reason = metaJson['reason'] ?? 'Unknown error';
      throw LightningAddressException(
        'Lightning Address server returned error: $reason',
      );
    }

    final callback = metaJson['callback'] as String?;
    if (callback == null || callback.isEmpty) {
      throw LightningAddressException(
        'Lightning Address metadata missing callback URL',
      );
    }

    // Validate amount against min/maxSendable (in millisatoshis)
    final amountMsat = amountSat * 1000;
    final minSendable = metaJson['minSendable'] as int?;
    final maxSendable = metaJson['maxSendable'] as int?;

    if (minSendable != null && amountMsat < minSendable) {
      throw LightningAddressException(
        'Amount too small: minimum is ${minSendable ~/ 1000} sats for $lnAddress',
      );
    }
    if (maxSendable != null && amountMsat > maxSendable) {
      throw LightningAddressException(
        'Amount too large: maximum is ${maxSendable ~/ 1000} sats for $lnAddress',
      );
    }

    // Step 2: Request a BOLT11 invoice from the callback URL
    final callbackUri = Uri.parse(callback).replace(
      queryParameters: {
        ...Uri.parse(callback).queryParameters,
        'amount': amountMsat.toString(),
      },
    );

    // Security: only allow HTTPS callbacks
    if (callbackUri.scheme != 'https') {
      throw LightningAddressException(
        'Lightning Address callback must use HTTPS (got ${callbackUri.scheme})',
      );
    }

    final invoiceResponse = await _client
        .get(callbackUri)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw LightningAddressException(
            'Timeout requesting invoice from $domain',
          ),
        );

    if (invoiceResponse.statusCode != 200) {
      throw LightningAddressException(
        'Failed to fetch invoice: HTTP ${invoiceResponse.statusCode} from callback',
      );
    }

    final Map<String, dynamic> invoiceJson;
    try {
      invoiceJson = jsonDecode(invoiceResponse.body) as Map<String, dynamic>;
    } catch (_) {
      throw LightningAddressException(
        'Invalid JSON in invoice response from $domain',
      );
    }

    if (invoiceJson['status'] == 'ERROR') {
      final reason = invoiceJson['reason'] ?? 'Unknown error';
      throw LightningAddressException('Invoice request failed: $reason');
    }

    final pr = invoiceJson['pr'] as String?;
    if (pr == null || pr.isEmpty) {
      throw LightningAddressException(
        'Invoice response missing payment request (pr field)',
      );
    }

    return pr;
  }
}

class LightningAddressException implements Exception {
  final String message;
  const LightningAddressException(this.message);

  @override
  String toString() => message;
}

final lightningAddressResolverProvider = Provider<LightningAddressResolver>(
  (ref) => LightningAddressResolver(),
);
