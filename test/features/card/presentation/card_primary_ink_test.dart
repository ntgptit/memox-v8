import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/features/card/presentation/widgets/items/card_add_details_widget.dart';
import 'package:memox/features/card/presentation/widgets/items/card_removable_tag_chip_widget.dart';

import '../../../support/library_harness.dart';

// Spec 2026-09-27 D2: a glyph is ink, so it reads in primaryInk; the tag
// chip's tint stays primary.
void main() {
  final ink = MxDerivedColors.primaryInkOf(AppColorSchemes.dark);

  Color? glyphColor(WidgetTester tester, Type owner) => IconTheme.of(
    tester.element(
      find
          .descendant(of: find.byType(owner), matching: find.byType(Icon))
          .first,
    ),
  ).color;

  libraryTest('Add details: the glyph is primaryInk', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(body: CardAddDetailsWidget(onPressed: () {})),
      brightness: Brightness.dark,
    );
    expect(glyphColor(tester, CardAddDetailsWidget), ink);
  });

  libraryTest('a removable tag chip: the glyph is primaryInk', (
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
    expect(glyphColor(tester, CardRemovableTagChipWidget), ink);
  });
}
