// Symbol-aware Material 3 rules (M3L00..M3L08). A symbol counts only when its
// element comes from package:flutter/, so a local function named like a
// Flutter one, or an import alias, changes nothing. The rule table is in
// docs/shared/design/m3-adoption-ledger.md §7.
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/line_info.dart';

const String _flutterUriPrefix = 'package:flutter/';
const String _flutterMaterialUriPrefix = 'package:flutter/src/material/';
const String _themeOwnerPrefix = 'lib/core/theme/';
const String _unresolvedUriCode = 'uri_does_not_exist';

const Set<String> _overlayFunctions = {'showGeneralDialog', 'showRawDialog'};
const Set<String> _overlayRoutes = {
  'DialogRoute',
  'RawDialogRoute',
  'ModalBottomSheetRoute',
};
const Set<String> _overlayBaseRoutes = {'ModalRoute', 'PopupRoute'};

const Set<String> _cupertinoFunctions = {
  'showAdaptiveDialog',
  'showCupertinoDialog',
  'showCupertinoModalPopup',
  'showCupertinoSheet',
};
const Set<String> _cupertinoClasses = {
  'CupertinoDialogRoute',
  'CupertinoModalPopupRoute',
  'CupertinoSheetRoute',
  'CupertinoSwitch',
  'CupertinoCheckbox',
  'CupertinoRadio',
  'CupertinoSlider',
  'CupertinoAlertDialog',
  'CupertinoActivityIndicator',
};

const Set<String> _barrierArguments = {
  'barrierColor',
  'modalBarrierColor',
  'scrimColor',
  'surfaceTintColor',
};
const Set<String> _appBarClasses = {'AppBarTheme', 'AppBarThemeData', 'AppBar'};
const Set<String> _appBarThemeClasses = {'AppBarTheme', 'AppBarThemeData'};

/// One finding. [rule] is M3L00..M3L08; [path] is relative to the lint root.
class M3Violation {
  const M3Violation({
    required this.rule,
    required this.path,
    required this.line,
    required this.message,
  });

  final String rule;
  final String path;
  final int line;
  final String message;

  @override
  String toString() => '$path:$line $rule $message';
}

/// An exemption for one rule in one file. All five fields are required.
class AllowEntry {
  const AllowEntry({
    required this.file,
    required this.rule,
    required this.reason,
    required this.owner,
    required this.review,
  });

  final String file;
  final String rule;
  final String reason;
  final String owner;
  final String review;
}

/// Reads the allowlist JSON. Throws [FormatException] when the document is
/// not a list of objects or any field is missing, empty or malformed.
List<AllowEntry> loadAllowlist(String jsonPath) {
  final decoded = jsonDecode(File(jsonPath).readAsStringSync());
  if (decoded is! List<Object?>) {
    throw const FormatException('the allowlist must be a JSON list');
  }
  return [for (final (index, raw) in decoded.indexed) _entryFrom(index, raw)];
}

