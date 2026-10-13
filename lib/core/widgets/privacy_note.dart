import 'package:flutter/material.dart';

/// A repeat of the privacy guarantee, kept visible in the UI rather than
/// buried in a settings screen.
class PrivacyNote extends StatelessWidget {
  const PrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.verified_user_outlined,
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'TollGate has no internet permission, so it cannot send data '
            'anywhere. Detection runs entirely on your phone and only looks at '
            'the screen structure of the apps you enable.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
