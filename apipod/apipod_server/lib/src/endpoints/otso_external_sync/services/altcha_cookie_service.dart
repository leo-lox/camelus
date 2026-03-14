import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

class AltchaCookieService {
  AltchaCookieService({HttpClient? httpClient})
      : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;

  Future<String> solveChallengeAndGetCookie({
    required Uri url,
    String challengeHeader = 'x-altcha',
    String payloadHeader = 'x-altcha-payload',
    String signatureHeader = 'x-altcha-signature',
    String submitMethod = 'POST',
    Map<String, String> initialHeaders = const {},
    Map<String, String> submitHeaders = const {},
    bool submitPayloadAsJsonBody = true,
    bool debug = false,
    Duration challengeTimeout = const Duration(seconds: 30),
  }) async {
    late final _HttpResponseData challengeResponse;
    try {
      challengeResponse = await _send(
        method: 'POST',
        url: url,
        headers: initialHeaders,
      ).timeout(challengeTimeout);
    } on TimeoutException {
      throw StateError(
        'ALTCHA challenge request timed out after ${challengeTimeout.inSeconds}s.',
      );
    }

    if (debug) {
      _debug('Challenge response status: ${challengeResponse.statusCode}');
      _debug('Challenge headers: ${challengeResponse.headers.keys.join(', ')}');
    }

    final challengeJson = challengeResponse.headerValue(challengeHeader);
    if (challengeJson == null || challengeJson.isEmpty) {
      if (debug) {
        _debug('Missing challenge header: $challengeHeader');
        _debug(
            'Challenge response body (first 500): ${_truncate(challengeResponse.body)}');
      }
      throw StateError('Missing ALTCHA header: $challengeHeader');
    }

    final challenge = _AltchaChallenge.fromHeader(challengeJson);
    final solvedNumber = _solve(challenge);

    final payloadMap = <String, dynamic>{
      'algorithm': challenge.algorithm,
      'challenge': challenge.challenge,
      'number': solvedNumber,
      'salt': challenge.salt,
    };

    final payloadWithSignatureMap = <String, dynamic>{
      ...payloadMap,
      'signature': challenge.signature,
    };

    final payloadBase64 = base64.encode(utf8.encode(jsonEncode(payloadMap)));
    final payloadBase64Url =
        base64UrlEncode(utf8.encode(jsonEncode(payloadMap)));
    final payloadWithSignatureBase64 =
        base64.encode(utf8.encode(jsonEncode(payloadWithSignatureMap)));
    final payloadWithSignatureBase64Url =
        base64UrlEncode(utf8.encode(jsonEncode(payloadWithSignatureMap)));

    final variants = <_AltchaVerificationVariant>[
      _AltchaVerificationVariant(
        name: 'base64+sig-in-payload+headers+body',
        payload: payloadWithSignatureBase64,
        includeHeaders: true,
        includeBody: true,
      ),
      _AltchaVerificationVariant(
        name: 'base64url+sig-in-payload+headers+body',
        payload: payloadWithSignatureBase64Url,
        includeHeaders: true,
        includeBody: true,
      ),
      _AltchaVerificationVariant(
        name: 'base64url+headers+body',
        payload: payloadBase64Url,
        includeHeaders: true,
        includeBody: true,
      ),
      _AltchaVerificationVariant(
        name: 'base64+headers+body',
        payload: payloadBase64,
        includeHeaders: true,
        includeBody: true,
      ),
      _AltchaVerificationVariant(
        name: 'base64url+headers-only',
        payload: payloadBase64Url,
        includeHeaders: true,
        includeBody: false,
      ),
      _AltchaVerificationVariant(
        name: 'base64+headers-only',
        payload: payloadBase64,
        includeHeaders: true,
        includeBody: false,
      ),
      _AltchaVerificationVariant(
        name: 'base64url+body-only',
        payload: payloadBase64Url,
        includeHeaders: false,
        includeBody: true,
      ),
      _AltchaVerificationVariant(
        name: 'base64+body-only',
        payload: payloadBase64,
        includeHeaders: false,
        includeBody: true,
      ),
    ];

    _HttpResponseData? verificationResponse;
    for (final variant in variants) {
      final headers = <String, String>{
        ...submitHeaders,
      };

      if (variant.includeHeaders) {
        headers[payloadHeader] = variant.payload;
        headers[signatureHeader] = challenge.signature;
      }

      String? body;
      if (submitPayloadAsJsonBody && variant.includeBody) {
        headers.putIfAbsent(
            HttpHeaders.contentTypeHeader, () => 'application/json');
        body = jsonEncode({
          'payload': variant.payload,
          'signature': challenge.signature,
        });
      }

      final response = await _send(
        method: submitMethod,
        url: url,
        headers: headers,
        body: body,
      );

      if (debug) {
        _debug('Verification variant: ${variant.name}');
        _debug('Verification response status: ${response.statusCode}');
        _debug('Verification body (first 500): ${_truncate(response.body)}');
      }

      verificationResponse = response;
      if (response.statusCode < 400) {
        break;
      }
    }

    if (verificationResponse == null) {
      throw StateError('ALTCHA verification did not produce a response.');
    }

    if (debug) {
      _debug(
          'Verification headers: ${verificationResponse.headers.keys.join(', ')}');
    }

    final cookieHeader = _buildCookieHeader(verificationResponse, debug: debug);

    if (cookieHeader.isEmpty) {
      throw StateError(
        'Could not parse cookie from verification response (status=${verificationResponse.statusCode}, body=${_truncate(verificationResponse.body)}).',
      );
    }

    if (debug) {
      _debug(
          'Final cookie header keys: ${_cookieKeys(cookieHeader).join(', ')}');
    }

    return cookieHeader;
  }

