import 'package:flutter/material.dart';

import '../../../core/utils/format.dart';
import '../../../data/models/app_stats.dart';

/// A GitHub-style contribution grid: one column per week, one cell per day.
///
/// A day turns green when the time spent in the monitored apps stayed under the daily
/// budget. Days before TollGate started recording are left neutral, so the grid never
/// flatters you with green you didn't earn.
class ContributionGraph extends StatelessWidget {
  const ContributionGraph({
    super.key,
    required this.days,
    required this.trackedFrom,
    required this.thresholdMs,
  });

  /// Oldest first, today last.
  final List<DayStat> days;

  /// Earliest date we have any data for (yyyy-MM-dd), or null.
  final String? trackedFrom;

  /// Time under which a day counts as green.
  final int thresholdMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    // Pad the start so the first column begins on a Sunday.
    final leading = days.first.dateTime.weekday % 7;
    final cells = <DayStat?>[
      ...List<DayStat?>.filled(leading, null),
      ...days,
    ];
    final weeks = <List<DayStat?>>[];
    for (var i = 0; i < cells.length; i += 7) {
      final week = cells.sublist(i, (i + 7).clamp(0, cells.length));
      while (week.length < 7) {
        week.add(null);
      }
      weeks.add(week);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final week in weeks)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Column(
                    children: [
                      for (final day in week)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: _Cell(
                            day: day,
                            trackedFrom: trackedFrom,
                            thresholdMs: thresholdMs,
                            scheme: scheme,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _LegendDot(color: _green(scheme), label: 'Under ${formatDurationCompact(thresholdMs)}'),
            const SizedBox(width: 14),
            _LegendDot(color: scheme.error.withValues(alpha: 0.55), label: 'Over'),
            const SizedBox(width: 14),
            _LegendDot(color: scheme.surfaceContainerHighest, label: 'No data'),
          ],
        ),
      ],
    );
  }
}

Color _green(ColorScheme scheme) => const Color(0xFF2E9E5B);

class _Cell extends StatelessWidget {
  const _Cell({
    required this.day,
    required this.trackedFrom,
    required this.thresholdMs,
    required this.scheme,
  });

  final DayStat? day;
  final String? trackedFrom;
  final int thresholdMs;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    const size = 14.0;

    if (day == null) {
      return const SizedBox(width: size, height: size);
    }

    final date = day!.date;
    final tooEarly = trackedFrom != null && date.compareTo(trackedFrom!) < 0;

    final Color color;
    if (tooEarly) {
      color = scheme.surfaceContainerHighest.withValues(alpha: 0.4);
    } else if (day!.timeMs < thresholdMs) {
      color = _green(scheme);
    } else {
      color = scheme.error.withValues(alpha: 0.55);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
