import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';

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

    Color ground(WidgetTester tester) => tester
        .widget<ColoredBox>(
          find
              .ancestor(
                of: find.byKey(_barKey),
                matching: find.byType(ColoredBox),
              )
              .first,
        )
        .color;

    testWidgets('surface at rest, surfaceContainer once scrolled, and back', (
      tester,
    ) async {
      await pumpMxPage(tester, shell());
      expect(ground(tester), appLightColors.background);

      await tester.drag(find.byKey(listKey), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(ground(tester), appLightColors.secondary);

      await tester.drag(find.byKey(listKey), const Offset(0, 1000));
      await tester.pumpAndSettle();
      expect(ground(tester), appLightColors.background);
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
      expect(ground(tester), appLightColors.background);

      await tester.drag(find.byKey(listKey), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(ground(tester), appLightColors.secondary);
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

      expect(ground(tester), appLightColors.background);
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

      expect(ground(tester), appLightColors.background);
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
      expect(ground(tester), appLightColors.secondary);

      body.value = const SizedBox.expand();
      await tester.pumpAndSettle();

      expect(ground(tester), appLightColors.background);
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
      expect(ground(tester), appLightColors.secondary);

      count.value = 2;
      await tester.pumpAndSettle();

      expect(ground(tester), appLightColors.background);
    });

    testWidgets('the colour eases in', (tester) async {
      await pumpMxPage(tester, shell());
      await tester.drag(find.byKey(listKey), const Offset(0, -300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final midway = ground(tester);
      expect(midway, isNot(appLightColors.background));
      expect(midway, isNot(appLightColors.secondary));
      await tester.pumpAndSettle();
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

      expect(ground(tester), appLightColors.secondary);
    });

    testWidgets('on a wide window the ground runs the full width while the '
        'bar keeps the column', (tester) async {
      await pumpMxWide(tester, shell());
      await tester.drag(find.byKey(listKey), const Offset(0, -300));
      await tester.pumpAndSettle();
      final band = find
          .ancestor(of: find.byKey(_barKey), matching: find.byType(ColoredBox))
          .first;

      expect(tester.getSize(band).width, 1280);
      expect(tester.getSize(find.byKey(_barKey)).width, lessThan(1280));
      expect(ground(tester), appLightColors.secondary);
    });
  });
}

/// A feature widget that builds the app bar, as the deck screen's does.
class _WrappedBar extends StatelessWidget {
  const _WrappedBar({super.key});

  @override
  Widget build(BuildContext context) => const MxAppBar(title: 'Library');
}
