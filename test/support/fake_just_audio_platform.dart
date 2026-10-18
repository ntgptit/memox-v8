import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

/// The native side of `just_audio` 0.10.6, faked at its channels, so the real
/// `AudioPlayer` runs over it in a test (the protocol of
/// `just_audio_platform_interface` 4.6.0, `method_channel_just_audio.dart`).
/// Time does not pass on its own: the test moves the clip on with [complete]
/// and reports a native error with [failMidPlay], as Android does
/// (`AudioPlayer.java` sendError: an error event, then idle).
final class FakeJustAudioPlatform {
  FakeJustAudioPlatform._();

  /// Installs the fake for the current test; removed when it ends.
  static FakeJustAudioPlatform install() {
    final fake = FakeJustAudioPlatform._();
    _messenger.setMockMethodCallHandler(_main, fake._onMain);
    addTearDown(() {
      _messenger.setMockMethodCallHandler(_main, null);
      for (final id in fake._ids) {
        fake._unregister(id);
      }
    });
    return fake;
  }

  static const _main = MethodChannel('com.ryanheise.just_audio.methods');
  static TestDefaultBinaryMessenger get _messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final _ids = <String>{};
  final _sinks = <String, MockStreamHandlerEventSink>{};

  /// Every call the player made, by method name.
  final calls = <String>[];

  /// The next `load` fails, as a missing file does.
  bool failLoad = false;

  JustAudioWireState _state = JustAudioWireState.idle;
  Duration _position = Duration.zero;
  Duration? _duration;
  bool _isPlaying = false;
  int? _errorCode;

  /// Where the native player is, in the clip.
  Duration get position => _position;

  /// Whether the native player plays.
  bool get isPlaying => _isPlaying;

  /// The clip played to its end.
  void complete() {
    _position = _duration ?? Duration.zero;
    _state = JustAudioWireState.completed;
    _emit();
  }

  /// A decoder error while playing: an error event, then idle with the
  /// error code, `playing` left as it was.
  void failMidPlay() {
    for (final sink in _sinks.values) {
      sink.error(code: '1', message: 'decoder');
    }
    _errorCode = 1;
    _state = JustAudioWireState.idle;
    _emit();
  }

  Future<Object?> _onMain(MethodCall call) async {
    calls.add(call.method);
    final args = call.arguments as Map<Object?, Object?>?;
    switch (call.method) {
      case 'init':
        _register(args!['id']! as String);
      case 'disposePlayer':
        _unregister(args!['id']! as String);
    }
    return <String, Object?>{};
  }

  void _register(String id) {
    _ids.add(id);
    _messenger
      ..setMockMethodCallHandler(
        MethodChannel('com.ryanheise.just_audio.methods.$id'),
        _onPlayer,
      )
      ..setMockStreamHandler(
        EventChannel('com.ryanheise.just_audio.events.$id'),
        MockStreamHandler.inline(
          onListen: (_, sink) => _sinks[id] = sink,
          onCancel: (_) => _sinks.remove(id),
        ),
      )
      ..setMockStreamHandler(
        EventChannel('com.ryanheise.just_audio.data.$id'),
        MockStreamHandler.inline(onListen: (_, _) {}),
      );
  }

  void _unregister(String id) {
    _sinks.remove(id);
    _messenger
      ..setMockMethodCallHandler(
        MethodChannel('com.ryanheise.just_audio.methods.$id'),
        null,
      )
      ..setMockStreamHandler(
        EventChannel('com.ryanheise.just_audio.events.$id'),
        null,
      )
      ..setMockStreamHandler(
        EventChannel('com.ryanheise.just_audio.data.$id'),
        null,
      );
  }

  Future<Object?> _onPlayer(MethodCall call) async {
    calls.add(call.method);
    final args = call.arguments as Map<Object?, Object?>;
    switch (call.method) {
      case 'load':
        return _load(args);
      case 'play':
        _isPlaying = true;
        _emit();
      case 'pause':
        _isPlaying = false;
        _emit();
      case 'seek':
        _position = Duration(microseconds: (args['position'] as int?) ?? 0);
        if (_state == JustAudioWireState.completed) {
          _state = JustAudioWireState.ready;
        }
        _emit();
      case 'dispose':
        _state = JustAudioWireState.idle;
    }
    return <String, Object?>{};
  }

  Future<Object?> _load(Map<Object?, Object?> args) async {
    final playlist = args['audioSource']! as Map<Object?, Object?>;
    final clip =
        (playlist['children']! as List<Object?>).first!
            as Map<Object?, Object?>;
    _duration = Duration(
      microseconds: (clip['end']! as int) - (clip['start']! as int),
    );
    _errorCode = null;
    _state = JustAudioWireState.loading;
    _emit();
    if (failLoad) {
      _errorCode = 404;
      _state = JustAudioWireState.idle;
      _emit();
      throw PlatformException(code: '404', message: 'no file');
    }
    _position = Duration(microseconds: (args['initialPosition'] as int?) ?? 0);
    _state = JustAudioWireState.ready;
    _emit();
    return <String, Object?>{'duration': _duration!.inMicroseconds};
  }

  void _emit() {
    // just_audio extrapolates a playing position from this instant with its
    // own wall clock (`_getPositionFor`, `just_audio.dart:673`), so the
    // fake stamps the event with the same clock: only the elapsed time, a
    // few microseconds, reaches a test, never the date it runs on.
    final stampedAt = DateTime.timestamp().millisecondsSinceEpoch;
    final event = <String, Object?>{
      'processingState': _state.index,
      'updateTime': stampedAt,
      'updatePosition': _position.inMicroseconds,
      'bufferedPosition': _position.inMicroseconds,
      'duration': _duration?.inMicroseconds,
      'icyMetadata': null,
      'currentIndex': 0,
      'androidAudioSessionId': null,
      'errorCode': _errorCode,
      'errorMessage': _errorCode == null ? null : 'error $_errorCode',
    };
    for (final sink in _sinks.values) {
      sink.success(event);
    }
  }
}

/// `ProcessingStateMessage`'s order on the wire (the index is what is sent).
enum JustAudioWireState { idle, loading, buffering, ready, completed }

/// The real player with the asset child of a clip swapped for a file URI:
/// an asset is first copied to a cache file on the device (`path_provider`),
/// which a host test cannot do. The copy itself is UNVERIFIED (device).
final class HostAudioPlayer extends AudioPlayer {
  HostAudioPlayer()
    : super(
        handleInterruptions: false,
        handleAudioSessionActivation: false,
        androidApplyAudioAttributes: false,
      );

  @override
  Future<Duration?> setAudioSource(
    AudioSource source, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) {
    final clip = source as ClippingAudioSource;
    return super.setAudioSource(
      ClippingAudioSource(
        child: AudioSource.uri(Uri.file('/clips/${clip.child.uri.path}')),
        start: clip.start,
        end: clip.end,
      ),
      preload: preload,
      initialIndex: initialIndex,
      initialPosition: initialPosition,
    );
  }
}
