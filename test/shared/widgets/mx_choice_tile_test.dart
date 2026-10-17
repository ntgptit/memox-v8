import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/forui_expect.dart';
import '../../support/theme_harness.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: materialHostTheme(
        brightness == Brightness.light ? buildLightTheme() : buildDarkTheme(),
      ),
      builder: mxThemeBuilder(
        brightness == Brightness.light ? buildLightTheme() : buildDarkTheme(),
      ),
      home: Scaffold(
        body: Center(child: SizedBox(width: 300, child: child)),
      ),
    );

MxChoiceTile _tile({
  MxChoiceTone tone = MxChoiceTone.idle,
  bool isSelected = false,
  bool isFaded = false,
  bool isRecessed = false,
  SemanticsSortKey? sortKey,
  VoidCallback? onTap,
}) => MxChoiceTile(
  tone: tone,
  isSelected: isSelected,
  isFaded: isFaded,
  isRecessed: isRecessed,
  sortKey: sortKey,
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
    await tester.pumpAndSettle();
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

    final colors = buildLightTheme().colors;
    expect(_decoration(tester).color, colors.primary);
    final text = tester.widget<Text>(find.text('① 보기 1'));
    expect(text.style?.color, colors.primaryForeground);
  });

  testWidgets('idle is the card ground with the content on the foreground', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_tile()));
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.text('① 보기 1'));
    expect(text.style?.color, buildLightTheme().colors.foreground);
  });

  for (final tone in [MxChoiceTone.right, MxChoiceTone.wrong]) {
    testWidgets('${tone.name}: a tint of the answer colour over the page, '
        'with that colour as its edge and its content', (tester) async {
      await tester.pumpWidget(_host(_tile(tone: tone)));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MxChoiceTile));
      final answer = tone == MxChoiceTone.right
          ? context.status.success
          : context.colors.error;
      final decoration = _decoration(tester);
      expect(decoration.color, answer.tintOver(MxTintBase.of(context)));
      expect((decoration.border! as Border).top.color, answer);
      expect(tester.widget<Text>(find.text('① 보기 1')).style?.color, answer);
    });
  }

  testWidgets('an idle recessed tile sits on the muted ground', (tester) async {
    await tester.pumpWidget(_host(_tile(isRecessed: true)));
    await tester.pumpAndSettle();

    expect(_decoration(tester).color, buildLightTheme().colors.muted);
  });

  testWidgets('a faded tile drops to the muted opacity and stays tappable', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(_host(_tile(isFaded: true, onTap: () => taps++)));
    await tester.pumpAndSettle();

    final fade = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(MxChoiceTile),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(fade.opacity, const AppDimens().opacityMuted);
    await tester.tap(find.byType(MxChoiceTile));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('the tone eases in, and lands at once under Remove animations', (
    tester,
  ) async {
    final colors = buildLightTheme().colors;
    Widget host({required bool still, required MxChoiceTone tone}) => _host(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: still),
          child: _tile(tone: tone),
        ),
      ),
    );

    await tester.pumpWidget(host(still: false, tone: MxChoiceTone.idle));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(still: false, tone: MxChoiceTone.selected));
    await tester.pump(const Duration(milliseconds: 50));
    expect(_decoration(tester).color, isNot(colors.primary));
    await tester.pumpAndSettle();
    expect(_decoration(tester).color, colors.primary);

    await tester.pumpWidget(host(still: true, tone: MxChoiceTone.idle));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(still: true, tone: MxChoiceTone.selected));
    await tester.pump();
    expect(_decoration(tester).color, colors.primary);
  });

  testWidgets('the sort key reaches the node TalkBack reads', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(_tile(sortKey: const OrdinalSortKey(3), onTap: () {})),
    );

    final key = tester.getSemantics(find.byType(MxChoiceTile)).sortKey;
    expect(key, isA<OrdinalSortKey>());
    expect((key! as OrdinalSortKey).order, 3);
    handle.dispose();
  });

  for (final brightness in Brightness.values) {
    testWidgets('Tab reaches the tile, Enter presses it and the theme focus '
        'outline marks it (${brightness.name})', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(_tile(onTap: () => taps++), brightness: brightness),
      );
      useKeyboardFocusHighlight();
      final ring = forUiTheme(
        tester,
        find.byType(MxChoiceTile),
      ).style.focusedOutlineStyle;
      expect(
        tester.renderObject(find.byType(MxChoiceTile)),
        isNot(paintsFocusRing(ring.color, width: ring.width)),
      );

      await tabTo(tester, find.text('① 보기 1'));

      expect(
        focusRingRender(tester),
        paintsFocusRing(ring.color, width: ring.width),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 1);
    });
  }

  testWidgets('an inert tile takes no focus', (tester) async {
    await tester.pumpWidget(_host(_tile()));
    useKeyboardFocusHighlight();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(MxChoiceTile),
        matching: find.byElementPredicate(
          (e) => e == FocusManager.instance.primaryFocus?.context,
        ),
      ),
      findsNothing,
    );
  });
}
