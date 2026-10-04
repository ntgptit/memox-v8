import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';

import 'support/mx_harness.dart';

Finder _fill() => find
    .descendant(
      of: find.byType(MxLinearProgress),
      matching: find.byType(DecoratedBox),
    )
    .at(1);

Widget _bar(
  double value, {
  MxLinearProgressSize size = MxLinearProgressSize.regular,
}) => SizedBox(
  width: 200,
  child: MxLinearProgress(value: value, semanticLabel: 'Session', size: size),
);

void main() {
  testWidgets('the fill is the value\'s share of the track', (tester) async {
    await pumpMx(tester, _bar(0.25));
    await tester.pumpAndSettle();
    expect(tester.getSize(_fill()).width, 50);
    expect(
      tester.getSize(find.byType(MxLinearProgress)).height,
      AppSize.progress,
    );
  });

  testWidgets('0 draws no fill; 100% fills the track', (tester) async {
    await pumpMx(tester, _bar(0));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(MxLinearProgress),
        matching: find.byType(DecoratedBox),
      ),
      findsOneWidget,
    );
    await pumpMx(tester, _bar(1));
    await tester.pumpAndSettle();
    expect(tester.getSize(_fill()).width, 200);
  });

  testWidgets('a small share above 0 still shows a dot', (tester) async {
    await pumpMx(tester, _bar(0.001, size: MxLinearProgressSize.thick));
    await tester.pumpAndSettle();
    expect(tester.getSize(_fill()), const Size.square(AppSize.progressThick));
  });

  testWidgets('it fills from the start edge in RTL', (tester) async {
    await pumpMx(tester, _bar(0.25), textDirection: TextDirection.rtl);
    await tester.pumpAndSettle();
    expect(
      tester.getTopRight(_fill()).dx,
      tester.getTopRight(find.byType(MxLinearProgress)).dx,
    );
  });

  testWidgets('thick is 8', (tester) async {
    await pumpMx(tester, _bar(0.5, size: MxLinearProgressSize.thick));
    expect(
      tester.getSize(find.byType(MxLinearProgress)).height,
      AppSize.progressThick,
    );
  });

  testWidgets('TalkBack reads what it measures and its value', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      const SizedBox(
        width: 200,
        child: MxLinearProgress(
          value: 0.62,
          semanticLabel: 'Mastery',
          semanticValue: '62%',
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(MxLinearProgress)),
      isSemantics(label: 'Mastery', value: '62%'),
    );
    semantics.dispose();
  });

  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    final AppSemanticColors x = theme.extension<AppSemanticColors>()!;
    final Map<MxLinearProgressTone, Color> fills = {
      MxLinearProgressTone.secondary: s.secondary,
      MxLinearProgressTone.newCard: x.statusNew,
      MxLinearProgressTone.learning: x.statusLearning,
      MxLinearProgressTone.reviewing: x.statusReviewing,
      MxLinearProgressTone.mastered: x.statusMastered,
      MxLinearProgressTone.success: x.success,
      MxLinearProgressTone.warning: x.warning,
      MxLinearProgressTone.danger: s.error,
    };
    for (final MapEntry(key: tone, value: fill) in fills.entries) {
      testWidgets('$name: ${tone.name} fills on the low track', (tester) async {
        await pumpMx(
          tester,
          SizedBox(
            width: 200,
            child: MxLinearProgress(
              value: 0.5,
              semanticLabel: 'Bar',
              tone: tone,
            ),
          ),
          theme: theme,
        );
        await tester.pumpAndSettle();
        final List<Color?> colors = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(MxLinearProgress),
                matching: find.byType(DecoratedBox),
              ),
            )
            .map((box) => (box.decoration as BoxDecoration).color)
            .toList();
        expect(colors, [s.surfaceContainerLow, fill]);
      });
    }

    testWidgets('$name: the generic bar is secondary, never primary', (
      tester,
    ) async {
      await pumpMx(tester, _bar(0.5), theme: theme);
      await tester.pumpAndSettle();
      final Color? fill =
          (tester.widget<DecoratedBox>(_fill()).decoration as BoxDecoration)
              .color;
      expect(fill, s.secondary);
      expect(fill, isNot(s.primary));
    });
  }
}
