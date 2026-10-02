import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_summary_model.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_preview_row_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_result_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/library_harness.dart';

// Screen 11's result names every row it skipped and why (critique
// 2026-10-02, F4; UC-TRANSFER-001 step 8).

final _en = lookupAppLocalizations(const Locale('en'));

ImportRow _invalid(int row) => ImportRow(
  rowNumber: row,
  kind: ImportRowKind.invalid,
  draft: CardDraft(front: 'term $row', back: ''),
  reason: CardRejection.blankContent,
);

ImportRow _duplicate(int row) => ImportRow(
  rowNumber: row,
  kind: ImportRowKind.duplicateInDeck,
  draft: CardDraft(front: 'dup $row', back: 'meaning $row'),
);

Widget _host(ImportSummary summary) => Scaffold(
  body: SingleChildScrollView(
    child: ImportResultWidget(state: CardImportDone(summary)),
  ),
);

void main() {
  libraryTest('a partial import lists its skipped rows with why, five at '
      'first, all after Show all', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        ImportSummary(
          written: 3,
          blank: 1,
          skipped: [
            for (var row = 2; row <= 5; row++) _invalid(row),
            for (var row = 6; row <= 8; row++) _duplicate(row),
          ],
        ),
      ),
    );

    expect(find.text(_en.importSkippedHeader.toUpperCase()), findsOneWidget);
    expect(find.byType(ImportPreviewRowWidget), findsNWidgets(5));
    expect(find.text('term 2'), findsOneWidget);
    expect(find.text(_en.importRowBackEmpty), findsNWidgets(4));
    expect(find.text('dup 7'), findsNothing);

    final showAll = find.text(_en.importSkippedShowAll(7));
    await tester.ensureVisible(showAll);
    await tester.tap(showAll);
    await tester.pumpAndSettle();

    expect(find.byType(ImportPreviewRowWidget), findsNWidgets(7));
    expect(find.text(_en.importRowDuplicateInDeck), findsNWidgets(3));
    expect(showAll, findsNothing);
  });

  libraryTest('five or fewer skipped rows need no Show all', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(ImportSummary(written: 1, blank: 0, skipped: [_invalid(3)])),
    );

    expect(find.byType(ImportPreviewRowWidget), findsOneWidget);
    expect(find.textContaining('Show all'), findsNothing);
  });

  libraryTest('a clean import lists nothing', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(const ImportSummary(written: 2, blank: 0, skipped: [])),
    );

    expect(find.byType(ImportPreviewRowWidget), findsNothing);
    expect(find.text(_en.importSkippedHeader.toUpperCase()), findsNothing);
  });
}
