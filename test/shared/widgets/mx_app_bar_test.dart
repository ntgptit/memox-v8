import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_breakpoints.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scaffold.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

import 'support/mx_harness.dart';

Future<void> _pump(
  WidgetTester tester,
  MxAppBar bar, {
  ThemeData? theme,
  Size size = const Size(400, 800),
  TextDirection direction = TextDirection.ltr,
  Widget? body,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? mxThemes['light'],
      home: Directionality(
        textDirection: direction,
        child: MxScreenScaffold(
          appBar: bar,
          body:
              body ??
              MxScreenScroll(
                children: [
                  for (var i = 0; i < 40; i++)
                    const SizedBox(height: 56, child: Text('Row')),
                ],
              ),
        ),
      ),
    ),
  );
}

Color _ground(WidgetTester tester) => tester
    .widget<Material>(
      find
          .descendant(
            of: find.byType(MxAppBar),
            matching: find.byType(Material),
          )
          .first,
    )
    .color!;

MxIconButton _icon(IconData icon) => MxIconButton(
  icon: icon,
  semanticLabel: icon.codePoint.toString(),
  onPressed: () {},
);

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    testWidgets(
      '$name: flat surface at rest, one tonal step when scrolled under',
      (tester) async {
        await _pump(tester, const MxAppBar(title: 'Library'), theme: theme);
        expect(tester.getSize(find.byType(MxAppBar)).height, AppSize.appBar);
        expect(_ground(tester), s.surface);
        await tester.drag(find.byType(Scrollable), const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(_ground(tester), s.surfaceContainer);
      },
    );
  }

  testWidgets('with no leading control the title starts on the gutter', (
    tester,
  ) async {
    await _pump(tester, const MxAppBar(title: 'Study'));
    expect(tester.getRect(find.text('Study')).left, 16);
  });

  testWidgets('after back the title starts 8 past its 48 target', (
    tester,
  ) async {
    await _pump(
      tester,
      const MxAppBar(title: 'Edit card', leading: MxAppBarLeading.back),
    );
    expect(tester.getRect(find.text('Edit card')).left, 4 + 48 + 8);
    expect(
      tester.widget<MxIconButton>(find.byType(MxIconButton)).semanticLabel,
      'Back',
    );
  });

  testWidgets('on a wide window its content keeps to the column', (
    tester,
  ) async {
    await _pump(
      tester,
      const MxAppBar(title: 'Study'),
      size: const Size(1000, 800),
    );
    expect(tester.getSize(find.byType(MxAppBar)).width, 1000);
    expect(
      tester.getRect(find.text('Study')).left,
      (1000 - AppBreakpoints.contentMax) / 2 + 16,
    );
  });

  testWidgets('close runs the caller instead of popping', (tester) async {
    var closed = 0;
    await _pump(
      tester,
      MxAppBar(
        title: '3 selected',
        leading: MxAppBarLeading.close,
        onLeading: () => closed++,
        isTitleLive: true,
      ),
    );
    await tester.tap(find.byIcon(Icons.close));
    expect(closed, 1);
  });

  testWidgets('the title is a header; a live one announces its change', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _pump(
      tester,
      const MxAppBar(
        title: '3 selected',
        leading: MxAppBarLeading.close,
        isTitleLive: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('3 selected')),
      isSemantics(isHeader: true, isLiveRegion: true),
    );
    semantics.dispose();
  });

  testWidgets('screen density uses the Title role, content Body Large', (
    tester,
  ) async {
    await _pump(tester, const MxAppBar(title: 'Library'));
    final TextTheme texts = mxThemes['light']!.textTheme;
    Text title() => tester.widget<Text>(find.text('Library'));
    expect(title().style?.fontSize, texts.titleLarge?.fontSize);
    await _pump(
      tester,
      const MxAppBar(title: 'Library', density: MxAppBarDensity.content),
    );
    expect(title().style?.fontSize, texts.titleMedium?.fontSize);
  });

  testWidgets('a long title keeps one line and the actions keep their place', (
    tester,
  ) async {
    await _pump(
      tester,
      MxAppBar(
        title: 'Irregular verbs of the past tense, chapter twelve',
        leading: MxAppBarLeading.back,
        actions: [
          _icon(Icons.search),
          _icon(Icons.tag),
          _icon(Icons.more_vert),
        ],
      ),
      size: const Size(360, 800),
    );
    expect(tester.takeException(), isNull);
    expect(tester.widget<Text>(find.textContaining('Irregular')).maxLines, 1);
    expect(
      tester.getRect(find.byIcon(Icons.more_vert)).right,
      lessThanOrEqualTo(360),
    );
  });

  testWidgets('a fourth icon action is refused', (tester) async {
    await _pump(
      tester,
      MxAppBar(
        title: 'Deck',
        actions: [
          _icon(Icons.search),
          _icon(Icons.tag),
          _icon(Icons.delete),
          _icon(Icons.more_vert),
        ],
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('one text action, in the text tone', (tester) async {
    var selected = 0;
    await _pump(
      tester,
      MxAppBar(
        title: 'Trash',
        textAction: MxAppBarTextAction(
          label: 'Select',
          onPressed: () => selected++,
        ),
      ),
    );
    await tester.tap(find.text('Select'));
    expect(selected, 1);
    expect(
      tester.getRect(find.text('Select')).right,
      lessThanOrEqualTo(400 - 4),
    );
  });

  testWidgets('in right-to-left text back leads from the right', (
    tester,
  ) async {
    await _pump(
      tester,
      const MxAppBar(title: 'Edit card', leading: MxAppBarLeading.back),
      direction: TextDirection.rtl,
    );
    expect(tester.getRect(find.byType(MxIconButton)).right, 400 - 4);
  });

  for (final double scale in [1.5, 2.0]) {
    testWidgets('at ${scale}x text a full bar neither clips nor overflows', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(
        tester,
        MxAppBar(
          title: 'Irregular verbs of the past tense',
          leading: MxAppBarLeading.back,
          actions: [_icon(Icons.search), _icon(Icons.more_vert)],
        ),
        size: const Size(360, 800),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(MxAppBar)).height, AppSize.appBar);
    });
  }

  testWidgets('at 2.0x text back, a title and a text action fit a phone', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(
      tester,
      MxAppBar(
        title: 'Trash',
        leading: MxAppBarLeading.back,
        textAction: MxAppBarTextAction(label: 'Select', onPressed: () {}),
      ),
      size: const Size(360, 800),
    );
    expect(tester.takeException(), isNull);
  });
}
