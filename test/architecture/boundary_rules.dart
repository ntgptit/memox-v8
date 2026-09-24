/// The folder and import rules of ADR-011, as pure functions over source
/// files. `boundary_rules_test.dart` proves each rule fires on a planted
/// violation; `boundaries_test.dart` applies them to the real `lib/`.
library;

import 'dart:io';

/// One Dart file under `lib/`: its repo-relative path and every URI it
/// imports or exports, resolved to `package:` form.
class SourceFile {
  const SourceFile(this.path, this.imports);

  final String path;
  final List<String> imports;
}

/// ADR-011 D2: the features each feature may import. Acyclic, with `srs`
/// at the base. A new feature adds its entry in the commit that creates it.
const allowedFeatureImports = <String, Set<String>>{
  'srs': {},
  'tags': {},
  'deck': {'srs'},
  'card': {'deck', 'srs', 'tags'},
};

const _package = 'package:memox/';
const _featuresPackage = 'package:memox/features/';

/// ADR-011 folder tree: the only folders directly under `lib/`.
const _topLevelFolders = {'app', 'core', 'features', 'l10n', 'shared'};

/// ADR-011 D1: the buckets of each layer. `di/` has none; it is flat.
const _layerBuckets = <String, Set<String>>{
  'domain': {'entities', 'models', 'repositories', 'failures', 'usecases'},
  'data': {'datasources', 'mappers', 'repositories', 'models'},
  'presentation': {'screens', 'controllers', 'states', 'providers', 'widgets'},
};

/// ADR-011 D8 (AD-15): the widget buckets, one level deep.
const _widgetBuckets = {'sections', 'items', 'overlays', 'support'};

/// ADR-011 D3: the domain buckets another feature may import.
const _publicDomainBuckets = {'entities', 'models', 'repositories', 'failures'};

/// ADR-011 dependency rules: what `domain/` never imports.
const _forbiddenInDomain = [
  'dart:ui',
  'package:flutter/',
  'package:flutter_riverpod/',
  'package:riverpod/',
  'package:riverpod_annotation/',
  'package:drift/',
  'package:drift_flutter/',
  'package:sqlite3/',
  'package:memox/app/',
  'package:memox/core/database/',
  'package:memox/shared/',
];

/// ADR-011 dependency rules: what `core/` never imports.
const _forbiddenInCore = [
  'package:memox/app/',
  'package:memox/features/',
  'package:memox/shared/',
];

