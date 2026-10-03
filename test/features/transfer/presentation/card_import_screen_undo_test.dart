import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/transfer/domain/usecases/undo_import_use_case.dart';
import 'package:memox/features/transfer/presentation/providers/undo_import_use_case_provider.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_commit_bar_widget.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import 'card_import_screen_harness.dart';

// The import screen over the real backend and a fake picker (UC-TRANSFER-001,
// IT-NAV-012, IT-CARD-014).
//
// Undo import, and Cancel while the cards are written.

Future<int> countActiveCards(LibraryEnv env) async =>
    (await env.db
            .customSelect(
              'SELECT COUNT(*) AS n FROM card WHERE delete_batch_id IS NULL',
            )
            .getSingle())
        .read<int>('n');

/// Throws [error] when the cards are moved to the Trash.
final class _ThrowingTrash implements CardRepository {
  _ThrowingTrash(this.error);

  final Object error;

  @override
  Future<Never> deleteCards({
    required Set<String> cardIds,
    DateTime? now,
  }) async => throw error;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  libraryTest('Undo import asks, then moves the imported cards to the Trash '
      'and closes (SP2a 2.25)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    var closed = 0;
    await pumpImport(
      tester,
      env,
      deck.id,
      file: csvFile('front,back\nmul,water\nbul,fire\n'),
      onClose: () => closed++,
    );
    await tapLabel(tester, enL10n.importSourceFile);
    await tapLabel(tester, enL10n.importReadAction);
    await tapLabel(tester, enL10n.importPreviewAction);
    await tapLabel(tester, enL10n.importCommitAction(2));
    expect(await countActiveCards(env), 2);

    await tapLabel(tester, enL10n.importUndoAction);
    expect(find.text(enL10n.importUndoTitle(2)), findsOneWidget);
    expect(find.text(enL10n.cardDeleteNote(2)), findsOneWidget);
    await tapLabel(tester, enL10n.commonCancel);
    expect(await countActiveCards(env), 2);
    expect(closed, 0);

    await tapLabel(tester, enL10n.importUndoAction);
    await tester.tap(
      find.descendant(
        of: find.byType(MxDialog),
        matching: find.text(enL10n.cardMoveToTrash),
      ),
    );
    await tester.pumpAndSettle();

    expect(await countActiveCards(env), 0);
    expect(closed, 1);
    expect(find.text(enL10n.importUndoneToast(2)), findsOneWidget);
  });

  libraryTest('Cancel stays live before the write and holds once it runs '
      '(SP2a 2.25, a pin of current behaviour)', (tester, env) async {
    final preview = const ImportPreview([
      ImportRow(
        rowNumber: 2,
        kind: ImportRowKind.ready,
        draft: CardDraft(front: 'a', back: 'b'),
      ),
    ]);
    Widget bar(CardImportDraft draft) => Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: ImportCommitBarWidget(
          draft: draft,
          onCancel: () {},
          onRead: () {},
          onPreview: () {},
          onCommit: () {},
        ),
      ),
    );
    VoidCallback? cancel() => tester
        .widget<MxButton>(find.widgetWithText(MxButton, enL10n.commonCancel))
        .onPressed;

    await pumpLibraryScreen(
      tester,
      env,
      bar(CardImportDraft(step: CardImportStep.preview, preview: preview)),
    );
    expect(cancel(), isNotNull);

    await pumpLibraryScreen(
      tester,
      env,
      bar(
        CardImportDraft(
          step: CardImportStep.importing,
          preview: preview,
          isBusy: true,
        ),
      ),
    );
    expect(cancel(), isNull);
  });

  for (final error in <Object>[
    StateError('trash exploded'),
    const UnknownDatabaseFailure(cause: 'locked'),
  ]) {
    libraryTest('an Undo whose move throws ${error.runtimeType} says so, '
        'keeps the cards and frees the dialog (SP2a 2.25)', (
      tester,
      env,
    ) async {
      final root = await env.decks.root('Korean');
      final deck = await env.decks.sub(root.id, 'Words');
      await pumpImport(
        tester,
        env,
        deck.id,
        file: csvFile('front,back\nmul,water\nbul,fire\n'),
        overrides: [
          undoImportUseCaseProvider.overrideWithValue(
            UndoImportUseCase(_ThrowingTrash(error)),
          ),
        ],
      );
      await tapLabel(tester, enL10n.importSourceFile);
      await tapLabel(tester, enL10n.importReadAction);
      await tapLabel(tester, enL10n.importPreviewAction);
      await tapLabel(tester, enL10n.importCommitAction(2));
      await tapLabel(tester, enL10n.importUndoAction);
      final confirm = find.descendant(
        of: find.byType(MxDialog),
        matching: find.widgetWithText(MxButton, enL10n.cardMoveToTrash),
      );

      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(find.text(enL10n.failureUnknown), findsOneWidget);
      expect(find.byType(MxDialog), findsOneWidget);
      expect(tester.widget<MxButton>(confirm).onPressed, isNotNull);
      expect(tester.widget<MxButton>(confirm).isLoading, isFalse);
      expect(await countActiveCards(env), 2);
    });
  }
}
