// DEV 3 — per PDR Section 11.1
import '../../app/constants.dart';
class AppRegistry {
  static String? resolvePackage(String appName) =>
      VConstants.appPackages[appName.toLowerCase()];
}
