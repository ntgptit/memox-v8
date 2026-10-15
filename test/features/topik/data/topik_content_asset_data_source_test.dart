import 'dart:convert';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/datasources/topik_content_asset_data_source.dart';
import 'package:memox/features/topik/domain/models/topik_content_issue_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

import '../../../support/topik_content_fixtures.dart';

// Spec §13.4; BR-TOPIK-008.

/// Assets from [files], by path; any other path is missing, as in the app.
final class _Bundle extends CachingAssetBundle {
  _Bundle(this._files);

  final Map<String, String> _files;

  @override
  Future<ByteData> load(String key) async {
    final text = _files[key];
    if (text == null) throw FlutterError('Unable to load asset: "$key".');
    return ByteData.sublistView(utf8.encode(text));
  }
}

const _manifest = 'assets/topik/manifest.json';

String _manifestOf(List<String> tests) => jsonEncode({'tests': tests});

Future<Set<String>> _paths(Set<String> paths) async => paths;

void main() {
  test('the manifest packs load and are checked against the bundle', () async {
    final source = TopikContentAssetDataSource(
      _Bundle({
        _manifest: _manifestOf([
          'topik2/96/reading.json',
          'topik2/96/listening.json',
        ]),
        'assets/topik/topik2/96/reading.json': jsonEncode(topikTestJson()),
        'assets/topik/topik2/96/listening.json': jsonEncode(
          topikTestJson(section: TopikSection.listening),
        ),
      }),
      assetPaths: () => _paths({topikFixtureAudioAsset}),
    );
    final load = await source.load();
    expect(load.accepted.map((test) => test.testId), [
      'topik2-96-reading',
      'topik2-96-listening',
    ]);
    expect(load.issues, isEmpty);
  });

  test('an audio file missing from the bundle rejects its test only', () async {
    final source = TopikContentAssetDataSource(
      _Bundle({
        _manifest: _manifestOf(['l.json', 'r.json']),
        'assets/topik/l.json': jsonEncode(
          topikTestJson(section: TopikSection.listening),
        ),
        'assets/topik/r.json': jsonEncode(topikTestJson()),
      }),
      assetPaths: () => _paths(const {}),
    );
    final load = await source.load();
    expect(load.accepted.map((test) => test.testId), ['topik2-96-reading']);
    expect(load.issues.single.rule, TopikContentRule.assets);
  });

  test(
    'a listed pack that is missing or not JSON is reported by its path',
    () async {
      final source = TopikContentAssetDataSource(
        _Bundle({
          _manifest: _manifestOf(['gone.json', 'bad.json', 'r.json']),
          'assets/topik/bad.json': '{ not json',
          'assets/topik/r.json': jsonEncode(topikTestJson()),
        }),
        assetPaths: () => _paths(const {}),
      );
      final load = await source.load();
      expect(load.accepted, hasLength(1));
      expect(load.issues.map((issue) => issue.testId), [
        'gone.json',
        'bad.json',
      ]);
    },
  );

  test('a missing or malformed manifest is no test and one issue', () async {
    for (final files in [
      <String, String>{},
      {_manifest: '{"tests": "nope"}'},
    ]) {
      final load = await TopikContentAssetDataSource(
        _Bundle(files),
        assetPaths: () => _paths(const {}),
      ).load();
      expect(load.accepted, isEmpty);
      expect(load.issues.single.testId, 'manifest.json');
    }
  });

  test('the asset paths are read once per load', () async {
    var reads = 0;
    await TopikContentAssetDataSource(
      _Bundle({
        _manifest: _manifestOf(['l.json']),
        'assets/topik/l.json': jsonEncode(
          topikTestJson(section: TopikSection.listening),
        ),
      }),
      assetPaths: () async {
        reads++;
        return {topikFixtureAudioAsset};
      },
    ).load();
    expect(reads, 1);
  });
}
