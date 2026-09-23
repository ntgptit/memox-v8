import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/gallery/gallery_screen.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';

Future<void> _pumpGallery(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const GalleryScreen(),
    ),
  );
  await tester.pump();
}

/// Scrolls the whole gallery so every lazily built section is laid out.
Future<void> _scrollThrough(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  testWidgets('every section renders without an exception', (tester) async {
    await _pumpGallery(tester);
    await _scrollThrough(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('every built group is present', (tester) async {
    await _pumpGallery(tester);

    for (final title in [
      'B · Actions',
      'C · Inputs & selection',
      'D · Surfaces, rows & content',
      'E · Status & metadata',
      'A · Chrome & navigation',
      'G · Loading, empty & error',
      'H · Layout',
    ]) {
      await tester.scrollUntilVisible(
        find.text(title),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('the theme switch flips the gallery to dark', (tester) async {
    await _pumpGallery(tester);
    await tester.tap(find.byTooltip('Dark theme'));
    await tester.pump();

    expect(
      Theme.of(tester.element(find.byType(MxAppBar).first)).brightness,
      Brightness.dark,
    );
  });

  testWidgets('the text switch renders everything at 2x', (tester) async {
    await _pumpGallery(tester);
    await tester.tap(find.byTooltip('Large text'));
    await tester.pump();

    expect(
      MediaQuery.textScalerOf(tester.element(find.byType(MxAppBar).first))
          .scale(10),
      20,
    );
    await _scrollThrough(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings opens the gallery and back returns', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final en = lookupAppLocalizations(const Locale('en'));
    await tester.pumpWidget(const ProviderScope(child: MemoxApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.navSettings));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(en.openGallery));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(GalleryScreen), findsOneWidget);

    // The page's own back comes first; the chrome demos also say 'Back'.
    await tester.tap(find.byTooltip('Back').first);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(GalleryScreen), findsNothing);
  });
}
