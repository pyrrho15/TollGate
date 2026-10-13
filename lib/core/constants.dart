/// Names shared between Dart and the native Android side.
class AppConstants {
  AppConstants._();

  static const String appName = 'TollGate';

  /// Shown in the About sheet. Keep in sync with pubspec `version`.
  static const String appVersion = '1.2.0';

  /// One-line description of what the app does.
  static const String tagline = 'Less scrolling. More living.';

  /// Must match MainActivity.METHOD_CHANNEL.
  static const String methodChannel = 'com.tollgate.app/blocker';

  /// Must match MainActivity.EVENT_CHANNEL.
  static const String eventChannel = 'com.tollgate.app/blocker_events';
}
