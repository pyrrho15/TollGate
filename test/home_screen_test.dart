import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tollgate/app.dart';
import 'package:tollgate/core/constants.dart';
import 'package:tollgate/data/models/app_stats.dart';
import 'package:tollgate/data/models/block_target.dart';
import 'package:tollgate/data/models/blocker_state.dart';
import 'package:tollgate/data/models/unblock_info.dart';
import 'package:tollgate/data/services/blocker_platform_service.dart';
import 'package:tollgate/features/home/home_controller.dart';
import 'package:tollgate/features/stats/stats_controller.dart';
import 'package:tollgate/features/stats/widgets/weekly_bars.dart';

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
      unblock: _state.unblock,
    );
    return _state;
  }

  @override
  Future<BlockerState> setTargetEnabled(String id, bool enabled,
      {String? phrase}) async {
    _state = BlockerState(
      accessibilityEnabled: _state.accessibilityEnabled,
      masterEnabled: _state.masterEnabled,
      targets: _state.targets
          .map((t) => t.id == id ? t.copyWith(enabled: enabled) : t)
          .toList(growable: false),
      unblock: _state.unblock,
    );
    return _state;
  }

  @override
  Future<BlockerState> requestUnblock(String phrase) async => _state;

  @override
  Future<BlockerState> reblockNow() async => _state;

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

BlockTarget _facebook({bool enabled = false}) => BlockTarget(
      id: 'facebook_reels',
      name: 'Facebook Reels',
      packageName: 'com.facebook.katana',
      description:
          'Blocks the full-screen Reels player. Feed, Groups, Marketplace and '
          'Messenger keep working.',
      enabled: enabled,
    );

BlockTarget _tiktok({bool enabled = false}) => BlockTarget(
      id: 'tiktok',
      name: 'TikTok',
      packageName: 'com.zhiliaoapp.musically',
      description:
          'TikTok is short video start to finish, so opening it sends you '
          'straight back out.',
      enabled: enabled,
    );

List<BlockTarget> _allTargets({bool enabled = false}) => [
      _youtube(enabled: enabled),
      _instagram(enabled: enabled),
      _facebook(enabled: enabled),
      _tiktok(enabled: enabled),
    ];

class _Case {
  const _Case(this.state, this.expectText);

  final BlockerState state;

  /// A string the Block page shows for this state, used to prove the state
  /// rendered (the Block page no longer has a status heading).
  final String expectText;
}

final _cases = <String, _Case>{
  'not set up': _Case(
    BlockerState(
      accessibilityEnabled: false,
      masterEnabled: false,
      targets: _allTargets(),
    ),
    'Turn on the permission',
  ),
  'protecting': _Case(
    BlockerState(
      accessibilityEnabled: true,
      masterEnabled: true,
      targets: _allTargets(enabled: true),
    ),
    'Take a break',
  ),
  'paused': _Case(
    BlockerState(
      accessibilityEnabled: true,
      masterEnabled: false,
      targets: _allTargets(enabled: true),
    ),
    'Turn protection on',
  ),
  'no feeds selected': _Case(
    BlockerState(
      accessibilityEnabled: true,
      masterEnabled: true,
      targets: _allTargets(),
    ),
    'Take a break',
  ),
  'on a break': _Case(
    BlockerState(
      accessibilityEnabled: true,
      masterEnabled: true,
      targets: _allTargets(enabled: true),
      unblock: _breakActive,
    ),
    'Break in progress',
  ),
  'hard locked': _Case(
    BlockerState(
      accessibilityEnabled: true,
      masterEnabled: true,
      targets: _allTargets(enabled: true),
      unblock: _hardLocked,
    ),
    'Locked until 10:00 AM',
  ),
  'notifications off': _Case(
    BlockerState(
      accessibilityEnabled: true,
      masterEnabled: true,
      targets: _allTargets(enabled: true),
      notificationsEnabled: false,
    ),
    'Notifications are turned off',
  ),
};

final _baseDay = DateTime(2026, 10, 14);

