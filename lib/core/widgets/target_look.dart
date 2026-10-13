import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Brand icon + color for a supported feed, so the same app looks consistent
/// everywhere it appears (home tiles, stats tiles, …).
class TargetLook {
  const TargetLook(this.icon, this.color);

  final IconData icon;
  final Color color;
}

TargetLook targetLookFor(String id, ColorScheme scheme) => switch (id) {
      'youtube_shorts' => const TargetLook(
          Icons.smart_display_rounded,
          AppTheme.youtube,
        ),
      'instagram_reels' => const TargetLook(
          Icons.slow_motion_video_rounded,
          AppTheme.instagram,
        ),
      _ => TargetLook(Icons.videocam_rounded, scheme.primary),
    };
