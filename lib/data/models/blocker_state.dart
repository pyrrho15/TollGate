import 'block_target.dart';

/// Snapshot of everything the UI needs to render, as reported by native.
class BlockerState {
  const BlockerState({
    required this.accessibilityEnabled,
    required this.masterEnabled,
    required this.targets,
  });

  /// Whether the user has actually granted the Android accessibility permission.
  final bool accessibilityEnabled;

  /// The user's intent to block.
  final bool masterEnabled;

  final List<BlockTarget> targets;

  /// Blocking is only truly happening when the permission is granted and the user asked for it.
  bool get isProtecting => accessibilityEnabled && masterEnabled;

  factory BlockerState.fromMap(Map<dynamic, dynamic> map) => BlockerState(
        accessibilityEnabled: map['accessibilityEnabled'] as bool,
        masterEnabled: map['masterEnabled'] as bool,
        targets: (map['targets'] as List)
            .map((e) => BlockTarget.fromMap(e as Map))
            .toList(growable: false),
      );
}
