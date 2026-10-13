import 'package:flutter/foundation.dart';

import '../../data/models/app_stats.dart';
import '../../data/services/blocker_platform_service.dart';

/// Loads the on-device stats and exposes them to the Stats screen. Mirrors the
/// HomeController shape: a tiny, testable wrapper around the platform service.
class StatsController extends ChangeNotifier {
  StatsController(this._service);

  final BlockerPlatformService _service;

  AppStats? _stats;
  AppStats? get stats => _stats;

  String? _error;
  String? get error => _error;

  /// Starts true: the screen kicks off the first [refresh] as soon as it opens.
  bool _loading = true;
  bool get isLoading => _loading && _stats == null;
  bool get hasData => _stats != null;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      _stats = await _service.getStats();
      _error = null;
    } catch (e) {
      _error = 'Could not load stats.\n$e';
    }
    _loading = false;
    notifyListeners();
  }
}
