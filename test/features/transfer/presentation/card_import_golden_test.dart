@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/transfer/domain/models/transfer_limits_model.dart';
import 'package:memox/features/transfer/domain/usecases/preview_import_use_case.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/providers/preview_import_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

// Kit 11's states as the app draws them, light and dark: the source, the
// mapping, a mixed preview and a partial result (spec §8.2 K1–K4).

final _en = lookupAppLocalizations(const Locale('en'));

/// Romanized fronts: the golden test font has no Hangul glyphs.
const _csv =
    'front,back,tags\n'
    'mul,water,noun\n'
    'bul,,\n'
    'sarang,love,\n'
    ',,\n'
    'mul,water,\n';

/// Throws on the duplicate read, the way a locked database does.
final class _BrokenDeckRead implements CardTransferRepository {
  @override
  Future<Set<CardFoldedPair>> foldedPairs(String deckId) async =>
      throw const UnknownDatabaseFailure(cause: 'locked');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

Future<String> _seed(LibraryEnv env) async {
  final root = await env.decks.root('Korean');
  final deck = await env.decks.sub(root.id, 'Words');
  await insertCard(
    env.db,
    id: 'x',
    deckId: deck.id,
    front: 'sarang',
    back: 'love',
  );
  return deck.id;
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> pump(WidgetTester tester, LibraryEnv env, String deckId) =>
        pumpLibraryGolden(
          tester,
          env,
          CardImportScreen(
            deckId: deckId,
            deckContext: _context,
            onClose: () {},
            onViewCards: () {},
          ),
          brightness,
          overrides: [
            importFilePickerProvider.overrideWithValue(
              () async => (
                name: 'words.csv',
                bytes: Uint8List.fromList(utf8.encode(_csv)),
              ),
            ),
          ],
        );

    libraryTest('import source, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pump(tester, env, deckId);
        await expectBoundaryGolden(tester, 'goldens/import_source_$theme.png');
      });
    });

    libraryTest('import mapping, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pump(tester, env, deckId);
        await _tap(tester, _en.importSourceFile);
        await _tap(tester, _en.importReadAction);
        await expectBoundaryGolden(tester, 'goldens/import_mapping_$theme.png');
      });
    });

    // Critique 2026-09-30 part 1: without a header each column still shows
    // its first value.
    libraryTest('import mapping, no header, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pump(tester, env, deckId);
        await _tap(tester, _en.importSourceFile);
        await _tap(tester, _en.importReadAction);
        await _tap(tester, _en.importHeaderToggle);
        await expectBoundaryGolden(
          tester,
          'goldens/import_mapping_no_header_$theme.png',
        );
      });
    });

    libraryTest('import preview, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pump(tester, env, deckId);
        await _tap(tester, _en.importSourceFile);
        await _tap(tester, _en.importReadAction);
        await _tap(tester, _en.importPreviewAction);
        await expectBoundaryGolden(tester, 'goldens/import_preview_$theme.png');
      });
    });

    // SP2a audit M2: the deck could not be read; nothing was lost, so the
    // banner is a warning.
    libraryTest('import preview failed, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          CardImportScreen(
            deckId: deckId,
            deckContext: _context,
            onClose: () {},
            onViewCards: () {},
          ),
          brightness,
          overrides: [
            importFilePickerProvider.overrideWithValue(
              () async => (
                name: 'words.csv',
                bytes: Uint8List.fromList(utf8.encode(_csv)),
              ),
            ),
            previewImportUseCaseProvider.overrideWithValue(
              PreviewImportUseCase(_BrokenDeckRead()),
            ),
          ],
        );
        await _tap(tester, _en.importSourceFile);
        await _tap(tester, _en.importReadAction);
        await _tap(tester, _en.importPreviewAction);
        await expectBoundaryGolden(
          tester,
          'goldens/import_preview_failed_$theme.png',
        );
      });
    });

    libraryTest('import too large, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          CardImportScreen(
            deckId: deckId,
            deckContext: _context,
            onClose: () {},
            onViewCards: () {},
          ),
          brightness,
          overrides: [
            importFilePickerProvider.overrideWithValue(
              () async => (
                name: 'words.csv',
                bytes: Uint8List(TransferLimits.maxBytes + 1),
              ),
            ),
          ],
        );
        await _tap(tester, _en.importSourceFile);
        await _tap(tester, _en.importReadAction);
        await expectBoundaryGolden(
          tester,
          'goldens/import_too_large_$theme.png',
        );
      });
    });

    libraryTest('import partial result, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pump(tester, env, deckId);
        await _tap(tester, _en.importSourceFile);
        await _tap(tester, _en.importReadAction);
        await _tap(tester, _en.importPreviewAction);
        await _tap(tester, _en.importCommitAction(1));
        await expectBoundaryGolden(tester, 'goldens/import_partial_$theme.png');
      });
    });
  }
}
