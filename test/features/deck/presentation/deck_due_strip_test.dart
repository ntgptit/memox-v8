import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_due_strip_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('the tappable strip names its destination', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DeckDueStripWidget(
            level: DeckLevel.of(const []),
            onOpen: () {},
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(InkWell)),
      isSemantics(isButton: true, label: 'Open Study'),
    );
    handle.dispose();
  });

  testWidgets('a display-only strip stays readable and is no button', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DeckDueStripWidget(level: DeckLevel.of(const []))),
      ),
    );

    expect(find.bySemanticsLabel(RegExp('0 cards due')), findsOneWidget);
    expect(find.bySemanticsLabel('Open Study'), findsNothing);
    handle.dispose();
  });
}
