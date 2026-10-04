import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_breakpoints.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_screen_scaffold.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import 'support/mx_harness.dart';

const Key _body = ValueKey<String>('body');

/// The snackbar's painted surface (the widget itself spans its margin).
final Finder _snackbarSurface = find
    .descendant(of: find.byType(SnackBar), matching: find.byType(Material))
    .first;

MxScreenScaffold _screen({bool hasFooter = false, bool hasFab = false}) =>
    MxScreenScaffold(
      appBar: const MxAppBar(title: 'Spanish'),
      breadcrumb: const MxBreadcrumb(
        items: [
          MxBreadcrumbItem(label: 'Library'),
          MxBreadcrumbItem(label: 'Spanish'),
        ],
      ),
      body: const SizedBox.expand(key: _body),
      footer: hasFooter
          ? const MxFooterBar(caption: 'Saved on this phone')
          : null,
      fab: hasFab
          ? MxFab(icon: Icons.add, semanticLabel: 'New card', onPressed: () {})
          : null,
    );

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(400, 800),
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: mxThemes['light'],
      home: Directionality(textDirection: direction, child: screen),
    ),
  );
}

void main() {
  testWidgets('bar, pinned breadcrumb, body, then the footer', (tester) async {
    await _pump(tester, _screen(hasFooter: true));
    final double bar = tester.getRect(find.byType(MxAppBar)).bottom;
    final Rect path = tester.getRect(find.byType(MxBreadcrumb));
    final Rect body = tester.getRect(find.byKey(_body));
    final Rect footer = tester.getRect(find.byType(MxFooterBar));
    expect(path.top, greaterThanOrEqualTo(bar));
    expect(body.top, greaterThanOrEqualTo(path.bottom));
    expect(footer.top, greaterThanOrEqualTo(body.bottom));
    expect(footer.bottom, 800);
  });

  testWidgets('on a wide window the body keeps to the 720 column', (
    tester,
  ) async {
    await _pump(tester, _screen(), size: const Size(1000, 800));
    final Rect body = tester.getRect(find.byKey(_body));
    expect(body.width, AppBreakpoints.contentMax);
    expect(body.left, (1000 - AppBreakpoints.contentMax) / 2);
  });

  testWidgets('the FAB sits 16 inside the column, above the footer', (
    tester,
  ) async {
    await _pump(
      tester,
      _screen(hasFooter: true, hasFab: true),
      size: const Size(1000, 800),
    );
    final Rect fab = tester.getRect(find.byType(MxFab));
    final Rect footer = tester.getRect(find.byType(MxFooterBar));
    final double columnEnd = (1000 + AppBreakpoints.contentMax) / 2;
    expect(fab.right, columnEnd - 16);
    expect(fab.bottom, footer.top - 16);
  });

  testWidgets('in right-to-left text the FAB moves to the start edge', (
    tester,
  ) async {
    await _pump(tester, _screen(hasFab: true), direction: TextDirection.rtl);
    expect(tester.getRect(find.byType(MxFab)).left, 16);
  });

  testWidgets('the FAB clears the system bar when no footer holds it', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(bottom: 48);
    await _pump(tester, _screen(hasFab: true));
    expect(tester.getRect(find.byType(MxFab)).bottom, 800 - 48 - 16);
  });

  testWidgets('the footer rides above the keyboard', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await _pump(tester, _screen(hasFooter: true));
    expect(
      tester.getRect(find.byType(MxFooterBar)).bottom,
      lessThanOrEqualTo(800 - 300),
    );
  });

  testWidgets('the footer clears the navigation bar on its own ground', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    await _pump(tester, _screen(hasFooter: true));
    expect(tester.getRect(find.byType(MxFooterBar)).bottom, 800);
    expect(
      tester.getRect(find.text('Saved on this phone')).bottom,
      lessThanOrEqualTo(800 - 48),
    );
  });

  testWidgets('with the keyboard up the footer sits on it, not on the bar', (
    tester,
  ) async {
    // The platform zeroes the bottom padding while the keyboard covers the
    // system bar; the view padding still names the bar.
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    tester.view.padding = FakeViewPadding.zero;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await _pump(tester, _screen(hasFooter: true));
    expect(tester.getRect(find.byType(MxFooterBar)).bottom, 800 - 300);
  });

  testWidgets(
    'a pinned breadcrumb shares the bar ground as content passes under',
    (tester) async {
      await _pump(
        tester,
        MxScreenScaffold(
          appBar: const MxAppBar(title: 'Spanish'),
          breadcrumb: const MxBreadcrumb(
            items: [
              MxBreadcrumbItem(label: 'Library'),
              MxBreadcrumbItem(label: 'Spanish'),
            ],
          ),
          body: ListView(
            children: [
              for (var i = 0; i < 40; i++)
                const SizedBox(height: 56, child: Text('Row')),
            ],
          ),
        ),
      );
      Color ground(Finder of) => tester
          .widget<Material>(
            find.ancestor(of: of, matching: find.byType(Material)).first,
          )
          .color!;
      final ColorScheme s = mxThemes['light']!.colorScheme;
      expect(ground(find.byType(MxBreadcrumb)), s.surface);
      await tester.drag(find.byType(Scrollable), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(ground(find.text('Spanish').first), s.surfaceContainer);
      expect(ground(find.byType(MxBreadcrumb)), s.surfaceContainer);
    },
  );

  testWidgets('with a footer the body still gets one status-bar inset', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 40);
    await _pump(
      tester,
      const MxScreenScaffold(
        appBar: MxAppBar(title: 'New card'),
        body: MxScreenScroll(children: [SizedBox(key: _body, height: 40)]),
        footer: MxFooterBar(caption: 'Saved on this phone'),
      ),
    );
    expect(
      tester.getRect(find.byKey(_body)).top,
      tester.getRect(find.byType(MxAppBar)).bottom,
    );
  });

  testWidgets('with a footer the body does not see the keyboard again', (
    tester,
  ) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    late double seen;
    await _pump(
      tester,
      MxScreenScaffold(
        appBar: const MxAppBar(title: 'New card'),
        body: Builder(
          builder: (context) {
            seen = MediaQuery.viewInsetsOf(context).bottom;
            return const SizedBox.expand();
          },
        ),
        footer: const MxFooterBar(caption: 'Saved on this phone'),
      ),
    );
    expect(seen, 0);
  });

  testWidgets('over a footer the FAB keeps 16, whatever the system bar', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    await _pump(tester, _screen(hasFooter: true, hasFab: true));
    expect(
      tester.getRect(find.byType(MxFab)).bottom,
      tester.getRect(find.byType(MxFooterBar)).top - 16,
    );
  });

  testWidgets('a bottom inset handed down by the shell drops while typing', (
    tester,
  ) async {
    await _pump(tester, _screen(hasFooter: true));
    final double rest = tester.getSize(find.byType(MxFooterBar)).height;
    tester.view.padding = const FakeViewPadding(bottom: 80);
    tester.view.viewPadding = const FakeViewPadding(bottom: 80);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await _pump(tester, _screen(hasFooter: true));
    expect(tester.getRect(find.byType(MxFooterBar)).bottom, 800 - 300);
    expect(tester.getSize(find.byType(MxFooterBar)).height, rest);
  });

  testWidgets('the FAB keeps clear of a display cutout at its end', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(right: 40);
    tester.view.viewPadding = const FakeViewPadding(right: 40);
    await _pump(tester, _screen(hasFab: true));
    expect(tester.getRect(find.byType(MxFab)).right, 400 - 40 - 16);
  });

  testWidgets('a breadcrumb needs the bar it is pinned under', (tester) async {
    await _pump(
      tester,
      const MxScreenScaffold(
        breadcrumb: MxBreadcrumb(items: [MxBreadcrumbItem(label: 'Library')]),
        body: SizedBox.expand(),
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('a snackbar floats above the footer, even one its Save opened', (
    tester,
  ) async {
    await _pump(
      tester,
      MxScreenScaffold(
        appBar: const MxAppBar(title: 'New card'),
        body: const SizedBox.expand(),
        footer: MxFooterBar(
          caption: 'Saved on this phone',
          actions: Builder(
            builder: (context) => MxSheetActions(
              confirmLabel: 'Save card',
              onConfirm: () => showMxSnackbar(context, message: 'Card saved'),
            ),
          ),
        ),
      ),
    );
    // The footer's height reaches the scaffold on the frame after layout.
    await tester.pump();
    await tester.tap(find.text('Save card'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(_snackbarSurface).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(MxFooterBar)).top - 16),
    );
  });

  testWidgets('a snackbar floats above the FAB', (tester) async {
    await _pump(
      tester,
      MxScreenScaffold(
        appBar: const MxAppBar(title: 'Library'),
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showMxSnackbar(context, message: 'Deck added'),
            child: const Text('Go'),
          ),
        ),
        fab: MxFab(icon: Icons.add, semanticLabel: 'New', onPressed: () {}),
      ),
    );
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(_snackbarSurface).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(MxFab)).top - 16),
    );
  });
}