AllowEntry _entryFrom(int index, Object? raw) {
  if (raw is! Map<String, Object?>) {
    throw FormatException('allowlist entry $index is not an object');
  }
  String field(String key) {
    final value = raw[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('allowlist entry $index has no "$key"');
  }

  final review = field('review');
  if (DateTime.tryParse(review) == null) {
    throw FormatException(
      'allowlist entry $index: "review" is not a YYYY-MM-DD date',
    );
  }
  return AllowEntry(
    file: field('file'),
    rule: field('rule'),
    reason: field('reason'),
    owner: field('owner'),
    review: review,
  );
}

/// Lints [absolutePaths] and returns the violations the [allowlist] does not
/// cover, plus one M3L00 per allowlist entry that covered nothing.
Future<List<M3Violation>> lintPaths(
  List<String> absolutePaths, {
  required String root,
  required List<AllowEntry> allowlist,
}) async {
  final found = <M3Violation>[];
  final collection = AnalysisContextCollection(
    includedPaths: absolutePaths,
    resourceProvider: PhysicalResourceProvider.INSTANCE,
    sdkPath: _dartSdkPath(),
  );
  try {
    for (final path in absolutePaths) {
      final session = collection.contextFor(path).currentSession;
      final result = await session.getResolvedUnit(path);
      if (result is! ResolvedUnitResult) {
        throw StateError('could not resolve $path');
      }
      _requireResolvedImports(result, path);
      final visitor = _M3Visitor(
        relativePath: relativeToRoot(path, root),
        lineInfo: result.lineInfo,
        out: found,
      );
      result.unit.accept(visitor);
    }
  } finally {
    await collection.dispose();
  }
  return applyAllowlist(found, allowlist);
}

// `dart run` finds its SDK by itself; `flutter test` runs inside
// flutter_tester, which has none beside it, so the SDK is looked up from
// FLUTTER_ROOT and then from `dart` on PATH.
String? _dartSdkPath() {
  bool isSdk(String dir) => Directory('$dir/lib/_internal').existsSync();
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final candidates = [
    File(Platform.resolvedExecutable).parent.parent.path,
    if (flutterRoot != null) '$flutterRoot/bin/cache/dart-sdk',
    for (final dir in (Platform.environment['PATH'] ?? '').split(
      Platform.isWindows ? ';' : ':',
    ))
      if (File('$dir/dart').existsSync())
        File('$dir/dart')
            .resolveSymbolicLinksSync()
            .replaceFirst(RegExp(r'[\\/]bin[\\/]dart$'), ''),
  ];
  return candidates.where(isSdk).firstOrNull;
}

// An import that does not resolve leaves every symbol from it without an
// element, which would read as a clean file.
void _requireResolvedImports(ResolvedUnitResult result, String path) {
  for (final diagnostic in result.diagnostics) {
    if (diagnostic.diagnosticCode.lowerCaseName != _unresolvedUriCode) continue;
    throw StateError('$path has an import that does not resolve');
  }
}

/// [path] relative to [root], with `/` separators on every platform, so it
/// compares equal to the allowlist's `file` and to `lib/core/theme/`.
String relativeToRoot(String path, String root) {
  final slashed = _slashes(path);
  final base = _slashes(root);
  final prefix = base.endsWith('/') ? base : '$base/';
  return slashed.startsWith(prefix)
      ? slashed.substring(prefix.length)
      : slashed;
}

String _slashes(String path) => path.replaceAll(r'\', '/');

/// Drops the violations an entry covers (same file and rule, whatever the
/// separator the entry was written with) and adds an M3L00 per entry that
/// covered nothing.
List<M3Violation> applyAllowlist(
  List<M3Violation> found,
  List<AllowEntry> allowlist,
) {
  bool covers(AllowEntry e, M3Violation v) =>
      _slashes(e.file) == v.path && e.rule == v.rule;
  final kept = [
    for (final v in found)
      if (!allowlist.any((e) => covers(e, v))) v,
  ];
  final stale = [
    for (final e in allowlist)
      if (!found.any((v) => covers(e, v)))
        M3Violation(
          rule: 'M3L00',
          path: e.file,
          line: 0,
          message: 'stale allowlist entry for ${e.rule}',
        ),
  ];
  return [...kept, ...stale];
}

/// What an invocation resolved to: the Flutter class that owns it (if any)
/// and its name. A constructor without a name is called `new`.
typedef _Callee = ({String? owner, String name});

class _M3Visitor extends RecursiveAstVisitor<void> {
  _M3Visitor({
    required this.relativePath,
    required this.lineInfo,
    required this.out,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<M3Violation> out;
  final Set<String> _seen = {};

  bool get _inThemeOwner => relativePath.startsWith(_themeOwnerPrefix);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _checkCall(node, node.constructorName.element, node.argumentList);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _checkCall(node, node.methodName.element, node.argumentList);
    super.visitMethodInvocation(node);
  }

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    _checkCall(node, node.element, node.argumentList);
    super.visitDotShorthandConstructorInvocation(node);
  }

  @override
  void visitDotShorthandInvocation(DotShorthandInvocation node) {
    _checkCall(node, node.memberName.element, node.argumentList);
    super.visitDotShorthandInvocation(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final supers = [
      ?node.extendsClause?.superclass,
      ...?node.implementsClause?.interfaces,
    ];
    for (final type in supers) {
      final element = type.element;
      if (!_fromFlutter(element)) continue;
      if (!_overlayBaseRoutes.contains(element?.name)) continue;
      _report(
        'M3L01',
        type.offset,
        'class ${node.declaredFragment?.name} builds on ${element?.name}; '
            'open overlays through the shared Mx adapters',
      );
    }
    super.visitClassDeclaration(node);
  }

  void _checkCall(AstNode node, Element? element, ArgumentList args) {
    final callee = _calleeOf(element);
    final named = <String, Expression>{
      for (final arg in args.arguments)
        if (arg is NamedArgument) arg.name.lexeme: arg.argumentExpression,
    };
    if (callee != null) {
      _checkOverlay(node, callee);
      _checkCupertino(node, element, callee);
      _checkColorScheme(node, callee);
      _checkTheme(node, callee, named);
      _checkAppBar(node, callee, named);
    }
    _checkScaffold(node, callee, named);
    _checkArguments(node, named);
  }

  void _checkOverlay(AstNode node, _Callee callee) {
    final owner = callee.owner;
    final isFunction = owner == null && _overlayFunctions.contains(callee.name);
    if (!isFunction && !_overlayRoutes.contains(owner)) return;
    _report(
      'M3L01',
      node.offset,
      '${owner ?? callee.name} bypasses the shared Mx overlay adapters',
    );
  }

  void _checkCupertino(AstNode node, Element? element, _Callee callee) {
    final owner = callee.owner;
    final isFunction =
        owner == null && _cupertinoFunctions.contains(callee.name);
    final isClass = _cupertinoClasses.contains(owner);
    final isAdaptive =
        callee.name == 'adaptive' &&
        (element?.library?.uri.toString().startsWith(
              _flutterMaterialUriPrefix,
            ) ??
            false);
    if (!isFunction && !isClass && !isAdaptive) return;
    _report(
      'M3L02',
      node.offset,
      '${owner ?? callee.name}${isAdaptive ? '.adaptive' : ''} is a '
          'Cupertino or adaptive substitute; Material 3 only (ADR-001)',
    );
  }

  void _checkScaffold(
    AstNode node,
    _Callee? callee,
    Map<String, Expression> named,
  ) {
    if (callee?.owner != 'Scaffold') return;
    if (!named.containsKey('drawerScrimColor')) return;
    _report(
      'M3L03',
      node.offset,
      'Scaffold.drawerScrimColor overrides the theme',
    );
  }

  void _checkArguments(AstNode node, Map<String, Expression> named) {
    if (named.containsKey('colorSchemeSeed')) {
      _report('M3L06', node.offset, 'colorSchemeSeed builds a runtime scheme');
    }
    if (_inThemeOwner) return;
    for (final name in named.keys.where(_barrierArguments.contains)) {
      _report('M3L04', node.offset, '$name: belongs to lib/core/theme/');
    }
  }

  void _checkTheme(
    AstNode node,
    _Callee callee,
    Map<String, Expression> named,
  ) {
    final isThemeData =
        callee.owner == 'ThemeData' && named.containsKey('platform');
    if (isThemeData) {
      _report(
        'M3L05',
        node.offset,
        'ThemeData(platform:) changes M3 behaviour',
      );
    }
  }

  void _checkColorScheme(AstNode node, _Callee callee) {
    if (callee.owner != 'ColorScheme') return;
    if (callee.name != 'fromSeed' && callee.name != 'fromImageProvider') return;
    _report(
      'M3L06',
      node.offset,
      'ColorScheme.${callee.name} builds a runtime scheme; '
          'the scheme comes from design/tokens.json',
    );
  }

  void _checkAppBar(
    AstNode node,
    _Callee callee,
    Map<String, Expression> named,
  ) {
    final owner = callee.owner;
    if (!_appBarClasses.contains(owner)) return;
    final hasIcons =
        named.containsKey('iconTheme') || named.containsKey('foregroundColor');
    if (hasIcons && !named.containsKey('actionsIconTheme')) {
      _report(
        'M3L07',
        node.offset,
        '$owner sets iconTheme or foregroundColor without actionsIconTheme',
      );
    }
    final background = named['backgroundColor'];
    if (background == null || !_appBarThemeClasses.contains(owner)) return;
    if (_isWidgetStateColorOrNull(background.staticType)) return;
    _report(
      'M3L08',
      background.offset,
      '$owner.backgroundColor must be a WidgetStateColor, '
          'not ${background.staticType}',
    );
  }

  void _report(String rule, int offset, String message) {
    if (!_seen.add('$rule@$offset')) return;
    out.add(
      M3Violation(
        rule: rule,
        path: relativePath,
        line: lineInfo.getLocation(offset).lineNumber,
        message: message,
      ),
    );
  }
}

bool _fromFlutter(Element? element) =>
    element?.library?.uri.toString().startsWith(_flutterUriPrefix) ?? false;

_Callee? _calleeOf(Element? element) {
  if (element is! ExecutableElement || !_fromFlutter(element)) return null;
  final name = element.name;
  if (name == null) return null;
  final enclosing = element.enclosingElement;
  return (
    owner: enclosing is InterfaceElement ? enclosing.name : null,
    name: name,
  );
}

bool _isWidgetStateColorOrNull(DartType? type) {
  if (type is! InterfaceType) return true;
  if (type.isDartCoreNull) return true;
  return [
    type,
    ...type.allSupertypes,
  ].any((t) => t.element.name == 'WidgetStateColor' && _fromFlutter(t.element));
}
