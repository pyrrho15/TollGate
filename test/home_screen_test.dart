import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tollgate/app.dart';
import 'package:tollgate/data/models/block_target.dart';
import 'package:tollgate/data/models/blocker_state.dart';
import 'package:tollgate/data/services/blocker_platform_service.dart';
import 'package:tollgate/features/home/home_controller.dart';

/// In-memory stand-in for the platform channel service so the UI can be
/// exercised without an Android device.
class _FakeBlockerService extends BlockerPlatformService {
  _FakeBlockerService(this._state);

  BlockerState _state;

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

Future<void> _pump(WidgetTester tester, BlockerState state) async {
  final controller = HomeController(_FakeBlockerService(state));
  await controller.init();
  await tester.pumpWidget(
    ChangeNotifierProvider<HomeController>.value(
      value: controller,
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

    await tester.scrollUntilVisible(find.text('Version 1.1.0'), 250);
    expect(find.text('Version 1.1.0'), findsOneWidget);
  });
}
