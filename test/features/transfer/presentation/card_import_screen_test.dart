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
import 'package:memox/features/transfer/domain/models/transfer_limits_model.dart';
import 'package:memox/features/transfer/presentation/providers/preview_import_use_case_provider.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import 'card_import_screen_harness.dart';

// The import screen over the real backend and a fake picker (UC-TRANSFER-001,
// IT-NAV-012, IT-CARD-014).
//
// The steps: preview, source, mapping and the refusals at step 1.

Future<int> countCards(LibraryEnv env) async =>
    (await env.db.customSelect('SELECT COUNT(*) AS n FROM card').getSingle())
        .read<int>('n');

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
        deckContext: deckContextHeader,
        onClose: () {},
        onViewCards: () {},
      ),
      overrides: [
        importFilePickerProvider.overrideWithValue(
          () async => csvFile('front,back\nmul,water\n'),
        ),
        previewImportUseCaseProvider.overrideWithValue(
          PreviewImportUseCase(flaky),
        ),
      ],
    );
    await tapLabel(tester, enL10n.importSourceFile);
    await tapLabel(tester, enL10n.importReadAction);
    await tapLabel(tester, enL10n.importPreviewAction);

    expect(find.text(enL10n.importProblemPreviewTitle), findsOneWidget);
    final preview = tester.widget<MxButton>(
      find.widgetWithText(MxButton, enL10n.importPreviewAction),
    );
    expect(preview.isLoading, isFalse);
    expect(preview.onPressed, isNotNull);

    flaky.isBroken = false;
    await tapLabel(tester, enL10n.importPreviewAction);
    expect(find.text(enL10n.importBadgeReady(1)), findsOneWidget);
    expect(find.text(enL10n.importProblemPreviewTitle), findsNothing);
  });

  libraryTest('a file becomes cards through the four steps (IT-CARD-014)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    var viewed = 0;
    await pumpImport(
      tester,
      env,
      deck.id,
      file: csvFile('front,back,tags\nmul,water,noun\nbul,fire,\n'),
      onViewCards: () => viewed++,
    );

    expect(find.text(enL10n.importPickTitle), findsOneWidget);
    await tapLabel(tester, enL10n.importSourceFile);
    expect(find.text('vocab.csv'), findsOneWidget);

    await tapLabel(tester, enL10n.importReadAction);
    expect(find.text(enL10n.importHeaderToggle), findsOneWidget);
    expect(find.text(enL10n.importFieldFront), findsOneWidget);

    await tapLabel(tester, enL10n.importPreviewAction);
    // Ready is a fine state, not learning progress (tone pass T6).
    expect(
      tester
          .widget<MxBadge>(
            find.widgetWithText(MxBadge, enL10n.importBadgeReady(2)),
          )
          .tone,
      MxBadgeTone.success,
    );
    // The chips carry the breakdown and the button the count: no header
    // total, no caption (critique 2026-09-30 part 3b).
    expect(find.textContaining('rows ready'), findsNothing);
    expect(find.text('2 rows will become new cards.'), findsNothing);

    await tapLabel(tester, enL10n.importCommitAction(2));
    expect(find.text(enL10n.importDoneTitle), findsOneWidget);
    expect(await countCards(env), 2);

    await tapLabel(tester, enL10n.importViewCards);
    expect(viewed, 1);
  });

  libraryTest(
    'Back steps back one step; at step 1 it closes (IT-NAV-012 step 4)',
    (tester, env) async {
      final root = await env.decks.root('Korean');
      final deck = await env.decks.sub(root.id, 'Words');
      var closed = 0;
      await pumpImport(
        tester,
        env,
        deck.id,
        file: csvFile('front,back\nmul,water\n'),
        onClose: () => closed++,
      );
      await tapLabel(tester, enL10n.importSourceFile);
      await tapLabel(tester, enL10n.importReadAction);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(enL10n.importReadAction), findsOneWidget);
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
    await pumpImport(
      tester,
      env,
      deck.id,
      file: csvFile('term,meaning\nmul,water\n'),
    );
    await tapLabel(tester, enL10n.importSourceFile);
    await tapLabel(tester, enL10n.importReadAction);

    expect(find.text(enL10n.importMappingIncomplete), findsOneWidget);
    // Nothing was mapped, so the note does not say it was.
    expect(find.text(enL10n.importMappingNote), findsNothing);
    await tapLabel(tester, enL10n.importPreviewAction);
    expect(find.text(enL10n.importHeaderToggle), findsOneWidget);
  });

  libraryTest('a file over the cap says how to split it (SP2a 2.23)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await pumpImport(
      tester,
      env,
      deck.id,
      file: (name: 'big.csv', bytes: Uint8List(TransferLimits.maxBytes + 1)),
    );
    await tapLabel(tester, enL10n.importSourceFile);
    await tapLabel(tester, enL10n.importReadAction);

    expect(find.text(enL10n.importProblemTooLargeTitle), findsOneWidget);
    expect(
      find.text(
        enL10n.importProblemTooLargeBody(
          TransferLimits.maxRows,
          TransferLimits.maxMegabytes,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(enL10n.importChooseAnother), findsOneWidget);
  });

  libraryTest('a Latin-1 file is refused at step 1 with guidance (E1)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await pumpImport(
      tester,
      env,
      deck.id,
      file: (
        name: 'latin.csv',
        bytes: Uint8List.fromList([0x63, 0xE9, 0x2C, 0x62]),
      ),
    );
    await tapLabel(tester, enL10n.importSourceFile);
    await tapLabel(tester, enL10n.importReadAction);

    expect(find.text(enL10n.importProblemEncodingTitle), findsOneWidget);
    expect(await countCards(env), 0);
    // Reading the same file again cannot help (kit 11 badEncoding).
    final read = find.widgetWithText(MxButton, enL10n.importReadAction);
    expect(tester.widget<MxButton>(read).onPressed, isNull);
    expect(find.text(enL10n.importCaptionProblemFile), findsOneWidget);
    // M3-C2: a banner action is a compact primary button, as elsewhere.
    final choose = tester.widget<MxButton>(
      find.widgetWithText(MxButton, enL10n.importChooseAnother),
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
    await pumpImport(tester, env, deck.id);
    await tapLabel(tester, enL10n.importSourcePaste);
    await tester.enterText(
      find.byType(EditableText),
      'front\tback\nbap\trice\n',
    );
    await tester.pumpAndSettle();

    expect(find.text(enL10n.importCaptionPrivatePaste), findsOneWidget);
    expect(find.text(enL10n.importCaptionPrivate), findsNothing);
  });
}
