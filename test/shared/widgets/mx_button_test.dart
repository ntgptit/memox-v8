import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import 'support/mx_harness.dart';

Color? _fill(WidgetTester tester) => tester
    .widget<TextButton>(find.byType(TextButton))
    .style!
    .backgroundColor!
    .resolve(<WidgetState>{});

Color? _content(WidgetTester tester) => tester
    .widget<TextButton>(find.byType(TextButton))
    .style!
    .foregroundColor!
    .resolve(<WidgetState>{});

Size _painted(WidgetTester tester) => tester.getSize(
  find.descendant(of: find.byType(TextButton), matching: find.byType(Material)),
);

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    final AppSemanticColors x = theme.extension<AppSemanticColors>()!;
    final Map<MxButtonTone, (Color, Color)> pairs = {
      MxButtonTone.primary: (s.primary, s.onPrimary),
      MxButtonTone.secondary: (s.surfaceContainer, s.onSurface),
      MxButtonTone.outline: (Colors.transparent, s.primary),
      MxButtonTone.text: (Colors.transparent, s.primary),
      MxButtonTone.destructive: (s.error, s.onError),
      MxButtonTone.dangerSoft: (s.errorContainer, s.onErrorContainer),
      MxButtonTone.warning: (x.warning, x.onWarning),
    };
    for (final MapEntry(key: tone, value: (fill, content)) in pairs.entries) {
      testWidgets('$name: ${tone.name} paints its role pair', (tester) async {
        await pumpMx(
          tester,
          MxButton(label: 'Go', tone: tone, onPressed: () {}),
          theme: theme,
        );
        expect(_fill(tester), fill);
        expect(_content(tester), content);
      });
    }

    testWidgets('$name: the theme slots are the same style as MxButton', (
      tester,
    ) async {
      final Map<ButtonStyle?, MxButtonTone> slots = {
        theme.filledButtonTheme.style: MxButtonTone.primary,
        theme.outlinedButtonTheme.style: MxButtonTone.outline,
        theme.textButtonTheme.style: MxButtonTone.text,
      };
      for (final MapEntry(key: style, value: tone) in slots.entries) {
        expect(style!.backgroundColor!.resolve({}), pairs[tone]!.$1);
        expect(style.foregroundColor!.resolve({}), pairs[tone]!.$2);
      }
    });
  }

  testWidgets('outline draws an outline edge; the others draw none', (
    tester,
  ) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    await pumpMx(
      tester,
      MxButton(label: 'Go', tone: MxButtonTone.outline, onPressed: () {}),
    );
    final BorderSide edge = tester
        .widget<TextButton>(find.byType(TextButton))
        .style!
        .side!
        .resolve({})!;
    expect(edge.color, s.outline);
    await pumpMx(tester, MxButton(label: 'Go', onPressed: () {}));
    expect(
      tester
          .widget<TextButton>(find.byType(TextButton))
          .style!
          .side!
          .resolve({}),
      BorderSide.none,
    );
  });

  for (final size in MxButtonSize.values) {
    testWidgets('${size.name} paints ${size.height} and hits at least 48', (
      tester,
    ) async {
      await pumpMx(tester, MxButton(label: 'Go', size: size, onPressed: () {}));
      expect(_painted(tester).height, size.height);
      final Size hit = tester.getSize(find.byType(TextButton));
      expect(hit.height, greaterThanOrEqualTo(AppSize.tapTarget));
      expect(hit.width, greaterThanOrEqualTo(AppSize.tapTarget));
    });
  }

  testWidgets('a disabled button is dimmed and announced as disabled', (
    tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpMx(tester, const MxButton(label: 'Go', onPressed: null));
    expect(
      tester.widget<Opacity>(find.byType(Opacity)).opacity,
      AppOpacity.disabled,
    );
    expect(
      tester.getSemantics(find.byType(TextButton)),
      matchesSemantics(
        label: 'Go',
        isButton: true,
        hasEnabledState: true,
        isFocusable: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('loading keeps the width, shows a spinner and blocks taps', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxButton(label: 'Save the deck', onPressed: () => taps++),
    );
    final double width = tester.getSize(find.byType(TextButton)).width;
    await pumpMx(
      tester,
      MxButton(
        label: 'Save the deck',
        isLoading: true,
        onPressed: () => taps++,
      ),
    );
    expect(find.byType(MxSpinner), findsOneWidget);
    expect(tester.getSize(find.byType(TextButton)).width, width);
    expect(find.byType(Opacity), findsNothing);
    await tester.tap(find.byType(TextButton), warnIfMissed: false);
    expect(taps, 0);
    expect(find.bySemanticsLabel('Save the deck'), findsOneWidget);
  });

  testWidgets('a regular label wraps to two lines; compact keeps one', (
    tester,
  ) async {
    const String long = 'Import the cards from a file you exported before';
    await pumpMx(
      tester,
      SizedBox(
        width: 200,
        child: MxButton(label: long, onPressed: () {}),
      ),
    );
    expect(tester.widget<Text>(find.text(long)).maxLines, 2);
    expect(_painted(tester).height, greaterThan(AppSize.buttonRegular));
    await pumpMx(
      tester,
      SizedBox(
        width: 200,
        child: MxButton(
          label: long,
          size: MxButtonSize.compact,
          onPressed: () {},
        ),
      ),
    );
    expect(tester.widget<Text>(find.text(long)).maxLines, 1);
    expect(_painted(tester).height, AppSize.buttonCompact);
  });

  testWidgets('the detail line takes the button content colour', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxButton(label: 'Study', detail: 'Overdue first', onPressed: () {}),
      theme: mxThemes['dark'],
    );
    final RenderParagraph line = tester.renderObject(
      find.text('Overdue first'),
    );
    expect(line.text.style!.color, mxThemes['dark']!.colorScheme.onPrimary);
  });

  testWidgets('the icon leads the label, on the right in RTL', (tester) async {
    await pumpMx(
      tester,
      MxButton(label: 'Add', icon: Icons.add, onPressed: () {}),
      textDirection: TextDirection.rtl,
    );
    expect(
      tester.getCenter(find.byIcon(Icons.add)).dx,
      greaterThan(tester.getCenter(find.text('Add')).dx),
    );
  });

  testWidgets('a keyboard focus draws the focus ring; a tap does not', (
    tester,
  ) async {
    await pumpMx(tester, MxButton(label: 'Go', onPressed: () {}));
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final Finder ring = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.foregroundPainter != null,
    );
    expect(ring, findsOneWidget);
  });
}
