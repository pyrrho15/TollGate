import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/privacy_note.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/block_target.dart';
import 'home_controller.dart';
import 'widgets/break_card.dart';
import 'widgets/commitment_dialog.dart';
import 'widgets/notification_card.dart';
import 'widgets/permission_card.dart';
import 'widgets/status_banner.dart';
import 'widgets/target_tile.dart';

/// The "Block" tab: the status summary and the controls that turn blocking
/// on or off. Explanatory content lives on the how-it-works page instead.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Switching to Android Settings to grant permission and coming back should
    // immediately reflect the real state.
    if (state == AppLifecycleState.resumed) {
      context.read<HomeController>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();

    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error != null && controller.state == null) {
      return _ErrorView(
        message: controller.error!,
        onRetry: controller.refresh,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: _content(context, controller),
    );
  }

  Widget _content(BuildContext context, HomeController controller) {
    final state = controller.state!;
    final hasPermission = state.accessibilityEnabled;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gutter,
        8,
        AppTheme.gutter,
        40,
      ),
      children: [
        StatusBanner(state: state),
        if (!hasPermission) ...[
          const SizedBox(height: AppTheme.gutter),
          PermissionCard(onOpenSettings: controller.openAccessibilitySettings),
        ],
        if (hasPermission) ...[
          const SizedBox(height: AppTheme.gutter),
          BreakCard(
            state: state,
            onEnableProtection: controller.enableProtection,
            onStartBreak: () => _startBreak(context, controller),
            onStopBreak: controller.reblockNow,
          ),
          if (state.masterEnabled && !state.notificationsEnabled) ...[
            const SizedBox(height: 12),
            NotificationCard(onOpenSettings: controller.openNotificationSettings),
          ],
        ],
        const SizedBox(height: 28),
        const SectionHeader(
          title: 'Blocked feeds',
          subtitle: 'Choose which short-form feeds to block.',
        ),
        ...state.targets.map(
          (target) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TargetTile(
              target: target,
              // Feeds can only be changed once the engine can actually run.
              enabled: hasPermission && state.masterEnabled,
              onChanged: (value) => _toggleTarget(context, controller, target, value),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const PrivacyNote(),
      ],
    );
  }

  /// Turning a feed off is a commitment decision; turning it on is free.
  Future<void> _toggleTarget(
    BuildContext context,
    HomeController controller,
    BlockTarget target,
    bool value,
  ) async {
    if (value) {
      final error = await controller.setTargetEnabled(target.id, true);
      if (error != null && context.mounted) _snack(context, error);
      return;
    }

    await showCommitmentDialog(
      context,
      title: 'Stop blocking ${target.name}?',
      description: 'This turns off blocking for this feed. Type the sentence to confirm.',
      actionLabel: 'Stop blocking',
      onSubmit: (phrase) => controller.setTargetEnabled(
        target.id,
        false,
        phrase: phrase,
      ),
    );
  }

  Future<void> _startBreak(BuildContext context, HomeController controller) async {
    await showCommitmentDialog(
      context,
      title: 'Start a break?',
      description: 'Reels and Shorts will be allowed until you re-block or run out of '
          "today's break time.",
      actionLabel: 'Start break',
      onSubmit: controller.requestUnblock,
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
