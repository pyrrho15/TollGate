import 'unblock_info.dart';

/// Screen-time and blocking statistics, built by the native side and read by the
/// Stats screen. All values are on-device only.
class AppStats {
  const AppStats({
    required this.today,
    required this.targets,
    required this.history,
    this.unblock = UnblockInfo.empty,
  });

  /// Local date these "today" figures belong to (yyyy-MM-dd).
  final String today;

  /// Today's per-app figures.
  final List<TargetStat> targets;

  /// Last seven days, oldest first (includes today). Each day carries its own
  /// per-app split so any day can be shown as a donut.
  final List<DayStat> history;

  /// Today's break budget, so the Stats screen can show breaks taken.
  final UnblockInfo unblock;

  int get todayTimeMs => targets.fold(0, (sum, t) => sum + t.timeMs);
  int get todayBlocks => targets.fold(0, (sum, t) => sum + t.blocks);
  bool get isEmptyToday => todayTimeMs == 0 && todayBlocks == 0;

  factory AppStats.fromMap(Map<dynamic, dynamic> map) => AppStats(
        today: map['today'] as String,
        targets: (map['targets'] as List)
            .map((e) => TargetStat.fromMap(e as Map))
            .toList(growable: false),
        history: (map['history'] as List)
            .map((e) => DayStat.fromMap(e as Map))
            .toList(growable: false),
        unblock: map['unblock'] == null
            ? UnblockInfo.empty
            : UnblockInfo.fromMap(map['unblock'] as Map),
      );
}

/// Figures for a single supported app on a single day.
class TargetStat {
  const TargetStat({
    required this.id,
    required this.name,
    required this.timeMs,
    required this.blocks,
    required this.opens,
  });

  final String id;
  final String name;
  final int timeMs;
  final int blocks;
  final int opens;

  factory TargetStat.fromMap(Map<dynamic, dynamic> map) => TargetStat(
        id: map['id'] as String,
        name: map['name'] as String,
        timeMs: (map['timeMs'] as num).toInt(),
        blocks: (map['blocks'] as num).toInt(),
        opens: (map['opens'] as num).toInt(),
      );
}

/// One day in the seven-day history.
class DayStat {
  const DayStat({
    required this.date,
    required this.timeMs,
    required this.blocks,
    this.targets = const [],
  });

  final String date;
  final int timeMs;
  final int blocks;

  /// That day's per-app split, in the same order as [AppStats.targets].
  final List<TargetStat> targets;

  /// `yyyy-MM-dd` parsed without pulling in intl.
  DateTime get dateTime => DateTime.parse(date);

  /// e.g. `Monday`, `Tuesday` — derived from the date, locale-independent.
  String get weekdayName => const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ][dateTime.weekday - 1];

  factory DayStat.fromMap(Map<dynamic, dynamic> map) => DayStat(
        date: map['date'] as String,
        timeMs: (map['timeMs'] as num).toInt(),
        blocks: (map['blocks'] as num).toInt(),
        targets: ((map['targets'] as List?) ?? const [])
            .map((e) => TargetStat.fromMap(e as Map))
            .toList(growable: false),
      );
}
