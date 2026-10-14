import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';

import '../../../support/theme_expect.dart';

import 'package:memox/features/card/presentation/widgets/items/card_add_details_widget.dart';
import 'package:memox/features/card/presentation/widgets/items/card_removable_tag_chip_widget.dart';

import '../../../support/library_harness.dart';

// A glyph reads in the accent colour; the tag chip is the Material 3 input chip.
void main() {
  final accent = accentOf(darkColorScheme);

  Color? glyphColor(WidgetTester tester, Type owner) => IconTheme.of(
    tester.element(
      find
          .descendant(of: find.byType(owner), matching: find.byType(Icon))
          .first,
    ),
  ).color;

  libraryTest('Add details: the glyph is the accent', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(body: CardAddDetailsWidget(onPressed: () {})),
      brightness: Brightness.dark,
    );
    expect(glyphColor(tester, CardAddDetailsWidget), accent);
  });

  // Material 3 unselected input chip: no fill, onSurfaceVariant label and
  // remove glyph.
  libraryTest(
    'a removable tag chip: no fill, onSurfaceVariant label and glyph',
    (tester, env) async {
      await pumpLibraryScreen(
        tester,
        env,
        Scaffold(
          body: CardRemovableTagChipWidget(name: 'verb', onRemove: () {}),
        ),
        brightness: Brightness.dark,
      );
      final fill =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(CardRemovableTagChipWidget),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as ShapeDecoration;

      expect(fill.color, isNull);
      expect(
        glyphColor(tester, CardRemovableTagChipWidget),
        darkColorScheme.onSurfaceVariant,
      );
      expect(
        tester.widget<Text>(find.text('verb')).style!.color,
        darkColorScheme.onSurfaceVariant,
      );
    },
  );

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

  // Material 3 input chip: 32 tall, an 8 corner with a 1dp outlineVariant
  // edge, an 18 remove glyph, and the whole 48 area removes the tag.
  libraryTest('a removable tag chip: the M3 input chip geometry', (
    tester,
    env,
  ) async {
    var removed = 0;
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: Center(
          child: CardRemovableTagChipWidget(
            name: 'verb',
            onRemove: () => removed++,
          ),
        ),
      ),
    );
    final chip = find.descendant(
      of: find.byType(CardRemovableTagChipWidget),
      matching: find.byType(DecoratedBox),
    );
    final decoration =
        tester.widget<DecoratedBox>(chip.first).decoration as ShapeDecoration;

    expect(tester.getSize(chip.first).height, 32);
    expect(
      decoration.shape,
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: lightColorScheme.outlineVariant),
      ),
    );
    expect(
      tester
          .getSize(
            find.descendant(
              of: find.byType(CardRemovableTagChipWidget),
              matching: find.byType(Icon),
            ),
          )
          .width,
      18,
    );
    expect(
      tester.getSize(find.byType(CardRemovableTagChipWidget)).height,
      greaterThanOrEqualTo(48),
    );
    // A tap on the chip's top edge, outside the 32 box but inside the 48
    // area, still removes the tag.
    await tester.tapAt(tester.getTopLeft(chip.first) + const Offset(20, -6));
    expect(removed, 1);
  });
}
