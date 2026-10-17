// Symbol-aware ForUI boundary rules (UIL00..UIL06, ADR-025). A symbol counts
// by the library its element comes from (package:flutter/, package:material_ui/
// or package:forui/), so an import alias or a local function with a Flutter
// name changes nothing. The rule table is in docs/forui-migration/FORUI_ARCHITECTURE.md.
//
//   UIL00  an allowlist entry that covers nothing, or whose review has passed
//   UIL01  an overlay opened outside the shared Mx overlay adapters
//   UIL02  a Cupertino or `.adaptive` substitute (Android, ForUI only)
//   UIL03  a Material import outside the approved infrastructure names
//   UIL04  a barrier, scrim or surface-tint argument outside lib/core/theme/
//   UIL05  a theme built outside lib/core/theme/, or a runtime seed scheme
//   UIL06  package:forui imported outside lib/core/theme/, lib/shared/, lib/app/
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/line_info.dart';

const String _flutterUriPrefix = 'package:flutter/';
const String _materialUiUriPrefix = 'package:material_ui/';
const String _foruiUriPrefix = 'package:forui/';
const String _themeOwnerPrefix = 'lib/core/theme/';
const String _unresolvedUriCode = 'uri_does_not_exist';

/// The files that may open an overlay route: the shared adapters every
/// feature goes through (showMxDialog, showMxBottomSheet, showMxSnackbar).
const Set<String> _overlayAdapters = {
  'lib/shared/widgets/mx_bottom_sheet.dart',
  'lib/shared/widgets/mx_dialog.dart',
  'lib/shared/widgets/mx_held_route.dart',
  'lib/shared/widgets/mx_snackbar.dart',
};

const Set<String> _overlayFunctions = {
  'showAboutDialog',
  'showBottomSheet',
  'showDatePicker',
  'showDialog',
  'showFDialog',
  'showFPersistentSheet',
  'showFSheet',
  'showFToast',
  'showGeneralDialog',
  'showLicensePage',
  'showMenu',
  'showModalBottomSheet',
  'showRawDialog',
  'showRawFToast',
  'showSearch',
  'showTimePicker',
};
const Set<String> _overlayRoutes = {
  'DialogRoute',
  'FDialogRoute',
  'FModalSheetRoute',
  'ModalBottomSheetRoute',
  'RawDialogRoute',
};
const Set<String> _overlayBaseRoutes = {'ModalRoute', 'PopupRoute'};
const Set<String> _messengerOverlays = {'showMaterialBanner', 'showSnackBar'};

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

/// The Material names lib/ may import, each with the path prefix it is
/// limited to (empty: anywhere). They are infrastructure ForUI does not
/// replace: the app host, page routes, motion constants, platform widgets
/// with no ForUI counterpart, and the material_ui types ForUI's own API takes.
const Map<String, String> _materialInfrastructure = {
  'Durations': '',
  'Easing': '',
  'FloatingActionButtonLocation': 'lib/shared/widgets/mx_app_shell.dart',
  'InputBorder': 'lib/shared/widgets/',
  'MaterialApp': 'lib/app/',
  'MaterialLocalizations': '',
  'MaterialPageRoute': '',
  'OutlineInputBorder': 'lib/shared/widgets/',
  'RefreshIndicator': '',
  'ReorderableListView': '',
  'Scaffold': 'lib/shared/widgets/mx_app_shell.dart',
  'ScaffoldPrelayoutGeometry': 'lib/shared/widgets/mx_app_shell.dart',
  'SelectableText': '',
  'SelectionArea': '',
  'ThemeExtension': 'lib/core/theme/',
  'ThemeMode': '',
  'TimeOfDay': '',
};

/// The files that bridge ForUI to the Material host and may import Material
/// whole (behind a prefix): the host theme and the theme host widget.
const Set<String> _materialHostFiles = {
  'lib/app/app_theme_host.dart',
  'lib/core/theme/app_theme.dart',
};

const Set<String> _foruiOwnerPrefixes = {
  'lib/app/',
  'lib/core/theme/',
  'lib/shared/',
};

const Set<String> _barrierArguments = {
  'barrierColor',
  'drawerScrimColor',
  'modalBarrierColor',
  'scrimColor',
  'surfaceTintColor',
};

const Set<String> _themeClasses = {
  'ColorScheme',
  'FColors',
  'FStyle',
  'FThemeData',
  'FTypeface',
  'FTypography',
  'TextTheme',
  'ThemeData',
  'Typography',
};

