import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

import '../../support/widget_harness.dart';

const _dotKey = ValueKey('mx-status-dot');

Color? _fill(WidgetTester tester, Finder finder) =>
    (tester.widget<DecoratedBox>(finder).decoration as BoxDecoration).color;

void main() {
  final semantic = MxSemanticColors.light;

  testWidgets('the status fixes the dot and fill; the label is its ink', (
    tester,
  ) async {
    final derived = MxDerivedColors.resolve(AppColorSchemes.light, semantic);
    for (final (status, color, ink) in [
      (MxCardStatus.newCard, semantic.statusNew, derived.statusNewInk),
      (
        MxCardStatus.learning,
        semantic.statusLearning,
        derived.statusLearningInk,
      ),
      (
        MxCardStatus.reviewing,
        semantic.statusReviewing,
        derived.statusReviewingInk,
      ),
      (
        MxCardStatus.mastered,
        semantic.statusMastered,
        derived.statusMasteredInk,
      ),
    ]) {
      await pumpMx(tester, MxStatusBadge(status: status, label: 'State'));
      final pill = find
          .descendant(
            of: find.byType(MxStatusBadge),
            matching: find.byType(DecoratedBox),
          )
          .first;

      expect(_fill(tester, pill), color.withValues(alpha: 0.12));
      expect(_fill(tester, find.byKey(_dotKey)), color);
      expect(tester.widget<Text>(find.text('State')).style!.color, ink);
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
}
