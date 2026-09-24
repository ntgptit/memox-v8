import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import '../../support/widget_harness.dart';

void main() {
  final scheme = AppColorSchemes.light;
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

  testWidgets('52 tall, 16/400 value, resting fill and muted glyph', (
    tester,
  ) async {
    await pump(tester);
    final field = tester.widget<TextField>(find.byType(TextField));

    expect(tester.getSize(find.byType(TextField)).height, 52);
    expect(field.style!.fontSize, 16);
    expect(field.decoration!.fillColor, scheme.surfaceContainer);
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.search)).color,
      scheme.onSurfaceVariant,
    );
  });

  testWidgets('no clear button until there is a query', (tester) async {
    await pump(tester);
    expect(find.byTooltip('Clear search'), findsNothing);

    await tester.enterText(find.byType(TextField), 'verb');
    await tester.pump();
    expect(find.byTooltip('Clear search'), findsOneWidget);
    expect(tester.getSize(find.byType(TextField)).height, 52);
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

  testWidgets('focus lightens the fill and tints the glyph', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));

    expect(field.decoration!.fillColor, scheme.surfaceContainerLowest);
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.search)).color,
      scheme.primary,
    );
  });

  testWidgets('a long query stays on one line', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'a very long query ' * 8);
    await tester.pump();

    expect(tester.widget<TextField>(find.byType(TextField)).maxLines, 1);
    expect(tester.getSize(find.byType(TextField)).height, 52);
  });

  group('trigger', () {
    Future<void> pumpTrigger(WidgetTester tester, VoidCallback onTap) => pumpMx(
      tester,
      SizedBox(
        width: 328,
        child: MxSearchField.trigger(hintText: 'Search decks', onTap: onTap),
      ),
    );

    testWidgets('looks like the resting field: 52 tall, resting fill, hint', (
      tester,
    ) async {
      await pumpTrigger(tester, () {});
      final field = tester.widget<TextField>(find.byType(TextField));

      expect(tester.getSize(find.byType(TextField)).height, 52);
      expect(field.decoration!.fillColor, scheme.surfaceContainer);
      expect(find.text('Search decks'), findsOneWidget);
    });

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
}
