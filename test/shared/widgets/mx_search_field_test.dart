import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart' as mu;
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

final _field = find.byType(FTextField);

FTextFieldStyle _style(WidgetTester tester) =>
    forUiTheme(tester, _field).textFieldStyles.lg;

/// What the field's decorator paints behind the text.
mu.InputDecoration _decoration(WidgetTester tester) =>
    tester.widget<mu.InputDecorator>(find.byType(mu.InputDecorator)).decoration;

/// The edge the field draws in [states].
BorderSide _edge(
  WidgetTester tester, [
  Set<mu.WidgetState> states = const {},
]) => (_decoration(tester).border! as mu.WidgetStateProperty<mu.InputBorder>)
    .resolve(states)
    .borderSide;

Finder _clear() => find.bySemanticsLabel('Clear search');

void main() {
  final colors = appLightColors;
  late TextEditingController controller;

  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  Future<void> pump(WidgetTester tester, {ValueChanged<String>? onChanged}) =>
      pumpMx(
        tester,
        SizedBox(
          width: 328,
          child: MxSearchField(
            controller: controller,
            hintText: 'Search decks and cards',
            clearLabel: 'Clear search',
            onChanged: onChanged,
          ),
        ),
      );

  testWidgets('a large ForUI field tall, the value in the content style, '
      'the muted surface and a muted glyph', (tester) async {
    await pump(tester);
    final style = _style(tester);

    expect(tester.getSize(_field).height, style.constraints.minHeight);
    expect(tester.getSize(_field).height, greaterThanOrEqualTo(48));
    expect(_decoration(tester).filled, isTrue);
    expect(_decoration(tester).fillColor, colors.muted);
    expect(_decoration(tester).hintText, 'Search decks and cards');
    expect(
      iconColor(tester, find.byIcon(AppIcons.search)),
      colors.mutedForeground,
    );
    await tester.enterText(find.byType(EditableText), 'verbs');
    await tester.pump();
    final text = tester.widget<EditableText>(find.byType(EditableText));
    expect(text.style.fontSize, style.contentTextStyle.resolve({}).fontSize);
    expect(text.style.color, style.contentTextStyle.resolve({}).color);
  });

  testWidgets('the surface has no edge, at rest or focused', (tester) async {
    await pump(tester);
    expect(_edge(tester), BorderSide.none);

    await tester.tap(_field);
    await tester.pump();

    expect(_edge(tester, {mu.WidgetState.focused}), BorderSide.none);
    expect(_decoration(tester).fillColor, colors.muted);
  });

  // DEV-393 review: a field holding a query lost its name (only its value
  // was read), and so did the route it names on screen 04.
  testWidgets('the hint names the field, empty or holding a query, once', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(find.bySemanticsLabel('Search decks and cards'), findsOneWidget);

    controller.text = 'verbs';
    // Once the hint has faded out.
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Search decks and cards'), findsOneWidget);
    expect(tester.getSemantics(find.byType(EditableText)).value, 'verbs');
    handle.dispose();
  });

  testWidgets('no clear button until there is a query', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(_clear(), findsNothing);
    final rest = tester.getSize(_field).height;

    await tester.enterText(find.byType(EditableText), 'verb');
    await tester.pumpAndSettle();
    expect(_clear(), findsOneWidget);
    expect(tester.getSize(_field).height, rest);
    handle.dispose();
  });

  testWidgets('the clear button is a 48 target at the end of the field', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await tester.enterText(find.byType(EditableText), 'verb');
    await tester.pumpAndSettle();

    expect(find.byType(MxIconButton), findsOneWidget);
    expect(tester.getSize(_clear()).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(_clear()).height, greaterThanOrEqualTo(48));
    expect(
      tester.getRect(_field).right - tester.getRect(_clear()).right,
      lessThanOrEqualTo(8),
    );
    handle.dispose();
    await expectAccessibleTargets(tester);
  });

  testWidgets('clear empties the query and reports it', (tester) async {
    final handle = tester.ensureSemantics();
    final reported = <String>[];
    await pump(tester, onChanged: reported.add);
    await tester.enterText(find.byType(EditableText), 'verb');
    await tester.pump();
    await tester.tap(_clear());
    await tester.pumpAndSettle();

    expect(controller.text, isEmpty);
    expect(reported.last, isEmpty);
    expect(_clear(), findsNothing);
    handle.dispose();
  });

  testWidgets('clear keeps the field focused', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await tester.tap(_field);
    await tester.enterText(find.byType(EditableText), 'kanji');
    await tester.pump();
    await tester.tap(_clear());
    await tester.pumpAndSettle();

    expect(controller.text, isEmpty);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    handle.dispose();
  }, variant: TargetPlatformVariant.all());

  testWidgets('focus keeps the search surface and tints the glyph', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(_field);
    await tester.pump();

    expect(_decoration(tester).fillColor, colors.muted);
    expect(iconColor(tester, find.byIcon(AppIcons.search)), colors.primary);
  });

  testWidgets('a long query stays on one line', (tester) async {
    await pump(tester);
    final rest = tester.getSize(_field).height;
    await tester.enterText(find.byType(EditableText), 'a very long query ' * 8);
    await tester.pump();

    expect(tester.widget<EditableText>(find.byType(EditableText)).maxLines, 1);
    expect(tester.getSize(_field).height, rest);
  });

  group('trigger', () {
    final button = find.byType(FButton);

    Future<void> pumpTrigger(WidgetTester tester, VoidCallback onTap) => pumpMx(
      tester,
      SizedBox(
        width: 328,
        child: MxSearchField.trigger(hintText: 'Search decks', onTap: onTap),
      ),
    );

    testWidgets('looks like the resting field: as tall, muted surface, hint', (
      tester,
    ) async {
      await pump(tester);
      final rest = tester.getSize(_field).height;
      final hintStyle = _style(tester).hintTextStyle.resolve({});
      await pumpTrigger(tester, () {});

      expect(tester.getSize(button).height, rest);
      expect(tester.getSize(button).width, 328);
      expect(paintedDecoration(tester, button).color, colors.muted);
      expect(paintedSide(tester, button), BorderSide.none);
      final pill = paintedDecoration(tester, button).shape;
      expect(
        pill.getOuterPath(const Rect.fromLTWH(0, 0, 328, 48)).getBounds(),
        const Rect.fromLTWH(0, 0, 328, 48),
      );
      expect(find.text('Search decks'), findsOneWidget);
      final hint = DefaultTextStyle.of(
        tester.element(find.text('Search decks')),
      ).style;
      expect(
        (hint.color, hint.fontSize, hint.fontWeight, hint.fontFamily),
        (
          hintStyle.color,
          hintStyle.fontSize,
          hintStyle.fontWeight,
          hintStyle.fontFamily,
        ),
      );
      expect(
        iconColor(tester, find.byIcon(AppIcons.search)),
        colors.mutedForeground,
      );
    });

    testWidgets('the glyph and the hint sit at the 16 inset, 8 apart', (
      tester,
    ) async {
      await pumpTrigger(tester, () {});

      final left = tester.getTopLeft(button).dx;
      final glyph = tester.getRect(find.byIcon(AppIcons.search));
      expect(glyph.left - left, 16);
      expect(tester.getTopLeft(find.text('Search decks')).dx - glyph.right, 8);
    });

    testWidgets('a tap calls onTap once and takes no focus', (tester) async {
      var taps = 0;
      await pumpTrigger(tester, () => taps++);

      await tester.tap(find.byType(MxSearchField));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(tester.testTextInput.hasAnyClients, isFalse);
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('hovering leaves the search surface as it is', (tester) async {
      await pumpTrigger(tester, () {});
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);

      await mouse.moveTo(tester.getCenter(button));
      await tester.pumpAndSettle();

      expect(paintedDecoration(tester, button).color, colors.muted);
      expect(paintedSide(tester, button), BorderSide.none);
      final hint = DefaultTextStyle.of(
        tester.element(find.text('Search decks')),
      ).style;
      expect(
        hint.color,
        forUiTheme(
          tester,
          button,
        ).textFieldStyles.lg.hintTextStyle.resolve({}).color,
      );
      expect(
        iconColor(tester, find.byIcon(AppIcons.search)),
        colors.mutedForeground,
      );
    });

    testWidgets('pressing it does not shrink it', (tester) async {
      await pumpTrigger(tester, () {});
      final rest = tester.getRect(button);

      final press = await tester.startGesture(tester.getCenter(button));
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.getRect(button), rest);
      expect(paintedDecoration(tester, button).color, colors.muted);
      await press.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the keyboard reaches it at one tab stop, with the outline '
        'round the pill, and Enter presses it', (tester) async {
      var taps = 0;
      await pumpTrigger(tester, () => taps++);
      final scope = FocusScope.of(tester.element(find.byType(MxSearchField)));

      expect(
        scope.traversalDescendants.where((n) => n.canRequestFocus),
        hasLength(1),
      );
      useKeyboardFocusHighlight();
      final outline = forUiTheme(
        tester,
        find.byType(MxSearchField),
      ).style.focusedOutlineStyle;
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(
        focusRingRender(tester),
        paintsFocusRing(outline.color, width: outline.width),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('reads as a button named by the hint, with no clear button', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpTrigger(tester, () {});

      expect(
        tester.getSemantics(find.bySemanticsLabel('Search decks')),
        isSemantics(label: 'Search decks', isButton: true, hasTapAction: true),
      );
      expect(find.bySemanticsLabel('Search decks'), findsOneWidget);
      expect(find.byType(MxIconButton), findsNothing);
      semantics.dispose();
    });
  });

  group('isAutofocused', () {
    testWidgets('is off by default: the field does not take focus', (
      tester,
    ) async {
      await pump(tester);

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
    });

    testWidgets('takes focus on arrival and opens the keyboard', (
      tester,
    ) async {
      await pumpMx(
        tester,
        SizedBox(
          width: 328,
          child: MxSearchField(
            controller: controller,
            hintText: 'Search decks and cards',
            clearLabel: 'Clear search',
            isAutofocused: true,
          ),
        ),
      );
      await tester.pump();

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(tester.testTextInput.hasAnyClients, isTrue);
    });
  });

  // M3F-13 asked the filled field to hover at the token layer; the ForUI
  // search surface paints the one muted ground in every state, in both
  // themes.
  for (final brightness in Brightness.values) {
    testWidgets('a hovered search field keeps the muted surface '
        '($brightness)', (tester) async {
      await pumpMx(
        tester,
        SizedBox(
          width: 328,
          child: MxSearchField(
            controller: controller,
            hintText: 'Search decks and cards',
            clearLabel: 'Clear search',
          ),
        ),
        brightness: brightness,
      );
      final muted = brightness == Brightness.light
          ? appLightColors.muted
          : appDarkColors.muted;
      expect(_decoration(tester).fillColor, muted);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(_field));
      await tester.pumpAndSettle();

      expect(_decoration(tester).fillColor, muted);
    });
  }
}
