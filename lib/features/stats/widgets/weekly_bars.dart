import 'package:flutter/material.dart';

import '../../../core/utils/format.dart';
import '../../../data/models/app_stats.dart';

/// A compact seven-day bar chart of total time, drawn with plain widgets so the
/// app stays dependency-free. Tapping a bar selects that day, which the caller
/// uses to show that day's per-app breakdown.
class WeeklyBars extends StatelessWidget {
  const WeeklyBars({
    super.key,
    required this.history,
    required this.selectedIndex,
    required this.onSelect,
  });

  /// Oldest first, today last.
  final List<DayStat> history;

  /// Index into [history] currently shown in the per-app donut.
  final int selectedIndex;

  final ValueChanged<int> onSelect;

  /// Height of the drawing area (bars only; labels sit above/below).
  static const _barAreaHeight = 96.0;

  static const _weekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final maxMs = history.fold<int>(0, (m, d) => d.timeMs > m ? d.timeMs : m);
    final todayIndex = history.length - 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Last 7 days',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'Tap a day',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < history.length; i++)
                  Expanded(
                    child: _Bar(
                      label: formatDurationCompact(history[i].timeMs),
                      // 0..1, with a floor so an empty day still shows a sliver.
                      factor: maxMs == 0
                          ? 0.06
                          : 0.08 + 0.92 * (history[i].timeMs / maxMs),
                      selected: i == selectedIndex,
                      isToday: i == todayIndex,
                      weekday: _weekdays[history[i].dateTime.weekday - 1],
                      scheme: scheme,
                      onTap: () => onSelect(i),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.factor,
    required this.selected,
    required this.isToday,
    required this.weekday,
    required this.scheme,
    required this.onTap,
  });

  final String label;
  final double factor;
  final bool selected;
  final bool isToday;
  final String weekday;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: WeeklyBars._barAreaHeight,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: factor,
                  child: Container(
                    width: 16,
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primary
                          : scheme.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              weekday,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            // A dot marks today, so a past day can be selected without losing it.
            SizedBox(
              height: 8,
              child: isToday
                  ? Center(
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
