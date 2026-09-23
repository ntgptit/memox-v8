import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'boundary_rules.dart';

/// A source file whose imports are written the way a developer would, then
/// resolved the way the rules see them.
SourceFile _file(String path, [List<String> imports = const []]) =>
    SourceFile(path, [for (final uri in imports) resolveImport(path, uri)]);

void main() {
  group('shape', () {
    test('the ADR-011 layout passes', () {
      final sources = [
        _file('lib/main.dart'),
        _file('lib/app/app.dart'),
        _file('lib/app/router/app_router.dart'),
        _file('lib/core/error/outcome.dart'),
        _file('lib/features/deck/domain/entities/deck_entity.dart'),
        _file('lib/features/deck/data/repositories/deck_repository_impl.dart'),
        _file('lib/features/deck/di/deck_repository_provider.dart'),
        _file('lib/features/deck/presentation/screens/deck_list_screen.dart'),
        _file(
          'lib/features/deck/presentation/widgets/items/deck_tile_widget.dart',
        ),
      ];

      expect(shapeViolations(sources), isEmpty);
    });

    test('a barrel at the feature root is rejected', () {
      final sources = [_file('lib/features/deck/deck.dart')];

      expect(shapeViolations(sources), hasLength(1));
    });

    test('a file directly in a layer folder is rejected', () {
      final sources = [_file('lib/features/deck/domain/deck.dart')];

      expect(shapeViolations(sources), hasLength(1));
    });

    test('an unknown layer, bucket or top-level folder is rejected', () {
      final sources = [
        _file('lib/features/deck/logic/deck_rules.dart'),
        _file('lib/features/deck/domain/rules/deck_rule.dart'),
        _file('lib/utils/strings.dart'),
      ];

      expect(shapeViolations(sources), hasLength(3));
    });

    test('a widget sits one level deep in an AD-15 bucket', () {
      const widgets = 'lib/features/deck/presentation/widgets';
      final sources = [
        _file('$widgets/deck_tile_widget.dart'),
        _file('$widgets/rows/deck_tile_widget.dart'),
        _file('$widgets/items/tile/deck_tile_widget.dart'),
      ];

      expect(shapeViolations(sources), hasLength(3));
    });

    test('core/ holds concern folders, not loose files', () {
      final sources = [_file('lib/core/outcome.dart')];

      expect(shapeViolations(sources), hasLength(1));
    });

    test('di/ is flat', () {
      final sources = [_file('lib/features/deck/di/sub/deck_provider.dart')];

      expect(shapeViolations(sources), hasLength(1));
    });
  });

  group('domain purity', () {
    test('domain may import plain Dart, meta, core and other domain code', () {
      final sources = [
        _file('lib/features/deck/domain/entities/deck_entity.dart', [
          'package:meta/meta.dart',
          'package:memox/core/error/outcome.dart',
          'package:memox/features/srs/domain/models/scheduler_type_model.dart',
          '../models/deck_content_type_model.dart',
        ]),
      ];

      expect(domainPurityViolations(sources), isEmpty);
    });

    test(
      'domain importing Flutter, Riverpod, Drift or core/database fails',
      () {
        final sources = [
          _file('lib/features/study/domain/models/study_mode.dart', [
            'package:flutter/foundation.dart',
            'package:riverpod_annotation/riverpod_annotation.dart',
            'package:drift/drift.dart',
            'package:memox/core/database/app_database.dart',
          ]),
        ];

        expect(domainPurityViolations(sources), hasLength(4));
      },
    );

    test('domain reaching data/ or di/ fails, relative paths included', () {
      final sources = [
        _file('lib/features/deck/domain/repositories/deck_repository.dart', [
          '../../data/repositories/deck_repository_impl.dart',
          'package:memox/features/deck/di/deck_repository_provider.dart',
        ]),
      ];

      expect(domainPurityViolations(sources), hasLength(2));
    });
  });

  group('cross-feature imports', () {
    const cardRepository =
        'lib/features/card/data/repositories/card_repository_impl.dart';

    test('public domain buckets along an allowed edge pass', () {
      final sources = [
        _file(cardRepository, [
          'package:memox/features/deck/domain/repositories/deck_repository.dart',
          'package:memox/features/srs/domain/models/scheduler_type_model.dart',
        ]),
      ];

      expect(crossFeatureViolations(sources), isEmpty);
    });

    test('an edge outside the import map fails', () {
      final sources = [
        _file('lib/features/srs/domain/models/srs_scheduler.dart', [
          'package:memox/features/deck/domain/entities/deck_entity.dart',
        ]),
      ];

      expect(crossFeatureViolations(sources), hasLength(1));
    });

    test(
      'data/, presentation/, usecases/ and barrels of another feature fail',
      () {
        final sources = [
          _file(cardRepository, [
            'package:memox/features/deck/data/repositories/deck_repository_impl.dart',
            'package:memox/features/deck/presentation/screens/deck_list_screen.dart',
            'package:memox/features/deck/domain/usecases/create_deck_use_case.dart',
            'package:memox/features/deck/deck.dart',
          ]),
        ];

        expect(crossFeatureViolations(sources), hasLength(4));
      },
    );

    test('another feature di/ is reachable from presentation/ and di/ only', () {
      const deckProvider =
          'package:memox/features/deck/di/deck_repository_provider.dart';
      final allowedFrom = [
        _file(
          'lib/features/card/presentation/providers/create_card_provider.dart',
          [deckProvider],
        ),
        _file('lib/features/card/di/card_repository_provider.dart', [
          deckProvider,
        ]),
      ];
      final rejectedFrom = [
        _file(cardRepository, [deckProvider]),
      ];

      expect(crossFeatureViolations(allowedFrom), isEmpty);
      expect(crossFeatureViolations(rejectedFrom), hasLength(1));
    });

    test('a relative import is judged like its package path', () {
      final sources = [
        _file(cardRepository, [
          '../../../deck/data/repositories/deck_repository_impl.dart',
        ]),
      ];

      expect(crossFeatureViolations(sources), hasLength(1));
    });

    test('an export of another feature internals fails like an import', () {
      final source = parseSource(
        'lib/features/card/domain/entities/card_entity.dart',
        "export 'package:memox/features/deck/data/datasources/deck_dao.dart';\n",
      );

      expect(crossFeatureViolations([source]), hasLength(1));
    });
  });

  group('core', () {
    test('core importing a feature, app/ or shared/ fails', () {
      final sources = [
        _file('lib/core/database/app_database.dart', [
          'package:memox/features/deck/domain/entities/deck_entity.dart',
          'package:memox/app/app.dart',
          'package:memox/shared/widgets/mx_button.dart',
        ]),
      ];

      expect(coreViolations(sources), hasLength(3));
    });
  });

  group('import map', () {
    test('the declared map is acyclic', () {
      expect(cyclesIn(allowedFeatureImports), isEmpty);
    });

    test('a cycle is reported with its path', () {
      const cyclic = {
        'srs': {'deck'},
        'deck': {'srs'},
      };

      expect(cyclesIn(cyclic), ['srs -> deck -> srs']);
    });
  });

  test('readSources skips generated files and keeps paths repo-relative', () {
    final root = Directory.systemTemp.createTempSync('boundary_rules');
    addTearDown(() => root.deleteSync(recursive: true));
    const provider = 'lib/features/deck/di/deck_repository_provider';
    File('${root.path}/$provider.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync("part 'deck_repository_provider.g.dart';\n");
    File('${root.path}/$provider.g.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync("part of 'deck_repository_provider.dart';\n");

    final sources = readSources(root);

    expect(sources.map((source) => source.path), ['$provider.dart']);
    expect(sources.single.imports, isEmpty);
  });

  test('resolveImport maps a relative path under lib/ to package form', () {
    expect(
      resolveImport(
        'lib/features/card/data/repositories/card_repository_impl.dart',
        '../../../deck/domain/entities/deck_entity.dart',
      ),
      'package:memox/features/deck/domain/entities/deck_entity.dart',
    );
  });
}
