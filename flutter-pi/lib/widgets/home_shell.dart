import 'package:flutter/material.dart';

import '../app_state.dart';
import '../pages/components_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/feedback_page.dart';
import '../pages/forms_page.dart';
import '../pages/layout_page.dart';
import '../pages/settings_page.dart';
import '../pages/table_page.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon, this.builder);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

final _destinations = <_Destination>[
  _Destination(
    'Dashboard',
    Icons.dashboard_outlined,
    Icons.dashboard,
    (_) => const DashboardPage(),
  ),
  _Destination(
    'Components',
    Icons.widgets_outlined,
    Icons.widgets,
    (_) => const ComponentsPage(),
  ),
  _Destination(
    'Forms',
    Icons.edit_note_outlined,
    Icons.edit_note,
    (_) => const FormsPage(),
  ),
  _Destination(
    'Dialogs',
    Icons.chat_bubble_outline,
    Icons.chat_bubble,
    (_) => const FeedbackPage(),
  ),
  _Destination(
    'Editable Table',
    Icons.table_chart_outlined,
    Icons.table_chart,
    (_) => const TablePage(),
  ),
  _Destination(
    'Lists & Layout',
    Icons.view_list_outlined,
    Icons.view_list,
    (_) => const LayoutPage(),
  ),
  _Destination(
    'Settings',
    Icons.settings_outlined,
    Icons.settings,
    (_) => const SettingsPage(),
  ),
];

/// Main scaffold. Narrow screens (e.g. 800x480 Pi touch display) get a modal
/// left drawer; wide screens get a permanent sidebar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _wideBreakpoint = 1000.0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  void _select(int i, bool wide) {
    setState(() => _index = i);
    if (!wide) _scaffoldKey.currentState?.closeDrawer();
  }

  Future<void> _confirmLogout() async {
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
    if (ok == true && mounted) AppScope.read(context).logout();
  }

  Widget _buildNav(BuildContext context, bool wide) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    return NavigationDrawer(
      selectedIndex: _index,
      onDestinationSelected: (i) => _select(i, wide),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 16),
          child: Row(
            children: [
              CircleAvatar(child: Text((state.user ?? '?')[0].toUpperCase())),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pi Demo', style: theme.textTheme.titleMedium),
                    Text(
                      state.user ?? '',
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
        for (final d in _destinations)
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
              if (!wide) _scaffoldKey.currentState?.closeDrawer();
              _confirmLogout();
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    final state = AppScope.of(context);
    final dest = _destinations[_index];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final page = KeyedSubtree(
      key: ValueKey(_index),
      child: dest.builder(context),
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: !wide,
        title: Text(dest.label),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () =>
                state.themeMode = isDark ? ThemeMode.light : ThemeMode.dark,
          ),
          Badge.count(
            count: 3,
            offset: const Offset(-4, 4),
            child: IconButton(
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('3 new notifications (demo)')),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Account',
            icon: const Icon(Icons.account_circle),
            onSelected: (v) {
              if (v == 'logout') _confirmLogout();
              if (v == 'settings') {
                setState(() => _index = _destinations.length - 1);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(enabled: false, child: Text(state.user ?? '')),
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
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sign out'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: wide ? null : _buildNav(context, false),
      body: wide
          ? Row(
              children: [
                SizedBox(width: 300, child: _buildNav(context, true)),
                const VerticalDivider(width: 1),
                Expanded(child: page),
              ],
            )
          : page,
    );
  }
}
