import 'dart:async';

import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/features/topik/data/datasources/topik_audio_player_data_source.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_audio_repository.dart';

/// The listening player's rules over the plugin (BR-TOPIK-017): no
/// autoplay, the same group keeps playing, replay from the start, a clamped
/// seek, four speeds, and a failure kept as a state with one warning.
final class TopikAudioRepositoryImpl implements TopikAudioRepository {
  TopikAudioRepositoryImpl(this._source) {
    _reports = _source.snapshots.listen(
      _onSnapshot,
      onError: (Object error) => _onFailure(error),
    );
  }

  final TopikAudioPlayerDataSource _source;
  late final StreamSubscription<TopikPlayerSnapshot> _reports;
  final _states = StreamController<TopikAudioState>.broadcast();
  TopikAudioState _state = TopikAudioState.initial;

  @override
  TopikAudioState get state => _state;

  @override
  Stream<TopikAudioState> watchState() async* {
    yield _state;
    yield* _states.stream;
  }

  @override
  Future<void> load(TopikAudioClip clip) async {
    if (_state.clip == clip && _state.status != TopikAudioStatus.failed) {
      return;
    }
    if (_state.clip != null) await _guard(_source.stop);
    _emit(
      _state.copyWith(
        status: TopikAudioStatus.loading,
        clip: clip,
        positionMs: 0,
      ),
    );
    // A later load of another group overtakes this one: from then on this
    // load changes nothing, not even on failure.
    final loaded = await _guard(
      () => _source.setClip(
        asset: clip.asset,
        startMs: clip.startMs,
        endMs: clip.endMs,
      ),
      forClip: clip,
    );
    if (!loaded || _state.clip != clip) return;
    await _guard(() => _source.setSpeed(_state.speed), forClip: clip);
    if (_state.clip != clip) return;
    _emit(_state.copyWith(status: TopikAudioStatus.ready));
  }

  @override
  Future<void> play() async {
    if (!_isLoaded) return;
    if (_state.status == TopikAudioStatus.completed) {
      if (!await _guard(() => _source.seek(0))) return;
    }
    await _guard(_source.play);
  }

  @override
  Future<void> pause() async {
    if (_isLoaded) await _guard(_source.pause);
  }

  @override
  Future<void> seek(int positionMs) async {
    final clip = _state.clip;
    if (clip == null || !_isLoaded) return;
    await _guard(() => _source.seek(positionMs.clamp(0, clip.lengthMs)));
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (!topikAudioSpeeds.contains(speed)) {
      throw ArgumentError.value(speed, 'speed', 'is not a practice speed');
    }
    _emit(_state.copyWith(speed: speed));
    if (_isLoaded) await _guard(() => _source.setSpeed(speed));
  }

  @override
  Future<void> stop() async {
    if (!_isLoaded) return;
    if (await _guard(_source.stop)) {
      _emit(_state.copyWith(status: TopikAudioStatus.ready, positionMs: 0));
    }
  }

  @override
  Future<void> dispose() async {
    await _reports.cancel();
    await _states.close();
    await _source.dispose();
  }

  bool get _isLoaded => switch (_state.status) {
    TopikAudioStatus.ready ||
    TopikAudioStatus.playing ||
    TopikAudioStatus.completed => true,
    _ => false,
  };

  void _onSnapshot(TopikPlayerSnapshot snapshot) {
    final clip = _state.clip;
    if (clip == null || !_isLoaded) return;
    final status = switch (snapshot.phase) {
      TopikPlayerPhase.completed => TopikAudioStatus.completed,
      _ when snapshot.playing => TopikAudioStatus.playing,
      _ => TopikAudioStatus.ready,
    };
    _emit(
      _state.copyWith(
        status: status,
        positionMs: snapshot.positionMs.clamp(0, clip.lengthMs),
      ),
    );
  }

  /// Runs a plugin call; a failure becomes the failed state and one
  /// warning naming the asset (BR-TOPIK-017). Whether it succeeded. A call
  /// made [forClip] that is no longer loaded leaves the state alone.
  Future<bool> _guard(
    Future<void> Function() call, {
    TopikAudioClip? forClip,
  }) async {
    try {
      await call();
      return true;
    } catch (error) {
      _onFailure(error, forClip: forClip);
      return false;
    }
  }

  /// One warning naming the asset, and the failed state unless the failure
  /// belongs to a clip no longer loaded (BR-TOPIK-017).
  void _onFailure(Object error, {TopikAudioClip? forClip}) {
    appLogger.warning(
      'topik.audio_failed',
      category: LogCategory.state,
      context: {
        'asset': (forClip ?? _state.clip)?.asset,
        'error': error.runtimeType.toString(),
      },
    );
    if (forClip == null || forClip == _state.clip) {
      _emit(_state.copyWith(status: TopikAudioStatus.failed));
    }
  }

  void _emit(TopikAudioState next) {
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }
}
