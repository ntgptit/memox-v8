import 'dart:convert';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/starter_decks/data/datasources/template_asset_data_source.dart';

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

const _manifest = 'assets/templates/manifest.json';

String _manifestOf(List<String> files) => jsonEncode({'templates': files});

/// A template file with [id] and one card.
String _templateOf(String id) => jsonEncode({
  'templateId': id,
  'version': 1,
  'locale': 'en',
  'title': 'Template $id',
  'contentSource': 'Development fixture',
  'frontLanguage': 'en',
  'backLanguage': 'vi',
  'defaultScheduler': 'sm2',
  'decks': [
    {
      'name': 'Deck',
      'cards': [
        {'front': 'hello', 'back': 'xin chào'},
      ],
    },
  ],
});

Future<List<String>> _loadedIds(Map<String, String> files) async => [
  for (final template in await TemplateAssetDataSource(_Bundle(files)).load())
    template.templateId,
];

void main() {
  test('the templates load in the order of the manifest', () async {
    expect(
      await _loadedIds({
        _manifest: _manifestOf(['b.json', 'a.json']),
        'assets/templates/a.json': _templateOf('a'),
        'assets/templates/b.json': _templateOf('b'),
      }),
      ['b', 'a'],
    );
  });

  test(
    'a missing or malformed manifest is no template (UC-STARTER-001 E2)',
    () async {
      final template = {'assets/templates/a.json': _templateOf('a')};

      expect(await _loadedIds(template), isEmpty);
      expect(await _loadedIds({...template, _manifest: 'not json'}), isEmpty);
      expect(
        await _loadedIds({...template, _manifest: '{"templates": "a.json"}'}),
        isEmpty,
      );
    },
  );

  test('a missing, malformed or invalid file is left out and the others '
      'load (UC-STARTER-001 E3)', () async {
    expect(
      await _loadedIds({
        _manifest: _manifestOf([
          'missing.json',
          'malformed.json',
          'invalid.json',
          'good.json',
        ]),
        'assets/templates/malformed.json': '{"templateId": ',
        'assets/templates/invalid.json': '{"templateId": "invalid"}',
        'assets/templates/good.json': _templateOf('good'),
      }),
      ['good'],
    );
  });

  test('a file whose id an earlier file has is left out (spec D6)', () async {
    final templates = await TemplateAssetDataSource(
      _Bundle({
        _manifest: _manifestOf(['first.json', 'second.json']),
        'assets/templates/first.json': _templateOf('same'),
        'assets/templates/second.json': _templateOf('same')
            .replaceFirst('Template same', 'Another title'),
      }),
    ).load();

    expect([for (final t in templates) t.title], ['Template same']);
  });
}
