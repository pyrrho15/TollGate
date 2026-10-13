import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

  /// Protection is a one-way switch in the UI: turning it *on* arms blocking. The only
  /// way to pause it is a budgeted break ([requestUnblock]).
  Future<void> enableProtection() =>
      _apply(() => _service.setMasterEnabled(true), prefix: 'Could not turn on protection.');

  /// Returns null on success, or a human-readable reason the change was refused.
  Future<String?> setTargetEnabled(String id, bool enabled, {String? phrase}) async {
    try {
      _state = await _service.setTargetEnabled(id, enabled, phrase: phrase);
      _error = null;
      notifyListeners();
      return null;
    } catch (e) {
      return _reason(e, prefix: 'Could not change that feed.');
    }
  }

  /// Returns null on success, or a human-readable reason the break was refused.
  Future<String?> requestUnblock(String phrase) async {
    try {
      _state = await _service.requestUnblock(phrase);
      _error = null;
      notifyListeners();
      return null;
    } catch (e) {
      return _reason(e, prefix: 'Could not start a break.');
    }
  }

  Future<void> reblockNow() =>
      _apply(() => _service.reblockNow(), prefix: 'Could not re-block.');

  Future<void> _apply(
    Future<BlockerState> Function() action, {
    required String prefix,
  }) async {
    try {
      _state = await action();
      _error = null;
    } catch (e) {
      _error = _reason(e, prefix: prefix);
    }
    notifyListeners();
  }

  /// Maps the native error codes to copy a non-technical user can act on.
  String _reason(Object e, {required String prefix}) {
    if (e is PlatformException) {
      return switch (e.code) {
        'phrase_mismatch' => 'That doesn\'t match the sentence exactly.',
        'hard_window' =>
          'No breaks between 12am and 10am. Blocking is locked until 10am.',
        'budget_exhausted' => "Today's break time is used up. It resets at midnight.",
        'unavailable' => 'A break is not possible right now.',
        _ => '$prefix ${e.message ?? ''}'.trim(),
      };
    }
    return prefix;
  }

  Future<void> openAccessibilitySettings() => _service.openAccessibilitySettings();

  Future<void> openNotificationSettings() => _service.openNotificationSettings();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
