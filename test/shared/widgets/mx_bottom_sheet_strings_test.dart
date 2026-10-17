import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../support/theme_harness.dart';
import '../../support/widget_harness.dart';

// showMxBottomSheet's barrier and grabber strings come from Material.
const _grabberKey = ValueKey('mx-sheet-grabber');

void main() {
  group('the barrier and grabber strings come from Material', () {
    Future<void> open(WidgetTester tester, {Locale? locale}) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            FLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: materialHostTheme(buildLightTheme()),
          builder: mxThemeBuilder(buildLightTheme()),
          home: Scaffold(
            body: Builder(
              builder: (context) => MxButton(
                label: 'Open',
                onPressed: () => showMxBottomSheet<void>(
                  context,
                  builder: (_) => const MxBottomSheet(child: Text('Sheet')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    /// The route's barrier, whether ForUI paints it with or without a filter.
    (String?, String?) barrier(WidgetTester tester) {
      final animated = find.byType(FAnimatedModalBarrier);
      if (animated.evaluate().isNotEmpty) {
        final widget = tester.widget<FAnimatedModalBarrier>(animated.last);
        return (widget.semanticsLabel, widget.semanticsOnTapHint);
      }
      final widget = tester.widget<FModalBarrier>(
        find.byType(FModalBarrier).last,
      );
      return (widget.semanticsLabel, widget.semanticsOnTapHint);
    }

    testWidgets('the scrim says "scrim" and offers to close the sheet', (
      tester,
    ) async {
      await open(tester);
      final material = MaterialLocalizations.of(
        tester.element(find.byType(MxBottomSheet)),
      );

      expect(barrier(tester), (
        material.scrimLabel,
        material.scrimOnTapHint(material.bottomSheetLabel),
      ));
    });

    testWidgets('in Vietnamese no string carries a literal "\$"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester, locale: const Locale('vi'));
      final material = MaterialLocalizations.of(
        tester.element(find.byType(MxBottomSheet)),
      );
      final (label, hint) = barrier(tester);
      final grabber = tester.getSemantics(find.byKey(_grabberKey)).label;

      expect(
        Localizations.localeOf(tester.element(find.byType(MxBottomSheet)))
            .languageCode,
        'vi',
      );
      expect(hint, contains(material.bottomSheetLabel));
      expect(grabber, material.modalBarrierDismissLabel);
      for (final text in [label, hint, grabber]) {
        expect(text, isNotEmpty);
        expect(text, isNot(contains(r'$')));
      }
      handle.dispose();
    });
  });
}
