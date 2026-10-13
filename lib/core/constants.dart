/// Names shared between Dart and the native Android side.
class AppConstants {
  AppConstants._();

  static const String appName = 'TollGate';

  /// Shown in the About sheet. Keep in sync with pubspec `version`.
  static const String appVersion = '1.3.1';

  /// One-line description of what the app does.
  static const String tagline = 'Less scrolling. More living.';

  /// Must match UnblockSchedule.PHRASE on the native side.
  static const String commitmentPhrase = "I'll regret this later";

  /// Must match UnblockSchedule.DAILY_BUDGET_MS.
  static const Duration dailyUnblockBudget = Duration(minutes: 90);

  /// Must match UnblockSchedule's hard window: 12am–10am.
  static const int hardBlockStartHour = 0;
  static const int hardBlockEndHour = 10;

  /// Must match MainActivity.METHOD_CHANNEL.
  static const String methodChannel = 'com.tollgate.app/blocker';

  /// Must match MainActivity.EVENT_CHANNEL.
  static const String eventChannel = 'com.tollgate.app/blocker_events';
}
