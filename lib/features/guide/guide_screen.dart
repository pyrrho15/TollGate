import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/privacy_note.dart';
import '../../core/widgets/section_header.dart';
import 'widgets/how_it_works.dart';

/// The "How it works" page: everything that explains what TollGate does, put in
/// one place instead of crowding the controls on the home page.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gutter,
        8,
        AppTheme.gutter,
        40,
      ),
      children: [
        // Intro
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary.withValues(alpha: 0.16),
                scheme.primary.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
          ),
          child: Text(
            'TollGate can\'t work like a normal app: Android sandboxes every app, '
            'so the only sanctioned way to notice a Short or Reel is the same '
            'accessibility layer that powers screen readers. Here\'s exactly '
            'what that means.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 28),

        const SectionHeader(title: 'In three steps'),
        const HowItWorks(),
        const SizedBox(height: 28),

        const SectionHeader(
          title: 'What TollGate can\'t see',
          subtitle: 'The permission is scoped by Android, not by our promise.',
        ),
        const _CantSeeCard(),
        const SizedBox(height: 28),

        const SectionHeader(title: 'Your privacy'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: PrivacyNote(),
        ),
        const SizedBox(height: 28),

        const SectionHeader(title: 'About'),
        _AboutCard(tagline: AppConstants.tagline),
      ],
    );
  }
}

class _CantSeeCard extends StatelessWidget {
  const _CantSeeCard();

  static const _items = <String>[
    'Your messages, email and calls',
    'Banking and payment apps',
    'Passwords and your keyboard',
    'Anything outside the apps you enable',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_off_outlined,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _items[i],
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            if (i != _items.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.tagline});

  final String tagline;

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
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.shield_rounded,
                      color: scheme.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Version ${AppConstants.appVersion}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              tagline,
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'An Android-only app that silently sends you back when YouTube '
              'Shorts, Instagram Reels, Facebook Reels or TikTok open. No '
              'internet permission, no accounts, no data collection.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
