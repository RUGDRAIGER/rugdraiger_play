import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformConfig {
  PlatformConfig._();

  static bool get isDesktop =>
      !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  static bool get isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);
}
