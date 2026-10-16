import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The face a test renders the code text style in: the app asks for the
/// system `monospace`, which a test host does not have, so it would paint
/// Ahem boxes. DejaVu Sans Mono stands in; its licence sits beside it.
const String _monospaceFamily = 'monospace';
const String _monospaceFile = 'test/support/fonts/DejaVuSansMono.ttf';

/// Loads every font the app bundles (Be Vietnam Pro, Noto Sans KR, Material Icons) and
/// a monospace stand-in, so text and glyphs render for real in every test
/// instead of as Ahem boxes.
///
/// A tap whose point does not reach the widget it names fails the test
/// ([_MissedTapBinding]).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  _MissedTapBinding();
  tearDown(_failOnMissedTap);
  await _loadBundledFonts();
  await _loadMonospace();
  await testMain();
}

Future<void> _loadMonospace() async {
  final bytes = await File(_monospaceFile).readAsBytes();
  final loader = FontLoader(_monospaceFamily)
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

Future<void> _loadBundledFonts() async {
  final manifest = jsonDecode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final family in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(family['family'] as String);
    final fonts = (family['fonts'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    for (final font in fonts) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// What flutter_test prints when a tap, drag or long press derives a point
/// that does not hit the widget its finder names.
const String _missedTapWarning = 'would not hit test on the specified widget';

final List<String> _missedTaps = [];

/// The default binding, except that a missed tap is recorded.
///
/// flutter_test only prints a missed tap, and a passing run's output is never
/// read: two goldens of a dialog that never opened, and two of an import
/// choice that was never made, were committed that way (the taps landed on a
/// widget off-screen, or on a spot a scroll had not been laid out to yet).
/// `WidgetController.hitTestWarningShouldBeFatal` is not used: on Flutter
/// 3.47.5 the error it throws crashes while describing a `RenderParagraph`
/// and the test then hangs for minutes. A test that means to tap a widget that
/// ignores pointers passes `warnIfMissed: false`, which prints nothing.
class _MissedTapBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  DebugPrintCallback get debugPrintOverride => _print;

  static void _print(String? message, {int? wrapWidth}) {
    if (message != null && message.contains(_missedTapWarning)) {
      _missedTaps.add(message);
    }
    debugPrintSynchronously(message, wrapWidth: wrapWidth);
  }
}

void _failOnMissedTap() {
  if (_missedTaps.isEmpty) return;
  final missed = List.of(_missedTaps);
  _missedTaps.clear();
  fail(
    'a tap missed the widget it named (${missed.length}x); scroll it in and '
    'pump before tapping, or pass warnIfMissed: false if it ignores '
    'pointers on purpose:\n${missed.first.trim()}',
  );
}
