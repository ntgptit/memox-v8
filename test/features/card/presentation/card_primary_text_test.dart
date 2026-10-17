import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_palette.dart';

import 'package:memox/features/card/presentation/widgets/items/card_add_details_widget.dart';
import 'package:memox/features/card/presentation/widgets/items/card_removable_tag_chip_widget.dart';

import '../../../support/library_harness.dart';

// A glyph reads in the accent colour; the tag chip is the shared ForUI chip.
void main() {
  final accent = appDarkColors.primary;

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

  // The removable tag is the shared chip at rest: ForUI's extra-small outline
  // button, its fill, label and glyph.
  libraryTest(
    'a removable tag chip: the outline chip\'s fill, label and glyph',
    (tester, env) async {
      await pumpLibraryScreen(
        tester,
        env,
        Scaffold(
          body: CardRemovableTagChipWidget(name: 'verb', onRemove: () {}),
        ),
        brightness: Brightness.dark,
      );
      final chip = find.byType(CardRemovableTagChipWidget);
      final style = _chipStyle(tester, chip);
      final fill =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: chip,
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as ShapeDecoration;

      expect(fill.color, (style.decoration.base as ShapeDecoration).color);
      expect(
        glyphColor(tester, CardRemovableTagChipWidget),
        style.contentStyle.iconStyle.base.color,
      );
      expect(
        tester.widget<Text>(find.text('verb')).style!.color,
        style.contentStyle.textStyle.base.color,
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

  // The shared chip: 32 tall with ForUI's outline edge and glyph, and the
  // whole 48 area removes the tag.
  libraryTest('a removable tag chip: the chip geometry', (tester, env) async {
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

    final style = _chipStyle(tester, find.byType(CardRemovableTagChipWidget));

    expect(tester.getSize(chip.first).height, 32);
    expect(decoration.shape, (style.decoration.base as ShapeDecoration).shape);
    expect(
      tester
          .getSize(
            find.descendant(
              of: find.byType(CardRemovableTagChipWidget),
              matching: find.byType(Icon),
            ),
          )
          .width,
      style.contentStyle.iconStyle.base.size,
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

/// The style ForUI gives the extra-small outline button the chip is drawn in.
FButtonStyle _chipStyle(WidgetTester tester, Finder chip) {
  final context = tester.element(chip);
  return FTheme.of(context).buttonStyles.outline
      .resolve({context.platformVariant, FButtonSizeVariant.xs});
}
