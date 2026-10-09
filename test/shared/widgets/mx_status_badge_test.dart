import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

import '../../support/widget_harness.dart';

const _dotKey = ValueKey('mx-status-dot');

Color? _fill(WidgetTester tester, Finder finder) =>
    (tester.widget<DecoratedBox>(finder).decoration as BoxDecoration).color;

void main() {
  testWidgets('the status fixes the dot (fill), the pill (container) and '
      'the label (on-container)', (tester) async {
    for (final status in MxCardStatus.values) {
      await pumpMx(tester, MxStatusBadge(status: status, label: 'State'));
      final context = tester.element(find.byType(MxStatusBadge));
      final pill = find
          .descendant(
            of: find.byType(MxStatusBadge),
            matching: find.byType(DecoratedBox),
          )
          .first;

      expect(_fill(tester, pill), status.container(context));
      expect(_fill(tester, find.byKey(_dotKey)), status.fill(context));
      expect(
        tester.widget<Text>(find.text('State')).style!.color,
        status.onContainer(context),
      );
    }
  });

  testWidgets('pill: 22 tall, 6 before the 6 dot, 4 gap, 8 after', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxStatusBadge(status: MxCardStatus.learning, label: 'Learning'),
    );
    final badge = tester.getRect(find.byType(MxStatusBadge));
    final dot = tester.getRect(find.byKey(_dotKey));
    final label = tester.getRect(find.text('Learning'));

    expect(badge.height, 22);
    expect(dot.size, const Size.square(6));
    expect(dot.left - badge.left, 6);
    expect(label.left - dot.right, 4);
    expect(badge.right - label.right, 8);
  });

  testWidgets('dot only: an 8 circle announced by its label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxStatusBadge(
        status: MxCardStatus.mastered,
        label: 'Mastered',
        isDot: true,
      ),
    );

    expect(tester.getSize(find.byKey(_dotKey)), const Size.square(8));
    expect(find.text('Mastered'), findsNothing);
    expect(find.bySemanticsLabel('Mastered'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('status roles (spec 2026-10-08 §4.7): fill, foreground, '
      'container, on-container, both themes', (tester) async {
    for (final brightness in Brightness.values) {
      late BuildContext context;
      await pumpMx(
        tester,
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
        brightness: brightness,
      );
      final colors = context.colors;
      final semantic = context.semanticColors;
      expect(MxCardStatus.newCard.fill(context), colors.outline);
      expect(MxCardStatus.newCard.foreground(context), colors.onSurfaceVariant);
      expect(
        MxCardStatus.newCard.container(context),
        colors.surfaceContainerHigh,
      );
      expect(
        MxCardStatus.newCard.onContainer(context),
        colors.onSurfaceVariant,
      );
      expect(MxCardStatus.learning.fill(context), semantic.warning);
      expect(MxCardStatus.learning.foreground(context), semantic.warning);
      expect(
        MxCardStatus.learning.container(context),
        semantic.warningContainer,
      );
      expect(
        MxCardStatus.learning.onContainer(context),
        semantic.onWarningContainer,
      );
      expect(MxCardStatus.reviewing.fill(context), colors.primary);
      expect(
        MxCardStatus.reviewing.foreground(context),
        semantic.primaryForeground,
      );
      expect(
        MxCardStatus.reviewing.container(context),
        colors.primaryContainer,
      );
      expect(
        MxCardStatus.reviewing.onContainer(context),
        colors.onPrimaryContainer,
      );
      expect(MxCardStatus.mastered.fill(context), semantic.mastery);
      expect(MxCardStatus.mastered.foreground(context), semantic.mastery);
      expect(
        MxCardStatus.mastered.container(context),
        semantic.masteryContainer,
      );
      expect(
        MxCardStatus.mastered.onContainer(context),
        semantic.onMasteryContainer,
      );
    }
  });

  testWidgets('the pill is the container with its on-container label and '
      'the fill dot', (tester) async {
    await pumpMx(
      tester,
      const MxStatusBadge(status: MxCardStatus.learning, label: 'Learning'),
      brightness: Brightness.dark,
    );
    final pill = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    expect(
      (pill.decoration as BoxDecoration).color,
      MxSemanticColors.dark.warningContainer,
    );
    expect(
      tester.widget<Text>(find.text('Learning')).style!.color,
      MxSemanticColors.dark.onWarningContainer,
    );
  });
}
