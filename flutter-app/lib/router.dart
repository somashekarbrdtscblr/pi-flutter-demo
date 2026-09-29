import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/components_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/dialogs_page.dart';
import 'pages/forms_page.dart';
import 'pages/lists_page.dart';
import 'pages/login_page.dart';
import 'pages/products_page.dart';
import 'pages/settings_page.dart';
import 'state/auth_state.dart';
import 'widgets/home_shell.dart';

/// One entry in the side navigation. The shell and the router both read this
/// list, so adding a page means adding one line here.
class Destination {
  const Destination(
    this.path,
    this.label,
    this.icon,
    this.selectedIcon,
    this.page,
  );

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

const destinations = <Destination>[
  Destination(
    '/dashboard',
    'Dashboard',
    Icons.dashboard_outlined,
    Icons.dashboard,
    DashboardPage(),
  ),
  Destination(
    '/components',
    'Components',
    Icons.widgets_outlined,
    Icons.widgets,
    ComponentsPage(),
  ),
  Destination(
    '/forms',
    'Forms',
    Icons.edit_note_outlined,
    Icons.edit_note,
    FormsPage(),
  ),
  Destination(
    '/dialogs',
    'Dialogs',
    Icons.chat_bubble_outline,
    Icons.chat_bubble,
    DialogsPage(),
  ),
  Destination(
    '/products',
    'Products',
    Icons.table_chart_outlined,
    Icons.table_chart,
    ProductsPage(),
  ),
  Destination(
    '/lists',
    'Lists & Layout',
    Icons.view_list_outlined,
    Icons.view_list,
    ListsPage(),
  ),
  Destination(
    '/settings',
    'Settings',
    Icons.settings_outlined,
    Icons.settings,
    SettingsPage(),
  ),
];

const loginPath = '/login';
const homePath = '/dashboard';

GoRouter createRouter(AuthState auth) {
  return GoRouter(
    initialLocation: homePath,
    refreshListenable: auth,
    redirect: (context, state) {
      final atLogin = state.matchedLocation == loginPath;
      if (!auth.isLoggedIn) {
        if (atLogin) return null;
        // Remember where the user was headed so login can send them back.
        return Uri(
          path: loginPath,
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }
      if (atLogin) return state.uri.queryParameters['from'] ?? homePath;
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => homePath),
      GoRoute(path: loginPath, builder: (_, _) => const LoginPage()),
      // Plain ShellRoute: switching pages disposes the old one (lowest RAM
      // on the Pi). Shared data lives in providers, not in pages.
      ShellRoute(
        builder: (context, state, child) =>
            HomeShell(location: state.matchedLocation, child: child),
        routes: [
          for (final d in destinations)
            GoRoute(
              path: d.path,
              // No transition animation: cheaper on the Pi's GPU.
              pageBuilder: (_, state) =>
                  NoTransitionPage(key: state.pageKey, child: d.page),
            ),
        ],
      ),
    ],
  );
}
