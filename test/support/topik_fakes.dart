import 'dart:async';

import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_audio_repository.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';

/// A catalog of the given tests; a test can change it between reads, or
/// make the next reads throw [failure].
final class FakeTopikContentRepository implements TopikContentRepository {
  FakeTopikContentRepository(this.tests);

  List<TopikTest> tests;
  Object? failure;

  @override
  Future<List<TopikTest>> catalog() async {
    final failure = this.failure;
    if (failure != null) throw failure;
    return tests;
  }
}

/// A player a test drives: each command is logged in [calls] and moves the
/// state at once. A load is ready at the clip's start, or fails while
/// [failsLoads].
final class FakeTopikAudioRepository implements TopikAudioRepository {
  FakeTopikAudioRepository([this._state = TopikAudioState.initial]);

  TopikAudioState _state;
  final _states = StreamController<TopikAudioState>.broadcast();
  final calls = <String>[];
  var failsLoads = false;

  @override
  TopikAudioState get state => _state;

  @override
  Stream<TopikAudioState> watchState() => Stream.multi((listener) {
    listener.add(_state);
    final changes = _states.stream.listen(listener.add);
    listener.onCancel = changes.cancel;
  });

  /// Moves the player to [next], as the plugin would.
  void emit(TopikAudioState next) {
    _state = next;
    _states.add(next);
  }

  @override
  Future<void> load(TopikAudioClip clip) async {
    calls.add('load ${clip.startMs}');
    emit(
      TopikAudioState(
        status: failsLoads ? TopikAudioStatus.failed : TopikAudioStatus.ready,
        clip: clip,
        positionMs: 0,
        speed: _state.speed,
      ),
    );
  }

  @override
  Future<void> play() async {
    calls.add('play');
    emit(_state.copyWith(status: TopikAudioStatus.playing));
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    emit(_state.copyWith(status: TopikAudioStatus.ready));
  }

  @override
  Future<void> seek(int positionMs) async {
    calls.add('seek $positionMs');
    emit(_state.copyWith(positionMs: positionMs));
  }

  @override
  Future<void> setSpeed(double speed) async {
    calls.add('speed $speed');
    emit(_state.copyWith(speed: speed));
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    emit(_state.copyWith(status: TopikAudioStatus.ready, positionMs: 0));
  }

  @override
  Future<void> dispose() async => calls.add('dispose');
}
