import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';

import '../../support/theme_expect.dart';

import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import '../../support/widget_harness.dart';

void main() {
  final scheme = lightColorScheme;
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

  testWidgets(
    'sizeSearch tall, labelMedium value, search surface and muted glyph',
    (tester) async {
      await pump(tester);
      final field = tester.widget<TextField>(find.byType(TextField));

      expect(
        tester.getSize(find.byType(TextField)).height,
        const AppDimens().sizeSearch,
      );
      expect(
        field.style,
        tester.element(find.byType(TextField)).texts.labelMedium,
      );
      expect(
        field.decoration!.fillColor,
        MxColorsExtension.light.searchSurface,
      );
      // The theme's field has no fill: the bar asks for its own.
      expect(
        tester
            .widget<InputDecorator>(find.byType(InputDecorator))
            .decoration
            .filled,
        isTrue,
      );
      expect(
        tester.widget<Icon>(find.byIcon(AppIcons.search)).color,
        scheme.onSurfaceVariant,
      );
    },
  );

  // DEV-393 review: a field holding a query lost its name (only its value
  // was read), and so did the route it names on screen 04.
  testWidgets('the hint names the field, empty or holding a query, once', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    // The text field's own node, where the hint and the value are read.
    final field = find.byType(EditableText);
    expect(tester.getSemantics(field).label, 'Search decks and cards');

    controller.text = 'verbs';
    // Once the hint has faded out (it adds an empty line while it fades).
    await tester.pumpAndSettle();
    final node = tester.getSemantics(field);
    expect(node.label, 'Search decks and cards');
    expect(node.value, 'verbs');
    handle.dispose();
  });

  testWidgets('no clear button until there is a query', (tester) async {
    await pump(tester);
    expect(find.byTooltip('Clear search'), findsNothing);

    await tester.enterText(find.byType(TextField), 'verb');
    await tester.pump();
    expect(find.byTooltip('Clear search'), findsOneWidget);
    expect(
      tester.getSize(find.byType(TextField)).height,
      const AppDimens().sizeSearch,
    );
  });

  testWidgets('clear empties the query and reports it', (tester) async {
    final reported = <String>[];
    await pump(tester, onChanged: reported.add);
    await tester.enterText(find.byType(TextField), 'verb');
    await tester.pump();
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(reported.last, isEmpty);
    expect(find.byTooltip('Clear search'), findsNothing);
  });

  testWidgets('clear keeps the field focused', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'kanji');
    await tester.pump();
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  }, variant: TargetPlatformVariant.all());

  testWidgets('focus keeps the search surface and tints the glyph', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));

    expect(field.decoration!.fillColor, MxColorsExtension.light.searchSurface);
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.search)).color,
      accentOf(scheme),
    );
  });

  testWidgets('a long query stays on one line', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'a very long query ' * 8);
    await tester.pump();

    expect(tester.widget<TextField>(find.byType(TextField)).maxLines, 1);
    expect(
      tester.getSize(find.byType(TextField)).height,
      const AppDimens().sizeSearch,
    );
  });

  group('trigger', () {
    Future<void> pumpTrigger(WidgetTester tester, VoidCallback onTap) => pumpMx(
      tester,
      SizedBox(
        width: 328,
        child: MxSearchField.trigger(hintText: 'Search decks', onTap: onTap),
      ),
    );

    testWidgets(
      'looks like the resting field: sizeSearch tall, search surface, hint',
      (tester) async {
        await pumpTrigger(tester, () {});
        final field = tester.widget<TextField>(find.byType(TextField));

        expect(
          tester.getSize(find.byType(TextField)).height,
          const AppDimens().sizeSearch,
        );
        expect(
          field.decoration!.fillColor,
          MxColorsExtension.light.searchSurface,
        );
        expect(find.text('Search decks'), findsOneWidget);
      },
    );

    testWidgets('a tap calls onTap once and takes no focus', (tester) async {
      var taps = 0;
      await pumpTrigger(tester, () => taps++);

      await tester.tap(find.byType(MxSearchField));
      await tester.pump();

      expect(taps, 1);
      expect(tester.testTextInput.hasAnyClients, isFalse);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
    });

    testWidgets('a press ripples over the field, clipped to its stadium', (
      tester,
    ) async {
      await pumpTrigger(tester, () {});
      final field = tester.getRect(find.byType(TextField));
      final inks = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_InkFeatures',
      );

      final gesture = await tester.startGesture(field.center);
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        tester.renderObject(inks.last),
        paints..clipRRect(
          rrect: RRect.fromRectAndRadius(
            Offset.zero & field.size,
            Radius.circular(const AppDimens().sizeSearch / 2),
          ),
        ),
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('hovering lays the hover state over the field', (tester) async {
      await pumpTrigger(tester, () {});
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);

      await mouse.moveTo(tester.getCenter(find.byType(TextField)));
      await tester.pumpAndSettle();
      final inks = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_InkFeatures',
      );

      expect(
        tester.renderObject(inks.last),
        paints..rrect(
          color: Theme.of(tester.element(find.byType(MxSearchField)))
              .hoverColor,
        ),
      );
    });

    testWidgets('the keyboard reaches it at one tab stop', (tester) async {
      await pumpTrigger(tester, () {});
      final scope = FocusScope.of(tester.element(find.byType(MxSearchField)));

      expect(
        scope.traversalDescendants.where((n) => n.canRequestFocus),
        hasLength(1),
      );
    });

    testWidgets('reads as a button named by the hint, with no clear button', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpTrigger(tester, () {});

      expect(
        tester.getSemantics(find.byType(MxSearchField)),
        isSemantics(label: 'Search decks', isButton: true, hasTapAction: true),
      );
      expect(find.byType(MxIconButton), findsNothing);
      semantics.dispose();
    });
  });

  // M3F-13: a filled enabled decorator blends ThemeData.hoverColor into its
  // fill, so the search surface now hovers at the token layer.
  for (final brightness in Brightness.values) {
    testWidgets('M3F-13: a hovered search field blends onSurface at '
        'opacityHover over the search surface ($brightness)', (tester) async {
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
      final context = tester.element(find.byType(MxSearchField));
      // The decorator paints its fill with the hover colour blended in.
      PaintPattern paintsFill(Color color) =>
          paints..something((name, arguments) {
            if (name != #drawRRect && name != #drawPath) return false;
            final paint = arguments.whereType<Paint>().first;
            return paint.style == PaintingStyle.fill &&
                paint.color.toARGB32() == color.toARGB32();
          });
      final painter = tester.renderObject(
        find
            .descendant(
              of: find.byType(InputDecorator),
              matching: find.byType(CustomPaint),
            )
            .first,
      );

      expect(painter, paintsFill(context.mxColors.searchSurface));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(TextField)));
      await tester.pumpAndSettle();

      expect(
        painter,
        paintsFill(
          Color.alphaBlend(
            context.colors.onSurface.withValues(
              alpha: context.dimens.opacityHover,
            ),
            context.mxColors.searchSurface,
          ),
        ),
      );
    });
  }
}
