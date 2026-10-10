import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/features/card/presentation/widgets/items/card_add_details_widget.dart';
import 'package:memox/features/card/presentation/widgets/items/card_removable_tag_chip_widget.dart';

import '../../../support/library_harness.dart';

// Spec 2026-10-10 §5.2: a primary glyph reads primaryText; the tag chip is a
// primary soft ground.
void main() {
  final primaryText = MxSemanticColors.dark.primaryText;

  Color? glyphColor(WidgetTester tester, Type owner) => IconTheme.of(
    tester.element(
      find
          .descendant(of: find.byType(owner), matching: find.byType(Icon))
          .first,
    ),
  ).color;

  libraryTest('Add details: the glyph is primaryText', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(body: CardAddDetailsWidget(onPressed: () {})),
      brightness: Brightness.dark,
    );
    expect(glyphColor(tester, CardAddDetailsWidget), primaryText);
  });

  libraryTest('a removable tag chip: the primary soft ground, glyph and label '
      'on-soft, light in Night too (spec 2026-10-10 D4)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: CardRemovableTagChipWidget(name: 'verb', onRemove: () {}),
      ),
      brightness: Brightness.dark,
    );
    const night = MxSemanticColors.dark;
    expect(glyphColor(tester, CardRemovableTagChipWidget), night.onPrimarySoft);
    expect(
      tester.widget<Text>(find.text('verb')).style!.color,
      night.onPrimarySoft,
    );
    final ground = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(CardRemovableTagChipWidget),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((ground.decoration as BoxDecoration).color, night.primarySoft);
  });

  // SW-REV-005: the chip's one TalkBack node keeps the tap that removes it.
  libraryTest('a removable tag chip: TalkBack keeps its tap', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    var removed = 0;
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: CardRemovableTagChipWidget(
          name: 'verb',
          onRemove: () => removed++,
        ),
      ),
    );
    final node = tester.getSemantics(find.bySemanticsLabel(RegExp('verb')));
    expect(node, isSemantics(hasTapAction: true));
    tester.semantics.tap(find.semantics.byLabel(RegExp('verb')));
    await tester.pump();
    expect(removed, 1);
    handle.dispose();
  });
}
