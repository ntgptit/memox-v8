import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../../support/theme_harness.dart';
import '../../support/widget_harness.dart';

// showMxDialog's route: on the root navigator, with Material's barrier strings.

void main() {
  // The dialog covers the whole app, bottom nav included: it opens on the
  // root navigator, as the Material dialog it replaced did.
  group('over a shell branch', () {
    Future<void> openFromBranch(WidgetTester tester, void Function() onNav) {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
        initialLocation: '/a',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => Scaffold(
              body: shell,
              bottomNavigationBar: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onNav,
                child: const SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: Text('Bottom nav'),
                ),
              ),
            ),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/a',
                    builder: (context, state) => Center(
                      child: MxButton(
                        label: 'Open',
                        onPressed: () => showMxDialog<void>(
                          context,
                          builder: (_) => const MxDialog(title: 'Delete deck?'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      return tester.pumpWidget(
        MaterialApp.router(
          theme: materialHostTheme(buildLightTheme()),
          builder: mxThemeBuilder(buildLightTheme()),
          routerConfig: router,
        ),
      );
    }

    testWidgets('the bottom nav cannot be tapped while a dialog is open', (
      tester,
    ) async {
      var navTaps = 0;
      await openFromBranch(tester, () => navTaps++);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bottom nav'));
      expect(navTaps, 1, reason: 'the nav answers before the dialog opens');

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(MxDialog), findsOneWidget);

      await tester.tap(find.text('Bottom nav'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(navTaps, 1);
    });

    testWidgets('the dialog is a route of the root navigator', (tester) async {
      await openFromBranch(tester, () {});
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final dialog = tester.element(find.byType(MxDialog));
      final root = Navigator.of(dialog, rootNavigator: true);
      expect(Navigator.of(dialog), same(root));
    });
  });

  group('the barrier strings come from Material', () {
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
                onPressed: () => showMxDialog<void>(
                  context,
                  builder: (_) => const MxDialog(title: 'Delete deck?'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    FAnimatedModalBarrier barrier(WidgetTester tester) => tester
        .widget<FAnimatedModalBarrier>(find.byType(FAnimatedModalBarrier).last);

    testWidgets('the label dismisses, the hint closes the dialog', (
      tester,
    ) async {
      await open(tester);
      final material = MaterialLocalizations.of(
        tester.element(find.byType(MxDialog)),
      );

      expect(barrier(tester).semanticsLabel, material.modalBarrierDismissLabel);
      expect(
        barrier(tester).semanticsOnTapHint,
        material.scrimOnTapHint(material.dialogLabel),
      );
    });

    testWidgets('in Vietnamese they read as text, never as "\$"', (
      tester,
    ) async {
      await open(tester, locale: const Locale('vi'));
      final material = MaterialLocalizations.of(
        tester.element(find.byType(MxDialog)),
      );

      expect(
        Localizations.localeOf(tester.element(find.byType(MxDialog)))
            .languageCode,
        'vi',
      );
      final hint = barrier(tester).semanticsOnTapHint!;
      expect(hint, contains(material.dialogLabel));
      expect(hint, isNot(contains(r'$')));
      expect(barrier(tester).semanticsLabel, isNot(contains(r'$')));
      expect(barrier(tester).semanticsLabel, material.modalBarrierDismissLabel);
    });
  });
}
