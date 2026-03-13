// lib/features/actions/app_registry.dart

import 'package:vanimitra/app/constants.dart';

class AppRegistry {
  AppRegistry._();

  /// Resolves a spoken app name to its Android package identifier.
  /// Returns null if the app name is not recognised.
  static String? resolvePackage(String appName) {
    return VConstants.appPackages[appName.toLowerCase().trim()];
  }
}
