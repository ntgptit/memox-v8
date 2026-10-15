import 'dart:convert';
import 'dart:io';

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
}
