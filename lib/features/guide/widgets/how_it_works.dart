import 'package:flutter/material.dart';

/// A short, plain-language explanation of what the app does under the hood.
/// Kept on the how-it-works page on purpose: the whole point of TollGate is
/// that it is understandable and trustworthy.
class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final items = <(IconData, String, String)>[
      (
        Icons.search_rounded,
        'It watches the layout',
        'Text is matched by structure, not language — so it works in any locale '
            'and after most app updates.',
      ),
      (
        Icons.keyboard_return_rounded,
        'It presses Back',
        'When a Short or Reel opens, the app sends you back to where you were. '
            'No overlay, no interruption.',
      ),
      (
        Icons.lock_outline_rounded,
        'It stays on your phone',
        'TollGate has no internet permission, so nothing can leave your device. '
            'There are no accounts and no tracking.',
      ),
    ];

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      items[i].$1,
                      size: 20,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].$2,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].$3,
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
            ),
            if (i != items.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}
