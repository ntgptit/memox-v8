@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/di/export_share_repository_provider.dart';
import 'package:memox/features/card/di/card_transfer_repository_provider.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_file_repository.dart';
import 'package:memox/features/transfer/domain/usecases/build_export_use_case.dart';
import 'package:memox/features/transfer/presentation/providers/build_export_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/states/card_export_state.dart';
import 'package:memox/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_export_share.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

// Kit 12's sheet as the app draws it, light and dark: the whole deck, a
// failed file and a stale selection (rulings E1–E6).

final _en = lookupAppLocalizations(const Locale('en'));

const _open = 'Open export';

/// An encoder that fails, the way a full disk does (E4).
final class _FailingFiles implements TransferFileRepository {
  @override
  Future<Outcome<Never, TransferRejection>> write(rows, format) async =>
      const Rejected(TransferRejection.encodeFailed);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> pump(
      WidgetTester tester,
      LibraryEnv env,
      CardExportScope Function(String deckId) scope, {
      bool isFailing = false,
    }) async {
      final root = await env.decks.root('Korean');
      final deck = await env.decks.sub(root.id, 'Words');
      await insertCard(env.db, id: 'a', deckId: deck.id);
      await pumpLibraryGolden(
        tester,
        env,
        Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => MxButton(
                label: _open,
                onPressed: () => showCardExportSheet(context, scope(deck.id)),
              ),
            ),
          ),
        ),
        brightness,
        overrides: [
          exportShareRepositoryProvider.overrideWithValue(FakeExportShare()),
          if (isFailing)
            buildExportUseCaseProvider.overrideWith(
              (ref) => BuildExportUseCase(
                ref.watch(cardTransferRepositoryProvider),
                _FailingFiles(),
              ),
            ),
        ],
      );
      await tester.tap(find.text(_open));
      await tester.pumpAndSettle();
    }

    CardExportScope wholeDeck(String deckId) =>
        CardExportScope.deck(deckId: deckId, deckName: 'Words', cardCount: 1);

    libraryTest('export whole deck, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pump(tester, env, wholeDeck);
        await expectBoundaryGolden(tester, 'goldens/export_deck_$theme.png');
      });
    });

    libraryTest('export failed, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pump(tester, env, wholeDeck, isFailing: true);
        await tester.tap(find.widgetWithText(MxButton, _en.exportAction(1)));
        await tester.pumpAndSettle();
        await expectBoundaryGolden(tester, 'goldens/export_failed_$theme.png');
      });
    });

    libraryTest('export stale selection, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pump(
          tester,
          env,
          (deckId) =>
              CardExportScope.selection(deckId: deckId, ids: {'a', 'gone'}),
        );
        await tester.tap(find.widgetWithText(MxButton, _en.exportAction(2)));
        await tester.pumpAndSettle();
        await expectBoundaryGolden(tester, 'goldens/export_stale_$theme.png');
      });
    });
  }
}
