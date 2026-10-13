import 'package:flutter/material.dart';

/// Shown only when protection is armed but Android is blocking our notifications.
/// Without this, the pinned "you're unblocked" reminder would never appear.
class NotificationCard extends StatelessWidget {
  const NotificationCard({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_off_rounded,
                    color: scheme.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Notifications are turned off',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Android won't show the pinned break reminder unless you allow "
              'notifications. Turn them on so the reminder (and the time left) '
              'is always visible.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.notifications_active_rounded, size: 20),
                label: const Text('Turn on notifications'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
