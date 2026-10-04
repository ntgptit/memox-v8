import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:flutter/rendering.dart';

import 'support/mx_harness.dart';

Widget _large(Widget child) => MediaQuery(
  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
  child: child,
);

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    final AppSemanticColors x = theme.extension<AppSemanticColors>()!;
    final Map<MxBadgeTone, (Color, Color)> pairs = {
      MxBadgeTone.primary: (s.primaryContainer, s.onPrimaryContainer),
      MxBadgeTone.mastery: (
        x.statusMasteredContainer,
        x.onStatusMasteredContainer,
      ),
      MxBadgeTone.success: (x.successContainer, x.onSuccessContainer),
      MxBadgeTone.warning: (x.warningContainer, x.onWarningContainer),
      MxBadgeTone.danger: (s.errorContainer, s.onErrorContainer),
      MxBadgeTone.neutral: (s.surfaceContainerHigh, s.onSurfaceVariant),
    };
    for (final MapEntry(key: tone, value: (ground, content)) in pairs.entries) {
      testWidgets('$name: ${tone.name} is its container pair', (tester) async {
        await pumpMx(
          tester,
          MxBadge(label: '23 due', tone: tone),
          theme: theme,
        );
        final BoxDecoration box =
            tester.widget<DecoratedBox>(find.byType(DecoratedBox)).decoration
                as BoxDecoration;
        expect(box.color, ground);
        expect(tester.widget<Text>(find.text('23 due')).style!.color, content);
      });
    }
  }

  testWidgets('22 tall at rest, taller with large text', (tester) async {
    await pumpMx(tester, const MxBadge(label: '23 due'));
    expect(tester.getSize(find.byType(MxBadge)).height, AppSize.badge);
    await tester.pumpWidget(
      MaterialApp(
        theme: mxThemes['light'],
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Center(child: MxBadge(label: '23 due')),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(MxBadge)).height,
      greaterThan(AppSize.badge),
    );
  });

  testWidgets('at large text a narrow badge wraps rather than cut its unit', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _large(const SizedBox(width: 64, child: MxBadge(label: '23 due'))),
    );
    expect(
      tester
          .renderObject<RenderParagraph>(find.text('23 due'))
          .didExceedMaxLines,
      isFalse,
    );
  });
}
