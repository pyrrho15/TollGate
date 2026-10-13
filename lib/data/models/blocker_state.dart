import 'block_target.dart';
import 'unblock_info.dart';

/// Snapshot of everything the UI needs to render, as reported by native.
class BlockerState {
  const BlockerState({
    required this.accessibilityEnabled,
    required this.masterEnabled,
    required this.targets,
    this.unblock = UnblockInfo.empty,
    this.notificationsEnabled = true,
  });

  /// Whether the user has actually granted the Android accessibility permission.
  final bool accessibilityEnabled;

  /// The user's intent to block.
  final bool masterEnabled;

  final List<BlockTarget> targets;

  /// Today's break budget / hard-schedule state.
  final UnblockInfo unblock;

  /// Whether notifications are allowed; the pinned break reminder needs this.
  final bool notificationsEnabled;

  /// Blocking is only truly happening when the permission is granted and the user asked for it.
  bool get isProtecting => accessibilityEnabled && masterEnabled;

  /// Blocking is actively bouncing feeds right now (not on a break).
  bool get isProtectingNow => isProtecting && !unblock.active;

  factory BlockerState.fromMap(Map<dynamic, dynamic> map) => BlockerState(
        accessibilityEnabled: map['accessibilityEnabled'] as bool,
        masterEnabled: map['masterEnabled'] as bool,
        targets: (map['targets'] as List)
            .map((e) => BlockTarget.fromMap(e as Map))
            .toList(growable: false),
        unblock: map['unblock'] == null
            ? UnblockInfo.empty
            : UnblockInfo.fromMap(map['unblock'] as Map),
        notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      );
}
