import 'dart:convert';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:memox/features/topik/data/mappers/topik_content_pack_mapper.dart';
import 'package:memox/features/topik/domain/models/topik_content_issue_model.dart';

/// Every asset path the bundle holds (the app reads the `AssetManifest`).
typedef TopikAssetPaths = Future<Set<String>> Function();

/// The TOPIK packs bundled with the app (spec §13.4): the manifest lists the
/// pack files relative to `assets/topik/`, and each file is one test.
final class TopikContentAssetDataSource {
  const TopikContentAssetDataSource(this._bundle, {required this._assetPaths});

  final AssetBundle _bundle;
  final TopikAssetPaths _assetPaths;

  static const String manifestPath = 'assets/topik/manifest.json';
  static const String _folder = 'assets/topik/';
  static const String _manifestName = 'manifest.json';

  /// The valid tests and every issue (BR-TOPIK-008). It never throws for
  /// content: a missing or malformed manifest is no test.
  Future<TopikContentLoad> load() async {
    final fileIssues = <TopikContentIssue>[];
    final files = <TopikPackFile>[];
    for (final entry in await _manifestEntries(fileIssues)) {
      final json = await _jsonAt('$_folder$entry', entry, fileIssues);
      if (json == null) continue;
      files.add((origin: entry, json: json));
    }
    final present = await _assetPaths();
    return topikContentOf(
      files,
      assetExists: present.contains,
      fileIssues: fileIssues,
    );
  }

  Future<List<String>> _manifestEntries(List<TopikContentIssue> issues) async {
    final json = await _jsonAt(manifestPath, _manifestName, issues);
    if (json == null) return const [];
    final tests = json is Map<String, Object?> ? json['tests'] : null;
    if (tests is List<Object?> && tests.every((entry) => entry is String)) {
      return tests.cast<String>();
    }
    issues.add(
      const TopikContentIssue.error(
        TopikContentRule.shape,
        _manifestName,
        'tests must be a list of paths',
      ),
    );
    return const [];
  }

  /// The JSON of the asset at [path]; null, with an issue labelled [name],
  /// when it is missing or is not JSON.
  Future<Object?> _jsonAt(
    String path,
    String name,
    List<TopikContentIssue> issues,
  ) async {
    try {
      return jsonDecode(await _bundle.loadString(path));
    } on FlutterError {
      // A missing asset: the bundle says so with a FlutterError.
      issues.add(
        TopikContentIssue.error(TopikContentRule.shape, name, 'file not found'),
      );
    } on FormatException catch (error) {
      issues.add(
        TopikContentIssue.error(
          TopikContentRule.shape,
          name,
          'not JSON: ${error.message}',
        ),
      );
    }
    return null;
  }
}
