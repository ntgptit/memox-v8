import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import 'support/mx_harness.dart';

OutlineInputBorder _enabledEdge(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).decoration!.enabledBorder!
        as OutlineInputBorder;

/// The height the fill and the edge are painted at: one line of the field's
/// style plus its padding. An outer `constraints` box would make the widget
/// taller than this without growing the paint, so none may be set.
double _paintedHeight(WidgetTester tester) {
  final TextField field = tester.widget(find.byType(TextField));
  final InputDecoration decoration = field.decoration!;
  expect(decoration.constraints, isNull);
  final EdgeInsets padding = decoration.contentPadding! as EdgeInsets;
  final TextStyle style = field.style!;
  return padding.vertical + style.fontSize! * style.height!;
}

void main() {
  testWidgets('form: 52 tall on the muted fill with a 3:1 outline edge', (
    tester,
  ) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(controller: TextEditingController()),
      ),
    );
    expect(tester.getSize(find.byType(TextField)).height, AppSize.field);
    expect(_paintedHeight(tester), AppSize.field);
    expect(_enabledEdge(tester).borderSide.color, s.outline);
  });

  testWidgets('an error turns the edge to error and shows its message', (
    tester,
  ) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: TextEditingController(),
          label: 'Name',
          message: 'Enter a name',
        ),
      ),
    );
    expect(_enabledEdge(tester).borderSide.color, s.error);
    expect(find.byType(MxFieldMessage), findsOneWidget);
    expect(find.text('Enter a name'), findsOneWidget);
  });

  testWidgets('a warning keeps the edge and shows its message', (tester) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: TextEditingController(),
          message: 'Close to the limit',
          messageTone: MxFieldMessageTone.warning,
        ),
      ),
    );
    expect(_enabledEdge(tester).borderSide.color, s.outline);
  });

  testWidgets('the label and the Required mark sit above the field', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: TextEditingController(),
          label: 'Term',
          requiredText: 'Required',
        ),
      ),
    );
    expect(
      tester.getBottomLeft(find.text('Term')).dy,
      lessThan(tester.getTopLeft(find.byType(TextField)).dy),
    );
    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('detail and meaning grow with their text', (tester) async {
    final controller = TextEditingController(text: 'one');
    await pumpMx(
      tester,
      SizedBox(
        width: 240,
        child: MxTextField(
          controller: controller,
          variant: MxTextFieldVariant.meaning,
        ),
      ),
    );
    expect(_paintedHeight(tester), AppSize.fieldMeaning);
    final double short = tester.getSize(find.byType(TextField)).height;
    controller.text = List.filled(12, 'a meaning that wraps').join(' ');
    await tester.pump();
    expect(
      tester.getSize(find.byType(InputDecorator)).height,
      greaterThan(short),
    );
  });

  testWidgets('code takes six digits only, centred', (tester) async {
    final controller = TextEditingController();
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: controller,
          variant: MxTextFieldVariant.code,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '12a34567');
    expect(controller.text, '123456');
    final TextField field = tester.widget(find.byType(TextField));
    expect(field.textAlign, TextAlign.center);
    expect(field.keyboardType, TextInputType.number);
  });

  testWidgets('study is bare: no fill and no edge', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: TextEditingController(),
          variant: MxTextFieldVariant.study,
        ),
      ),
    );
    final InputDecoration decoration = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;
    expect(decoration.filled, isFalse);
    expect(decoration.enabledBorder, InputBorder.none);
  });
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    testWidgets('$name: focus draws a 2dp Indigo Accent edge, not primary', (
      tester,
    ) async {
      await pumpMx(
        tester,
        SizedBox(
          width: 300,
          child: MxTextField(controller: TextEditingController()),
        ),
        theme: theme,
      );
      final OutlineInputBorder focused =
          tester
                  .widget<TextField>(find.byType(TextField))
                  .decoration!
                  .focusedBorder!
              as OutlineInputBorder;
      expect(focused.borderSide.color, theme.colorScheme.onPrimaryContainer);
      expect(focused.borderSide.width, AppStroke.control);
      expect(
        tester.widget<TextField>(find.byType(TextField)).cursorColor,
        anyOf(isNull, theme.colorScheme.onPrimaryContainer),
      );
    });
  }

  testWidgets('read-only keeps full contrast, can be focused and copied', (
    tester,
  ) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: TextEditingController(text: 'Spanish'),
          label: 'Deck',
          isReadOnly: true,
        ),
      ),
    );
    final TextField field = tester.widget(find.byType(TextField));
    expect(field.readOnly, isTrue);
    expect(field.enabled, isNot(false));
    expect(field.showCursor, isFalse);
    expect(field.decoration!.fillColor, s.surfaceContainer);
    expect(field.decoration!.enabledBorder!.borderSide.style, BorderStyle.none);
    expect(find.byType(Opacity), findsNothing);
    expect(
      tester.getSemantics(find.byType(EditableText)),
      isSemantics(
        isTextField: true,
        isReadOnly: true,
        isEnabled: true,
        isFocusable: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('disabled dims the whole field and cannot be focused', (
    tester,
  ) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: TextEditingController(text: 'Spanish'),
          label: 'Deck',
          isEnabled: false,
        ),
      ),
    );
    final TextField field = tester.widget(find.byType(TextField));
    expect(field.enabled, isFalse);
    expect(field.readOnly, isFalse);
    final Opacity dim = tester.widget(
      find.ancestor(of: find.text('Deck'), matching: find.byType(Opacity)),
    );
    expect(dim.opacity, AppOpacity.disabled);
    expect(
      find.ancestor(of: find.byType(TextField), matching: find.byWidget(dim)),
      findsOneWidget,
    );
    expect(
      field.decoration!.disabledBorder!.borderSide.color,
      s.outlineVariant,
    );
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pump();
    expect(
      tester.getSemantics(find.byType(EditableText)),
      // Flutter marks every text field focusable in semantics; a disabled
      // one is announced as disabled, and a tap cannot give it focus.
      isSemantics(isTextField: true, isEnabled: false),
    );
    semantics.dispose();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
  });

  testWidgets('a leading icon and one named trailing action', (tester) async {
    var cleared = 0;
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: TextEditingController(),
          leadingIcon: Icons.search,
          trailingAction: MxTextFieldAction(
            icon: Icons.close,
            semanticLabel: 'Clear',
            onPressed: () => cleared++,
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byType(MxIconButton), findsOneWidget);
    await tester.tap(find.byTooltip('Clear'));
    expect(cleared, 1);
    expect(tester.getSize(find.byType(TextField)).height, AppSize.field);
  });

  testWidgets('a growing field keeps its text at the top', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: TextEditingController(),
          variant: MxTextFieldVariant.meaning,
        ),
      ),
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).textAlignVertical,
      TextAlignVertical.top,
    );
  });

  testWidgets('the visible label names the field for TalkBack', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxTextField(
          controller: TextEditingController(),
          label: 'Deck',
          requiredText: 'Required',
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(EditableText)),
      isSemantics(isTextField: true, label: 'Deck', hint: 'Required'),
    );
    semantics.dispose();
  });
}