String _isoDate(int daysAgo) {
  final d = _baseDay.subtract(Duration(days: daysAgo));
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

String _weekdayName(int daysAgo) =>
    DayStat(date: _isoDate(daysAgo), timeMs: 0, blocks: 0).weekdayName;

const _breakActive = UnblockInfo(
  budgetMs: 90 * 60 * 1000,
  usedMs: 48 * 60 * 1000,
  remainingMs: 42 * 60 * 1000,
  sessions: 1,
  active: true,
  hardWindow: false,
  activeSince: 0,
);

const _hardLocked = UnblockInfo(
  budgetMs: 90 * 60 * 1000,
  usedMs: 0,
  remainingMs: 90 * 60 * 1000,
  sessions: 0,
  active: false,
  hardWindow: true,
  activeSince: 0,
);

/// That day's per-app split, in the same shape the native snapshot returns.
List<TargetStat> _dayTargets(int daysAgo) => [
      TargetStat(
        id: 'youtube_shorts',
        name: 'YouTube Shorts',
        timeMs: (60 - daysAgo * 5) * 60 * 1000,
        blocks: 25,
        opens: 9,
      ),
      const TargetStat(
        id: 'instagram_reels',
        name: 'Instagram Reels',
        timeMs: 18 * 60 * 1000,
        blocks: 7,
        opens: 4,
      ),
      const TargetStat(
        id: 'facebook_reels',
        name: 'Facebook Reels',
        timeMs: 12 * 60 * 1000,
        blocks: 3,
        opens: 2,
      ),
      const TargetStat(
        id: 'tiktok',
        name: 'TikTok',
        timeMs: 20 * 60 * 1000,
        blocks: 5,
        opens: 3,
      ),
    ];

AppStats _sampleStats() => AppStats(
      today: _isoDate(0),
      targets: _dayTargets(0),
      history: [
        for (var i = 6; i >= 0; i--)
          DayStat(
            date: _isoDate(i),
            timeMs: _dayTargets(i).fold(0, (sum, t) => sum + t.timeMs),
            blocks: i,
            targets: _dayTargets(i),
          ),
      ],
      unblock: _breakActive,
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
      expect(find.text(entry.value.expectText), findsOneWidget);

      // Lower items sit below the fold on a small screen; scroll like a user
      // would and make sure everything renders without overflow.
      await tester.scrollUntilVisible(
        find.text('Blocked feeds'),
        200,
        scrollable: scrollable,
      );
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('TikTok'),
        200,
        scrollable: scrollable,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('TikTok'), findsOneWidget);
      expect(find.text('Facebook Reels'), findsOneWidget);
    });
  }

  testWidgets('starting a break requires the commitment phrase', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, _cases['protecting']!.state);

    // The break card offers a break, and shows the budget for the day.
    expect(find.text('Take a break'), findsOneWidget);

    await tester.tap(find.text('Take a break'));
    await tester.pumpAndSettle();

    // The gate shows the exact sentence to retype.
    expect(find.text(AppConstants.commitmentPhrase), findsOneWidget);
    expect(find.text('Start break'), findsOneWidget);

    // Submitting closes the dialog (the fake accepts the phrase).
    await tester.tap(find.text('Start break'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Start break'), findsNothing);
  });

  testWidgets('warns when notifications are disabled', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, _cases['notifications off']!.state);

    expect(find.text('Notifications are turned off'), findsOneWidget);
    expect(find.text('Turn on notifications'), findsOneWidget);
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

  testWidgets('stats page shows today, then a picked day', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, _cases['protecting']!.state);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The consistency graph is gone and today's two numbers share one grid.
    expect(find.text('Screen time'), findsOneWidget);
    expect(find.text('Breaks today'), findsOneWidget);
    expect(find.text('Last 7 days'), findsOneWidget);
    // Default view is today.
    expect(find.text('Today by app'), findsOneWidget);

    // Pick the oldest bar; the donut below should switch to that day.
    final bars =
        find.descendant(of: find.byType(WeeklyBars), matching: find.byType(InkWell));
    await tester.tap(bars.first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('${_weekdayName(6)} by app'), findsOneWidget);
    expect(find.text('Today by app'), findsNothing);

    // The per-app legend still lists every monitored app.
    await tester.scrollUntilVisible(
      find.text('TikTok'),
      200,
      scrollable: scrollable,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('TikTok'), findsOneWidget);
    expect(find.text('YouTube Shorts'), findsOneWidget);
  });
}
