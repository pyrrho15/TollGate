import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/format.dart';
import '../../../core/widgets/target_look.dart';
import '../../../data/models/app_stats.dart';

/// A dependency-free donut showing where today's screen time went: one arc per
/// monitored app, with the total in the middle and a legend underneath.
///
/// Drawn with a plain [CustomPainter] so the app stays free of chart packages.
class ScreenTimeDonut extends StatelessWidget {
  const ScreenTimeDonut({
    super.key,
    required this.targets,
    required this.dayLabel,
  });

  final List<TargetStat> targets;

  /// Short label for the day being shown, e.g. `today` or `Wed`.
  final String dayLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final total = targets.fold<int>(0, (sum, t) => sum + t.timeMs);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          children: [
            SizedBox(
              width: 168,
              height: 168,
              child: CustomPaint(
                painter: _DonutPainter(
                  slices: [
                    for (final t in targets)
                      if (t.timeMs > 0)
                        (
                          targetLookFor(t.id, scheme).color,
                          total == 0 ? 0.0 : t.timeMs / total,
                        ),
                  ],
                  strokeWidth: 22,
                  trackColor: scheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatDuration(total),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dayLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            for (final t in targets) _LegendRow(stat: t, total: total),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.stat, required this.total});

  final TargetStat stat;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final look = targetLookFor(stat.id, scheme);
    final share = total == 0 ? 0 : (stat.timeMs / total * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: look.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$share% · ${stat.blocks} blocked',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatDuration(stat.timeMs),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.strokeWidth,
    required this.trackColor,
  });

  /// (color, fraction of the whole) per arc.
  final List<(Color, double)> slices;
  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    if (radius <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    var start = -math.pi / 2;
    for (final (color, fraction) in slices) {
      var sweep = fraction * 2 * math.pi;
      if (sweep <= 0) continue;
      // Leave a hairline gap between arcs so neighbouring apps stay distinct.
      if (slices.length > 1) sweep = math.max(0, sweep - 0.05);
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt
          ..color = color,
      );
      start += fraction * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.slices != slices ||
      old.strokeWidth != strokeWidth ||
      old.trackColor != trackColor;
}
