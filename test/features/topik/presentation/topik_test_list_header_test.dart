import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_test_list_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/forui_expect.dart';
import '../../../support/library_harness.dart';

// Screen 35, Q-A-2 (audit 2026-10-17): the sort trigger says what it sorts.

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('the sort trigger is named as a sort, with the order shown', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: TopikTestListHeaderWidget(
          section: TopikSection.reading,
          testCount: 3,
          order: TopikTestOrder.roundDescending,
          onSort: () {},
        ),
      ),
    );

    expect(
      byControlLabel(
        _en.topikSortTrigger(
          _en.topikOrderName(TopikTestOrder.roundDescending),
        ),
      ),
      findsOneWidget,
    );
  });
}
