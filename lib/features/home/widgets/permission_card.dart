import 'package:flutter/material.dart';

/// Explains, plainly, why the accessibility permission is needed and walks the
/// user through granting it — including the "Allow restricted settings" step
/// Android 13+ hides behind the overflow menu for sideloaded apps.
class PermissionCard extends StatelessWidget {
  const PermissionCard({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.key_rounded, color: scheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Turn on the permission',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Android only lets an app read another app\'s screen through the '
              'accessibility service. TollGate uses it to spot Shorts or Reels '
              'the moment they open and press Back for you — nothing else.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const _Step(
              index: 1,
              text: 'Tap the button below to open Accessibility settings.',
            ),
            const _Step(
              index: 2,
              text: 'Find “TollGate Short Block” in the list.',
            ),
            const _Step(
              index: 3,
              text:
                  'If the toggle is greyed out, first tap the ⋮ menu and choose '
                  '“Allow restricted settings”.',
            ),
            const _Step(
              index: 4,
              text: 'Turn the toggle on. This screen updates by itself.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_rounded, size: 20),
                label: const Text('Open accessibility settings'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Scoped to YouTube and Instagram only.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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

/// A single numbered instruction line.
class _Step extends StatelessWidget {
  const _Step({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
