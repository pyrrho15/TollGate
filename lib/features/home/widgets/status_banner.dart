import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/blocker_state.dart';

/// The headline of the home screen: an always-accurate summary of whether
/// blocking is really happening right now.
class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.state});

  final BlockerState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final anyTargetOn = state.targets.any((t) => t.enabled);

    final (IconData icon, Color color, String title, String subtitle,
        String pill) = switch (state) {
      _ when !state.accessibilityEnabled => (
          Icons.report_gmailerrorred_rounded,
          scheme.error,
          'Not set up yet',
          'Grant the accessibility permission to start protecting you.',
          'OFF',
        ),
      _ when !state.masterEnabled => (
          Icons.pause_circle_rounded,
          scheme.outline,
          'Paused',
          'Permission granted, but protection has not been turned on.',
          'OFF',
        ),
      _ when state.unblock.active => (
          Icons.hourglass_bottom_rounded,
          scheme.tertiary,
          'On a break',
          'Reels and Shorts are allowed. Re-block whenever you are ready.',
          'BREAK',
        ),
      _ when state.unblock.hardWindow => (
          Icons.lock_clock_rounded,
          scheme.primary,
          'Locked until 10am',
          'No Reels or Shorts — and no breaks — between 12am and 10am.',
          'LOCKED',
        ),
      _ when !anyTargetOn => (
          Icons.tune_rounded,
          scheme.tertiary,
          'Nothing selected',
          'Turn on at least one feed below to start blocking.',
          'IDLE',
        ),
      _ => (
          Icons.verified_user_rounded,
          scheme.primary,
          'Protecting',
          'Opening Reels or Shorts will bounce you straight back.',
          'ON',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              pill,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