/// One finding. [rule] is UIL00..UIL06; [path] is relative to the lint root.
class UiViolation {
  const UiViolation({
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
  if (!_isStrictDate(review)) {
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

final RegExp _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// True for exactly `YYYY-MM-DD` naming a real calendar day.
bool _isStrictDate(String text) {
  if (!_datePattern.hasMatch(text)) return false;
  final parsed = DateTime.tryParse(text);
  return parsed != null && _dayOf(parsed) == text;
}

String _dayOf(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Lints [absolutePaths] and returns the violations the [allowlist] does not
/// cover, plus one UIL00 per allowlist entry that covered nothing and one per
/// entry whose review date is before [today] (the current day by default).
///
/// [partial] says [absolutePaths] are some of `lib/`, not all of it (the
/// changed files of `dod_check.sh --changed`): an entry is then stale only when
/// its file was linted, because an entry for a file left out covers nothing
/// here without being stale. Expiry is checked for every entry either way.
Future<List<UiViolation>> lintPaths(
  List<String> absolutePaths, {
  required String root,
  required List<AllowEntry> allowlist,
  DateTime? today,
  bool partial = false,
}) async {
  final linted = partial
      ? {for (final path in absolutePaths) relativeToRoot(path, root)}
      : null;
  final found = <UiViolation>[];
  if (absolutePaths.isEmpty) {
    return applyAllowlist(found, allowlist, today: today, linted: linted);
  }
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
      final visitor = _UiVisitor(
        relativePath: relativeToRoot(path, root),
        lineInfo: result.lineInfo,
        out: found,
      );
      result.unit.accept(visitor);
    }
  } finally {
    await collection.dispose();
  }
  return applyAllowlist(found, allowlist, today: today, linted: linted);
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
/// compares equal to the allowlist's `file` and to the owner paths below.
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
/// separator the entry was written with) and adds an UIL00 per entry that
/// covered nothing, and one per entry whose `review` day is before [today]
/// (the current day by default; an entry reviewed today is still valid).
/// [linted] (root-relative, `/` separators) limits the stale check to the
/// entries of those files; null means the whole of `lib/` was linted.
List<UiViolation> applyAllowlist(
  List<UiViolation> found,
  List<AllowEntry> allowlist, {
  DateTime? today,
  Set<String>? linted,
}) {
  final day = _dayOf(today ?? DateTime.now());
  bool covers(AllowEntry e, UiViolation v) =>
      _slashes(e.file) == v.path && e.rule == v.rule;
  final kept = [
    for (final v in found)
      if (!allowlist.any((e) => covers(e, v))) v,
  ];
  final stale = [
    for (final e in allowlist)
      if ((linted == null || linted.contains(_slashes(e.file))) &&
          !found.any((v) => covers(e, v)))
        UiViolation(
          rule: 'UIL00',
          path: e.file,
          line: 0,
          message: 'stale allowlist entry for ${e.rule}',
        ),
  ];
  final expired = [
    for (final e in allowlist)
      if (e.review.compareTo(day) < 0)
        UiViolation(
          rule: 'UIL00',
          path: e.file,
          line: 0,
          message:
              'allowlist entry for ${e.rule} expired: review was due '
              '${e.review}',
        ),
  ];
  return [...kept, ...stale, ...expired];
}

/// What an invocation resolved to: the class that owns it (if any), its
/// name, the library it comes from, and whether it makes a new object (a
/// constructor or a static factory). A constructor without a name is `new`.
typedef _Callee = ({String? owner, String name, String uri, bool creates});

class _UiVisitor extends RecursiveAstVisitor<void> {
  _UiVisitor({
    required this.relativePath,
    required this.lineInfo,
    required this.out,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<UiViolation> out;
  final Set<String> _seen = {};

  bool get _inThemeOwner => relativePath.startsWith(_themeOwnerPrefix);

  bool get _isOverlayAdapter => _overlayAdapters.contains(relativePath);

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue ?? '';
    _checkMaterialImport(node, uri);
    _checkForuiImport(node, uri);
    super.visitImportDirective(node);
  }

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
      if (!_fromUiLibrary(element) || _isOverlayAdapter) continue;
      final name = element?.name;
      if (!_overlayBaseRoutes.contains(name) &&
          !_overlayRoutes.contains(name)) {
        continue;
      }
      _report(
        'UIL01',
        type.offset,
        'class ${node.declaredFragment?.name} builds on $name; '
            'open overlays through the shared Mx adapters',
      );
    }
    super.visitClassDeclaration(node);
  }

  void _checkMaterialImport(ImportDirective node, String uri) {
    if (!_isMaterialUri(uri)) return;
    if (_materialHostFiles.contains(relativePath)) return;
    if (uri.startsWith('package:flutter/src/') ||
        uri.contains('/src/') ||
        node.prefix != null) {
      _report(
        'UIL03',
        node.offset,
        '$uri: import Material through a `show` list of infrastructure names',
      );
      return;
    }
    final shown = [
      for (final combinator in node.combinators)
        if (combinator is ShowCombinator)
          for (final name in combinator.shownNames) name,
    ];
    if (shown.isEmpty) {
      _report(
        'UIL03',
        node.offset,
        '$uri without `show`; ForUI and the Mx widgets draw the UI (ADR-025)',
      );
      return;
    }
    for (final name in shown) {
      final scope = _materialInfrastructure[name.name];
      if (scope != null && relativePath.startsWith(scope)) continue;
      _report(
        'UIL03',
        name.offset,
        scope == null
            ? '${name.name} is a Material component; use ForUI or an Mx widget'
            : '${name.name} belongs to $scope only',
      );
    }
  }

  void _checkForuiImport(ImportDirective node, String uri) {
    if (!uri.startsWith(_foruiUriPrefix)) return;
    if (_foruiOwnerPrefixes.any(relativePath.startsWith)) return;
    _report(
      'UIL06',
      node.offset,
      '$uri outside lib/core/theme, lib/shared and lib/app; '
          'features use the Mx widgets',
    );
  }

  void _checkCall(AstNode node, Element? element, ArgumentList args) {
    final callee = _calleeOf(element);
    final named = <String, Expression>{
      for (final arg in args.arguments)
        if (arg is NamedArgument) arg.name.lexeme: arg.argumentExpression,
    };
    if (callee != null) {
      _checkOverlay(node, callee);
      _checkCupertino(node, callee);
      _checkTheme(node, callee, named);
    }
    _checkArguments(node, named);
  }

  void _checkOverlay(AstNode node, _Callee callee) {
    if (_isOverlayAdapter) return;
    final owner = callee.owner;
    final isFunction = owner == null && _overlayFunctions.contains(callee.name);
    final isRoute = _overlayRoutes.contains(owner) && callee.creates;
    final isMessenger =
        owner == 'ScaffoldMessengerState' &&
        _messengerOverlays.contains(callee.name);
    if (!isFunction && !isRoute && !isMessenger) return;
    _report(
      'UIL01',
      node.offset,
      '${owner ?? callee.name} bypasses the shared Mx overlay adapters',
    );
  }

  void _checkCupertino(AstNode node, _Callee callee) {
    final owner = callee.owner;
    final isFunction =
        owner == null && _cupertinoFunctions.contains(callee.name);
    final isClass = _cupertinoClasses.contains(owner);
    final isAdaptive = callee.name == 'adaptive' && _isMaterialUri(callee.uri);
    if (!isFunction && !isClass && !isAdaptive) return;
    _report(
      'UIL02',
      node.offset,
      '${owner ?? callee.name}${isAdaptive ? '.adaptive' : ''} is a '
          'Cupertino or adaptive substitute; Android, ForUI only (ADR-025)',
    );
  }

  void _checkArguments(AstNode node, Map<String, Expression> named) {
    if (named.containsKey('colorSchemeSeed')) {
      _report('UIL05', node.offset, 'colorSchemeSeed builds a runtime scheme');
    }
    if (_inThemeOwner) return;
    for (final name in named.keys.where(_barrierArguments.contains)) {
      _report('UIL04', node.offset, '$name: belongs to lib/core/theme/');
    }
  }

  void _checkTheme(
    AstNode node,
    _Callee callee,
    Map<String, Expression> named,
  ) {
    final owner = callee.owner;
    if (!_themeClasses.contains(owner)) return;
    if (owner == 'ThemeData' && named.containsKey('platform')) {
      _report('UIL05', node.offset, 'ThemeData(platform:) changes behaviour');
      return;
    }
    if (callee.name == 'fromSeed' || callee.name == 'fromImageProvider') {
      _report(
        'UIL05',
        node.offset,
        '$owner.${callee.name} builds a runtime scheme; '
            'the palette is app_palette.dart',
      );
      return;
    }
    if (_inThemeOwner || !callee.creates) return;
    _report(
      'UIL05',
      node.offset,
      '$owner is built in lib/core/theme/ only; read the theme instead',
    );
  }

  void _report(String rule, int offset, String message) {
    if (!_seen.add('$rule@$offset')) return;
    out.add(
      UiViolation(
        rule: rule,
        path: relativePath,
        line: lineInfo.getLocation(offset).lineNumber,
        message: message,
      ),
    );
  }
}

bool _isMaterialUri(String uri) =>
    uri.startsWith('package:flutter/material.dart') ||
    uri.startsWith('package:flutter/src/material/') ||
    uri.startsWith(_materialUiUriPrefix);

String _libraryOf(Element? element) => element?.library?.uri.toString() ?? '';

bool _fromUiLibrary(Element? element) {
  final uri = _libraryOf(element);
  return uri.startsWith(_flutterUriPrefix) ||
      uri.startsWith(_materialUiUriPrefix) ||
      uri.startsWith(_foruiUriPrefix);
}

_Callee? _calleeOf(Element? element) {
  if (element is! ExecutableElement || !_fromUiLibrary(element)) return null;
  final name = element.name;
  if (name == null) return null;
  final enclosing = element.enclosingElement;
  return (
    owner: enclosing is InterfaceElement ? enclosing.name : null,
    name: name,
    uri: _libraryOf(element),
    creates: element is ConstructorElement || element.isStatic,
  );
}
