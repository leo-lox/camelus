import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'domain_layer/entities/starter_pack_identifier.dart';
import 'lifecycle/app_init_shell.dart';
import 'presentation_layer/components/app_bottom_navigation_bar/app_bottom_navigation_bar.dart';
import 'presentation_layer/components/drawer/nostr_side_menu.dart';
import 'presentation_layer/components/drawer/nostr_side_menu_post_button.dart';
import 'presentation_layer/components/drawer/side_menu_logo.dart';
import 'presentation_layer/components/relays_connectivity_widget.dart';
import 'presentation_layer/components/right_sidebar/right_siedbar.dart';
import 'presentation_layer/components/starter_packs/edit_starter_pack/edit_starter_pack.dart';
import 'presentation_layer/components/starter_packs/open_starter_pack.dart';
import 'presentation_layer/layouts/mobile_bottom_menu_layout.dart';
import 'presentation_layer/layouts/responsive_layout.dart';
import 'presentation_layer/layouts/three_colum_layout.dart';
import 'presentation_layer/routes/deeplink_reciever_page.dart';
import 'presentation_layer/routes/home_page_desktop.dart';
import 'presentation_layer/routes/home_page_mobile.dart';
import 'presentation_layer/routes/nostr/blockedUsers/blocked_users.dart';
import 'presentation_layer/routes/nostr/bookmarks/bookmarks_page.dart';
import 'presentation_layer/routes/nostr/event_view/event_view_page.dart';
import 'presentation_layer/routes/nostr/onboarding/onboarding.dart';
import 'presentation_layer/routes/nostr/profile/edit_profile_page.dart';
import 'presentation_layer/routes/nostr/profile/profile_page_2.dart';
import 'presentation_layer/routes/nostr/relays_page.dart';
import 'presentation_layer/routes/nostr/search_feed_page/search_feed_page.dart';
import 'presentation_layer/routes/nostr/settings/theme/theme_settings.dart';
import 'presentation_layer/routes/notification_page.dart';
import 'presentation_layer/routes/search/search_page.dart';
import 'presentation_layer/routes/nostr/settings/file_servers/settings_file_servers.dart';
import 'presentation_layer/routes/nostr/settings/inital_route/inital_route_settings.dart';
import 'presentation_layer/routes/nostr/settings/locale/locale_settings.dart';
import 'presentation_layer/routes/nostr/settings/moderation/moderation_settings.dart';
import 'presentation_layer/routes/nostr/settings/settings_page.dart';

redirects(BuildContext context, GoRouterState state) {
  return null;
}

final routes = [
  /// global shell
  ShellRoute(
    builder: (context, state, child) {
      return AppInitializationShell(child: child);
    },
    routes: [
      // Shell route for persistent layout
      ShellRoute(
        builder: (context, state, child) {
          return ResponsiveLayout(
            desktopContent: ThreeColumnLayout(
              leftSidebar: NostrSideMenu(
                trailingButtonWidget: Padding(
                  padding: const EdgeInsets.only(top: 40, left: 10, right: 10),
                  child: NostrSideMenuPostButton(),
                ),
                leadingWidget: SideMenuLogo(
                  trailingWidget: RelaysConnectivityWidget(
                    onTap: () {
                      context.push('/nostr/relays');
                    },
                  ),
                ),
              ),
              mainContent: child,
              rightSidebar: RightSiedbar(),
            ),
            mobileContent: MobileBottomMenuLayout(
              mainContent: child,
              bottomNavigationBar: AppBottomNavigationBar(),
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => ResponsiveLayout(
              desktopContent: const HomePageDesktop(),
              mobileContent: const HomePageMobile(initialTab: '/'),
            ),
          ),
          GoRoute(
            path: '/posts-and-replies',
            builder: (context, state) =>
                const HomePageMobile(initialTab: '/posts-and-replies'),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
            routes: [
              GoRoute(
                path: 'file-servers',
                builder: (context, state) => const SettingsFileServers(),
              ),
              GoRoute(
                path: 'initial-route',
                builder: (context, state) => const InitalRouteSettings(),
              ),
              GoRoute(
                path: 'locale',
                builder: (context, state) => const LocaleSettingsPage(),
              ),
              GoRoute(
                path: 'moderation',
                builder: (context, state) => const ModerationSettingsPage(),
              ),
              GoRoute(
                path: 'theme',
                builder: (context, state) => const ThemeSettingsPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/nostr/event',
            builder: (context, state) {
              final args = state.extra as Map<String, dynamic>;
              return EventViewPage(
                rootNoteId: args['root'] as String,
                openNoteId: args['scrollIntoView'] as String?,
              );
            },
          ),
          GoRoute(
            path: '/nostr/relays',
            builder: (context, state) {
              return RelaysPage();
            },
          ),
          GoRoute(
            path: '/nostr/profile/:pubkey',
            builder: (context, state) =>
                ProfilePage2(pubkey: state.pathParameters['pubkey']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    EditProfilePage(pubkey: state.pathParameters['pubkey']!),
              ),
            ],
          ),
          GoRoute(
            path: '/nostr/search',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: SearchFeedPage(query: state.extra as String),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) => child,
            ),
          ),
          GoRoute(
            path: '/nostr/bookmarks',
            builder: (context, state) => const BookmarksPage(),
          ),
          GoRoute(
            path: '/nostr/blockedUsers',
            builder: (context, state) => const BlockedUsers(),
          ),
          GoRoute(
            path: '/edit-starter-pack',
            builder: (context, state) => EditStarterPack(
              starterPackIdentifier: state.extra as StarterPackIdentifier,
            ),
          ),
          GoRoute(
            path: '/open-starter-pack',
            builder: (context, state) => OpenStarterPack(
              starterPackIdentifier: state.extra as StarterPackIdentifier,
            ),
          ),
        ],
      ),
      // Routes outside the shell (no persistent layout)
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const NostrOnboarding(),
      ),

      GoRoute(
        path: '/:id',
        builder: (context, state) =>
            DeeplinkRecieverPage(userParam: state.pathParameters['id']!),
      ),
    ],
  ),

  /// needed to support old installations
  GoRoute(
    path: '/',
    redirect: (context, state) {
      return '/home';
    },
  ),
];
