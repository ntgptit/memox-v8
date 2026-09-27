import 'dart:convert';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:memox/features/starter_decks/data/mappers/starter_template_mapper.dart';
import 'package:memox/features/starter_decks/domain/models/starter_template_model.dart';

/// The starter templates bundled with the app (starter decks spec §5): the
/// manifest lists the template files, and each file is one template.
final class TemplateAssetDataSource {
  const TemplateAssetDataSource(this._bundle);

  final AssetBundle _bundle;

  static const manifestPath = 'assets/templates/manifest.json';
  static const _folder = 'assets/templates/';

  /// The templates that pass spec D6, in manifest order. A missing or
  /// malformed manifest is no template (UC-STARTER-001 E2); a missing,
  /// malformed or invalid file, or one whose id an earlier file has, is left
  /// out while the others load (E3). It never throws for content.
  Future<List<StarterTemplate>> load() async {
    final templates = <StarterTemplate>[];
    final ids = <String>{};
    for (final file in await _manifestFiles()) {
      final template = starterTemplateOf(await _jsonAt('$_folder$file'));
      if (template == null || !ids.add(template.templateId)) continue;
      templates.add(template);
    }
    return templates;
  }

  Future<List<String>> _manifestFiles() async {
    final json = await _jsonAt(manifestPath);
    if (json is! Map<String, Object?>) return const [];
    final files = json['templates'];
    if (files is! List<Object?>) return const [];
    return [
      for (final file in files)
        if (file is String) file,
    ];
  }

  /// The JSON of the asset at [path]; null when it is missing or is not JSON.
  Future<Object?> _jsonAt(String path) async {
    try {
      return jsonDecode(await _bundle.loadString(path));
    } on FlutterError {
      // A missing asset: the bundle says so with a FlutterError.
      return null;
    } on FormatException {
      return null;
    }
  }
}
