import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/blocker_state.dart';
import '../../data/services/blocker_platform_service.dart';

/// Owns the UI state and talks to native. The screen stays dumb; this class is the
/// single place that mutates blocker state.
class HomeController extends ChangeNotifier {
  HomeController(this._service);

  final BlockerPlatformService _service;
  StreamSubscription<BlockerState>? _subscription;

  BlockerState? _state;
  BlockerState? get state => _state;

  String? _error;
  String? get error => _error;

  bool get isLoading => _state == null && _error == null;

  Future<void> init() async {
    await _load();
    // Native pushes on permission changes and service (dis/re)connect. Failures here
    // are not fatal: the screen can still be refreshed manually.
    _subscription = _service.stateStream.listen(
      (next) {
        _state = next;
        _error = null;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      _state = await _service.getState();
      _error = null;
    } catch (e) {
      _error = 'Could not reach the blocker engine.\n$e';
    }
    notifyListeners();
  }

  Future<void> setMasterEnabled(bool enabled) =>
      _apply(() => _service.setMasterEnabled(enabled));

  Future<void> setTargetEnabled(String id, bool enabled) =>
      _apply(() => _service.setTargetEnabled(id, enabled));

  Future<void> _apply(Future<BlockerState> Function() action) async {
    try {
      _state = await action();
      _error = null;
    } catch (e) {
      _error = 'Could not save the setting.\n$e';
    }
    notifyListeners();
  }

  Future<void> openAccessibilitySettings() => _service.openAccessibilitySettings();

  Future<void> openNotificationSettings() => _service.openNotificationSettings();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
