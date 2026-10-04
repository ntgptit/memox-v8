import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:flutter/rendering.dart';

import 'support/mx_harness.dart';

Widget _large(Widget child) => MediaQuery(
  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
  child: child,
);

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final AppSemanticColors x = theme.extension<AppSemanticColors>()!;
    final Map<MxStatusBadgeKind, (Color, Color)> pairs = {
      MxStatusBadgeKind.newCard: (x.statusNew, x.statusNewContainer),
      MxStatusBadgeKind.learning: (x.statusLearning, x.statusLearningContainer),
      MxStatusBadgeKind.reviewing: (
        x.statusReviewing,
        x.statusReviewingContainer,
      ),
      MxStatusBadgeKind.mastered: (x.statusMastered, x.statusMasteredContainer),
    };
    for (final MapEntry(key: kind, value: (mark, ground)) in pairs.entries) {
      testWidgets('$name: ${kind.name} dots its mark on its container', (
        tester,
      ) async {
        await pumpMx(
          tester,
          MxStatusBadge(kind: kind, label: kind.name),
          theme: theme,
        );
        final List<Color?> fills = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .map((box) => (box.decoration as BoxDecoration).color)
            .toList();
        expect(fills, containsAll(<Color>[ground, mark]));
      });
    }
  }

  testWidgets('the dot form is 8 and still named for TalkBack', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxStatusBadge(
        kind: MxStatusBadgeKind.learning,
        label: 'Learning',
        isDot: true,
      ),
    );
    expect(
      tester.getSize(find.byType(MxStatusBadge)),
      const Size.square(AppSize.statusDot),
    );
    expect(find.text('Learning'), findsNothing);
    expect(
      tester.getSemantics(find.byType(MxStatusBadge)),
      isSemantics(label: 'Learning'),
    );
    semantics.dispose();
  });

  testWidgets('at large text a narrow badge wraps rather than cut its label', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _large(
        const SizedBox(
          width: 80,
          child: MxStatusBadge(
            kind: MxStatusBadgeKind.reviewing,
            label: 'Reviewing',
          ),
        ),
      ),
    );
    expect(
      tester
          .renderObject<RenderParagraph>(find.text('Reviewing'))
          .didExceedMaxLines,
      isFalse,
    );
  });
}
