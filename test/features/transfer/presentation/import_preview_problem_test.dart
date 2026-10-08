import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_import_target_model.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_plan_model.dart';
import 'package:memox/features/transfer/domain/models/import_sections_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_commit_bar_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_preview_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/library_harness.dart';

// A refusal that comes back to the preview, from the commit or from Preview
// again, says why and locks Import (final review of DEV-289).

final _en = lookupAppLocalizations(const Locale('en'));

const _faces = ColumnMapping({0: TransferField.front, 1: TransferField.back});

CardImportDraft _draft(TransferRejection problem) {
  const table = SourceTable(
    rows: [
      ['Term', 'Meaning'],
      ['*Part 1', ''],
      ['a', 'b'],
    ],
  );
  final plan = ImportPlan(
    table: table,
    mapping: _faces,
    hasHeaderRow: true,
    target: const CardImportTarget(
      isDeckOfCards: false,
      canHoldCards: false,
      hasRoomBelow: true,
      pairs: {},
      children: [],
    ),
    sections: splitSections(table: table, mapping: _faces, hasHeaderRow: true),
  );
  return CardImportDraft(
    step: CardImportStep.preview,
    table: table,
    mapping: _faces,
    plan: plan,
    preview: plan.preview(defaultDeckName: 'Uncategorized', choices: const {}),
    problem: problem,
  );
}

void main() {
  for (final (problem, title) in [
    (TransferRejection.depthExceeded, _en.importProblemDepthTitle),
    (
      TransferRejection.sectionsNeedDeckContainer,
      _en.importProblemSectionsTitle,
    ),
  ]) {
    libraryTest('$problem on the preview says why and locks Import', (
      tester,
      env,
    ) async {
      final draft = _draft(problem);
      await pumpLibraryScreen(
        tester,
        env,
        Scaffold(
          body: SingleChildScrollView(
            child: ImportPreviewSectionWidget(
              draft: draft,
              onIncludeDuplicates: (_) {},
              onChooseSection: (_, _) {},
              onRenameDefault: (_) {},
              onPreviewAgain: () {},
            ),
          ),
          bottomNavigationBar: ImportCommitBarWidget(
            draft: draft,
            onCancel: () {},
            onRead: () {},
            onPreview: () {},
            onCommit: () {},
          ),
        ),
      );

      expect(find.text(title), findsOneWidget);
      expect(
        tester
            .widget<MxButton>(
              find.widgetWithText(MxButton, _en.importCommitAction(1)),
            )
            .onPressed,
        isNull,
      );
    });
  }
}
