import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_note.dart';

import 'support/mx_harness.dart';

Size _tile(WidgetTester tester) => tester.getSize(
  find
      .descendant(
        of: find.byType(MxEmptyState),
        matching: find.byType(SizedBox),
      )
      .first,
);

void main() {
  testWidgets('a 64 tile, a header title, two actions and a footnote', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    var created = 0;
    await pumpMx(
      tester,
      SizedBox(
        width: 360,
        child: MxEmptyState(
          icon: Icons.style,
          title: 'No decks yet',
          message: 'Make a deck, or import one you exported before.',
          action: MxEmptyStateAction(
            label: 'Create deck',
            onPressed: () => created++,
          ),
          secondaryAction: MxEmptyStateAction(
            label: 'Import cards',
            onPressed: () {},
          ),
          footnote: 'Decks stay on this phone until you sign in.',
        ),
      ),
    );
    expect(_tile(tester), const Size.square(AppSize.emptyTile));
    expect(
      tester.getSemantics(find.text('No decks yet')),
      isSemantics(isHeader: true, label: 'No decks yet'),
    );
    final List<MxButton> buttons = tester
        .widgetList<MxButton>(find.byType(MxButton))
        .toList();
    expect(buttons.first.tone, MxButtonTone.primary);
    expect(buttons.last.tone, MxButtonTone.text);
    expect(find.byType(MxNote), findsOneWidget);
    await tester.tap(find.text('Create deck'));
    expect(created, 1);
    semantics.dispose();
  });

  testWidgets('compact is a 48 tile', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 360,
        child: MxEmptyState(
          icon: Icons.search_off,
          title: 'No results',
          isCompact: true,
        ),
      ),
    );
    expect(_tile(tester), const Size.square(AppSize.emptyTileCompact));
  });

  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    final AppSemanticColors x = theme.extension<AppSemanticColors>()!;
    final Map<MxEmptyStateTone, (Color, Color)> pairs = {
      MxEmptyStateTone.primary: (s.primaryContainer, s.onPrimaryContainer),
      MxEmptyStateTone.neutral: (s.surfaceContainerHigh, s.onSurfaceVariant),
      MxEmptyStateTone.success: (x.successContainer, x.onSuccessContainer),
      MxEmptyStateTone.warning: (x.warningContainer, x.onWarningContainer),
      MxEmptyStateTone.danger: (s.errorContainer, s.onErrorContainer),
    };
    for (final MapEntry(key: tone, value: (ground, glyph)) in pairs.entries) {
      testWidgets('$name: ${tone.name} tile', (tester) async {
        await pumpMx(
          tester,
          SizedBox(
            width: 360,
            child: MxEmptyState(icon: Icons.style, title: 'Done', tone: tone),
          ),
          theme: theme,
        );
        final BoxDecoration box =
            tester
                    .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                    .decoration
                as BoxDecoration;
        expect(box.color, ground);
        expect(tester.widget<Icon>(find.byIcon(Icons.style)).color, glyph);
      });
    }
  }
}
