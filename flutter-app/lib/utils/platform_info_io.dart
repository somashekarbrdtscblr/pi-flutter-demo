import 'dart:io' show Platform;

String get platformName =>
    '${Platform.operatingSystem} (Dart ${Platform.version.split(' ').first})';

String get cpuCores => '${Platform.numberOfProcessors}';
