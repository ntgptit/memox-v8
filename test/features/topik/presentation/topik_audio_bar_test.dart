import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_audio_bar_widget.dart';
import 'package:memox/shared/widgets/mx_slider.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_fakes.dart';
import '../../../support/forui_expect.dart';

const _clip = TopikAudioClip(asset: 'a.mp3', startMs: 0, endMs: 30000);

// The audio bar of screen 37 (detail file 37, BR-TOPIK-017).
void main() {
  Future<FakeTopikAudioRepository> pump(
    WidgetTester tester,
    LibraryEnv env, {
    bool failsLoads = false,
  }) async {
    final player = FakeTopikAudioRepository()..failsLoads = failsLoads;
    await pumpLibraryScreen(
      tester,
      env,
      const Scaffold(body: TopikAudioBarWidget(clip: _clip)),
      overrides: [topikAudioRepositoryProvider.overrideWithValue(player)],
    );
    await tester.pumpAndSettle();
    return player;
  }

  libraryTest('loads its clip and waits: no autoplay', (tester, env) async {
    final player = await pump(tester, env);

    expect(player.calls, ['load 0']);
    expect(byControlLabel('Play'), findsOneWidget);
    expect(find.text('0:00 / 0:30'), findsOneWidget);
  });

  libraryTest('play, then pause; the time follows the player', (
    tester,
    env,
  ) async {
    final player = await pump(tester, env);

    await tester.tap(byControlLabel('Play'));
    await tester.pump();
    expect(byControlLabel('Pause'), findsOneWidget);
    player.emit(player.state.copyWith(positionMs: 12500));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('0:12 / 0:30'), findsOneWidget);
    await tester.tap(byControlLabel('Pause'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(player.calls, ['load 0', 'play', 'pause']);
  });

  libraryTest('the speed sheet sets the speed', (tester, env) async {
    final player = await pump(tester, env);

    await tester.tap(find.text('1×'));
    await tester.pumpAndSettle();
    expect(find.text('Playback speed'), findsOneWidget);
    await tester.tap(find.text('1.5×'));
    await tester.pumpAndSettle();

    expect(player.calls.last, 'speed 1.5');
    expect(find.text('1.5×'), findsOneWidget);
  });

  libraryTest('a clip that fails is a warning; Retry loads it again', (
    tester,
    env,
  ) async {
    final player = await pump(tester, env, failsLoads: true);

    expect(find.text("Couldn't play this audio"), findsOneWidget);
    expect(find.text('Your answers are safe.'), findsOneWidget);
    player.failsLoads = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't play this audio"), findsNothing);
    expect(player.calls, ['load 0', 'load 0']);
  });

  libraryTest('the seek bar says where it is, of how long', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, env);

    final data = tester.getSemantics(find.byType(MxSlider)).getSemanticsData();
    expect(data.label, 'Audio position');
    expect(data.value, '0:00 / 0:30');
    handle.dispose();
  });

  libraryTest('the speed chip reads its purpose and value as one node', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, env);

    expect(find.text('1×'), findsOneWidget);
    expect(find.bySemanticsLabel('Playback speed, 1×'), findsOneWidget);
    handle.dispose();
  });
}
