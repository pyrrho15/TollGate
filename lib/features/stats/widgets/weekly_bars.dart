import 'package:flutter/material.dart';

import '../../../core/utils/format.dart';
import '../../../data/models/app_stats.dart';

/// A compact seven-day bar chart of total time, drawn with plain widgets so the
/// app stays dependency-free.
class WeeklyBars extends StatelessWidget {
  const WeeklyBars({super.key, required this.history});

  /// Oldest first, today last.
  final List<DayStat> history;

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
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Last 7 days',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
                      emphasized: i == todayIndex,
                      weekday: _weekdays[history[i].dateTime.weekday - 1],
                      scheme: scheme,
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
    required this.emphasized,
    required this.weekday,
    required this.scheme,
  });

  final String label;
  final double factor;
  final bool emphasized;
  final String weekday;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
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
                  color: emphasized
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
            color: emphasized ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
