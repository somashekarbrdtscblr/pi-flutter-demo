import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../router.dart';
import '../state/auth_state.dart';
import '../state/settings_state.dart';
import 'section.dart';

/// App bar + navigation around the current page. Narrow screens (e.g. an
/// 800x480 Pi display or a phone) get a modal drawer; wide ones a sidebar.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.location, required this.child});

  static const wideBreakpoint = 1000.0;

  final String location;
  final Widget child;

  int get _index {
    final i = destinations.indexWhere((d) => location.startsWith(d.path));
    return i == -1 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !wide,
        title: Text(destinations[_index].label),
        actions: const [
          _ThemeToggle(),
          _NotificationsButton(),
          _AccountMenu(),
          SizedBox(width: 8),
        ],
      ),
      drawer: wide ? null : _NavDrawer(selected: _index, modal: true),
      body: wide
          ? Row(
              children: [
                SizedBox(
                  width: 300,
                  child: _NavDrawer(selected: _index, modal: false),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            )
          : child,
    );
  }
}

Future<void> confirmLogout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.logout),
      title: const Text('Sign out?'),
      content: const Text('You will need to sign in again.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  // The router's redirect sends us to /login once auth changes.
  if (ok == true && context.mounted) context.read<AuthState>().logout();
}

class _NavDrawer extends StatelessWidget {
  const _NavDrawer({required this.selected, required this.modal});

  final int selected;
  final bool modal;

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthState, String>((a) => a.user ?? '');
    final theme = Theme.of(context);
    return NavigationDrawer(
      selectedIndex: selected,
      onDestinationSelected: (i) {
        if (modal) Navigator.pop(context);
        context.go(destinations[i].path);
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 16),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(user.isEmpty ? '?' : user[0].toUpperCase()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chota POS', style: theme.textTheme.titleMedium),
                    Text(
                      user,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(indent: 28, endIndent: 28),
        for (final d in destinations)
          NavigationDrawerDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label),
          ),
        const Divider(indent: 28, endIndent: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            shape: const StadiumBorder(),
            onTap: () {
              if (modal) Navigator.pop(context);
              confirmLogout(context);
            },
          ),
        ),
      ],
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: 'Toggle theme',
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
      onPressed: () => context.read<SettingsState>().themeMode = isDark
          ? ThemeMode.light
          : ThemeMode.dark,
    );
  }
}

class _NotificationsButton extends StatelessWidget {
  const _NotificationsButton();

  @override
  Widget build(BuildContext context) {
    return Badge.count(
      count: 3,
      offset: const Offset(-4, 4),
      child: IconButton(
        tooltip: 'Notifications',
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => showSnack(context, '3 new notifications (demo)'),
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthState, String>((a) => a.user ?? '');
    return PopupMenuButton<String>(
      tooltip: 'Account',
      icon: const Icon(Icons.account_circle),
      onSelected: (v) => switch (v) {
        'settings' => context.go('/settings'),
        _ => confirmLogout(context),
      },
      itemBuilder: (context) => [
        PopupMenuItem(enabled: false, child: Text(user)),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(leading: Icon(Icons.logout), title: Text('Sign out')),
        ),
      ],
    );
  }
}
