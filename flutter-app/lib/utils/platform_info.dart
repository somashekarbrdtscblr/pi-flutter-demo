// dart:io is not available on web, so pick the implementation at compile time.
export 'platform_info_web.dart' if (dart.library.io) 'platform_info_io.dart';
