import 'package:flutter/services.dart';

import '../models/app_stats.dart';
import '../models/blocker_state.dart';

/// Thin wrapper over the platform channels. This is the only place in the Dart code
/// that knows about channels or method names.
class BlockerPlatformService {
  const BlockerPlatformService();

  static const MethodChannel _methods =
      MethodChannel('com.tollgate.app/blocker');
  static const EventChannel _events =
      EventChannel('com.tollgate.app/blocker_events');

  Future<BlockerState> getState() async {
    final map = await _methods.invokeMethod<Map<dynamic, dynamic>>('getState');
    return BlockerState.fromMap(map!);
  }

  Future<BlockerState> setMasterEnabled(bool enabled) async {
    final map = await _methods
        .invokeMethod<Map<dynamic, dynamic>>('setMasterEnabled', enabled);
    return BlockerState.fromMap(map!);
  }

  Future<BlockerState> setTargetEnabled(String id, bool enabled) async {
    final map = await _methods.invokeMethod<Map<dynamic, dynamic>>(
      'setTargetEnabled',
      <String, dynamic>{'id': id, 'enabled': enabled},
    );
    return BlockerState.fromMap(map!);
  }

  Future<void> openAccessibilitySettings() =>
      _methods.invokeMethod<void>('openAccessibilitySettings');

  Future<void> openNotificationSettings() =>
      _methods.invokeMethod<void>('openNotificationSettings');

  /// On-device usage/blocking stats. Never leaves the phone.
  Future<AppStats> getStats() async {
    final map = await _methods.invokeMethod<Map<dynamic, dynamic>>('getStats');
    return AppStats.fromMap(map!);
  }

  /// Pushed by native whenever the permission or settings change.
  Stream<BlockerState> get stateStream => _events
      .receiveBroadcastStream()
      .map((event) => BlockerState.fromMap(event as Map));
}
