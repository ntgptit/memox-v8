import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';

import '../../support/theme_harness.dart';
import '../../support/widget_harness.dart';

const _barKey = Key('bar');

void main() {
  group('the app bar ground when content scrolls under it', () {
    final tall = [for (var i = 0; i < 30; i++) const SizedBox(height: 80)];
    final listKey = GlobalKey();

    MxAppShell shell() => MxAppShell(
      appBar: const MxAppBar(title: 'Library', key: _barKey),
      body: ListView(key: listKey, children: tall),
    );

    // The band behind the bar: the page ground, with a hairline under it.
    final band = find.ancestor(
      of: find.byKey(_barKey),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).border != null,
      ),
    );

    BoxDecoration paint(WidgetTester tester) =>
        tester.widget<DecoratedBox>(band.first).decoration as BoxDecoration;

    Color ground(WidgetTester tester) => paint(tester).color!;

    Color edge(WidgetTester tester) =>
        (paint(tester).border! as Border).bottom.color;

    final clear = appLightColors.border.withValues(alpha: 0);

    testWidgets('the page ground with no edge at rest, the hairline edge once '
        'scrolled, and back', (tester) async {
      await pumpMxPage(tester, shell());
      expect(ground(tester), appLightColors.background);
      expect(edge(tester), clear);

      await tester.drag(find.byKey(listKey), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(ground(tester), appLightColors.background);
      expect(edge(tester), appLightColors.border);

      await tester.drag(find.byKey(listKey), const Offset(0, 1000));
      await tester.pumpAndSettle();
      expect(ground(tester), appLightColors.background);
      expect(edge(tester), clear);
    });

    testWidgets('a bar wrapped in a widget of its own takes the ground too', (
      tester,
    ) async {
      await pumpMxPage(
        tester,
        MxAppShell(
          appBar: const _WrappedBar(key: _barKey),
          body: ListView(key: listKey, children: tall),
        ),
      );
      expect(edge(tester), clear);

      await tester.drag(find.byKey(listKey), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(ground(tester), appLightColors.background);
      expect(edge(tester), appLightColors.border);
    });

    testWidgets('a bar that paints its own ground keeps the shell out of it', (
      tester,
    ) async {
      await pumpMxPage(
        tester,
        MxAppShell(
          hasOwnAppBarGround: true,
          appBar: const _WrappedBar(key: _barKey),
          body: ListView(key: listKey, children: tall),
        ),
      );
      await tester.drag(find.byKey(listKey), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(edge(tester), clear);
    });

    testWidgets('content that fits never scrolls under', (tester) async {
      await pumpMxPage(
        tester,
        MxAppShell(
          appBar: const MxAppBar(title: 'Library', key: _barKey),
          body: ListView(children: const [SizedBox(height: 40)]),
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(edge(tester), clear);
    });

    testWidgets('swapping the scrolled body for one that does not scroll '
        'clears the ground', (tester) async {
      final body = ValueNotifier<Widget>(
        ListView(key: listKey, children: tall),
      );
      addTearDown(body.dispose);
      await pumpMxPage(
        tester,
        ValueListenableBuilder(
          valueListenable: body,
          builder: (_, child, _) => MxAppShell(
            appBar: const MxAppBar(title: 'Library', key: _barKey),
            body: child,
          ),
        ),
      );
      await tester.drag(find.byKey(listKey), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(edge(tester), appLightColors.border);

      body.value = const SizedBox.expand();
      await tester.pumpAndSettle();

      expect(edge(tester), clear);
    });

    testWidgets('content that shrinks back into the viewport clears the '
        'ground', (tester) async {
      final count = ValueNotifier(30);
      addTearDown(count.dispose);
      await pumpMxPage(
        tester,
        ValueListenableBuilder(
          valueListenable: count,
          builder: (_, n, _) => MxAppShell(
            appBar: const MxAppBar(title: 'Library', key: _barKey),
            body: ListView(
              key: listKey,
              children: [
                for (var i = 0; i < n; i++) const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      );
      await tester.drag(find.byKey(listKey), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(edge(tester), appLightColors.border);

      count.value = 2;
      await tester.pumpAndSettle();

      expect(edge(tester), clear);
    });

    testWidgets('the colour eases in', (tester) async {
      await pumpMxPage(tester, shell());
      await tester.drag(find.byKey(listKey), const Offset(0, -300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final midway = edge(tester);
      expect(midway, isNot(clear));
      expect(midway, isNot(appLightColors.border));
      await tester.pumpAndSettle();
    });

    testWidgets('a theme change is followed at the theme\'s pace, not eased '
        'again after it (follow-ups spec T1)', (tester) async {
      Widget app(FThemeData theme) => MaterialApp(
        theme: materialHostTheme(theme),
        builder: mxThemeBuilder(theme),
        home: shell(),
      );
      await tester.pumpWidget(app(buildLightTheme()));
      await tester.drag(find.byKey(listKey), const Offset(0, -300));
      await tester.pumpAndSettle();

      // ForUI eases the theme over 200 ms; an edge that eased its own
      // colour on top would still be on its way here.
      await tester.pumpWidget(app(buildDarkTheme()));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 50));

      expect(edge(tester), buildDarkTheme().colors.border);
    });

    testWidgets('reduced motion changes the colour at once', (tester) async {
      await pumpMxPage(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: shell(),
          ),
        ),
      );
      await tester.drag(find.byKey(listKey), const Offset(0, -300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(edge(tester), appLightColors.border);
    });

    testWidgets('on a wide window the ground runs the full width while the '
        'bar keeps the column', (tester) async {
      await pumpMxWide(tester, shell());
      await tester.drag(find.byKey(listKey), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(tester.getSize(band.first).width, 1280);
      expect(tester.getSize(find.byKey(_barKey)).width, lessThan(1280));
      expect(ground(tester), appLightColors.background);
      expect(edge(tester), appLightColors.border);
    });
  });
}

/// A feature widget that builds the app bar, as the deck screen's does.
class _WrappedBar extends StatelessWidget {
  const _WrappedBar({super.key});

  @override
  Widget build(BuildContext context) => const MxAppBar(title: 'Library');
}
