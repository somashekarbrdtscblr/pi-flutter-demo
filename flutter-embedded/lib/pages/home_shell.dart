import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'components_page.dart';
import 'dashboard_page.dart';
import 'dialogs_page.dart';
import 'forms_page.dart';
import 'lists_page.dart';
import 'settings_page.dart';
import 'table_page.dart';

class _Dest {
  const _Dest(this.label, this.icon, this.selectedIcon, this.builder);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

final _destinations = <_Dest>[
  _Dest('Dashboard', Icons.dashboard_outlined, Icons.dashboard, (_) => const DashboardPage()),
  _Dest('Forms', Icons.edit_note_outlined, Icons.edit_note, (_) => const FormsPage()),
  _Dest('Dialogs', Icons.chat_bubble_outline, Icons.chat_bubble, (_) => const DialogsPage()),
  _Dest('Data Table', Icons.table_chart_outlined, Icons.table_chart, (_) => const TablePage()),
  _Dest('Components', Icons.widgets_outlined, Icons.widgets, (_) => const ComponentsPage()),
  _Dest('Lists & Tabs', Icons.view_list_outlined, Icons.view_list, (_) => const ListsPage()),
  _Dest('Settings', Icons.settings_outlined, Icons.settings, (_) => const SettingsPage()),
];

/// Main layout. Wide screens (>= 900px): permanent sidebar.
/// Narrow screens (e.g. 800x480 Pi display): modal left drawer.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _select(int i, {bool closeDrawer = false}) {
    setState(() => _index = i);
    if (closeDrawer) Navigator.of(context).pop();
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.logout),
        title: const Text('Logout?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Logout')),
        ],
      ),
    );
    if (ok == true && mounted) AppScope.of(context).logout();
  }

  NavigationDrawer _drawer({required bool modal}) {
    final state = AppScope.of(context);
    return NavigationDrawer(
      selectedIndex: _index,
      onDestinationSelected: (i) => _select(i, closeDrawer: modal),
      children: [
        // Compact header: 480px-tall Pi displays can't spare a full
        // UserAccountsDrawerHeader.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('Admin'),
            subtitle: Text(state.user ?? '', overflow: TextOverflow.ellipsis),
          ),
        ),
        for (final d in _destinations)
          NavigationDrawerDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Divider(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              if (modal) Navigator.pop(context);
              _confirmLogout();
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final dest = _destinations[_index];

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(dest.label),
        automaticallyImplyLeading: !wide,
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(state.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => state.themeMode =
                state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: const Badge(label: Text('3'), child: Icon(Icons.notifications_outlined)),
            onPressed: () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text('3 new notifications'))),
          ),
          PopupMenuButton<String>(
            tooltip: 'Account',
            icon: const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16)),
            onSelected: (v) {
              if (v == 'logout') _confirmLogout();
              if (v == 'settings') setState(() => _index = _destinations.length - 1);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'settings', child: ListTile(leading: Icon(Icons.settings), title: Text('Settings'))),
              PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout), title: Text('Logout'))),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: wide ? null : _drawer(modal: true),
      body: KeyedSubtree(key: ValueKey(_index), child: dest.builder(context)),
    );

    if (!wide) return scaffold;
    return Row(
      children: [
        SizedBox(width: 280, child: _drawer(modal: false)),
        const VerticalDivider(width: 1),
        Expanded(child: scaffold),
      ],
    );
  }
}
