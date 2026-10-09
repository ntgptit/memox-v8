import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/presentation/widgets/items/card_add_details_widget.dart';
import 'package:memox/features/card/presentation/widgets/items/card_removable_tag_chip_widget.dart';

import '../../../support/library_harness.dart';

// A glyph is ink, so it reads in primaryForeground; the tag chip's pill is
// the primaryContainer role.
void main() {
  Color? glyphColor(WidgetTester tester, Type owner) => IconTheme.of(
    tester.element(
      find
          .descendant(of: find.byType(owner), matching: find.byType(Icon))
          .first,
    ),
  ).color;

  libraryTest('Add details: the glyph is primaryForeground', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(body: CardAddDetailsWidget(onPressed: () {})),
      brightness: Brightness.dark,
    );
    final context = tester.element(find.byType(CardAddDetailsWidget));
    expect(
      glyphColor(tester, CardAddDetailsWidget),
      context.semanticColors.primaryForeground,
    );
  });

  libraryTest('a removable tag chip: the glyph is primaryForeground', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: CardRemovableTagChipWidget(name: 'verb', onRemove: () {}),
      ),
      brightness: Brightness.dark,
    );
    final context = tester.element(find.byType(CardRemovableTagChipWidget));
    expect(
      glyphColor(tester, CardRemovableTagChipWidget),
      context.semanticColors.primaryForeground,
    );
  });

  libraryTest('a removable tag chip: the pill is primaryContainer and the '
      'label onPrimaryContainer', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: CardRemovableTagChipWidget(name: 'verb', onRemove: () {}),
      ),
      brightness: Brightness.dark,
    );
    final context = tester.element(find.byType(CardRemovableTagChipWidget));
    final pill = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(CardRemovableTagChipWidget),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(
      (pill.decoration as BoxDecoration).color,
      context.colors.primaryContainer,
    );
    final label = tester.widget<Text>(find.text('verb'));
    expect(label.style!.color, context.colors.onPrimaryContainer);
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
