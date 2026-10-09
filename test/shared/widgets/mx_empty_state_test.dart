import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_note.dart';

import '../../support/widget_harness.dart';

Finder _tile(IconData icon) => find
    .ancestor(of: find.byIcon(icon), matching: find.byType(DecoratedBox))
    .first;

void main() {
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

  testWidgets('each tone is its container with its foreground glyph', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      final colors = brightness == Brightness.light
          ? AppColorSchemes.light
          : AppColorSchemes.dark;
      final semantic = brightness == Brightness.light
          ? MxSemanticColors.light
          : MxSemanticColors.dark;
      final tones = {
        MxEmptyStateTone.primary: (
          colors.primaryContainer,
          semantic.primaryForeground,
        ),
        MxEmptyStateTone.neutral: (
          colors.surfaceContainerHigh,
          colors.onSurfaceVariant,
        ),
        MxEmptyStateTone.success: (semantic.successContainer, semantic.success),
        MxEmptyStateTone.warning: (semantic.warningContainer, semantic.warning),
        MxEmptyStateTone.danger: (colors.errorContainer, colors.error),
      };
      for (final MapEntry(key: tone, value: (ground, glyph)) in tones.entries) {
        await pumpMx(
          tester,
          MxEmptyState(icon: AppIcons.inbox, title: 'T', tone: tone),
          brightness: brightness,
        );
        // The theme animates from the previous brightness.
        await tester.pumpAndSettle();
        final tile = tester.widget<DecoratedBox>(_tile(AppIcons.inbox));

        expect(
          (tile.decoration as BoxDecoration).color,
          ground,
          reason: '$tone ${brightness.name}',
        );
        expect(
          tester.widget<Icon>(find.byIcon(AppIcons.inbox)).color,
          glyph,
          reason: '$tone ${brightness.name} glyph',
        );
      }
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

  testWidgets('a footnote sits 20 below the action as a note', (tester) async {
    await pumpMx(
      tester,
      MxEmptyState(
        icon: AppIcons.inbox,
        title: 'Trash is empty',
        actionLabel: 'Back to library',
        onAction: () {},
        footnote: 'Deleted items stay here for 30 days.',
      ),
    );

    expect(
      tester.getTopLeft(find.byType(MxNote)).dy -
          tester.getBottomLeft(find.byType(MxButton)).dy,
      20,
    );
    // The footnote form, with no fill and no edge: a boxed note inside the
    // raised card was two ghost edges in dark (audit 2026-10-08 F-02).
    expect(tester.widget<MxNote>(find.byType(MxNote)).isHint, isTrue);
  });

  testWidgets('a secondary action sits between the action and the footnote', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxEmptyState(
        icon: AppIcons.library,
        title: 'Start your library',
        actionLabel: 'Create deck',
        onAction: () {},
        secondaryActionLabel: 'Browse starter decks',
        footnote: 'Everything stays on this device.',
      ),
    );
    final primary = tester.getTopLeft(find.text('Create deck')).dy;
    final secondary = tester.getTopLeft(find.text('Browse starter decks')).dy;
    final note = tester
        .getTopLeft(find.text('Everything stays on this device.'))
        .dy;

    expect(primary, lessThan(secondary));
    expect(secondary, lessThan(note));
  });

  testWidgets('a secondary action without a callback is disabled', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxEmptyState(
        icon: AppIcons.library,
        title: 'Start your library',
        secondaryActionLabel: 'Browse starter decks',
      ),
    );
    final button = tester.widget<MxButton>(
      find.widgetWithText(MxButton, 'Browse starter decks'),
    );

    expect(button.onPressed, isNull);
    expect(button.tone, MxButtonTone.secondary);
  });
  testWidgets('a third action is an outline block button, 8 under the second', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxEmptyState(
        icon: AppIcons.folder,
        title: 'Empty deck',
        actionLabel: 'New card',
        onAction: () {},
        secondaryActionLabel: 'New sub-deck',
        onSecondaryAction: () {},
        tertiaryActionLabel: 'Import cards',
        onTertiaryAction: () => taps++,
      ),
    );
    final buttons = tester.widgetList<MxButton>(find.byType(MxButton)).toList();

    expect(buttons.map((b) => b.tone), [
      MxButtonTone.primary,
      MxButtonTone.secondary,
      MxButtonTone.outline,
    ]);
    expect(buttons.every((b) => b.isBlock), isTrue);
    expect(
      tester.getTopLeft(find.widgetWithText(MxButton, 'Import cards')).dy -
          tester
              .getBottomLeft(find.widgetWithText(MxButton, 'New sub-deck'))
              .dy,
      8,
    );
    await tester.tap(find.text('Import cards'));
    expect(taps, 1);
  });

  test('a tertiary label without its callback is a programming error', () {
    expect(
      () => MxEmptyState(
        icon: AppIcons.inbox,
        title: 'x',
        tertiaryActionLabel: 'Import',
      ),
      throwsAssertionError,
    );
  });
}
