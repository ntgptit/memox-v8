import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_mapping_row_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/support/import_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/forui_expect.dart';
import '../../../support/library_harness.dart';

// Screen 11 (audit 2026-10-17): a column's field chip names its column.

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest("the field chip names its column for TalkBack, not only the "
      'field', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: ImportMappingRowWidget(
          column: 0,
          header: 'Term',
          sample: 'bap',
          field: null,
          onAssign: (_) {},
        ),
      ),
    );

    expect(
      byControlLabel(_en.importFieldTrigger('A', _en.importField(null))),
      findsOneWidget,
    );
  });
}
