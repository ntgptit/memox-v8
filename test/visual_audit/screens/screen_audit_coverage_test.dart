import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Debug-only tooling, not a production screen.
const Set<String> _exempt = {'lib/app/gallery/gallery_screen.dart'};

const String _companionRoot = 'test/visual_audit/screens';

/// Where [screenPath]'s companion lives: its path under `lib/` without the
/// `presentation/` segment, under [_companionRoot].
String companionFor(String screenPath) {
  final rest = screenPath
      .substring('lib/'.length)
      .replaceFirst('/presentation/', '/')
      .replaceFirst(RegExp(r'\.dart$'), '_visual_audit_test.dart');
  return '$_companionRoot/$rest';
}

/// `deck_level_screen.dart` → `DeckLevelScreen`.
String screenClassOf(String screenPath) => screenPath
    .split('/')
    .last
    .replaceFirst(RegExp(r'\.dart$'), '')
    .split('_')
    .map((part) => part[0].toUpperCase() + part.substring(1))
    .join();

List<String> _productionScreens() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path.replaceAll(r'\', '/'))
        .where((path) => path.endsWith('_screen.dart'))
        .where((path) => !_exempt.contains(path))
        .toList()
      ..sort();

void main() {
  test('a companion mirrors its screen without presentation/', () {
    expect(
      companionFor(
        'lib/features/deck/presentation/screens/deck_level_screen.dart',
      ),
      'test/visual_audit/screens/features/deck/screens/'
      'deck_level_screen_visual_audit_test.dart',
    );
    expect(
      companionFor('lib/app/placeholder_screen.dart'),
      'test/visual_audit/screens/app/placeholder_screen_visual_audit_test.dart',
    );
    expect(
      screenClassOf('lib/app/placeholder_screen.dart'),
      'PlaceholderScreen',
    );
  });

  test('the scan still finds the production screens', () {
    final screens = _productionScreens();
    expect(
      screens,
      contains('lib/features/deck/presentation/screens/deck_level_screen.dart'),
    );
    expect(screens, isNot(contains('lib/app/gallery/gallery_screen.dart')));
  });

  test('every production screen has a companion that audits it', () {
    final problems = <String>[];
    for (final screen in _productionScreens()) {
      final companion = File(companionFor(screen));
      if (!companion.existsSync()) {
        problems.add('$screen: no ${companion.path}');
        continue;
      }
      final text = companion.readAsStringSync();
      if (!text.contains('auditProductionScreen(')) {
        problems.add('${companion.path}: never calls auditProductionScreen');
      }
      if (!text.contains('screen: ${screenClassOf(screen)}')) {
        problems.add(
          '${companion.path}: never audits ${screenClassOf(screen)}',
        );
      }
    }
    expect(problems, isEmpty);
  });
}
