import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_audio_repository.dart';
import 'package:memox/features/topik/presentation/screens/topik_attempt_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_slider.dart';

import '../../../support/forui_expect.dart';
import '../../../support/library_harness.dart';
import '../../../support/topik_attempt_screen_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';

// The States rows of screen 37 (TOPIK attempt) whose detail file cites no
// executed test: audioLoading and pictureGroup.

final _en = lookupAppLocalizations(const Locale('en'));

/// A picture the app bundles, standing for a content asset.
const _picture = 'assets/brand/google_g.png';

/// A player whose clip never finishes loading.
final class _LoadingAudio implements TopikAudioRepository {
  TopikAudioState _state = TopikAudioState.initial;
  final _states = StreamController<TopikAudioState>.broadcast();
  final calls = <String>[];

  @override
  TopikAudioState get state => _state;

  @override
  Stream<TopikAudioState> watchState() => Stream.multi((listener) {
    listener.add(_state);
    final changes = _states.stream.listen(listener.add);
    listener.onCancel = changes.cancel;
  });

  @override
  Future<void> load(TopikAudioClip clip) {
    calls.add('load ${clip.startMs}');
    _state = TopikAudioState(
      status: TopikAudioStatus.loading,
      clip: clip,
      positionMs: 0,
      speed: _state.speed,
    );
    _states.add(_state);
    return Completer<void>().future;
  }

  @override
  Future<void> play() async => calls.add('play');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> seek(int positionMs) async => calls.add('seek $positionMs');

  @override
  Future<void> setSpeed(double speed) async => calls.add('speed $speed');

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> dispose() async => calls.add('dispose');
}

/// A reading test whose first group's passage and first question's options
/// are pictures.
TopikTest _pictureTest() {
  final json = topikTestJson();
  groupJson(json, 'g1')['passage'] = {'image': _picture};
  questionJson(json, 1)['options'] = [
    for (var idx = 1; idx <= 4; idx++) {'idx': idx, 'image': _picture},
  ];
  return topikTestOfFixtureJson(json);
}

void main() {
  libraryTest('audioLoading: while the clip loads Play is off and the seek bar '
      'has no length', (tester, env) async {
    final listening = topikTestFixture(section: TopikSection.listening);
    final attempt = await topikSeedAttempt(env, listening);
    final player = _LoadingAudio();
    await pumpLibraryScreen(
      tester,
      env,
      TopikAttemptScreen(
        attemptId: attempt.id,
        onClose: () {},
        onSubmitted: (_) {},
      ),
      overrides: [
        ...topikContentOverrides([listening]),
        topikAudioRepositoryProvider.overrideWithValue(player),
      ],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(player.calls, ['load 0']);
    expect(player.state.status, TopikAudioStatus.loading);
    expect(byControlLabel(_en.topikPlay), findsOneWidget);
    expect(
      tester.widget<FButton>(byControlLabel(_en.topikPlay)).onPress,
      isNull,
    );
    expect(byControlLabel(_en.topikPause), findsNothing);
    expect(tester.widget<MxSlider>(find.byType(MxSlider)).max, 0);
    expect(player.calls, isNot(contains('play')));
  });

  libraryTest('pictureGroup: a passage and options that are pictures draw '
      'them and read "Picture" to TalkBack', (tester, env) async {
    final handle = tester.ensureSemantics();
    final test = _pictureTest();
    final attempt = await topikSeedAttempt(env, test);
    await pumpTopikAttempt(tester, env, attempt.id, catalog: [test]);

    final pictures = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == _picture,
    );
    // The group's passage and the four options.
    expect(pictures, findsNWidgets(5));
    // The passage image is announced; each option tile names its picture.
    expect(find.bySemanticsLabel(_en.topikPicture), findsOneWidget);
    for (var idx = 1; idx <= 4; idx++) {
      expect(
        find.bySemanticsLabel(_en.topikOptionLabel(idx, _en.topikPicture)),
        findsOneWidget,
        reason: 'option $idx',
      );
    }
    expect(tester.takeException(), isNull);
    handle.dispose();
  });
}
