import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/domain/usecases/preview_import_use_case.dart';
import 'package:memox/features/transfer/presentation/providers/preview_import_use_case_provider.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_mapping_row_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

// The import screen over the real backend and a fake picker (UC-TRANSFER-001,
// IT-NAV-012, IT-CARD-014).

final _en = lookupAppLocalizations(const Locale('en'));

ImportPickedFile _file(String text) =>
    (name: 'vocab.csv', bytes: Uint8List.fromList(utf8.encode(text)));

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

Future<int> _cards(LibraryEnv env) async =>
    (await env.db.customSelect('SELECT COUNT(*) AS n FROM card').getSingle())
        .read<int>('n');

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  String deckId, {
  ImportPickedFile? file,
  VoidCallback? onClose,
  VoidCallback? onViewCards,
}) => pumpLibraryScreen(
  tester,
  env,
  CardImportScreen(
    deckId: deckId,
    deckContext: _context,
    onClose: onClose ?? () {},
    onViewCards: onViewCards ?? () {},
  ),
  overrides: [importFilePickerProvider.overrideWithValue(() async => file)],
);

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

/// Throws on the duplicate read until [isBroken] turns false.
final class _FlakyDeckRead implements CardTransferRepository {
  _FlakyDeckRead(this._inner);

  final CardTransferRepository _inner;
  var isBroken = true;

  @override
  Future<Set<CardFoldedPair>> foldedPairs(String deckId) async {
    if (isBroken) throw const UnknownDatabaseFailure(cause: 'locked');
    return _inner.foldedPairs(deckId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  libraryTest('a preview that cannot read the deck says so and Preview rows '
      'tries again (SP2a 2.22)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    final flaky = _FlakyDeckRead(
      CardTransferRepositoryImpl(
        env.db,
        CardRepositoryImpl(
          env.db,
          ScheduleRepositoryImpl(env.db),
          TagRepositoryImpl(env.db),
        ),
      ),
    );
    await pumpLibraryScreen(
      tester,
      env,
      CardImportScreen(
        deckId: deck.id,
        deckContext: _context,
        onClose: () {},
        onViewCards: () {},
      ),
      overrides: [
        importFilePickerProvider.overrideWithValue(
          () async => _file('front,back\nmul,water\n'),
        ),
        previewImportUseCaseProvider.overrideWithValue(
          PreviewImportUseCase(flaky),
        ),
      ],
    );
    await _tap(tester, _en.importSourceFile);
    await _tap(tester, _en.importReadAction);
    await _tap(tester, _en.importPreviewAction);

    expect(find.text(_en.importProblemPreviewTitle), findsOneWidget);
    final preview = tester.widget<MxButton>(
      find.widgetWithText(MxButton, _en.importPreviewAction),
    );
    expect(preview.isLoading, isFalse);
    expect(preview.onPressed, isNotNull);

    flaky.isBroken = false;
    await _tap(tester, _en.importPreviewAction);
    expect(find.text(_en.importBadgeReady(1)), findsOneWidget);
    expect(find.text(_en.importProblemPreviewTitle), findsNothing);
  });

