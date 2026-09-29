import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/section.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _seeds = [
    Colors.indigo, Colors.teal, Colors.green, Colors.orange, Colors.pink, Colors.deepPurple, Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final mq = MediaQuery.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Section(title: 'Appearance', children: [
          const Text('Theme mode'),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Dark')),
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.settings_suggest), label: Text('System')),
            ],
            selected: {state.themeMode},
            onSelectionChanged: (s) => state.themeMode = s.first,
          ),
          const SizedBox(height: 16),
          const Text('Seed color'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final c in _seeds)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => state.seed = c,
                  child: CircleAvatar(
                    backgroundColor: c,
                    child: state.seed == c ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                ),
            ],
          ),
        ]),
        Section(title: 'Device info', children: [
          ListTile(leading: const Icon(Icons.aspect_ratio), title: const Text('Logical size'),
              trailing: Text('${mq.size.width.round()} × ${mq.size.height.round()}')),
          ListTile(leading: const Icon(Icons.blur_on), title: const Text('Device pixel ratio'),
              trailing: Text(mq.devicePixelRatio.toStringAsFixed(2))),
          ListTile(leading: const Icon(Icons.person), title: const Text('Signed in as'),
              trailing: Text(state.user ?? '-')),
        ]),
      ],
    );
  }
}