final _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Reads every hand-written Dart file under `lib/` of [projectRoot], with
/// paths relative to it (`lib/...`). Generated `.g.dart` files are skipped.
List<SourceFile> readSources(Directory projectRoot) {
  final root = projectRoot.path.replaceAll(r'\', '/');
  final lib = Directory('$root/lib');
  if (!lib.existsSync()) return const [];
  final files = lib
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (file) => file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'),
      );
  return [
    for (final file in files)
      parseSource(
        file.path.replaceAll(r'\', '/').substring(root.length + 1),
        file.readAsStringSync(),
      ),
  ];
}

/// Collects the import and export URIs of [content], resolved against [path].
SourceFile parseSource(String path, String content) => SourceFile(path, [
  for (final match in _directive.allMatches(content))
    resolveImport(path, match.group(1)!),
]);

/// Resolves a relative [uri] written in [fromPath] (`lib/...`) to its
/// `package:memox/...` form, so a relative import is judged like the package
/// path it names. `dart:` and `package:` URIs are returned unchanged.
String resolveImport(String fromPath, String uri) {
  if (uri.startsWith('dart:') || uri.startsWith('package:')) return uri;
  final segments = fromPath.split('/')..removeLast();
  for (final part in uri.split('/')) {
    if (part == '.') continue;
    if (part != '..') {
      segments.add(part);
      continue;
    }
    if (segments.isNotEmpty) segments.removeLast();
  }
  if (segments.isEmpty || segments.first != 'lib') return segments.join('/');
  return '$_package${segments.skip(1).join('/')}';
}

/// ADR-011 D1, D11: every file sits where the layout allows it.
List<String> shapeViolations(List<SourceFile> sources) => [
  for (final source in sources)
    if (_shapeProblem(source.path) case final problem?)
      '${source.path}: $problem',
];

/// ADR-011 dependency rules: `domain/` is plain Dart and reaches no
/// other layer.
List<String> domainPurityViolations(List<SourceFile> sources) => [
  for (final source in sources)
    if (_layerOf(source.path) == 'domain')
      for (final uri in source.imports)
        if (_isForbiddenInDomain(uri)) '${source.path} imports $uri',
];

/// ADR-011 D2–D3: another feature is reached only through its public
/// domain buckets (or its `di/`, from `presentation/` and `di/`), and only
/// along an edge of [allowed].
List<String> crossFeatureViolations(
  List<SourceFile> sources, {
  Map<String, Set<String>> allowed = allowedFeatureImports,
}) {
  final violations = <String>[];
  for (final source in sources) {
    final own = _featureOf(source.path);
    if (own == null) continue;
    for (final uri in source.imports) {
      final problem = _crossFeatureProblem(source.path, own, uri, allowed);
      if (problem == null) continue;
      violations.add('${source.path} imports $uri: $problem');
    }
  }
  return violations;
}

/// ADR-011 dependency rules: `core/` knows no feature, no `app/` and no
/// `shared/`.
List<String> coreViolations(List<SourceFile> sources) => [
  for (final source in sources)
    if (source.path.startsWith('lib/core/'))
      for (final uri in source.imports)
        if (_forbiddenInCore.any(uri.startsWith)) '${source.path} imports $uri',
];

/// ADR-011 D2: every cycle in [map], each written as `a -> b -> a`.
List<String> cyclesIn(Map<String, Set<String>> map) {
  final cycles = <String>[];
  final done = <String>{};

  void visit(String node, List<String> stack) {
    final start = stack.indexOf(node);
    if (start >= 0) {
      cycles.add([...stack.sublist(start), node].join(' -> '));
      return;
    }
    if (done.contains(node)) return;
    for (final next in map[node] ?? const <String>{}) {
      visit(next, [...stack, node]);
    }
    done.add(node);
  }

  for (final node in map.keys) {
    visit(node, const []);
  }
  return cycles;
}

/// `lib/features/<f>/...` -> `<f>`, otherwise null.
String? _featureOf(String path) {
  const prefix = 'lib/features/';
  if (!path.startsWith(prefix)) return null;
  return path.substring(prefix.length).split('/').first;
}

/// `lib/features/<f>/<layer>/...` -> `<layer>`, otherwise null.
String? _layerOf(String path) {
  final feature = _featureOf(path);
  if (feature == null) return null;
  final below = path.substring('lib/features/$feature/'.length).split('/');
  return below.length > 1 ? below.first : null;
}

String? _shapeProblem(String path) {
  final parts = path.split('/');
  if (parts.length == 2) {
    return parts[1] == 'main.dart' ? null : 'only main.dart sits in lib/';
  }
  final top = parts[1];
  if (!_topLevelFolders.contains(top)) return 'lib/$top/ is not in ADR-011';
  if (top == 'core' && parts.length == 3) return 'core/ holds concern folders';
  if (top != 'features') return null;
  return _featureShapeProblem(parts.sublist(2));
}

/// [parts] is the path below `lib/features/`: `<f>/<layer>/...`.
String? _featureShapeProblem(List<String> parts) {
  if (parts.length < 3) return 'a feature root holds no file';
  final layer = parts[1];
  if (layer == 'di') return parts.length == 3 ? null : 'di/ is flat';
  final buckets = _layerBuckets[layer];
  if (buckets == null) return '$layer/ is not a layer';
  if (parts.length == 3) return 'a file sits directly in $layer/';
  final bucket = parts[2];
  if (!buckets.contains(bucket)) return '$layer/$bucket/ is not a bucket';
  if (bucket == 'widgets') return _widgetShapeProblem(parts.sublist(3));
  return parts.length == 4 ? null : '$layer/$bucket/ is one level deep';
}

/// [parts] is the path below `presentation/widgets/`.
String? _widgetShapeProblem(List<String> parts) {
  if (parts.length < 2) return 'a file sits directly in widgets/';
  if (!_widgetBuckets.contains(parts.first)) {
    return 'widgets/${parts.first}/ is not an AD-15 bucket';
  }
  return parts.length == 2 ? null : 'widget buckets are one level deep';
}

bool _isForbiddenInDomain(String uri) {
  if (_forbiddenInDomain.any(uri.startsWith)) return true;
  final target = _featureTarget(uri);
  return target != null && target.layer != 'domain';
}

String? _crossFeatureProblem(
  String path,
  String own,
  String uri,
  Map<String, Set<String>> allowed,
) {
  final target = _featureTarget(uri);
  if (target == null || target.feature == own) return null;
  if (!(allowed[own] ?? const <String>{}).contains(target.feature)) {
    return '$own may not depend on ${target.feature}';
  }
  final isPublicDomain =
      target.layer == 'domain' && _publicDomainBuckets.contains(target.bucket);
  if (isPublicDomain) return null;
  final ownLayer = _layerOf(path);
  final mayUseDi = ownLayer == 'presentation' || ownLayer == 'di';
  if (target.layer == 'di' && mayUseDi) return null;
  return 'import only its domain/{entities,models,repositories,failures}/, '
      'or its di/ from presentation/ and di/';
}

/// `package:memox/features/<f>/<layer>/<bucket>/...` split into its parts.
({String feature, String layer, String? bucket})? _featureTarget(String uri) {
  if (!uri.startsWith(_featuresPackage)) return null;
  final parts = uri.substring(_featuresPackage.length).split('/');
  if (parts.length < 3) return (feature: parts.first, layer: '', bucket: null);
  final bucket = parts.length > 3 ? parts[2] : null;
  return (feature: parts[0], layer: parts[1], bucket: bucket);
}