  String _buildCookieHeader(_HttpResponseData response, {required bool debug}) {
    final cookiesByName = <String, String>{};

    final setCookieValues =
        response.headers[HttpHeaders.setCookieHeader] ?? const <String>[];
    if (debug) {
      _debug('Set-Cookie count: ${setCookieValues.length}');
    }
    for (final setCookieValue in setCookieValues) {
      final cookie = Cookie.fromSetCookieValue(setCookieValue);
      cookiesByName[cookie.name] = cookie.value;
    }

    Map<String, dynamic>? jsonBody;
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          jsonBody = decoded;
        }
      } catch (_) {
        jsonBody = null;
      }
    }

    final token = jsonBody?['token'];
    if (token is String && token.isNotEmpty) {
      cookiesByName['accessToken'] = token;
    }

    if (!cookiesByName.containsKey('csrftoken')) {
      final csrfToken = jsonBody?['csrf_token'];
      if (csrfToken is String && csrfToken.isNotEmpty) {
        cookiesByName['csrftoken'] = csrfToken;
      }
    }

    if (debug) {
      _debug('Extracted cookie keys: ${cookiesByName.keys.join(', ')}');
    }

    final orderedNames = <String>['accessToken', 'csrftoken', 'sessionid'];
    final parts = <String>[];

    for (final name in orderedNames) {
      final value = cookiesByName[name];
      if (value != null && value.isNotEmpty) {
        parts.add('$name=$value');
      }
    }

    for (final entry in cookiesByName.entries) {
      if (!orderedNames.contains(entry.key) && entry.value.isNotEmpty) {
        parts.add('${entry.key}=${entry.value}');
      }
    }

    return parts.join('; ');
  }

  List<String> _cookieKeys(String cookieHeader) {
    return cookieHeader
        .split(';')
        .map((part) => part.trim())
        .where((part) => part.contains('='))
        .map((part) => part.split('=').first)
        .toList();
  }

  String _truncate(String value, {int max = 500}) {
    if (value.length <= max) {
      return value;
    }
    return '${value.substring(0, max)}...';
  }

  void _debug(String message) {
    print('[AltchaCookieService] $message');
  }

  int _solve(_AltchaChallenge challenge) {
    if (challenge.algorithm.toUpperCase() != 'SHA-256') {
      throw UnsupportedError(
        'Unsupported ALTCHA algorithm: ${challenge.algorithm}. Only SHA-256 is supported.',
      );
    }

    final matchSaltThenNumber =
        _findMatchingNumber(challenge, (number) => '${challenge.salt}$number');
    if (matchSaltThenNumber != null) {
      return matchSaltThenNumber;
    }

    final matchNumberThenSalt =
        _findMatchingNumber(challenge, (number) => '$number${challenge.salt}');
    if (matchNumberThenSalt != null) {
      return matchNumberThenSalt;
    }

    throw StateError(
      'Unable to solve ALTCHA challenge within maxNumber=${challenge.maxNumber}.',
    );
  }

  int? _findMatchingNumber(
    _AltchaChallenge challenge,
    String Function(int number) valueBuilder,
  ) {
    for (var number = 0; number <= challenge.maxNumber; number++) {
      final bytes = utf8.encode(valueBuilder(number));
      final digest = sha256.convert(bytes).toString();
      if (digest == challenge.challenge) {
        return number;
      }
    }
    return null;
  }

  Future<_HttpResponseData> _send({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    String? body,
  }) async {
    final request = await _httpClient.openUrl(method, url);
    for (final entry in headers.entries) {
      request.headers.set(entry.key, entry.value);
    }
    if (body != null) {
      request.write(body);
    }
    final response = await request.close();

    final responseBody = await utf8.decoder.bind(response).join();

    final responseHeaders = <String, List<String>>{};
    response.headers.forEach((name, values) {
      responseHeaders[name.toLowerCase()] = List<String>.from(values);
    });

    return _HttpResponseData(
      statusCode: response.statusCode,
      headers: responseHeaders,
      body: responseBody,
    );
  }
}

class _HttpResponseData {
  _HttpResponseData({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  final int statusCode;
  final Map<String, List<String>> headers;
  final String body;

  String? headerValue(String name) {
    final values = headers[name.toLowerCase()];
    if (values == null || values.isEmpty) {
      return null;
    }
    return values.first;
  }
}

class _AltchaVerificationVariant {
  _AltchaVerificationVariant({
    required this.name,
    required this.payload,
    required this.includeHeaders,
    required this.includeBody,
  });

  final String name;
  final String payload;
  final bool includeHeaders;
  final bool includeBody;
}

class _AltchaChallenge {
  _AltchaChallenge({
    required this.algorithm,
    required this.challenge,
    required this.maxNumber,
    required this.salt,
    required this.signature,
  });

  final String algorithm;
  final String challenge;
  final int maxNumber;
  final String salt;
  final String signature;

  factory _AltchaChallenge.fromHeader(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Invalid ALTCHA header JSON.');
    }

    final algorithm = decoded['algorithm'];
    final challenge = decoded['challenge'];
    final maxNumber = decoded['maxNumber'];
    final salt = decoded['salt'];
    final signature = decoded['signature'];

    if (algorithm is! String ||
        challenge is! String ||
        maxNumber is! int ||
        salt is! String ||
        signature is! String) {
      throw FormatException('ALTCHA header fields are missing or invalid.');
    }

    return _AltchaChallenge(
      algorithm: algorithm,
      challenge: challenge,
      maxNumber: maxNumber,
      salt: salt,
      signature: signature,
    );
  }
}
