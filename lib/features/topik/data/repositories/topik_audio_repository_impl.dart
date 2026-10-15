import 'dart:async';

import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/features/topik/data/datasources/topik_audio_player_data_source.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_audio_repository.dart';

/// The listening player's rules over the plugin (BR-TOPIK-017): no
/// autoplay, the same group keeps playing, replay from the start, a clamped
/// seek, four speeds, and a failure kept as a state with one warning.
///
/// It listens to the plugin but does not own it: the door's provider
/// releases the door.
final class TopikAudioRepositoryImpl implements TopikAudioRepository {
  TopikAudioRepositoryImpl(this._source) {
    _reports = _source.snapshots.listen(_onSnapshot, onError: _onPlayerError);
  }

  final TopikAudioPlayerDataSource _source;
  late final StreamSubscription<TopikPlayerSnapshot> _reports;
  final _states = StreamController<TopikAudioState>.broadcast();
  TopikAudioState _state = TopikAudioState.initial;

  /// The number of the latest [load]; an earlier one is overtaken.
  int _latestLoad = 0;
  bool _isDisposed = false;

  @override
  TopikAudioState get state => _state;

  @override
  Stream<TopikAudioState> watchState() => Stream.multi((listener) {
    // The current state and the subscription in one step, so no change
    // falls between them.
    listener.add(_state);
    final changes = _states.stream.listen(
      listener.add,
      onError: listener.addError,
      onDone: listener.close,
    );
    listener.onCancel = changes.cancel;
  });

  @override
  Future<void> load(TopikAudioClip clip) async {
    if (_isDisposed) return;
    if (_state.clip == clip && _state.status != TopikAudioStatus.failed) {
      return;
    }
    final load = ++_latestLoad;
    final hadClip = _state.clip != null;
    // The group is recorded before the first await, so a load that follows
    // sees it.
    _emit(
      _state.copyWith(
        status: TopikAudioStatus.loading,
        clip: clip,
        positionMs: 0,
      ),
    );
    // The plugin keeps playing across a new source: pause the previous
    // group, or the next one would start on its own.
    if (hadClip && !await _run(_source.pause, load: load)) return;
    final loaded = await _run(
      () => _source.setClip(
        asset: clip.asset,
        startMs: clip.startMs,
        endMs: clip.endMs,
      ),
      load: load,
    );
    if (!loaded || !_isCurrent(load)) return;
    if (!await _run(() => _source.setSpeed(_state.speed), load: load)) return;
    if (!_isCurrent(load)) return;
    _emit(_state.copyWith(status: TopikAudioStatus.ready));
  }

  @override
  Future<void> play() async {
    if (!_isLoaded) return;
    if (_state.status == TopikAudioStatus.completed) {
      if (!await _run(() => _source.seek(0))) return;
    }
    await _run(_source.play);
  }

  @override
  Future<void> pause() async {
    if (_isLoaded) await _run(_source.pause);
  }

  @override
  Future<void> seek(int positionMs) async {
    final clip = _state.clip;
    if (clip == null || !_isLoaded) return;
    await _run(() => _source.seek(positionMs.clamp(0, clip.lengthMs)));
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (!topikAudioSpeeds.contains(speed)) {
      throw ArgumentError.value(speed, 'speed', 'is not a practice speed');
    }
    _emit(_state.copyWith(speed: speed));
    if (_isLoaded) await _run(() => _source.setSpeed(speed));
  }

  @override
  Future<void> stop() async {
    if (!_isLoaded) return;
    if (await _run(_source.stop)) {
      _emit(_state.copyWith(status: TopikAudioStatus.ready, positionMs: 0));
    }
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    await _reports.cancel();
    await _states.close();
  }

  bool get _isLoaded => switch (_state.status) {
    TopikAudioStatus.ready ||
    TopikAudioStatus.playing ||
    TopikAudioStatus.completed => true,
    _ => false,
  };

  bool _isCurrent(int load) => !_isDisposed && load == _latestLoad;

  void _onSnapshot(TopikPlayerSnapshot snapshot) {
    final clip = _state.clip;
    if (clip == null || !_isLoaded) return;
    final hasJustEnded =
        snapshot.phase == TopikPlayerPhase.completed &&
        _state.status != TopikAudioStatus.completed;
    // The plugin still "plays" after the end, so a later seek would start
    // the clip again: pause it once, as it ends (a replay passes through
    // the completed phase again while playing, and must not be paused).
    if (hasJustEnded && snapshot.playing) unawaited(_run(_source.pause));
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

  /// A failure the plugin reports while a clip is loaded. One that comes
  /// while a load runs is that load's own, which reports it.
  void _onPlayerError(Object error) {
    if (_isDisposed || !_isLoaded) return;
    _fail(error);
  }

  /// Runs a plugin call; whether it succeeded. A failure becomes the failed
  /// state and one warning, unless the call belongs to a [load] since
  /// overtaken, or the player is gone: nothing failed for the person then.
  Future<bool> _run(Future<void> Function() call, {int? load}) async {
    try {
      await call();
      return true;
    } catch (error) {
      final isStale = _isDisposed || (load != null && !_isCurrent(load));
      if (!isStale) _fail(error);
      return false;
    }
  }

  /// One warning naming the asset, and the failed state (BR-TOPIK-017).
  void _fail(Object error) {
    appLogger.warning(
      'topik.audio_failed',
      category: LogCategory.state,
      context: {
        'asset': _state.clip?.asset,
        'error': error.runtimeType.toString(),
      },
    );
    _emit(_state.copyWith(status: TopikAudioStatus.failed));
  }

  void _emit(TopikAudioState next) {
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }
}