  libraryTest('a file becomes cards through the four steps (IT-CARD-014)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    var viewed = 0;
    await _pump(
      tester,
      env,
      deck.id,
      file: _file('front,back,tags\nmul,water,noun\nbul,fire,\n'),
      onViewCards: () => viewed++,
    );

    expect(find.text(_en.importPickTitle), findsOneWidget);
    await _tap(tester, _en.importSourceFile);
    expect(find.text('vocab.csv'), findsOneWidget);

    await _tap(tester, _en.importReadAction);
    expect(find.text(_en.importHeaderToggle), findsOneWidget);
    expect(find.text(_en.importFieldFront), findsOneWidget);

    await _tap(tester, _en.importPreviewAction);
    // Ready is a fine state, not learning progress (tone pass T6).
    expect(
      tester
          .widget<MxBadge>(
            find.widgetWithText(MxBadge, _en.importBadgeReady(2)),
          )
          .tone,
      MxBadgeTone.success,
    );
    // The chips carry the breakdown and the button the count: no header
    // total, no caption (critique 2026-09-30 part 3b).
    expect(find.textContaining('rows ready'), findsNothing);
    expect(find.text('2 rows will become new cards.'), findsNothing);

    await _tap(tester, _en.importCommitAction(2));
    expect(find.text(_en.importDoneTitle), findsOneWidget);
    expect(await _cards(env), 2);

    await _tap(tester, _en.importViewCards);
    expect(viewed, 1);
  });

  libraryTest(
    'Back steps back one step; at step 1 it closes (IT-NAV-012 step 4)',
    (tester, env) async {
      final root = await env.decks.root('Korean');
      final deck = await env.decks.sub(root.id, 'Words');
      var closed = 0;
      await _pump(
        tester,
        env,
        deck.id,
        file: _file('front,back\nmul,water\n'),
        onClose: () => closed++,
      );
      await _tap(tester, _en.importSourceFile);
      await _tap(tester, _en.importReadAction);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(_en.importReadAction), findsOneWidget);
      expect(closed, 0);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(closed, 1);
    },
  );

  libraryTest('an unmapped back locks Preview and says why (BR-TRANSFER-002)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(tester, env, deck.id, file: _file('term,meaning\nmul,water\n'));
    await _tap(tester, _en.importSourceFile);
    await _tap(tester, _en.importReadAction);

    expect(find.text(_en.importMappingIncomplete), findsOneWidget);
    // Nothing was mapped, so the note does not say it was.
    expect(find.text(_en.importMappingNote), findsNothing);
    await _tap(tester, _en.importPreviewAction);
    expect(find.text(_en.importHeaderToggle), findsOneWidget);
  });

  libraryTest('a Latin-1 file is refused at step 1 with guidance (E1)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(
      tester,
      env,
      deck.id,
      file: (
        name: 'latin.csv',
        bytes: Uint8List.fromList([0x63, 0xE9, 0x2C, 0x62]),
      ),
    );
    await _tap(tester, _en.importSourceFile);
    await _tap(tester, _en.importReadAction);

    expect(find.text(_en.importProblemEncodingTitle), findsOneWidget);
    expect(await _cards(env), 0);
    // Reading the same file again cannot help (kit 11 badEncoding).
    final read = find.widgetWithText(MxButton, _en.importReadAction);
    expect(tester.widget<MxButton>(read).onPressed, isNull);
    expect(find.text(_en.importCaptionProblemFile), findsOneWidget);
    // M3-C2: a banner action is a compact primary button, as elsewhere.
    final choose = tester.widget<MxButton>(
      find.widgetWithText(MxButton, _en.importChooseAnother),
    );
    expect(
      (choose.tone, choose.size),
      (MxButtonTone.primary, MxButtonSize.compact),
    );
  });

  libraryTest('pasted text is read on the device, and the caption says text', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(tester, env, deck.id);
    await _tap(tester, _en.importSourcePaste);
    await tester.enterText(
      find.byType(EditableText),
      'front\tback\nbap\trice\n',
    );
    await tester.pumpAndSettle();

    expect(find.text(_en.importCaptionPrivatePaste), findsOneWidget);
    expect(find.text(_en.importCaptionPrivate), findsNothing);
  });

  libraryTest(
    'duplicates are skipped unless included (A4); every row a duplicate locks Import (E3)',
    (tester, env) async {
      final root = await env.decks.root('Korean');
      final deck = await env.decks.sub(root.id, 'Words');
      await insertCard(
        env.db,
        id: 'x',
        deckId: deck.id,
        front: 'mul',
        back: 'water',
      );
      await _pump(tester, env, deck.id, file: _file('front,back\nmul,water\n'));
      await _tap(tester, _en.importSourceFile);
      await _tap(tester, _en.importReadAction);
      await _tap(tester, _en.importPreviewAction);

      expect(find.text(_en.importRowDuplicateInDeck), findsOneWidget);
      expect(find.text(_en.importCaptionNothingToImport), findsOneWidget);

      await _tap(tester, _en.importIncludeDuplicates);
      expect(find.text(_en.importCommitAction(1)), findsOneWidget);
    },
  );

  libraryTest('the results footer is one MxActionPair, outline first', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(tester, env, deck.id, file: _file('front,back\nmul,water\n'));
    await _tap(tester, _en.importSourceFile);
    await _tap(tester, _en.importReadAction);
    await _tap(tester, _en.importPreviewAction);
    await _tap(tester, _en.importCommitAction(1));

    final pair = tester.widget<MxActionPair>(find.byType(MxActionPair));
    expect(pair.leading!.tone, MxButtonTone.outline);
    expect(pair.leading!.label, _en.importAnother);
  });
  libraryTest('the deck path steps aside while typing and comes back after '
      '(audit P1)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(tester, env, deck.id);
    await tester.pumpAndSettle();

    expect(find.byType(MxBreadcrumb), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(find.byType(MxBreadcrumb), findsNothing);

    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.byType(MxBreadcrumb), findsOneWidget);
  });

  libraryTest('the mapping rows end their field chips on one edge, with no '
      'arrow wandering between (critique 2026-09-30)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(
      tester,
      env,
      deck.id,
      file: _file('front,back,tags\nmul,water,noun\n'),
    );
    await _tap(tester, _en.importSourceFile);
    await _tap(tester, _en.importReadAction);

    expect(find.byIcon(AppIcons.arrowRight), findsNothing);
    final chips = find.byType(MxChipTrigger);
    expect(chips, findsNWidgets(3));
    final rights = {
      for (var i = 0; i < 3; i++) tester.getTopRight(chips.at(i)).dx,
    };
    expect(rights, hasLength(1));
  });

  libraryTest('the file helper can be hidden, and stays hidden '
      '(critique 2026-09-30)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(tester, env, deck.id);
    expect(find.text(_en.importHelperBody), findsOneWidget);

    await tester.tap(find.byTooltip(_en.commonDismissNote));
    await tester.pumpAndSettle();
    expect(find.text(_en.importHelperBody), findsNothing);

    await _pump(tester, env, deck.id);
    await tester.pumpAndSettle();
    expect(find.text(_en.importHelperBody), findsNothing);
  });

  libraryTest('each column shows its first value, under the header when '
      'there is one (critique 2026-09-30)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(
      tester,
      env,
      deck.id,
      file: _file('front,back,tags\nmul,water,noun\n'),
    );
    await _tap(tester, _en.importSourceFile);
    await _tap(tester, _en.importReadAction);
    expect(find.text('mul'), findsOneWidget);
    expect(find.text('water'), findsOneWidget);

    await tester.tap(find.text(_en.importHeaderToggle));
    await tester.pumpAndSettle();
    // Without a header the first row is data.
    expect(find.text('front'), findsOneWidget);
  });

  libraryTest('a short or blank sample cell shows no sample', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(tester, env, deck.id, file: _file('front,back,tags\nmul, \n'));
    await _tap(tester, _en.importSourceFile);
    await _tap(tester, _en.importReadAction);
    expect(find.text('mul'), findsOneWidget);
    // Columns B (a blank cell) and C (a missing one) show only their name
    // and header, no sample line.
    final rows = find.byType(ImportMappingRowWidget);
    for (var i = 1; i < 3; i++) {
      final labels = find.descendant(
        of: rows.at(i),
        matching: find.byType(Column),
      );
      expect(
        find.descendant(of: labels.first, matching: find.byType(Text)),
        findsNWidgets(2),
      );
    }
    expect(tester.takeException(), isNull);
  });

  libraryTest('the file line counts data rows: a header row is not a row '
      '(critique 2026-09-30 part 3b)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(
      tester,
      env,
      deck.id,
      file: _file('front,back\nmul,water\nbul,fire\n'),
    );
    await _tap(tester, _en.importSourceFile);
    await _tap(tester, _en.importReadAction);
    expect(find.text(_en.importFileRead('CSV', 2, 2)), findsOneWidget);

    await _tap(tester, _en.importHeaderToggle);
    expect(find.text(_en.importFileRead('CSV', 3, 2)), findsOneWidget);
  });
}
