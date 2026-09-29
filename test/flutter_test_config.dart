import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The face a test renders `MxTextStyles.code` in: the app asks for the
/// system `monospace`, which a test host does not have, so it would paint
/// Ahem boxes. DejaVu Sans Mono stands in; its licence sits beside it.
const String _monospaceFamily = 'monospace';
const String _monospaceFile = 'test/support/fonts/DejaVuSansMono.ttf';

/// Loads every font the app bundles (Plus Jakarta Sans, Material Icons) and
/// a monospace stand-in, so text and glyphs render for real in every test
/// instead of as Ahem boxes.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
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
