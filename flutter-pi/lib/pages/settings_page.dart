import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets/section.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _seeds = [
    Colors.indigo,
    Colors.teal,
    Colors.deepOrange,
    Colors.pink,
    Colors.green,
    Colors.purple,
    Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final mq = MediaQuery.of(context);
    final theme = Theme.of(context);

    return PageBody(
      children: [
        Section(
          title: 'Appearance',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                    label: Text('Dark'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto),
                    label: Text('System'),
                  ),
                ],
                selected: {state.themeMode},
                onSelectionChanged: (s) => state.themeMode = s.first,
              ),
              const SizedBox(height: 16),
              Text('Seed colour', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final c in _seeds)
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => state.seed = c,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: c,
                        child: state.seed == c
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Section(
          title: 'Device info',
          subtitle: 'Handy when checking the Pi display',
          child: Column(
            children: [
              _info(
                'Logical size',
                '${mq.size.width.toStringAsFixed(0)} × ${mq.size.height.toStringAsFixed(0)}',
              ),
              _info(
                'Device pixel ratio',
                mq.devicePixelRatio.toStringAsFixed(2),
              ),
              _info(
                'Platform',
                kIsWeb
                    ? 'web'
                    : '${Platform.operatingSystem} (${Platform.version.split(' ').first})',
              ),
              _info(
                'Build mode',
                kReleaseMode
                    ? 'release'
                    : kProfileMode
                    ? 'profile'
                    : 'debug',
              ),
              _info(
                'CPU cores',
                kIsWeb ? '-' : '${Platform.numberOfProcessors}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _info(String k, String v) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(k),
    trailing: Text(v),
  );
}
