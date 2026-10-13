import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/privacy_note.dart';
import '../../core/widgets/section_header.dart';
import 'home_controller.dart';
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
        const SizedBox(height: AppTheme.gutter),
        _MasterSwitch(controller: controller),
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
              // Per-target switches only make sense once the engine can run.
              enabled: hasPermission && state.masterEnabled,
              onChanged: (value) =>
                  controller.setTargetEnabled(target.id, value),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const PrivacyNote(),
      ],
    );
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

class _MasterSwitch extends StatelessWidget {
  const _MasterSwitch({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = controller.state!;
    final canToggle = state.accessibilityEnabled;

    return Card(
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        secondary: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: canToggle ? 0.14 : 0.07),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            state.masterEnabled && canToggle
                ? Icons.shield_rounded
                : Icons.shield_outlined,
            color: canToggle ? scheme.primary : scheme.outline,
          ),
        ),
        title: Text(
          'Block Reels & Shorts',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          canToggle
              ? 'Turns blocking on or off for the feeds you selected below.'
              : 'Grant the accessibility permission above to enable this.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        value: state.masterEnabled,
        onChanged: canToggle ? controller.setMasterEnabled : null,
      ),
    );
  }
}
