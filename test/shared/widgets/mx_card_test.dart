import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import 'support/mx_harness.dart';

BoxDecoration _surface(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(MxCard),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    final AppSemanticColors x = theme.extension<AppSemanticColors>()!;
    final Map<MxCardTone, Color> grounds = {
      MxCardTone.raised: s.surfaceContainerLowest,
      MxCardTone.hero: s.primaryContainer,
      MxCardTone.warning: x.warningContainer,
      MxCardTone.success: x.successContainer,
      MxCardTone.danger: s.errorContainer,
      MxCardTone.recessed: s.surfaceContainerLow,
    };
    for (final MapEntry(key: tone, value: ground) in grounds.entries) {
      testWidgets('$name: ${tone.name} sits on its ground', (tester) async {
        await pumpMx(
          tester,
          MxCard(tone: tone, child: const Text('Spanish')),
          theme: theme,
        );
        expect(_surface(tester).color, ground);
      });
    }

    testWidgets('$name: raised is a whisper in light, a hairline in dark', (
      tester,
    ) async {
      await pumpMx(tester, const MxCard(child: Text('Spanish')), theme: theme);
      final BoxDecoration box = _surface(tester);
      if (name == 'dark') {
        expect(box.border!.top.color, s.outlineVariant);
        expect(box.boxShadow, isEmpty);
        return;
      }
      expect(box.boxShadow, hasLength(1));
      expect(box.border!.top.style, BorderStyle.none);
    });

    testWidgets('$name: chosen is a 2dp Indigo Accent edge', (tester) async {
      await pumpMx(
        tester,
        const MxCard(isSelected: true, child: Text('Spanish')),
        theme: theme,
      );
      final BorderSide edge = _surface(tester).border!.top;
      expect(edge.color, s.onPrimaryContainer);
      expect(edge.width, AppStroke.control);
    });
  }

  testWidgets('a 20 interior, none when full-bleed', (tester) async {
    await pumpMx(tester, const MxCard(child: Text('Spanish')));
    expect(
      tester.getTopLeft(find.text('Spanish')) -
          tester.getTopLeft(find.byType(MxCard)),
      const Offset(AppSpacing.card, AppSpacing.card),
    );
    await pumpMx(
      tester,
      const MxCard(isFullBleed: true, child: Text('Spanish')),
    );
    expect(
      tester.getTopLeft(find.text('Spanish')),
      tester.getTopLeft(find.byType(MxCard)),
    );
  });

  testWidgets('tinted content reads in the tone\'s on-container', (
    tester,
  ) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    await pumpMx(
      tester,
      const MxCard(tone: MxCardTone.danger, child: Text('Failed')),
    );
    final RenderParagraph text = tester.renderObject(find.text('Failed'));
    expect(text.text.style!.color, s.onErrorContainer);
  });

  testWidgets('a tappable card taps and takes the keyboard ring', (
    tester,
  ) async {
    var taps = 0;
    final Widget card = SizedBox(
      width: 200,
      child: MxCard(onTap: () => taps++, child: const Text('Spanish')),
    );
    await pumpMx(tester, card);
    await tester.tap(find.text('Spanish'));
    expect(taps, 1);
    final Size painted = tester.getSize(find.byType(MxCard));
    await expectMxKeyboardRingOnly(tester, card, painted: painted);
  });

  testWidgets('TalkBack hears a tappable card as a button, and its choice', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      MxCard(isSelected: true, onTap: () {}, child: const Text('Spanish')),
    );
    expect(
      tester.getSemantics(find.text('Spanish')),
      containsSemantics(
        label: 'Spanish',
        isButton: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    await pumpMx(tester, const MxCard(child: Text('Spanish')));
    expect(
      tester.getSemantics(find.text('Spanish')),
      containsSemantics(label: 'Spanish', isButton: false, isSelected: false),
    );
    semantics.dispose();
  });

  testWidgets('choosing a card moves neither its size nor its content', (
    tester,
  ) async {
    for (final ThemeData theme in mxThemes.values) {
      await pumpMx(
        tester,
        const SizedBox(width: 200, child: MxCard(child: Text('Spanish'))),
        theme: theme,
      );
      final Rect rest = tester.getRect(find.text('Spanish'));
      final Size card = tester.getSize(find.byType(MxCard));
      await pumpMx(
        tester,
        const SizedBox(
          width: 200,
          child: MxCard(isSelected: true, child: Text('Spanish')),
        ),
        theme: theme,
      );
      expect(tester.getRect(find.text('Spanish')), rest);
      expect(tester.getSize(find.byType(MxCard)), card);
    }
  });
}
