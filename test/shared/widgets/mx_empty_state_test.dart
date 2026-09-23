import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

import '../../support/widget_harness.dart';

Finder _tile(IconData icon) => find
    .ancestor(of: find.byIcon(icon), matching: find.byType(DecoratedBox))
    .first;

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('title, body and a block primary action', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxEmptyState(
        icon: AppIcons.inbox,
        title: 'No decks yet',
        body: 'Create one to start.',
        actionLabel: 'Create deck',
        onAction: () => taps++,
      ),
    );
    await tester.tap(find.byType(MxButton));

    expect(find.text('No decks yet'), findsOneWidget);
    expect(find.text('Create one to start.'), findsOneWidget);
    final button = tester.widget<MxButton>(find.byType(MxButton));
    expect(button.tone, MxButtonTone.primary);
    expect(button.isBlock, isTrue);
    expect(taps, 1);
  });

  testWidgets('no action paints no button', (tester) async {
    await pumpMx(
      tester,
      const MxEmptyState(icon: AppIcons.search, title: 'No match'),
    );

    expect(find.byType(MxButton), findsNothing);
  });

  test('a label without a callback is a programming error', () {
    expect(
      () => MxEmptyState(icon: AppIcons.inbox, title: 'x', actionLabel: 'Go'),
      throwsAssertionError,
    );
  });

  testWidgets('tone tints the tile at 10% and paints the glyph', (
    tester,
  ) async {
    final tones = {
      MxEmptyStateTone.primary: scheme.primary,
      MxEmptyStateTone.neutral: scheme.onSurfaceVariant,
      MxEmptyStateTone.success: MxSemanticColors.light.mastery,
      MxEmptyStateTone.warning: MxSemanticColors.light.warning,
      MxEmptyStateTone.danger: scheme.error,
    };
    for (final MapEntry(key: tone, value: color) in tones.entries) {
      await pumpMx(
        tester,
        MxEmptyState(icon: AppIcons.inbox, title: 'T', tone: tone),
      );
      final tile = tester.widget<DecoratedBox>(_tile(AppIcons.inbox));

      expect(
        (tile.decoration as BoxDecoration).color,
        color.withValues(alpha: 0.10),
        reason: '$tone',
      );
      expect(tester.widget<Icon>(find.byIcon(AppIcons.inbox)).color, color);
    }
  });

  testWidgets('full tile is 64/r20/32 glyph, compact 52/r16/24', (
    tester,
  ) async {
    await pumpMx(tester, const MxEmptyState(icon: AppIcons.inbox, title: 'T'));
    expect(tester.getSize(_tile(AppIcons.inbox)), const Size.square(64));
    expect(tester.getSize(find.byIcon(AppIcons.inbox)).width, 32);

    await pumpMx(
      tester,
      const MxEmptyState(icon: AppIcons.inbox, title: 'T', isCompact: true),
    );
    expect(tester.getSize(_tile(AppIcons.inbox)), const Size.square(52));
    expect(tester.getSize(find.byIcon(AppIcons.inbox)).width, 24);
  });

  testWidgets('long copy at 2x text does not overflow', (tester) async {
    await pumpMx(
      tester,
      const MxEmptyState(
        icon: AppIcons.inbox,
        title: 'Nothing is due today across every deck you study',
        body: 'Every card is resting until its next review date arrives.',
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
  });
}
