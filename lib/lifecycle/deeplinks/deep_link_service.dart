import 'dart:async';
import 'dart:developer';
import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  static final _appLinks = AppLinks();
  static StreamSubscription<Uri>? _linkSubscription;
  static BuildContext? _context;

  static void initialize(BuildContext context) {
    _context = context;
    _handleIncomingLinks();
  }

  static void _handleIncomingLinks() {
    // Handle initial link when app is launched
    _handleInitialLink();

    // Handle links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _processDeepLink(uri);
      },
      onError: (err) {
        log('Deep link error: $err');
      },
    );
  }

  static void _handleInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _processDeepLink(uri);
      }
    } catch (e) {
      log('Error handling initial link: $e');
    }
  }

  static void _processDeepLink(Uri uri) {
    log('Processing deep link: $uri');

    // Handle custom schemes (camelus:, nostr:)
    if (['camelus', 'nostr'].contains(uri.scheme)) {
      String? userParam;

      // Handle scheme:userParam format (no authority, path without leading slash)
      if (uri.authority.isEmpty &&
          uri.path.isNotEmpty &&
          !uri.path.startsWith('/')) {
        userParam = uri.path;
      }
      // Handle scheme://userParam format (userParam as authority/host)
      else if (uri.authority.isNotEmpty &&
          (uri.path == '/' || uri.path.isEmpty)) {
        userParam = uri.authority;
      }
      // handle sheme:/ format (userParam as path with leading slash)
      else if (uri.authority.isEmpty &&
          uri.path.isNotEmpty &&
          uri.path.startsWith('/')) {
        userParam = uri.path.substring(1); // Remove leading slash
      }

      if (userParam != null && userParam.isNotEmpty) {
        try {
          _context?.go("/$userParam");
        } catch (e) {
          _context?.go('/home');
        }
        return;
      }

      // Fallback for custom schemes
      _context?.go('/home');
      return;
    }

    // Handle HTTPS links (camelus.app)
    if (uri.scheme == 'https' && uri.host == 'camelus.app') {
      if (uri.pathSegments.isNotEmpty) {
        // Default for camelus.app links
        try {
          _context?.go("/${uri.pathSegments.join('-_-')}");
        } catch (e) {
          _context?.go('/home');
        }
        return;
      }

      // Fallback for other HTTPS links
      _context?.go('/home');
      return;
    }

    // For any other links, try to navigate directly
    try {
      _context?.go(uri.path.isEmpty ? '/' : uri.path);
    } catch (e) {
      _context?.go('/home');
    }
  }

  static void dispose() {
    _linkSubscription?.cancel();
  }
}
