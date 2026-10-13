import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tollgate/app.dart';
import 'package:tollgate/core/constants.dart';
import 'package:tollgate/data/models/app_stats.dart';
import 'package:tollgate/data/models/block_target.dart';
import 'package:tollgate/data/models/blocker_state.dart';
import 'package:tollgate/data/services/blocker_platform_service.dart';
import 'package:tollgate/features/home/home_controller.dart';
import 'package:tollgate/features/stats/stats_controller.dart';

/// In-memory stand-in for the platform channel service so the UI can be
/// exercised without an Android device.
class _FakeBlockerService extends BlockerPlatformService {
  _FakeBlockerService(this._state, this._stats);

  BlockerState _state;
  final AppStats _stats;

  @override
  Future<BlockerState> getState() async => _state;

  @override
  Future<BlockerState> setMasterEnabled(bool enabled) async {
    _state = BlockerState(
      accessibilityEnabled: _state.accessibilityEnabled,
      masterEnabled: enabled,
      targets: _state.targets,
    );
    return _state;
  }

  @override
  Future<BlockerState> setTargetEnabled(String id, bool enabled) async {
    _state = BlockerState(
      accessibilityEnabled: _state.accessibilityEnabled,
      masterEnabled: _state.masterEnabled,
      targets: _state.targets
          .map((t) => t.id == id ? t.copyWith(enabled: enabled) : t)
          .toList(growable: false),
    );
    return _state;
  }

  @override
  Future<void> openAccessibilitySettings() async {}

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<AppStats> getStats() async => _stats;

  @override
  Stream<BlockerState> get stateStream => const Stream.empty();
}

BlockTarget _youtube({bool enabled = false}) => BlockTarget(
      id: 'youtube_shorts',
      name: 'YouTube Shorts',
      packageName: 'com.google.android.youtube',
      description:
          'Blocks the immersive Shorts player. Normal videos, search and '
          'subscriptions keep working.',
      enabled: enabled,
    );

BlockTarget _instagram({bool enabled = false}) => BlockTarget(
      id: 'instagram_reels',
      name: 'Instagram Reels',
      packageName: 'com.instagram.android',
      description:
          'Blocks the Reels tab and the full-screen Reels viewer. DMs, feed '
          'and stories keep working.',
      enabled: enabled,
    );

class _Case {
  const _Case(this.state, this.statusTitle);
  final BlockerState state;
  final String statusTitle;
}

final _cases = <String, _Case>{
  'not set up': _Case(
    BlockerState(
      accessibilityEnabled: false,
      masterEnabled: false,
      targets: [_youtube(), _instagram()],
    ),
    'Not set up yet',
  ),
  'protecting': _Case(
    BlockerState(
      accessibilityEnabled: true,
      masterEnabled: true,
      targets: [_youtube(enabled: true), _instagram(enabled: true)],
    ),
    'Protecting',
  ),
  'paused': _Case(
    BlockerState(
      accessibilityEnabled: true,
      masterEnabled: false,
      targets: [_youtube(enabled: true), _instagram(enabled: true)],
    ),
    'Paused',
  ),
  'no feeds selected': _Case(
    BlockerState(
      accessibilityEnabled: true,
      masterEnabled: true,
      targets: [_youtube(), _instagram()],
    ),
    'Nothing selected',
  ),
};

final _baseDay = DateTime(2026, 10, 14);

String _isoDate(int daysAgo) {
  final d = _baseDay.subtract(Duration(days: daysAgo));
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

AppStats _sampleStats() => AppStats(
      today: _isoDate(0),
      targets: const [
        TargetStat(
          id: 'youtube_shorts',
          name: 'YouTube Shorts',
          timeMs: 72 * 60 * 1000,
          blocks: 25,
          opens: 9,
        ),
        TargetStat(
          id: 'instagram_reels',
          name: 'Instagram Reels',
          timeMs: 18 * 60 * 1000,
          blocks: 7,
          opens: 4,
        ),
      ],
      history: [
        for (var i = 6; i >= 0; i--)
          DayStat(
            date: _isoDate(i),
            timeMs: i * 5 * 60 * 1000,
            blocks: i,
          ),
      ],
    );

Future<void> _pump(WidgetTester tester, BlockerState state) async {
  final service = _FakeBlockerService(state, _sampleStats());
  final home = HomeController(service);
  await home.init();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeController>.value(value: home),
        ChangeNotifierProvider<StatsController>.value(
          value: StatsController(service),
        ),
      ],
      child: const TollGateApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final scrollable = find.byType(Scrollable).first;

  for (final entry in _cases.entries) {
    testWidgets('home renders "${entry.key}" without overflow', (tester) async {
      // A narrow-ish phone viewport stresses text wrapping.
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pump(tester, entry.value.state);

      expect(tester.takeException(), isNull);
      expect(find.text('TollGate'), findsOneWidget);
      expect(find.text(entry.value.statusTitle), findsOneWidget);

      // Lower items sit below the fold on a small screen; scroll like a user
      // would and make sure everything renders without overflow.
      await tester.scrollUntilVisible(
        find.text('Block Reels & Shorts'),
        200,
        scrollable: scrollable,
      );
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Instagram Reels'),
        200,
        scrollable: scrollable,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('YouTube Shorts'), findsOneWidget);
      expect(find.text('Instagram Reels'), findsOneWidget);
    });
  }

  testWidgets('toggling the master switch updates the UI', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, _cases['protecting']!.state);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Paused'), findsOneWidget);
  });

  testWidgets('bottom nav opens the how-it-works page', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, _cases['protecting']!.state);

    await tester.tap(find.text('How it works'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('In three steps'), findsOneWidget);

    // The rest of the page is below the fold; scroll to it.
    await tester.scrollUntilVisible(find.text('What TollGate can\'t see'), 250);
    expect(tester.takeException(), isNull);
    expect(find.text('What TollGate can\'t see'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Version ${AppConstants.appVersion}'),
      250,
    );
    expect(find.text('Version ${AppConstants.appVersion}'), findsOneWidget);
  });

  testWidgets('bottom nav opens the stats page', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, _cases['protecting']!.state);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('YouTube Shorts'), findsOneWidget);
    expect(find.text('Instagram Reels'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Last 7 days'), 250);
    expect(tester.takeException(), isNull);
    expect(find.text('Last 7 days'), findsOneWidget);
  });
}
