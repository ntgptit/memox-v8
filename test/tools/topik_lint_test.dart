import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_content_issue_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

import '../../tools/topik/topik_lint.dart';
import '../support/topik_content_fixtures.dart';

// BR-TOPIK-008: the gate's lint runs the app's mapper and check.

void main() {
  late Directory bundle;
  late Directory content;

  setUp(() {
    bundle = Directory.systemTemp.createTempSync('topik_lint');
    content = Directory('${bundle.path}/assets/topik')
      ..createSync(recursive: true);
    File('${bundle.path}/$topikFixtureAudioAsset')
      ..createSync(recursive: true)
      ..writeAsBytesSync([0]);
  });

  tearDown(() => bundle.deleteSync(recursive: true));

  void writePack(String path, Object? json) => File('${content.path}/$path')
    ..createSync(recursive: true)
    ..writeAsStringSync(json is String ? json : jsonEncode(json));

  void writeManifest(List<String> tests) =>
      writePack('manifest.json', {'tests': tests});

  TopikLintReport lint() =>
      lintTopikContent(contentRoot: content, bundleRoot: bundle);

  test('valid packs pass', () {
    writePack('topik2/96/reading.json', topikTestJson());
    writePack(
      'topik2/96/listening.json',
      topikTestJson(section: TopikSection.listening),
    );
    writeManifest(['topik2/96/reading.json', 'topik2/96/listening.json']);
    final report = lint();
    expect(report.issues, isEmpty);
    expect(report.testCount, 2);
    expect(report.passes, isTrue);
  });

  test('a broken pack fails while the others are still checked', () {
    final broken = topikTestJson(section: TopikSection.listening);
    questionJson(broken, 50)['points'] = 4;
    writePack('broken.json', broken);
    writePack('fine.json', topikTestJson());
    writeManifest(['broken.json', 'fine.json']);
    final report = lint();
    expect(report.passes, isFalse);
    expect(report.testCount, 2);
    expect(report.issues.map((issue) => issue.rule).toSet(), {
      TopikContentRule.points,
    });
  });

  test('a missing audio file fails on assets', () {
    File('${bundle.path}/$topikFixtureAudioAsset').deleteSync();
    writePack('listening.json', topikTestJson(section: TopikSection.listening));
    writeManifest(['listening.json']);
    expect(lint().issues.single.rule, TopikContentRule.assets);
  });

  test('a listed file that is missing or not JSON fails with its path', () {
    writePack('bad.json', '{ not json');
    writePack('fine.json', topikTestJson());
    writeManifest(['bad.json', 'gone.json', 'fine.json']);
    final report = lint();
    expect(report.testCount, 1);
    expect(report.issues.map((issue) => issue.testId), [
      'bad.json',
      'gone.json',
    ]);
  });

  test('a listed file that is not UTF-8 fails with its path', () {
    File('${content.path}/bad.json').writeAsBytesSync([0xff, 0xfe, 0x7b, 0x80]);
    writePack('fine.json', topikTestJson());
    writeManifest(['bad.json', 'fine.json']);
    final report = lint();
    expect(report.testCount, 1);
    expect(report.issues.single.testId, 'bad.json');
  });

  test('a pack without a test id is named by its file', () {
    writePack('nameless.json', topikTestJson()..remove('testId'));
    writeManifest(['nameless.json']);
    final report = lint();
    expect(report.passes, isFalse);
    expect(report.issues.map((issue) => issue.testId).toSet(), {
      'nameless.json',
    });
  });

  test('two packs with one test id fail on duplicate', () {
    writePack('a.json', topikTestJson());
    writePack('b.json', topikTestJson());
    writeManifest(['a.json', 'b.json']);
    expect(lint().issues.single.rule, TopikContentRule.duplicate);
  });

  test('a missing manifest fails', () {
    final report = lint();
    expect(report.passes, isFalse);
    expect(report.issues.single.testId, 'manifest.json');
  });

  group('declared asset folders (spec §13.4)', () {
    test('a pack or audio folder not declared in pubspec fails', () {
      writePack(
        'topik2/96/listening.json',
        topikTestJson(section: TopikSection.listening),
      );
      writeManifest(['topik2/96/listening.json']);
      final report = lintTopikContent(
        contentRoot: content,
        bundleRoot: bundle,
        declaredAssetFolders: {'assets/topik/'},
      );
      expect(report.passes, isFalse);
      expect(
        report.issues.map((issue) => issue.detail).join('\n'),
        allOf(
          contains('assets/topik/topik2/96/'),
          contains('assets/topik/fixture/'),
        ),
      );
    });

    test('every folder declared passes', () {
      writePack(
        'topik2/96/listening.json',
        topikTestJson(section: TopikSection.listening),
      );
      writeManifest(['topik2/96/listening.json']);
      final report = lintTopikContent(
        contentRoot: content,
        bundleRoot: bundle,
        declaredAssetFolders: {
          'assets/topik/',
          'assets/topik/topik2/96/',
          'assets/topik/fixture/',
        },
      );
      expect(report.issues, isEmpty);
    });
  });

  test('pubspec asset folders are read, comments and files aside', () {
    const yaml = '''
name: memox
flutter:
  generate: true
  assets:
    # The starter templates.
    - assets/templates/
    - assets/fonts/OFL-BeVietnamPro.txt
      - assets/topik/   # packs
  fonts:
    - family: BeVietnamPro
''';
    expect(declaredAssetFoldersOf(yaml), {
      'assets/templates/',
      'assets/topik/',
    });
  });

  group('existence is exact, as in the app bundle (BR-TOPIK-008)', () {
    // Windows and macOS file systems ignore case; the bundle does not.
    TopikLintReport lintIgnoringCase() => IOOverrides.runZoned(
      () => lintTopikContent(contentRoot: content, bundleRoot: bundle),
      createFile: _CaseInsensitiveFile.new,
    );

    test('an audio file whose name differs only in case is missing', () {
      File('${bundle.path}/$topikFixtureAudioAsset')
          .renameSync('${bundle.path}/assets/topik/fixture/LISTENING.mp3');
      writePack(
        'listening.json',
        topikTestJson(section: TopikSection.listening),
      );
      writeManifest(['listening.json']);
      final report = lintIgnoringCase();
      expect(report.issues.single.rule, TopikContentRule.assets);
    });

    test('a manifest entry whose name differs only in case is missing', () {
      writePack('reading.json', topikTestJson());
      writeManifest(['Reading.json']);
      final report = lintIgnoringCase();
      expect(report.testCount, 0);
      expect(report.issues.single.testId, 'Reading.json');
      expect(report.issues.single.detail, 'file not found');
    });
  });
}

/// A file as a case-insensitive file system (NTFS, APFS) sees it: a path
/// whose name differs only in case resolves to the file that exists.
final class _CaseInsensitiveFile implements File {
  _CaseInsensitiveFile(this.path);

  @override
  final String path;

  File? get _match {
    final slash = path.lastIndexOf('/');
    final folder = Directory(path.substring(0, slash));
    if (!folder.existsSync()) return null;
    final name = path.substring(slash + 1).toLowerCase();
    for (final entry in folder.listSync()) {
      final entryName = entry.path.substring(entry.path.lastIndexOf('/') + 1);
      if (entryName.toLowerCase() == name) {
        return IOOverrides.runWithIOOverrides(
          () => File(entry.path),
          _RealFiles(),
        );
      }
    }
    return null;
  }

  @override
  bool existsSync() => _match != null;

  @override
  Uint8List readAsBytesSync() => _match!.readAsBytesSync();

  @override
  String readAsStringSync({Encoding encoding = utf8}) =>
      _match!.readAsStringSync(encoding: encoding);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Overrides nothing: files made inside it are the real ones.
final class _RealFiles extends IOOverrides {}
