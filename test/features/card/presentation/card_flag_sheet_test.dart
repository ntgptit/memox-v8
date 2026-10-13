import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_flag_sheet_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  testWidgets('the flag sheet has the shared title header (M3-A1)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: CardFlagSheetWidget()),
      ),
    );

    // The sheet's own head (SW-REV-008), not one drawn by hand.
    expect(
      tester.widget<MxBottomSheet>(find.byType(MxBottomSheet)).title,
      _en.cardFlag,
    );
    expect(find.text(_en.cardFlag), findsOneWidget);
  });
}
