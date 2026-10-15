import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/app_stats.dart';
import 'stats_controller.dart';
import 'widgets/screen_time_donut.dart';
import 'widgets/weekly_bars.dart';

/// The "Stats" tab: time spent in the apps you block and how many scrolls were
/// blocked, all counted on-device from the events the blocker already sees.
///
/// Today is shown first; picking a day in the seven-day chart swaps the per-app
/// donut below it to that day's split.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with WidgetsBindingObserver {
  /// Index into [AppStats.history] shown in the donut. -1 means "follow today",
  /// which stays correct when the day rolls over.
  int _selected = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The tab is rebuilt each time it is opened, so this refreshes on entry.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StatsController>().refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<StatsController>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StatsController>();

    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final stats = controller.stats;
    if (!controller.hasData || stats == null || stats.history.isEmpty) {
      return _ErrorView(
        message: controller.error ?? 'No stats available yet.',
        onRetry: controller.refresh,
      );
    }

    final history = stats.history;
    final selected =
        (_selected < 0 || _selected >= history.length) ? history.length - 1 : _selected;

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: _content(context, stats, selected),
    );
  }

  Widget _content(BuildContext context, AppStats stats, int selectedIndex) {
    final history = stats.history;
    final day = history[selectedIndex];
    final isToday = selectedIndex == history.length - 1;
    final dayName = isToday ? 'Today' : day.weekdayName;
    final shortName = isToday ? 'today' : day.weekdayName.substring(0, 3);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gutter,
        8,
        AppTheme.gutter,
        40,
      ),
      children: [
        _SummaryGrid(stats: stats),
        const SizedBox(height: 24),
        WeeklyBars(
          history: history,
          selectedIndex: selectedIndex,
          onSelect: (index) => setState(() => _selected = index),
        ),
        const SizedBox(height: 24),
        SectionHeader(
          title: '$dayName by app',
          subtitle: isToday
              ? "Where today's screen time went."
              : "Where ${day.weekdayName}'s screen time went.",
        ),
        ScreenTimeDonut(targets: day.targets, dayLabel: shortName),
      ],
    );
  }
}

/// Two side-by-side cards: today's total screen time, and the breaks taken.
class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.stats});

  final AppStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unblock = stats.unblock;
    final breaks = unblock.sessions;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MiniStat(
              icon: Icons.insights_rounded,
              tint: scheme.primary,
              label: 'Screen time',
              value: formatDuration(stats.todayTimeMs),
              caption:
                  'Today · ${stats.todayBlocks} ${stats.todayBlocks == 1 ? 'scroll' : 'scrolls'} blocked',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MiniStat(
              icon: Icons.coffee_rounded,
              tint: scheme.tertiary,
              label: 'Breaks today',
              value: '$breaks',
              caption: '${formatDuration(unblock.remainingMs)} left',
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: tint),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
