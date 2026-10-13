import 'package:flutter/material.dart';

import '../../../core/widgets/target_look.dart';
import '../../../data/models/block_target.dart';

/// A single feed the user can block. Shows a branded icon so the target is
/// recognisable at a glance, and dims when blocking can't actually run.
class TargetTile extends StatelessWidget {
  const TargetTile({
    super.key,
    required this.target,
    required this.enabled,
    required this.onChanged,
  });

  final BlockTarget target;

  /// Whether the switch can be interacted with (i.e. permission is granted).
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final look = targetLookFor(target.id, scheme);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: look.color.withValues(alpha: enabled ? 0.14 : 0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                look.icon,
                color: enabled ? look.color : scheme.outline,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: enabled ? scheme.onSurface : scheme.outline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    target.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Switch(
              value: target.enabled,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}
