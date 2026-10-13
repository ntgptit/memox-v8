import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

import '../../support/widget_harness.dart';

const _navKey = Key('nav');

/// The ScaffoldMessenger shows a toast only in the outermost Scaffold, which
/// floats it above its own bottom bar and knows nothing of a footer in-flow
/// in a body (MxToastClearance).
void main() {
  group('a toast floats above a footer, never over its actions', () {
    var saves = 0;
    setUp(() => saves = 0);

    /// The footer of a form: Save, which shows the toast, and a caption.
    Widget saveBar() => MxFooterBar(
      caption: 'Cards are added one after another',
      child: Builder(
        builder: (context) => MxButton(
          label: 'Save',
          isBlock: true,
          onPressed: () {
            saves++;
            showMxSnackbar(context, message: 'Card added');
          },
        ),
      ),
    );

    /// The tab shell around a screen: the outer Scaffold, the only one that
    /// shows the toast, knows the nav but not the screen's footer.
    Widget inTabShell(Widget screen) => MxAppShell(
      body: screen,
      bottomBar: const SizedBox(key: _navKey, height: AppSize.bottomNavBlock),
    );

    Rect toast(WidgetTester tester) => tester.getRect(
      find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          )
          .first,
    );

    Future<void> saveTwice(WidgetTester tester) async {
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
      }
    }

    void expectClear(WidgetTester tester) {
      final footer = tester.getRect(find.byType(MxFooterBar));
      // A gutter above the footer, as above the nav without one.
      expect(toast(tester).bottom, footer.top - AppSpacing.gutter);
      // The second Save reached the button, not the toast.
      expect(saves, 2);
    }

    testWidgets('a screen in the tab shell, its footer in the slot', (
      tester,
    ) async {
      await pumpMxPage(
        tester,
        inTabShell(
          MxAppShell(body: const SizedBox.expand(), footer: saveBar()),
        ),
      );
      await saveTwice(tester);

      expectClear(tester);
    });

    testWidgets('a bar at the end of the body, as the bulk bar', (
      tester,
    ) async {
      await pumpMxPage(
        tester,
        inTabShell(
          MxAppShell(
            body: Column(
              children: [
                const Expanded(child: SizedBox.expand()),
                saveBar(),
              ],
            ),
          ),
        ),
      );
      await saveTwice(tester);

      expectClear(tester);
    });

    testWidgets('a full-screen route over the gesture inset', (tester) async {
      await pumpMxPage(
        tester,
        MxAppShell(body: const SizedBox.expand(), footer: saveBar()),
        padding: const EdgeInsets.only(bottom: 20),
      );
      await saveTwice(tester);

      expectClear(tester);
    });

    testWidgets('without a footer the toast keeps its place over the nav', (
      tester,
    ) async {
      await pumpMxPage(
        tester,
        inTabShell(
          Builder(
            builder: (context) => Center(
              child: MxButton(
                label: 'Show',
                onPressed: () => showMxSnackbar(context, message: 'Saved'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(
        toast(tester).bottom,
        tester.getTopLeft(find.byKey(_navKey)).dy - AppSpacing.gutter,
      );
    });

    testWidgets('a footer off stage, as on another tab, does not lift it', (
      tester,
    ) async {
      await pumpMxPage(
        tester,
        inTabShell(
          Stack(
            children: [
              Offstage(
                child: TickerMode(
                  enabled: false,
                  child: MxAppShell(
                    body: const SizedBox.expand(),
                    footer: saveBar(),
                  ),
                ),
              ),
              Builder(
                builder: (context) => Center(
                  child: MxButton(
                    label: 'Show',
                    onPressed: () => showMxSnackbar(context, message: 'Saved'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(
        toast(tester).bottom,
        tester.getTopLeft(find.byKey(_navKey)).dy - AppSpacing.gutter,
      );
    });

    testWidgets('the toast settles back when the footer goes', (tester) async {
      final hasFooter = ValueNotifier(true);
      addTearDown(hasFooter.dispose);
      await pumpMxPage(
        tester,
        inTabShell(
          ValueListenableBuilder(
            valueListenable: hasFooter,
            builder: (_, isShown, _) => MxAppShell(
              body: const SizedBox.expand(),
              footer: isShown ? saveBar() : null,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      hasFooter.value = false;
      await tester.pumpAndSettle();
      expect(
        toast(tester).bottom,
        tester.getTopLeft(find.byKey(_navKey)).dy - AppSpacing.gutter,
      );
    });
  });
}
