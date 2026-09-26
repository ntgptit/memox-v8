import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/di/export_share_repository_provider.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/presentation/states/card_export_state.dart';
import 'package:memox/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_export_share.dart';
import '../../../support/library_harness.dart';
import '../../../visual_audit/screen_audit.dart';

// The export sheet over the real backend and a fake share sheet
// (UC-TRANSFER-002, kit 12, rulings E1–E6).

final _en = lookupAppLocalizations(const Locale('en'));

const _open = 'Open export';

/// A page whose one button opens the sheet the way an entry point does.
class _Host extends StatelessWidget {
  const _Host(this.open);

  final Future<void> Function(BuildContext context) open;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Builder(
        builder: (context) =>
            MxButton(label: _open, onPressed: () => open(context)),
      ),
    ),
  );
}

Finder _button(String label) => find.widgetWithText(MxButton, label);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<({String deckId, FakeExportShare share})> _seed(
  WidgetTester tester,
  LibraryEnv env, {
  CardExportScope Function(String deckId)? scope,
  bool isWholeDeckEntry = false,
}) async {
  final root = await env.decks.root('Korean');
  final deck = await env.decks.sub(root.id, 'Words');
  await insertCard(env.db, id: 'a', deckId: deck.id, front: 'mul');
  await insertCard(env.db, id: 'b', deckId: deck.id, front: 'bul');
  final share = FakeExportShare();
  await pumpLibraryScreen(
    tester,
    env,
    _Host(
      (context) => isWholeDeckEntry
          ? showDeckExportSheet(context, deckId: deck.id, deckName: 'Words')
          : showCardExportSheet(context, scope!(deck.id)),
    ),
    overrides: [exportShareRepositoryProvider.overrideWithValue(share)],
  );
  await _tap(tester, _button(_open));
  return (deckId: deck.id, share: share);
}

void main() {
  libraryTest(
    'the whole deck is counted, then handed over; the toast says so (steps 1–7)',
    (tester, env) async {
      final (:deckId, :share) = await _seed(
        tester,
        env,
        isWholeDeckEntry: true,
      );

      expect(find.text(_en.exportTitleDeck(2)), findsOneWidget);
      expect(find.text(_en.exportBodyDeck('Words')), findsOneWidget);
      expect(find.text(_en.exportRecommended), findsOneWidget);
      final csv = find.widgetWithText(MxOptionRow, _en.exportFormatCsv);
      expect(tester.widget<MxOptionRow>(csv).isSelected, isTrue);

      await _tap(tester, _button(_en.exportAction(2)));

      expect(find.byType(CardExportSheetWidget), findsNothing);
      expect(find.text(_en.exportHandedOver(2)), findsOneWidget);
      expect(share.shared.single.format, TransferFormat.csv);
      expect(share.shared.single.fileName, startsWith('Words-'));
    },
  );

  libraryTest(
    'a selection names its count; XLSX is written when chosen (A1, A2)',
    (tester, env) async {
      final (:deckId, :share) = await _seed(
        tester,
        env,
        scope: (deckId) =>
            CardExportScope.selection(deckId: deckId, ids: {'a'}),
      );
      expect(find.text(_en.exportTitleSelection(1)), findsOneWidget);
      expect(find.text(_en.exportBodySelection), findsOneWidget);

      await _tap(tester, find.text(_en.exportFormatXlsx));
      await _tap(tester, _button(_en.exportAction(1)));

      expect(share.shared.single.format, TransferFormat.xlsx);
    },
  );

  libraryTest(
    'closing the share sheet keeps the export sheet as it was (A3, ruling E1)',
    (tester, env) async {
      await _seed(
        tester,
        env,
        scope: (deckId) =>
            CardExportScope.selection(deckId: deckId, ids: {'a'}),
      ).then((seeded) async {
        seeded.share.answer = const Ok(ExportShareResult.dismissed);
        await _tap(tester, find.text(_en.exportFormatTsv));
        await _tap(tester, _button(_en.exportAction(1)));
      });

      expect(find.byType(CardExportSheetWidget), findsOneWidget);
      final tsv = find.widgetWithText(MxOptionRow, _en.exportFormatTsv);
      expect(tester.widget<MxOptionRow>(tsv).isSelected, isTrue);
      expect(find.text(_en.exportHandedOver(1)), findsNothing);
    },
  );

  libraryTest(
    'a share error offers Try again; no share target offers Close only (E1, E2)',
    (tester, env) async {
      final (:deckId, :share) = await _seed(
        tester,
        env,
        scope: (deckId) =>
            CardExportScope.selection(deckId: deckId, ids: {'a'}),
      );
      share.answer = const Rejected(TransferRejection.shareFailed);
      await _tap(tester, _button(_en.exportAction(1)));
      expect(find.text(_en.exportShareFailedTitle), findsOneWidget);

      share.answer = const Rejected(TransferRejection.shareUnavailable);
      await _tap(tester, _button(_en.exportTryAgain));
      expect(find.text(_en.exportNoTargetTitle), findsOneWidget);
      expect(_button(_en.exportTryAgain), findsNothing);

      await _tap(tester, _button(_en.exportClose));
      expect(find.byType(CardExportSheetWidget), findsNothing);
    },
  );

  libraryTest('a selection with a card gone meanwhile exports nothing (E6)', (
    tester,
    env,
  ) async {
    final (:deckId, :share) = await _seed(
      tester,
      env,
      scope: (deckId) =>
          CardExportScope.selection(deckId: deckId, ids: {'a', 'gone'}),
    );

    await _tap(tester, _button(_en.exportAction(2)));

    expect(find.text(_en.exportStaleTitle), findsOneWidget);
    expect(_button(_en.exportClose), findsOneWidget);
    expect(share.shared, isEmpty);
  });

  libraryTest('an empty deck opens on nothing to export (E5)', (
    tester,
    env,
  ) async {
    await _seed(
      tester,
      env,
      scope: (deckId) =>
          CardExportScope.deck(deckId: deckId, deckName: 'Words', cardCount: 0),
    );

    expect(find.text(_en.exportEmptyTitle), findsOneWidget);
    expect(_button(_en.exportClose), findsOneWidget);
  });

  libraryTest('the sheet meets the target guidelines at 1x and 2x text', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await insertCard(env.db, id: 'a', deckId: deck.id);
    await auditProductionScreen(
      tester,
      screen: CardExportSheetWidget,
      pump: (brightness, scale) async {
        await pumpLibraryScreen(
          tester,
          env,
          _Host(
            (context) => showCardExportSheet(
              context,
              CardExportScope.deck(
                deckId: deck.id,
                deckName: 'Words',
                cardCount: 1,
              ),
            ),
          ),
          brightness: brightness,
          textScale: scale,
        );
        if (find.byType(CardExportSheetWidget).evaluate().isEmpty) {
          await _tap(tester, _button(_open));
        }
      },
    );
  });
}
