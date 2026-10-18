import 'dart:io';

/// Every Dart file under `lib/` as repo-relative path → text, for the rules
/// that read the source as text. The generated `.g.dart` files are left out
/// unless [includeGenerated] says otherwise.
Map<String, String> readLibSources({bool includeGenerated = false}) => {
  for (final file in Directory(
    'lib',
  ).listSync(recursive: true).whereType<File>())
    if (file.path.endsWith('.dart') &&
        (includeGenerated || !file.path.endsWith('.g.dart')))
      file.path.replaceAll(r'\', '/'): file.readAsStringSync(),
};
