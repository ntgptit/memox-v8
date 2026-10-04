import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_level_query_sheets_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  testWidgets('sort/filter sheet uses the shared sheet parts (M3-A2..A4)', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: DeckSortFilterSheetWidget(parentId: null)),
        ),
      ),
    );
    final header =
        tester.widget<MxBottomSheet>(find.byType(MxBottomSheet)).header!
            as Padding;

    expect((header.padding as EdgeInsets).bottom, AppSpacing.grouped);
    expect(
      tester
          .widget<MxListSectionHeader>(find.byType(MxListSectionHeader))
          .label,
      _en.deckSortByHeader,
    );
    expect(find.byType(MxSheetActions), findsOneWidget);
    expect(
      find.widgetWithText(MxSettingsRow, _en.deckFilterDueOnlyTitle),
      findsOneWidget,
    );
  });
}
