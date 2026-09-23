import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _pumpApp(WidgetTester tester, {bool hasGallery = true}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(child: MemoxApp(hasGallery: hasGallery)),
  );
  await tester.pumpAndSettle();
}

Finder _barTitle(String title, {bool skipOffstage = true}) => find.descendant(
  of: find.byType(MxAppBar, skipOffstage: skipOffstage),
  matching: find.text(title, skipOffstage: skipOffstage),
  skipOffstage: skipOffstage,
);

MxBottomNav _nav(WidgetTester tester) =>
    tester.widget<MxBottomNav>(find.byType(MxBottomNav));

/// A tab label inside the bottom nav; the app bar may show the same text.
Finder _tab(String label) =>
    find.descendant(of: find.byType(MxBottomNav), matching: find.text(label));

void main() {
  testWidgets('cold start lands on Library', (tester) async {
    await _pumpApp(tester);

    expect(_barTitle(_en.navLibrary), findsOneWidget);
    expect(_nav(tester).selectedIndex, 0);
  });

  testWidgets('four tabs in navigation.md order', (tester) async {
    await _pumpApp(tester);

    expect(_nav(tester).destinations.map((d) => d.label), [
      _en.navLibrary,
      _en.navStudy,
      _en.navProgress,
      _en.navSettings,
    ]);
  });

  testWidgets('switching tabs keeps the other branch alive', (tester) async {
    await _pumpApp(tester);
    await tester.tap(_tab(_en.navStudy));
    await tester.pumpAndSettle();

    expect(_nav(tester).selectedIndex, 1);
    expect(_barTitle(_en.navStudy), findsOneWidget);
    expect(_barTitle(_en.navLibrary, skipOffstage: false), findsOneWidget);
  });

  testWidgets('re-tapping the current tab keeps it selected', (tester) async {
    await _pumpApp(tester);
    await tester.tap(_tab(_en.navLibrary));
    await tester.pumpAndSettle();

    expect(_nav(tester).selectedIndex, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('each tab shows the neutral placeholder', (tester) async {
    await _pumpApp(tester);

    expect(find.text(_en.placeholderTitle), findsOneWidget);
    expect(find.text(_en.placeholderBody), findsOneWidget);
  });

  testWidgets('Vietnamese device locale gives Vietnamese tabs', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('vi')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await _pumpApp(tester);
    final vi = lookupAppLocalizations(const Locale('vi'));

    expect(_nav(tester).destinations.map((d) => d.label), [
      vi.navLibrary,
      vi.navStudy,
      vi.navProgress,
      vi.navSettings,
    ]);
  });

  testWidgets('an unsupported locale falls back to English', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await _pumpApp(tester);

    expect(_barTitle(_en.navLibrary), findsOneWidget);
  });

  testWidgets('dark system theme gives the dark page ground', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _pumpApp(tester);

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
      AppColorSchemes.dark.surface,
    );
  });

  testWidgets('the status inset is consumed once, above the tab app bar', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 72, bottom: 60);
    addTearDown(tester.view.resetPadding);
    await _pumpApp(tester);

    // 72 physical px at 3x = 24 logical.
    expect(tester.getTopLeft(find.byType(MxAppBar)).dy, 24);
    expect(tester.getSize(find.byType(MxAppBar)).height, 56);
  });

  testWidgets('Settings offers the gallery in debug builds', (tester) async {
    await _pumpApp(tester);
    await tester.tap(_tab(_en.navSettings));
    await tester.pumpAndSettle();

    expect(find.byTooltip(_en.openGallery), findsOneWidget);
  });

  testWidgets('without the gallery there is no route and no action', (
    tester,
  ) async {
    await _pumpApp(tester, hasGallery: false);
    await tester.tap(_tab(_en.navSettings));
    await tester.pumpAndSettle();

    expect(find.byTooltip(_en.openGallery), findsNothing);
    final router = buildAppRouter(hasGallery: false);
    addTearDown(router.dispose);
    expect(
      router.configuration.routes.whereType<GoRoute>().map((r) => r.path),
      isNot(contains(AppRoutes.gallery)),
    );
  });
}
