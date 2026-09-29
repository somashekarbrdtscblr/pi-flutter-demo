import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/settings_state.dart';
import '../utils/platform_info.dart';
import '../widgets/section.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final mq = MediaQuery.of(context);
    final theme = Theme.of(context);

    return PageBody(
      children: [
        Section(
          title: 'Appearance',
          subtitle: 'Saved on this device',
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
                selected: {settings.themeMode},
                onSelectionChanged: (s) => settings.themeMode = s.first,
              ),
              const SizedBox(height: 16),
              Text('Seed colour', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final c in SettingsState.seedColors)
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => settings.seed = c,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: c,
                        child: settings.seed.toARGB32() == c.toARGB32()
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
              _info('Platform', platformName),
              _info(
                'Build mode',
                kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug'),
              ),
              _info('CPU cores', cpuCores),
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
