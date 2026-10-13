import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../core/utils/format.dart';
import '../../../data/models/blocker_state.dart';

/// The "break time" control. Protection itself is a one-way switch (turning it on arms
/// blocking); the only way to pause is a timed break that spends today's budget.
class BreakCard extends StatelessWidget {
  const BreakCard({
    super.key,
    required this.state,
    required this.onEnableProtection,
    required this.onStartBreak,
    required this.onStopBreak,
  });

  final BlockerState state;
  final VoidCallback onEnableProtection;
  final VoidCallback onStartBreak;
  final VoidCallback onStopBreak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unblock = state.unblock;

    // 1. Protection has not been armed yet.
    if (!state.masterEnabled) {
      return _Shell(
        icon: Icons.shield_outlined,
        color: scheme.primary,
        title: 'Turn protection on',
        body: 'Arm the blocker once. After that, the only way to pause it is a daily '
            'break you have to ask for.',
        action: FilledButton.icon(
          onPressed: onEnableProtection,
          icon: const Icon(Icons.shield_rounded),
          label: const Text('Turn on protection'),
        ),
      );
    }

    // 2. Hard schedule: no breaks allowed.
    if (unblock.hardWindow) {
      return _Shell(
        icon: Icons.lock_clock_rounded,
        color: scheme.primary,
        title: 'Locked until ${AppConstants.hardBlockEndHour}:00 AM',
        body: 'No Reels or Shorts between ${AppConstants.hardBlockStartHour + 12}am and '
            '${AppConstants.hardBlockEndHour}am — and no breaks during that time.',
        // Show the budget for later, but no action.
      );
    }

    // 3. A break is running.
    if (unblock.active) {
      return _Shell(
        icon: Icons.hourglass_bottom_rounded,
        color: scheme.tertiary,
        title: 'Break in progress',
        body: '${formatDuration(unblock.remainingMs)} left today. '
            'A pinned reminder stays in your notifications.',
        progress: unblock.usedFraction,
        progressColor: scheme.tertiary,
        action: OutlinedButton.icon(
          onPressed: onStopBreak,
          icon: const Icon(Icons.block_rounded),
          label: const Text('Block now'),
        ),
      );
    }

    // 4. Out of budget for the day.
    if (unblock.remainingMs <= 0) {
      return _Shell(
        icon: Icons.hourglass_disabled_rounded,
        color: scheme.outline,
        title: "Today's break time is used up",
        body: 'Blocking is back on. The budget resets at midnight.',
        progress: 1,
        progressColor: scheme.outline,
      );
    }

    // 5. Budget available.
    return _Shell(
      icon: Icons.coffee_rounded,
      color: scheme.tertiary,
      title: '${formatDuration(unblock.remainingMs)} of break time left today',
      body: 'You can pause blocking for a while, but you\'ll have to type a sentence '
          'first — and it counts against today.',
      progress: unblock.usedFraction,
      progressColor: scheme.tertiary,
      action: FilledButton.tonalIcon(
        onPressed: onStartBreak,
        icon: const Icon(Icons.timer_outlined),
        label: const Text('Take a break'),
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.action,
    this.progress,
    this.progressColor,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final Widget? action;
  final double? progress;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(progressColor ?? color),
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: action),
            ],
          ],
        ),
      ),
    );
  }
}
