import 'dart:async';
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
        print('Deep link error: $err');
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
      print('Error handling initial link: $e');
    }
  }

  static void _processDeepLink(Uri uri) {
    print('Processing deep link: $uri');

    // Handle custom schemes (camelus:, myapp:, nostr:)
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

      if (userParam != null && userParam.isNotEmpty) {
        print('Navigating to profile: $userParam');
        _context?.go('/nostr/profile/$userParam');
        return;
      }

      // Fallback for custom schemes
      _context?.go('/home');
      return;
    }

    // Handle HTTPS links (camelus.app)
    if (uri.scheme == 'https' && uri.host == 'camelus.app') {
      if (uri.pathSegments.isNotEmpty) {
        final firstSegment = uri.pathSegments.first;

        switch (firstSegment) {
          case 'user':
            if (uri.pathSegments.length > 1) {
              final userParam = uri.pathSegments[1];
              _context?.go('/nostr/profile/$userParam');
              return;
            }
            break;
          case 'i':
            // Handle /i/ paths
            _context?.go('/home');
            return;
          case 'ii':
            // Handle /ii/ paths
            _context?.go('/home');
            return;
          case 's':
            // Handle /s/ paths
            _context?.go('/search');
            return;
        }
      }

      // Default for camelus.app links
      _context?.go('/home');
      return;
    }

    // For any other links, try to navigate directly
    try {
      _context?.go(uri.path.isEmpty ? '/' : uri.path);
    } catch (e) {
      print('Error navigating to ${uri.path}: $e');
      _context?.go('/home');
    }
  }

  static void dispose() {
    _linkSubscription?.cancel();
  }
}
