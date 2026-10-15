# TOPIK content loading Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Load the bundled TOPIK content packs into the app once, keep only valid tests (first of each id), log every rejected one, and make the gate prove that every pack and asset the content names is declared in `pubspec.yaml` (spec §13.4; Phase 2 plan 1 of §13.9, epic DEV-394).

**Architecture:** One pure function `topikContentOf` runs the content pipeline (read with `topikTestOf`, check with `checkTopikTest`, first valid copy of each id wins) for both callers: the lint in `tools/topik/` (files on disk) and a new `TopikContentAssetDataSource` (the app's `AssetBundle`). A domain contract `TopikContentRepository` with a memoizing implementation sits behind a `keepAlive` provider, so the catalog is parsed once per app run and a failed read can be retried.

**Tech Stack:** Dart 3.13 / Flutter 3.47.5, `flutter/services.dart` (`AssetBundle`, `AssetManifest`), Riverpod 3 codegen (`riverpod_annotation`), `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-10-15-topik-practice-design.md` (§4.3, §13.4). Rules: `docs/features/topik/rules/BR-TOPIK-008-de-khong-hop-le-bi-loai-khi-nap.md`.

## Global Constraints

- Layering (ADR-011): `domain/` imports no Flutter or Riverpod; `data/` imports its own `domain/` and `core/`; `di/` imports its own `data/`, `domain/`, `core/`; tools import `package:memox/...` files that import no Flutter (the lint runs under `dart run`).
- File suffixes: domain `_repository.dart`; data `_mapper.dart`, `_data_source.dart`, `_repository_impl.dart`; di `_provider.dart`.
- Riverpod: `@Riverpod(keepAlive: true)` for `topikContentRepository` only (owner approval 2026-10-15, spec §13.4); codegen, `Ref ref`; run `dart run build_runner build --delete-conflicting-outputs` after adding a provider.
- Logging: `appLogger.warning('topik.content_rejected', category: LogCategory.state, context: {...})` once per rejected pack; the content never reaches the UI as an error (BR-TOPIK-008).
- Duplicates: among packs that pass every check, the first in manifest order wins; a later copy is rejected with a `duplicate` error naming its file. An invalid copy never blocks a valid one.
- Pack paths in the manifest are relative to `assets/topik/`; asset paths inside a pack are bundle paths (`assets/topik/...`).
- Flutter asset folders are not recursive: every folder holding a pack or an asset is listed in `pubspec.yaml` `flutter.assets`.
- Package imports only; `strict-casts`; no `print`; tool output in English; `dart format` before each commit.
- Commits name the task's sub-issue (DEV-400…DEV-404, one per task in order) with the session's attribution lines.

## Review Focus

1. **The asset manifest cannot be read** (`AssetManifest.loadFromAssetBundle` throws): the catalog read fails as an error the screen can retry, and a retry reads again instead of replaying the cached failure (Task 3).
2. **A manifest entry that names a folder outside `assets/topik/`** (`../templates/x.json`): it resolves inside the bundle like any path; the gate's folder check still requires its folder to be declared, so it cannot silently ship missing (Task 4).
3. **An invalid first copy followed by a valid copy of the same id**: the valid copy is accepted, not reported as a duplicate (Task 1).
4. **The same rejected pack logged on every screen open**: the memoized catalog logs each rejection once per app run (Task 3).
5. **A pubspec asset line with a trailing comment or different indentation** (`    - assets/topik/   # packs`): the declared-folder parser still reads the folder (Task 4).

---

### Task 1: The shared content pipeline, used by the lint

**Files:**
- Create: `lib/features/topik/data/mappers/topik_content_pack_mapper.dart`
- Modify: `tools/topik/topik_lint.dart` (use the pipeline)
- Modify: `lib/features/topik/domain/models/topik_content_check_model.dart` (remove `checkTopikCatalog`, now replaced)
- Modify: `test/features/topik/domain/topik_content_check_test.dart` (remove the `checkTopikCatalog` test, moved)
- Test: `test/features/topik/data/topik_content_pack_mapper_test.dart`

**Interfaces:**
- Consumes: `topikTestOf(Object? json, {String origin})` → `TopikTestRead`; `checkTopikTest(TopikTest, {required bool Function(String) assetExists})`; `TopikContentIssue`, `TopikContentRule`.
- Produces:
  - `typedef TopikPackFile = ({String origin, Object? json});`
  - `final class TopikContentLoad { const TopikContentLoad({required List<TopikTest> accepted, required List<TopikContentIssue> issues, required int readCount}); List<TopikTest> accepted; List<TopikContentIssue> issues; int readCount; bool get hasErrors; }`
  - `TopikContentLoad topikContentOf(Iterable<TopikPackFile> files, {required bool Function(String assetPath) assetExists, List<TopikContentIssue> fileIssues = const []})` — `fileIssues` are problems found before decoding (missing file, not JSON), carried into `issues`.

- [ ] **Step 1: Write the failing test**

`test/features/topik/data/topik_content_pack_mapper_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/mappers/topik_content_pack_mapper.dart';
import 'package:memox/features/topik/domain/models/topik_content_issue_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

import '../../../support/topik_content_fixtures.dart';

// BR-TOPIK-008: the one pipeline the app loader and the lint share.

bool _everyAsset(String path) => true;

List<String> _acceptedIds(TopikContentLoad load) => [
  for (final test in load.accepted) test.testId,
];

void main() {
  test('valid packs are accepted in file order', () {
    final load = topikContentOf([
      (origin: 'listening.json', json: topikTestJson(section: TopikSection.listening)),
      (origin: 'reading.json', json: topikTestJson()),
    ], assetExists: _everyAsset);
    expect(_acceptedIds(load), ['topik2-96-listening', 'topik2-96-reading']);
    expect(load.issues, isEmpty);
    expect(load.readCount, 2);
    expect(load.hasErrors, isFalse);
  });

  test('a pack that fails a check is rejected, the others still load', () {
    final broken = topikTestJson(section: TopikSection.listening);
    questionJson(broken, 50)['points'] = 4;
    final load = topikContentOf([
      (origin: 'broken.json', json: broken),
      (origin: 'fine.json', json: topikTestJson()),
    ], assetExists: _everyAsset);
    expect(_acceptedIds(load), ['topik2-96-reading']);
    expect(load.readCount, 2);
    expect(load.hasErrors, isTrue);
    expect(load.issues.map((issue) => issue.rule).toSet(), {TopikContentRule.points});
  });

  test('the second valid copy of an id is a duplicate naming its file', () {
    final load = topikContentOf([
      (origin: 'a.json', json: topikTestJson()),
      (origin: 'b.json', json: topikTestJson()),
    ], assetExists: _everyAsset);
    expect(_acceptedIds(load), ['topik2-96-reading']);
    expect(load.issues.single.rule, TopikContentRule.duplicate);
    expect(load.issues.single.detail, contains('b.json'));
  });

  test('an invalid first copy does not block a valid second copy', () {
    final invalid = topikTestJson();
    questionJson(invalid, 1)['points'] = 5;
    final load = topikContentOf([
      (origin: 'a.json', json: invalid),
      (origin: 'b.json', json: topikTestJson()),
    ], assetExists: _everyAsset);
    expect(_acceptedIds(load), ['topik2-96-reading']);
    expect(
      load.issues.map((issue) => issue.rule),
      isNot(contains(TopikContentRule.duplicate)),
    );
  });

  test('a warning does not reject the pack', () {
    final json = topikTestJson();
    questionJson(json, 13)['questionType'] = 'R2_paragraph_blank';
    final load = topikContentOf([(origin: 'a.json', json: json)], assetExists: _everyAsset);
    expect(_acceptedIds(load), ['topik2-96-reading']);
    expect(load.issues.single.severity, TopikIssueSeverity.warning);
    expect(load.hasErrors, isFalse);
  });

  test('a pack whose JSON is unreadable is not read', () {
    final load = topikContentOf(
      [(origin: 'bad.json', json: 'nope')],
      assetExists: _everyAsset,
    );
    expect(load.accepted, isEmpty);
    expect(load.readCount, 0);
    expect(load.issues.single.testId, 'bad.json');
  });

  test('file issues found before decoding are carried', () {
    const missing = TopikContentIssue.error(
      TopikContentRule.shape,
      'gone.json',
      'file not found',
    );
    final load = topikContentOf(
      const [],
      assetExists: _everyAsset,
      fileIssues: const [missing],
    );
    expect(load.issues, [missing]);
    expect(load.hasErrors, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/data/topik_content_pack_mapper_test.dart`
Expected: FAIL — `topik_content_pack_mapper.dart` does not exist.

- [ ] **Step 3: Write the pipeline**

`lib/features/topik/data/mappers/topik_content_pack_mapper.dart`:

```dart
import 'package:memox/features/topik/data/mappers/topik_test_mapper.dart';
import 'package:memox/features/topik/domain/models/topik_content_check_model.dart';
import 'package:memox/features/topik/domain/models/topik_content_issue_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';

/// One decoded pack file and where it came from.
typedef TopikPackFile = ({String origin, Object? json});

/// What reading a set of packs gave (BR-TOPIK-008).
final class TopikContentLoad {
  const TopikContentLoad({
    required this.accepted,
    required this.issues,
    required this.readCount,
  });

  /// Tests that pass every check, the first of each id, in file order.
  final List<TopikTest> accepted;

  /// Every error and warning, the file problems first.
  final List<TopikContentIssue> issues;

  /// Files that read into a test, valid or not.
  final int readCount;

  bool get hasErrors => issues.any((issue) => issue.isError);
}

/// The one content pipeline (BR-TOPIK-008): the app's loader and the gate's
/// lint both run it, so what the gate stops is what the app refuses. Each
/// file is read, then checked; among the tests that pass, the first of each
/// id wins and a later copy is a duplicate. An invalid copy never blocks a
/// valid one.
TopikContentLoad topikContentOf(
  Iterable<TopikPackFile> files, {
  required bool Function(String assetPath) assetExists,
  List<TopikContentIssue> fileIssues = const [],
}) {
  final issues = [...fileIssues];
  final accepted = <TopikTest>[];
  final ids = <String>{};
  var readCount = 0;
  for (final file in files) {
    final read = topikTestOf(file.json, origin: file.origin);
    issues.addAll(read.issues);
    final test = read.test;
    if (test == null) continue;
    readCount++;
    final checks = checkTopikTest(test, assetExists: assetExists);
    issues.addAll(checks);
    if (checks.any((issue) => issue.isError)) continue;
    if (ids.add(test.testId)) {
      accepted.add(test);
      continue;
    }
    issues.add(
      TopikContentIssue.error(
        TopikContentRule.duplicate,
        test.testId,
        '${file.origin}: an earlier pack already has this test id',
      ),
    );
  }
  return TopikContentLoad(
    accepted: List.unmodifiable(accepted),
    issues: List.unmodifiable(issues),
    readCount: readCount,
  );
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/data/topik_content_pack_mapper_test.dart`
Expected: PASS (7 tests).

- [ ] **Step 5: Make the lint use the pipeline and retire `checkTopikCatalog`**

In `tools/topik/topik_lint.dart`, replace the imports of `topik_test_mapper.dart`, `topik_content_check_model.dart` and `topik_test_model.dart` with:

```dart
import 'package:memox/features/topik/data/mappers/topik_content_pack_mapper.dart';
```

and replace the body of `lintTopikContent` with:

```dart
TopikLintReport lintTopikContent({
  required Directory contentRoot,
  required Directory bundleRoot,
}) {
  final fileIssues = <TopikContentIssue>[];
  final files = <TopikPackFile>[];
  for (final entry in _manifestEntries(contentRoot, fileIssues)) {
    final json = _decode(File('${contentRoot.path}/$entry'), entry, fileIssues);
    if (json == null) continue;
    files.add((origin: entry, json: json));
  }
  final load = topikContentOf(
    files,
    assetExists: (path) => File('${bundleRoot.path}/$path').existsSync(),
    fileIssues: fileIssues,
  );
  return TopikLintReport(issues: load.issues, testCount: load.readCount);
}
```

In `lib/features/topik/domain/models/topik_content_check_model.dart`, delete the function `checkTopikCatalog` and its doc comment. In `test/features/topik/domain/topik_content_check_test.dart`, delete the test `'a second test with the same id is a duplicate'` (the pipeline test above covers the rule, now with the file named).

- [ ] **Step 6: Run the topik and tools tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik test/tools`
Expected: PASS. `test/tools/topik_lint_test.dart` `two packs with one test id fail on duplicate` still passes (one duplicate issue).

- [ ] **Step 7: Commit**

```bash
dart format lib/features/topik tools/topik test/features/topik
git add lib/features/topik tools/topik test/features/topik
git commit -m "feat(topik): DEV-400 one content pipeline for the app loader and the lint"
```

---

### Task 2: The asset data source

**Files:**
- Create: `lib/features/topik/data/datasources/topik_content_asset_data_source.dart`
- Test: `test/features/topik/data/topik_content_asset_data_source_test.dart`

**Interfaces:**
- Consumes: `topikContentOf`, `TopikContentLoad`, `TopikPackFile` (Task 1).
- Produces:
  - `typedef TopikAssetPaths = Future<Set<String>> Function();`
  - `final class TopikContentAssetDataSource { const TopikContentAssetDataSource(AssetBundle bundle, {required TopikAssetPaths assetPaths}); static const String manifestPath = 'assets/topik/manifest.json'; Future<TopikContentLoad> load(); }` — never throws for content; a missing or malformed manifest is an empty load with one `shape` issue labelled `manifest.json`.

- [ ] **Step 1: Write the failing test**

`test/features/topik/data/topik_content_asset_data_source_test.dart`:

```dart
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
        _manifest: _manifestOf(['topik2/96/reading.json', 'topik2/96/listening.json']),
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
        'assets/topik/l.json': jsonEncode(topikTestJson(section: TopikSection.listening)),
        'assets/topik/r.json': jsonEncode(topikTestJson()),
      }),
      assetPaths: () => _paths(const {}),
    );
    final load = await source.load();
    expect(load.accepted.map((test) => test.testId), ['topik2-96-reading']);
    expect(load.issues.single.rule, TopikContentRule.assets);
  });

  test('a listed pack that is missing or not JSON is reported by its path', () async {
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
    expect(load.issues.map((issue) => issue.testId), ['gone.json', 'bad.json']);
  });

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
        'assets/topik/l.json': jsonEncode(topikTestJson(section: TopikSection.listening)),
      }),
      assetPaths: () async {
        reads++;
        return {topikFixtureAudioAsset};
      },
    ).load();
    expect(reads, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/data/topik_content_asset_data_source_test.dart`
Expected: FAIL — the data source does not exist.

- [ ] **Step 3: Write the data source**

`lib/features/topik/data/datasources/topik_content_asset_data_source.dart`:

```dart
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
  const TopikContentAssetDataSource(
    this._bundle, {
    required TopikAssetPaths assetPaths,
  }) : _assetPaths = assetPaths;

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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/data/topik_content_asset_data_source_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
dart format lib/features/topik test/features/topik
git add lib/features/topik test/features/topik
git commit -m "feat(topik): DEV-401 read the bundled TOPIK packs through the asset bundle"
```

---

### Task 3: The content repository, memoized and keepAlive

**Files:**
- Create: `lib/features/topik/domain/repositories/topik_content_repository.dart`
- Create: `lib/features/topik/data/repositories/topik_content_repository_impl.dart`
- Create: `lib/features/topik/di/topik_content_repository_provider.dart`
- Test: `test/features/topik/data/topik_content_repository_impl_test.dart`

**Interfaces:**
- Consumes: `TopikContentLoad` (Task 1), `TopikContentAssetDataSource` (Task 2).
- Produces:
  - `abstract interface class TopikContentRepository { Future<List<TopikTest>> catalog(); }`
  - `final class TopikContentRepositoryImpl implements TopikContentRepository { TopikContentRepositoryImpl({required Future<TopikContentLoad> Function() load}); }`
  - `topikContentRepositoryProvider` (`@Riverpod(keepAlive: true)`, type `TopikContentRepository`).

- [ ] **Step 1: Write the failing test**

`test/features/topik/data/topik_content_repository_impl_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/features/topik/data/mappers/topik_content_pack_mapper.dart';
import 'package:memox/features/topik/data/repositories/topik_content_repository_impl.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

import '../../../support/recording_log_sink.dart';
import '../../../support/topik_content_fixtures.dart';

// Spec §13.4: parsed once per app run; rejections logged once (BR-TOPIK-008).

TopikContentLoad _loadOf(List<TopikPackFile> files) =>
    topikContentOf(files, assetExists: (_) => true);

void main() {
  late RecordingLogSink log;
  late AppLogger previous;

  setUp(() {
    log = RecordingLogSink();
    previous = appLogger;
    AppLogger.install(AppLogger(sinks: [log]));
  });
  tearDown(() => AppLogger.install(previous));

  test('the catalog is the accepted tests, read once', () async {
    var reads = 0;
    final repository = TopikContentRepositoryImpl(
      load: () async {
        reads++;
        return _loadOf([(origin: 'r.json', json: topikTestJson())]);
      },
    );
    final first = await repository.catalog();
    final second = await repository.catalog();
    expect(first.map((test) => test.testId), ['topik2-96-reading']);
    expect(identical(first, second), isTrue);
    expect(reads, 1);
  });

  test('each rejected pack is logged once, with its first error rule', () async {
    final broken = topikTestJson(section: TopikSection.listening);
    questionJson(broken, 50)['points'] = 4;
    final repository = TopikContentRepositoryImpl(
      load: () async => _loadOf([
        (origin: 'broken.json', json: broken),
        (origin: 'fine.json', json: topikTestJson()),
      ]),
    );
    await repository.catalog();
    await repository.catalog();
    final rejected = log.entries
        .where((entry) => entry.event == 'topik.content_rejected')
        .toList();
    expect(rejected, hasLength(1));
    expect(rejected.single.context['testId'], 'topik2-96-listening');
    expect(rejected.single.context['rule'], 'points');
  });

  test('warnings are not logged as rejections', () async {
    final json = topikTestJson();
    questionJson(json, 13)['questionType'] = 'R2_paragraph_blank';
    await TopikContentRepositoryImpl(
      load: () async => _loadOf([(origin: 'r.json', json: json)]),
    ).catalog();
    expect(log.events, isNot(contains('topik.content_rejected')));
  });

  test('a failed read is not cached: the next call reads again', () async {
    var reads = 0;
    final repository = TopikContentRepositoryImpl(
      load: () async {
        reads++;
        if (reads == 1) throw StateError('asset manifest unreadable');
        return _loadOf([(origin: 'r.json', json: topikTestJson())]);
      },
    );
    await expectLater(repository.catalog(), throwsStateError);
    expect(await repository.catalog(), hasLength(1));
    expect(reads, 2);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/data/topik_content_repository_impl_test.dart`
Expected: FAIL — the repository does not exist.

- [ ] **Step 3: Write the contract, the implementation and the provider**

`lib/features/topik/domain/repositories/topik_content_repository.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_test_model.dart';

/// The TOPIK tests the app can offer (BR-TOPIK-008): every bundled test that
/// passes the content check, the first of each id.
abstract interface class TopikContentRepository {
  /// The valid tests, in manifest order. Read once per app run.
  Future<List<TopikTest>> catalog();
}
```

`lib/features/topik/data/repositories/topik_content_repository_impl.dart`:

```dart
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/topik/data/mappers/topik_content_pack_mapper.dart';
import 'package:memox/features/topik/domain/models/topik_content_issue_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';

/// Reads the packs once and keeps the result (spec §13.4): the content never
/// changes while the app runs. A failed read is forgotten, so Retry reads
/// again.
final class TopikContentRepositoryImpl implements TopikContentRepository {
  TopikContentRepositoryImpl({required Future<TopikContentLoad> Function() load})
    : _load = load;

  final Future<TopikContentLoad> Function() _load;
  Future<List<TopikTest>>? _catalog;

  @override
  Future<List<TopikTest>> catalog() => _catalog ??= _read();

  Future<List<TopikTest>> _read() async {
    try {
      final load = await _load();
      _logRejections(load.issues);
      return load.accepted;
    } on Object {
      // Not swallowed: forget the failed read so Retry reads again.
      _catalog = null;
      rethrow;
    }
  }

  /// One log per rejected pack, with the first error that rejected it.
  void _logRejections(List<TopikContentIssue> issues) {
    final logged = <String>{};
    for (final issue in issues) {
      if (!issue.isError || !logged.add(issue.testId)) continue;
      appLogger.warning(
        'topik.content_rejected',
        category: LogCategory.state,
        context: {
          'testId': issue.testId,
          'rule': issue.rule.name,
          'detail': issue.detail,
        },
      );
    }
  }
}
```

`lib/features/topik/di/topik_content_repository_provider.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:memox/features/topik/data/datasources/topik_content_asset_data_source.dart';
import 'package:memox/features/topik/data/repositories/topik_content_repository_impl.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_content_repository_provider.g.dart';

/// The bundled TOPIK content, parsed once per app run (spec §13.4, owner
/// approval 2026-10-15): kept alive because the content never changes while
/// the app runs.
@Riverpod(keepAlive: true)
TopikContentRepository topikContentRepository(Ref ref) =>
    TopikContentRepositoryImpl(
      load: TopikContentAssetDataSource(
        rootBundle,
        assetPaths: () async =>
            (await AssetManifest.loadFromAssetBundle(rootBundle))
                .listAssets()
                .toSet(),
      ).load,
    );
```

Then run: `dart run build_runner build --delete-conflicting-outputs`
Expected: writes `lib/features/topik/di/topik_content_repository_provider.g.dart` (gitignored).

- [ ] **Step 4: Run test to verify it passes**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik test/architecture`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
dart format lib/features/topik test/features/topik
git add lib/features/topik test/features/topik
git commit -m "feat(topik): DEV-402 the content repository, read once per app run"
```

---

### Task 4: Declared asset folders, checked by the gate

**Files:**
- Modify: `pubspec.yaml` (`flutter.assets`: add `assets/topik/`)
- Modify: `tools/topik/topik_lint.dart` (optional declared-folder check; pubspec folder parser)
- Modify: `test/tools/topik_content_assets_test.dart` (pass the declared folders)
- Test: `test/tools/topik_lint_test.dart` (new cases)

**Interfaces:**
- Consumes: `lintTopikContent` (Task 1 version).
- Produces:
  - `TopikLintReport lintTopikContent({required Directory contentRoot, required Directory bundleRoot, Set<String>? declaredAssetFolders})` — when given, every pack's folder and every referenced asset's folder must be in the set (`assets` error otherwise).
  - `Set<String> declaredAssetFoldersOf(String pubspecYaml)` — the folder entries (ending in `/`) under `flutter: assets:`.

- [ ] **Step 1: Write the failing tests**

Append to `test/tools/topik_lint_test.dart`, inside `main()` after the last test:

```dart
  group('declared asset folders (spec §13.4)', () {
    test('a pack or audio folder not declared in pubspec fails', () {
      writePack('topik2/96/listening.json', topikTestJson(section: TopikSection.listening));
      writeManifest(['topik2/96/listening.json']);
      final report = lintTopikContent(
        contentRoot: content,
        bundleRoot: bundle,
        declaredAssetFolders: {'assets/topik/'},
      );
      expect(report.passes, isFalse);
      expect(
        report.issues.map((issue) => issue.detail).join('\n'),
        allOf(contains('assets/topik/topik2/96/'), contains('assets/topik/fixture/')),
      );
    });

    test('every folder declared passes', () {
      writePack('topik2/96/listening.json', topikTestJson(section: TopikSection.listening));
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
    expect(declaredAssetFoldersOf(yaml), {'assets/templates/', 'assets/topik/'});
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/tools/topik_lint_test.dart`
Expected: FAIL — `declaredAssetFolders` and `declaredAssetFoldersOf` do not exist.

- [ ] **Step 3: Implement the folder check and the parser**

In `tools/topik/topik_lint.dart`, change `lintTopikContent` to:

```dart
TopikLintReport lintTopikContent({
  required Directory contentRoot,
  required Directory bundleRoot,
  Set<String>? declaredAssetFolders,
}) {
  final fileIssues = <TopikContentIssue>[];
  final files = <TopikPackFile>[];
  final entries = _manifestEntries(contentRoot, fileIssues);
  for (final entry in entries) {
    final json = _decode(File('${contentRoot.path}/$entry'), entry, fileIssues);
    if (json == null) continue;
    files.add((origin: entry, json: json));
  }
  final load = topikContentOf(
    files,
    assetExists: (path) => File('${bundleRoot.path}/$path').existsSync(),
    fileIssues: fileIssues,
  );
  final folderIssues = declaredAssetFolders == null
      ? const <TopikContentIssue>[]
      : _undeclaredFolders(load, entries, declaredAssetFolders);
  return TopikLintReport(
    issues: [...load.issues, ...folderIssues],
    testCount: load.readCount,
  );
}

const String _bundleFolder = 'assets/topik/';

/// Flutter reads a declared folder's files, not its subfolders: every folder
/// holding a pack or an asset the packs name must be declared.
List<TopikContentIssue> _undeclaredFolders(
  TopikContentLoad load,
  List<String> entries,
  Set<String> declared,
) {
  final needed = <String, String>{
    _folderOf('$_bundleFolder$_manifestName'): _manifestName,
    for (final entry in entries) _folderOf('$_bundleFolder$entry'): entry,
    for (final test in load.accepted) ...{
      if (test.audioAsset case final audio?) _folderOf(audio): test.testId,
      for (final group in test.groups)
        if (group.passage?.image case final image?) _folderOf(image): test.testId,
      for (final question in test.questions)
        for (final option in question.options)
          if (option.image case final image?) _folderOf(image): test.testId,
    },
  };
  return [
    for (final MapEntry(key: folder, value: owner) in needed.entries)
      if (!declared.contains(folder))
        TopikContentIssue.error(
          TopikContentRule.assets,
          owner,
          'folder $folder is not declared in pubspec.yaml flutter.assets',
        ),
  ];
}

String _folderOf(String path) => path.substring(0, path.lastIndexOf('/') + 1);

/// The folder entries (ending in `/`) listed under `flutter: assets:`.
Set<String> declaredAssetFoldersOf(String pubspecYaml) {
  final folders = <String>{};
  var inAssets = false;
  for (final line in const LineSplitter().convert(pubspecYaml)) {
    final trimmed = line.trim();
    if (trimmed == 'assets:') {
      inAssets = true;
      continue;
    }
    if (!inAssets || trimmed.isEmpty || trimmed.startsWith('#')) continue;
    if (!trimmed.startsWith('- ')) {
      inAssets = false;
      continue;
    }
    final value = trimmed.substring(2).split('#').first.trim();
    if (value.endsWith('/')) folders.add(value);
  }
  return folders;
}
```

In `pubspec.yaml`, under `flutter: assets:` after `- assets/templates/en/`, add:

```yaml
    # The TOPIK content packs (ADR-023, spec §13.4); each pack and asset
    # folder is listed, and test/tools/topik_content_assets_test.dart checks it.
    - assets/topik/
```

Replace `test/tools/topik_content_assets_test.dart` with:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tools/topik/topik_lint.dart';

// BR-TOPIK-008, spec §13.4: no content pack that breaks a rule can merge,
// and every folder it needs is declared, so the app bundles what the gate saw.

void main() {
  test('every bundled TOPIK pack passes and every folder is declared', () {
    final report = lintTopikContent(
      contentRoot: Directory('assets/topik'),
      bundleRoot: Directory.current,
      declaredAssetFolders: declaredAssetFoldersOf(
        File('pubspec.yaml').readAsStringSync(),
      ),
    );
    expect(report.issues.where((issue) => issue.isError), isEmpty);
  });
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter pub get >/dev/null && bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/tools test/features/topik`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
dart format tools/topik test/tools
git add pubspec.yaml tools/topik test/tools
git commit -m "feat(topik): DEV-403 declare the TOPIK asset folder and check every needed folder"
```

---

### Task 5: Docs and the gate

**Files:**
- Modify: `docs/superpowers/specs/2026-10-15-topik-practice-design.md` (§4.3, §13.4)
- Modify: `docs/features/topik/README.md` (frontmatter `code:` gains `lib/features/topik/di`)
- Regenerate: `docs/_generated/`

- [ ] **Step 1: Align the spec**

In §13.4 replace `` `checkTopikTest` (asset existence from the `AssetManifest`) and `checkTopikCatalog`. Among
  duplicate ids the first valid one wins.`` with `` `checkTopikTest` through the shared pipeline `topikContentOf` (`data/mappers/topik_content_pack_mapper.dart`, asset existence from the `AssetManifest`). Among
  duplicate ids the first valid one wins; the lint runs the same pipeline.``, and replace `` `topikCatalogProvider` is `keepAlive` `` with `` `topikContentRepositoryProvider` is `keepAlive` and its implementation reads the packs once (a failed read is retried on the next call) ``.

In §4.3, after the sentence ending `prints every broken rule.`, add: `The gate test also requires every folder holding a pack or a referenced asset to be declared in `pubspec.yaml`, because Flutter does not read asset subfolders.`

- [ ] **Step 2: Update the README frontmatter**

Replace `code: [lib/features/topik/domain, lib/features/topik/data, tools/topik]` with `code: [lib/features/topik/domain, lib/features/topik/data, lib/features/topik/di, tools/topik]`.

- [ ] **Step 3: Regenerate and check docs**

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), 0 warning(s)`.

- [ ] **Step 4: Run the gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected: `✓ mechanical gates passed`.

- [ ] **Step 5: Commit**

```bash
git add docs
git commit -m "docs(topik): DEV-404 content loading as built"
```

## Out of this plan

- The use case and presentation provider that expose the catalog to screens 34–36 (plan 6, with the screens).
- The round-96 pack and its folders in `pubspec.yaml` (its own PR; Task 4's gate test will require them).
