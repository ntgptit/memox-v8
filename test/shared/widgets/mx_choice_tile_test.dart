import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: brightness == Brightness.light
          ? buildLightTheme()
          : buildDarkTheme(),
      home: Scaffold(
        body: Center(child: SizedBox(width: 300, child: child)),
      ),
    );

MxChoiceTile _tile({
  MxChoiceTone tone = MxChoiceTone.idle,
  bool isSelected = false,
  VoidCallback? onTap,
}) => MxChoiceTile(
  tone: tone,
  isSelected: isSelected,
  semanticsLabel: 'Option 1, 보기 1',
  padding: const EdgeInsets.all(16),
  onTap: onTap,
  builder: (foreground) => Text('① 보기 1', style: TextStyle(color: foreground)),
);

BoxDecoration _decoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(
                of: find.byType(MxChoiceTile),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration
        as BoxDecoration;

// The study choice surface, shared (TOPIK spec §13.10): Guess, Match and the
// TOPIK attempt's options.
void main() {
  testWidgets('one node: its label, a button, selected, and its tap', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      _host(_tile(isSelected: true, onTap: () => taps++)),
    );

    final node = tester.getSemantics(find.byType(MxChoiceTile));
    final flags = node.getSemanticsData().flagsCollection;
    expect(node.label, 'Option 1, 보기 1');
    expect(flags.isButton, isTrue);
    expect(flags.isSelected, Tristate.isTrue);
    await tester.tap(find.byType(MxChoiceTile));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('without a tap it is inert and not a button', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(_tile()));

    final node = tester.getSemantics(find.byType(MxChoiceTile));
    expect(node.getSemanticsData().flagsCollection.isButton, isFalse);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    handle.dispose();
  });

  testWidgets('at least a control tall, whatever its content', (tester) async {
    await tester.pumpWidget(
      _host(
        MxChoiceTile(
          tone: MxChoiceTone.idle,
          semanticsLabel: 'a',
          builder: (_) => const SizedBox(height: 4),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(MxChoiceTile)).height,
      greaterThanOrEqualTo(const AppDimens().sizeControl),
    );
  });

  testWidgets('selected is the primary fill with the content on primary', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_tile(tone: MxChoiceTone.selected)));
    await tester.pumpAndSettle();

    final colors = buildLightTheme().colorScheme;
    expect(_decoration(tester).color, colors.primary);
    final text = tester.widget<Text>(find.text('① 보기 1'));
    expect(text.style?.color, colors.primaryForeground);
  });

  testWidgets('idle is the card ground with the content on surface', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_tile()));
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.text('① 보기 1'));
    expect(text.style?.color, buildLightTheme().colorScheme.onSurface);
  });
}
