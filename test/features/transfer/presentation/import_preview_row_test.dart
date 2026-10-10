import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_preview_row_widget.dart';

import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

// Kit 11 preview table: `alignItems: 'center'` on every row.

void main() {
  libraryTest('the row number and the status mark are centred on a row of '
      'three lines (kit 11, owner 2026-09-26)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const Scaffold(
        body: Column(
          children: [
            ImportPreviewRowWidget(
              row: ImportRow(
                rowNumber: 3,
                kind: ImportRowKind.invalid,
                draft: CardDraft(front: 'bul', back: ''),
                reason: CardRejection.blankContent,
              ),
            ),
          ],
        ),
      ),
    );

    final row = find.byType(ImportPreviewRowWidget);
    expectCentredOn(tester, row, [
      find.descendant(of: row, matching: find.text('3')),
      find.descendant(of: row, matching: find.byType(Icon)),
    ]);
  });

  libraryTest('an invalid row is marked with the alert glyph its legend badge '
      'uses, not an X that reads as dismiss (critique 2026-09-30 3a)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      const Scaffold(
        body: Column(
          children: [
            ImportPreviewRowWidget(
              row: ImportRow(
                rowNumber: 3,
                kind: ImportRowKind.invalid,
                draft: CardDraft(front: 'bul', back: ''),
                reason: CardRejection.blankContent,
              ),
            ),
          ],
        ),
      ),
    );

    final row = find.byType(ImportPreviewRowWidget);
    expect(
      find.descendant(of: row, matching: find.byIcon(AppIcons.alert)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.byIcon(AppIcons.close)),
      findsNothing,
    );
  });

  libraryTest('a ready row is marked with a success-ink check (critique '
      '2026-09-30 tone pass, T6)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const Scaffold(
        body: Column(
          children: [
            ImportPreviewRowWidget(
              row: ImportRow(
                rowNumber: 2,
                kind: ImportRowKind.ready,
                draft: CardDraft(front: 'mul', back: 'water'),
              ),
            ),
          ],
        ),
      ),
    );
    final mark = find.byIcon(AppIcons.check);
    // The mark takes its colour from an IconTheme around the glyph.
    expect(
      IconTheme.of(tester.element(mark)).color,
      tester.element(mark).semanticColors.success,
    );
  });
}
